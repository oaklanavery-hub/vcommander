extends Control

var session: Node
var main: VBoxContainer
var status_label: Label
var room_label: Label
var code_input: LineEdit
var entry: VBoxContainer
var draft_page: VBoxContainer
var wait_label: Label
var offers: HBoxContainer
var timer_label: Label
var points_label: Label
var skill_button: Button
var resume_button: Button
var create_button: Button
var join_button: Button
var copy_button: Button
var return_button: Button
var own_summary: RichTextLabel
var rival_summary: RichTextLabel
var commander_portrait: CardPortrait
var commander_name: Label
var hearts := MatchHearts.new()
var battle_screen: Control
var _battle_round := 0
var _offer_key := ""

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    session = get_node("/root/OnlineSession")
    _build()
    ScreenStyle.apply(self)
    session.changed.connect(_refresh)
    _refresh()

func _build() -> void:
    var margin := MarginContainer.new()
    margin.name = "Margin"
    add_child(margin)
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.offset_left = 24
    margin.offset_top = 20
    margin.offset_right = -24
    margin.offset_bottom = -20
    main = VBoxContainer.new()
    main.name = "Main"
    main.add_theme_constant_override("separation", 8)
    margin.add_child(main)
    var header := HBoxContainer.new()
    header.name = "Header"
    main.add_child(header)
    var back := _button("Warband", _back)
    back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    back.custom_minimum_size.x = 132
    header.add_child(back)
    var title := ScreenStyle.label("FRIEND SHOWDOWN", 28)
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(title)
    room_label = ScreenStyle.label("Private room", 20)
    header.add_child(room_label)
    main.add_child(_label("Shared 1× battles  •  60 seconds to reconnect  •  No mastery or rank rewards", 16))
    main.add_child(hearts)
    var row := HBoxContainer.new()
    row.size_flags_vertical = Control.SIZE_EXPAND_FILL
    row.add_theme_constant_override("separation", 18)
    main.add_child(row)
    var roster := _panel(row, Vector2(260, 0))
    commander_name = _label("Your Commander", 22)
    roster.add_child(commander_name)
    commander_portrait = CardPortrait.new()
    commander_portrait.custom_minimum_size = Vector2(230, 204)
    roster.add_child(commander_portrait)
    own_summary = _summary(105)
    roster.add_child(own_summary)
    var body := _panel(row)
    body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    status_label = _label("", 19)
    body.add_child(status_label)
    entry = VBoxContainer.new()
    entry.add_theme_constant_override("separation", 14)
    body.add_child(entry)
    entry.add_child(_label("Gather a friend at the crossing", 26))
    entry.add_child(_label("Create a private room and share its code, or join a room your friend has made.", 17))
    var actions := HBoxContainer.new()
    entry.add_child(actions)
    create_button = _button("Create room", _create)
    ScreenStyle.primary(create_button)
    actions.add_child(create_button)
    resume_button = _button("Reconnect to room", _resume)
    actions.add_child(resume_button)
    code_input = LineEdit.new()
    code_input.name = "RoomCode"
    code_input.placeholder_text = "FRIEND'S ROOM CODE"
    code_input.max_length = 6
    code_input.custom_minimum_size.y = 58
    code_input.add_theme_font_size_override("font_size", 28)
    code_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
    code_input.text_submitted.connect(func(_text): _join())
    entry.add_child(code_input)
    join_button = _button("Join room", _join)
    entry.add_child(join_button)
    copy_button = _button("Copy room code", func():
        DisplayServer.clipboard_set(session.client.room)
        status_label.text = "Room code copied. Share it with your friend.")
    body.add_child(copy_button)
    wait_label = _label("", 24)
    wait_label.custom_minimum_size.y = 70
    body.add_child(wait_label)
    draft_page = VBoxContainer.new()
    draft_page.add_theme_constant_override("separation", 8)
    body.add_child(draft_page)
    var counters := HBoxContainer.new()
    draft_page.add_child(counters)
    points_label = _label("", 24)
    points_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    counters.add_child(points_label)
    timer_label = _label("", 24)
    timer_label.autowrap_mode = TextServer.AUTOWRAP_OFF
    timer_label.custom_minimum_size.x = 80
    timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    counters.add_child(timer_label)
    offers = HBoxContainer.new()
    offers.name = "Offers"
    offers.alignment = BoxContainer.ALIGNMENT_CENTER
    offers.add_theme_constant_override("separation", 12)
    draft_page.add_child(offers)
    skill_button = _button("Commander skill", func(): _act("skill"))
    draft_page.add_child(skill_button)
    rival_summary = _summary(90)
    body.add_child(rival_summary)
    return_button = _button("Back to warband", _back)
    body.add_child(return_button)

func _refresh() -> void:
    if not is_inside_tree():
        return
    var raw: Dictionary = session.client.state
    var view := PrivatePerspective.state_for_player(raw)
    var phase := str(view.get("phase", "")) if session.active else ""
    var forfeited: bool = phase == "complete" and view.get("end_reason") in ["disconnect_forfeit", "both_disconnected"]
    var show_battle: bool = not forfeited and phase in ["playing", "replay", "complete"] and not session.replay.is_empty()
    if show_battle:
        if battle_screen == null or _battle_round != int(raw["round"]):
            _clear_battle()
            battle_screen = load("res://scenes/combat/combat.tscn").instantiate()
            battle_screen.initial_hearts_revealed = true
            battle_screen.playback_driver = SharedBattlePresentation.new(session)
            battle_screen.battle_context = PrivateBattleContext.new(raw, session.replay, ContentDatabase)
            _battle_round = int(raw["round"])
            add_child(battle_screen)
        main.get_parent().hide()
        battle_screen.show()
        return
    _clear_battle()
    main.get_parent().show()
    status_label.text = session.status if session.available else "PvP · Coming Soon"
    entry.visible = phase.is_empty()
    create_button.disabled = not session.available or session.endpoint.is_empty() or session.active
    join_button.disabled = not session.available or session.endpoint.is_empty() or session.active
    resume_button.disabled = not session.available or session.active
    resume_button.visible = session.client.has_session()
    copy_button.visible = phase == "waiting"
    room_label.text = "Room " + session.client.room if not phase.is_empty() else "Private room"
    draft_page.visible = phase == "draft"
    return_button.visible = phase == "complete"
    wait_label.visible = not phase.is_empty() and phase != "draft"
    wait_label.text = {"waiting": "Waiting for your friend…", "loading": "Preparing both players for battle…", "simulating": "Your armies are taking their places…", "complete": "Match complete"}.get(phase, "Connecting to your room…")
    if forfeited:
        wait_label.text = "Both players disconnected. Match cancelled." if view.get("end_reason") == "both_disconnected" else ("You win! Your friend did not reconnect in time." if view.get("winner") == "player" else "You forfeited after 60 seconds disconnected.")
    if phase.is_empty():
        commander_name.text = str(GameState.get_selected_commander().get("display_name", "Choose a Commander"))
        commander_portrait.set_content(GameState.get_selected_commander(), true)
        var lines: Array[String] = []
        for card in ContentDatabase.get_cards_by_ids(GameState.army.get_cards()):
            lines.append(str(card["display_name"]))
        own_summary.text = "[b]Your warband[/b]\n" + "\n".join(lines)
        rival_summary.text = "Your friend brings their own Commander and four-card warband."
        return
    var own: Dictionary = view["self"]
    commander_name.text = str(own.get("commander", {}).get("display_name", "Your Commander"))
    commander_portrait.set_content(own.get("commander", {}), true)
    own_summary.text = _army_text("Your army", own)
    rival_summary.text = _army_text("Rival • " + str(view.get("rival", {}).get("commander", {}).get("display_name", "Waiting for a friend")), view.get("rival", {}))
    rival_summary.visible = not view.get("rival", {}).is_empty()
    hearts.displayed_losses = view.get("losses", {"player": 0, "opponent": 0}).duplicate()
    hearts.sudden_death = view.get("sudden_death", false)
    hearts.queue_redraw()
    if phase == "draft":
        points_label.text = "Round %d  •  %d picks left" % [int(view["round"]), int(view["points"])]
        _render_offers(view)
        var uses := int(own.get("skill_uses_remaining", 0))
        skill_button.text = "%s  •  1 pick  •  %d/2 uses left" % [str(own.get("commander", {}).get("active_skill", {}).get("display_name", "Commander skill")), uses]
        skill_button.tooltip_text = ScreenStyle.skill_description(own.get("commander", {}))
        skill_button.disabled = not session.can_act() or int(view["points"]) <= 0 or own.get("commander_skill_active", false) or uses <= 0
        for button in offers.get_children():
            button.disabled = not session.can_act() or int(view["points"]) <= 0

func _process(_delta: float) -> void:
    var state: Dictionary = session.client.state
    if state.get("phase") == "draft" and session.active:
        var deadline := float(state.get("server_time", 0)) + float(state.get("selection_seconds", 0))
        timer_label.text = "%ds" % maxi(0, ceili(deadline - session.client.server_time()))
    if session.active and state.has("connected"):
        var other := "opponent" if state.get("you") == "player" else "player"
        if not state["connected"].get(other, false) and state.get("phase") not in ["waiting", "complete"]:
            var end := float(state.get("server_time", 0)) + float(state.get("reconnect_seconds", {}).get(other, 0))
            status_label.text = "Friend disconnected • %ds to reconnect" % maxi(0, ceili(end - session.client.server_time()))

func _render_offers(view: Dictionary) -> void:
    var key := "%d:%d" % [int(view["round"]), int(view["revision"])]
    if key == _offer_key:
        return
    _offer_key = key
    for child in offers.get_children():
        offers.remove_child(child)
        child.queue_free()
    var index := 0
    for option in view.get("offer", []):
        var button: Button
        if option["type"] == "unit":
            var card := ContentDatabase.get_card(str(option["id"]))
            var tile := CardTile.new()
            tile.set_content(card)
            var count := int(view["self"].get("unit_counts", {}).get(card["id"], 0))
            tile.detail_text = "%d → %d / %d" % [count, mini(int(card["unit_cap"]), count + int(card["summon_amount"])), int(card["unit_cap"])]
            button = tile
        else:
            var buff := ContentDatabase.get_buff(str(option["id"]))
            button = Button.new()
            button.text = "%s\n\n+%d%% %s\n\nArmy-wide blessing" % [buff["display_name"], int(buff["percentage"]), str(buff["stat"]).replace("_", " ")]
            button.add_theme_font_size_override("font_size", 18)
        button.custom_minimum_size = Vector2(200, 216)
        button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        button.pressed.connect(_act.bind("pick", index))
        offers.add_child(button)
        index += 1

func _act(kind: String, index: int = -1) -> void:
    if session.act(kind, index):
        GameAudio.play_effect("pick" if kind == "pick" else "commander_skill")

func _create() -> void:
    _offer_key = ""
    session.start("create")

func _join() -> void:
    if code_input.text.strip_edges().length() != 6:
        status_label.text = "Enter the six-character room code from your friend."
        code_input.grab_focus()
        return
    _offer_key = ""
    session.start("join", code_input.text)

func _resume() -> void:
    session.start("resume")

func _back() -> void:
    GameMenu.confirm_leave("res://scenes/army_builder/army_builder.tscn")

func _clear_battle() -> void:
    if battle_screen != null:
        remove_child(battle_screen)
        battle_screen.queue_free()
        battle_screen = null

func _army_text(title: String, side: Dictionary) -> String:
    var entries: Array[String] = ["[b]" + title + "[/b]"]
    var army: Array[String] = []
    for card in side.get("cards", []):
        army.append("%s ×%d" % [card.get("display_name", "Unit"), int(side.get("unit_counts", {}).get(card["id"], 0))])
    var columns := 2 if title.begins_with("Rival") else 1
    for index in range(0, army.size(), columns):
        entries.append("  •  ".join(army.slice(index, mini(index + columns, army.size()))))
    entries.append("Skill uses: %d/2" % int(side.get("skill_uses_remaining", 2)))
    var bonus: Dictionary = side.get("set_bonus", {})
    entries.append("Theme inactive" if bonus.is_empty() else "Theme: " + ScreenStyle.bonus_description(bonus, true))
    for buff in side.get("buffs", []):
        entries.append("%s ×%d" % [buff.get("definition", {}).get("display_name", "Buff"), int(buff.get("stacks", 0))])
    return "\n".join(entries)

func _panel(parent: Node, minimum: Vector2 = Vector2.ZERO) -> VBoxContainer:
    var panel := PanelContainer.new()
    panel.custom_minimum_size = minimum
    panel.size_flags_horizontal = Control.SIZE_FILL if minimum.x > 0 else Control.SIZE_EXPAND_FILL
    parent.add_child(panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 8)
    panel.add_child(box)
    return box

func _button(text: String, action: Callable) -> Button:
    var button := Button.new()
    button.text = text
    button.custom_minimum_size.y = 46
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.pressed.connect(action)
    return button

func _label(text: String, font_size: int) -> Label:
    var label := ScreenStyle.label(text, font_size)
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    return label

func _summary(height: float) -> RichTextLabel:
    var label := RichTextLabel.new()
    label.bbcode_enabled = true
    label.add_theme_font_size_override("normal_font_size", 14)
    label.custom_minimum_size.y = height
    label.size_flags_vertical = Control.SIZE_EXPAND_FILL
    return label

func _unhandled_key_input(event: InputEvent) -> void:
    if GameMenu.overlay.visible:
        return
    if not event is InputEventKey or not event.pressed or event.echo or battle_screen != null:
        return
    if event.keycode in [KEY_1, KEY_2, KEY_3] and draft_page.visible:
        _act("pick", int(event.keycode - KEY_1))
    elif event.keycode == KEY_S and draft_page.visible and not skill_button.disabled:
        _act("skill")
