extends Control

const SELECTION_SECONDS := 30.0

@onready var back_button: Button = $Margin/Main/Header/Back
@onready var commander_label: Label = $Margin/Main/Header/Commander
@onready var round_label: Label = $Margin/Main/StatusRow/Round
@onready var selections_label: Label = $Margin/Main/StatusRow/Selections
@onready var timer_label: Label = $Margin/Main/StatusRow/Timer
@onready var offer_row: HBoxContainer = $Margin/Main/OfferPanel/Padding/OfferContent/OfferRow
@onready var skill_button: Button = $Margin/Main/OfferPanel/Padding/OfferContent/CommanderSkill
@onready var army_summary: RichTextLabel = $Margin/Main/SummaryRow/ArmyPanel/Padding/ArmySummary
@onready var buff_summary: RichTextLabel = $Margin/Main/SummaryRow/BuffPanel/Padding/BuffSummary
@onready var footer: Label = $Margin/Main/Footer

var _time_left: float = SELECTION_SECONDS

func _ready() -> void:
    back_button.pressed.connect(_go_back)
    skill_button.pressed.connect(_use_commander_skill)

    if not GameState.match_started:
        footer.text = "No active draft. Return to the Army Builder."
        skill_button.disabled = true
        set_process(false)
        return

    _refresh_all()

func _process(delta: float) -> void:
    if GameState.draft.is_phase_complete():
        return

    _time_left = maxf(0.0, _time_left - delta)
    timer_label.text = "Pick timer: %02d" % int(ceil(_time_left))
    if _time_left <= 0.0:
        if GameState.draft.auto_select():
            _time_left = SELECTION_SECONDS
            _refresh_all()

func _refresh_all() -> void:
    var commander: Dictionary = GameState.get_selected_commander()
    commander_label.text = "%s • Seed %d" % [
        str(commander.get("display_name", "Commander")),
        GameState.match_seed
    ]
    round_label.text = "Opening Pre-Battle"
    selections_label.text = "Selections left: %d" % GameState.draft.selection_points
    timer_label.text = "Pick timer: %02d" % int(ceil(_time_left))

    _refresh_offer()
    _refresh_skill(commander)
    _refresh_summaries()

    if GameState.draft.is_phase_complete():
        footer.text = "Opening draft complete. Your army state is ready for v0.4 deterministic auto-combat."
        timer_label.text = "Draft complete"
    else:
        footer.text = "Round 1 is Army-only. Every pick rerolls all three choices."

func _refresh_offer() -> void:
    for child in offer_row.get_children():
        child.queue_free()

    for index in range(GameState.draft.current_offer.size()):
        var option: Dictionary = GameState.draft.current_offer[index]
        var button := Button.new()
        button.custom_minimum_size = Vector2(330, 180)
        button.text = _option_text(option)
        button.disabled = GameState.draft.is_phase_complete()
        button.pressed.connect(_select_offer.bind(index))
        offer_row.add_child(button)

func _option_text(option: Dictionary) -> String:
    var option_type := str(option.get("type", ""))
    var option_id := str(option.get("id", ""))

    if option_type == "unit":
        var card: Dictionary = ContentDatabase.get_card(option_id)
        var current: int = GameState.draft.get_unit_count(option_id)
        var amount: int = int(card.get("summon_amount", 0))
        var cap: int = int(card.get("unit_cap", 0))
        var after: int = mini(cap, current + amount)
        return "%s\n%s • %s\n+%d units\n%d/%d → %d/%d" % [
            str(card.get("display_name", option_id)),
            str(card.get("element", "")).capitalize(),
            str(card.get("role", "unit")).capitalize(),
            amount,
            current,
            cap,
            after,
            cap
        ]

    var buff: Dictionary = ContentDatabase.get_buff(option_id)
    var stack: int = GameState.draft.get_buff_stacks(option_id)
    return "%s\n+%s%% %s\nStacks %d/%d" % [
        str(buff.get("display_name", option_id)),
        str(buff.get("percentage", 0)),
        str(buff.get("stat", "stat")).replace("_", " ").to_upper(),
        stack,
        int(buff.get("max_stacks", 3))
    ]

func _refresh_skill(commander: Dictionary) -> void:
    var skill: Dictionary = commander.get("active_skill", {})
    skill_button.text = "%s\nCost: 1 selection • Uses left: %d/2" % [
        str(skill.get("display_name", "Commander Skill")),
        GameState.draft.commander_skill_uses_remaining()
    ]
    skill_button.disabled = (
        GameState.draft.is_phase_complete()
        or GameState.draft.commander_skill_used_this_round
        or GameState.draft.commander_skill_uses_remaining() <= 0
    )

func _refresh_summaries() -> void:
    var army_lines: Array[String] = ["[b]Current Army[/b]"]
    for card_id in GameState.army.get_cards():
        var card: Dictionary = ContentDatabase.get_card(card_id)
        army_lines.append("%s  %d/%d" % [
            str(card.get("display_name", card_id)),
            GameState.draft.get_unit_count(card_id),
            int(card.get("unit_cap", 0))
        ])
    army_summary.text = "\n".join(army_lines)

    var buff_lines: Array[String] = ["[b]Active Buffs[/b]"]
    var any_buff := false
    for buff in ContentDatabase.get_all_buffs():
        var buff_id := str(buff.get("id", ""))
        var stacks: int = GameState.draft.get_buff_stacks(buff_id)
        if stacks <= 0:
            continue
        any_buff = true
        buff_lines.append("%s  %d/%d" % [
            str(buff.get("display_name", buff_id)),
            stacks,
            int(buff.get("max_stacks", 3))
        ])
    if not any_buff:
        buff_lines.append("None — buffs begin from Round 2")
    buff_summary.text = "\n".join(buff_lines)

func _select_offer(index: int) -> void:
    if GameState.draft.select_offer(index):
        _time_left = SELECTION_SECONDS
        _refresh_all()

func _use_commander_skill() -> void:
    if GameState.draft.use_commander_skill():
        _time_left = SELECTION_SECONDS
        _refresh_all()

func _go_back() -> void:
    GameState.match_started = false
    get_tree().change_scene_to_file("res://scenes/army_builder/army_builder.tscn")
