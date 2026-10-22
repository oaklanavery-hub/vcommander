extends CanvasLayer

const DEFAULT_PATH := "user://first_match_guide.cfg"
const STEPS := {
    "commander": ["Choose your Commander", "Each Commander has a signature theme and a different opening skill. Select any leader, read their magic, then choose Build Warband. Your four starting companions are ready to try.", "Choose a leader, then Build Warband"],
    "warband": ["Four companions, one strategy", "Keep a sturdy frontline and companions who can attack or help from behind. Four unique cards matching your Commander's theme activate the set bonus. You can use the starter warband or choose any unlocked companions.", "When all four slots are filled, choose Battle"],
    "draft": ["Recruit your first fighters", "Choose one of the three cards. A pick adds the shown number of bodies to your army and refreshes the choices. You have 30 seconds per pick; these notes pause that clock while you read.", "Choose a companion card"],
    "skill": ["Save a pick for magic?", "Your Commander skill costs one selection. You can prepare it once per round and twice per match. It resolves before either army moves. You may use it now, or spend your picks recruiting instead.", "Spend your remaining selections"],
    "ready": ["Your warband is ready", "Start the battle when you are ready. Battles begin at 1×. Commander magic finishes first, then your army fights automatically. Your choices and rewards follow the normal match rules.", "Choose Start Battle"],
    "battle": ["Watch, pause and inspect", "Both Commanders begin with four hearts. Losing a round costs one heart; a draw costs both sides a heart. Click or tap a companion for current stats, cooldowns and effects beside the field. Space pauses the replay.", "Inspect a companion and watch the battle"],
    "report": ["See what your army achieved", "The full battle has finished. Open Battle report to compare damage, healing and protection. Split or revived bodies contribute to their companion's row. You can inspect either warband, then continue the match.", "Open Battle report"],
    "complete": ["Ready for the next crossing", "You have learned the first-match flow. Close these notes to explore the report, then continue drafting. Armies and power cards persist between rounds. Mastery XP is earned when the whole match ends. You can replay this guide from How to play.", "Continue your adventure"]
}
const ORDER := ["commander", "warband", "draft", "skill", "ready", "battle", "report", "complete"]

var active := false
var completed := false
var preference_path := ""
var last_save_error: Error = OK
var overlay := Control.new()
var current_step := ""
var _seen: Dictionary = {}
var _pending: Array[String] = []
var _previous_pause := false
var _previous_focus: Control
var _draft_entry_points := 0

func _ready() -> void:
    layer = 45
    process_mode = Node.PROCESS_MODE_ALWAYS
    add_child(overlay)
    overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay.hide()
    var args := OS.get_cmdline_args()
    var scripted := args.has("--script") or args.has("-s") or DisplayServer.get_name() == "headless"
    preference_path = "" if scripted else DEFAULT_PATH
    load_preference()
    get_tree().scene_changed.connect(_scene_changed)

func load_preference() -> void:
    completed = false
    if preference_path.is_empty():
        return
    var config := ConfigFile.new()
    if config.load(preference_path) == OK and config.get_value("guide", "schema", 0) == 1:
        completed = config.get_value("guide", "completed", false) == true

func _save_completion() -> void:
    completed = true
    last_save_error = OK
    if preference_path.is_empty():
        return
    var config := ConfigFile.new()
    config.set_value("guide", "schema", 1)
    config.set_value("guide", "completed", true)
    last_save_error = config.save(preference_path + ".tmp")
    if last_save_error == OK:
        last_save_error = DirAccess.rename_absolute(ProjectSettings.globalize_path(preference_path + ".tmp"), ProjectSettings.globalize_path(preference_path))

func start() -> void:
    stop()
    if OnlineSession.active:
        return
    active = true
    _seen.clear()

func stop() -> void:
    active = false
    _pending.clear()
    _dismiss_panel()
    current_step = ""

func _scene_changed() -> void:
    if not active:
        return
    if OnlineSession.active:
        stop()
        return
    var scene := get_tree().current_scene
    if scene == null:
        return
    match scene.name:
        "MainMenu": stop()
        "CommanderSelect": announce("commander")
        "ArmyBuilder": announce("warband")
        "Draft":
            if GameState.match_state.round_number == 1:
                _draft_entry_points = GameState.draft.selection_points
                announce("ready" if GameState.draft.is_phase_complete() else "draft")
        "Combat": announce("battle")

func draft_updated() -> void:
    if not active or GameState.match_state.round_number != 1:
        return
    if GameState.draft.is_phase_complete():
        announce("ready")
    elif _seen.has("draft") and GameState.draft.selection_points < _draft_entry_points:
        announce("skill")

func battle_finished() -> void:
    announce("report")

func report_opened() -> void:
    if active and _seen.has("battle") and _seen.has("report"):
        _save_completion()
        announce("complete")

func announce(step: String) -> void:
    if active and not OnlineSession.active and STEPS.has(step) and not _seen.has(step):
        call_deferred("_show_step", step)

func _show_step(step: String) -> void:
    if not active or OnlineSession.active or _seen.has(step):
        return
    if overlay.visible:
        if not _pending.has(step):
            _pending.append(step)
        return
    _seen[step] = true
    current_step = step
    _previous_pause = get_tree().paused
    _previous_focus = get_viewport().gui_get_focus_owner()
    get_tree().paused = true
    for child in overlay.get_children():
        overlay.remove_child(child)
        child.queue_free()
    var dimmer := ColorRect.new()
    dimmer.color = Color(0.02, 0.04, 0.03, 0.76)
    overlay.add_child(dimmer)
    dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var center := CenterContainer.new()
    overlay.add_child(center)
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var panel := PanelContainer.new()
    panel.name = "CoachPanel"
    panel.custom_minimum_size.x = 650
    panel.add_theme_stylebox_override("panel", ScreenStyle.frame(Color("303529"), Color("cfaa69"), 16))
    center.add_child(panel)
    var body := VBoxContainer.new()
    body.add_theme_constant_override("separation", 16)
    panel.add_child(body)
    body.add_child(ScreenStyle.label("FIELD NOTES    ·    %d / %d" % [ORDER.find(step) + 1, ORDER.size()], 15))
    body.add_child(ScreenStyle.label(str(STEPS[step][0]), 30))
    var text := ScreenStyle.label(str(STEPS[step][1]), 18)
    text.custom_minimum_size.x = 610
    text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    body.add_child(text)
    var action := ScreenStyle.label(str(STEPS[step][2]), 20)
    action.add_theme_color_override("font_color", Color("edd198"))
    action.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    body.add_child(action)
    if step == "complete" and last_save_error != OK:
        body.add_child(ScreenStyle.label("Guide completed. This device could not save the reminder.", 14))
    var actions := HBoxContainer.new()
    actions.add_theme_constant_override("separation", 12)
    body.add_child(actions)
    var end_button := Button.new()
    end_button.text = "End guide"
    end_button.custom_minimum_size = Vector2(160, 44)
    end_button.pressed.connect(stop)
    end_button.visible = step != "complete"
    actions.add_child(end_button)
    var next := Button.new()
    next.name = "ContinueGuide"
    next.text = "Continue adventure" if step == "complete" else "Got it · let me try"
    next.custom_minimum_size.y = 44
    next.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    ScreenStyle.primary(next)
    next.pressed.connect(continue_step)
    actions.add_child(next)
    overlay.show()
    next.grab_focus()

func continue_step() -> void:
    var finished := current_step == "complete"
    _dismiss_panel()
    if finished:
        active = false
    elif not _pending.is_empty():
        var step: String = _pending.pop_front()
        call_deferred("_show_step", step)

func _dismiss_panel() -> void:
    if not overlay.visible:
        return
    overlay.hide()
    get_tree().paused = _previous_pause
    if is_instance_valid(_previous_focus) and _previous_focus.is_inside_tree() and _previous_focus.is_visible_in_tree():
        _previous_focus.grab_focus()

func _input(event: InputEvent) -> void:
    if overlay.visible and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
        continue_step()
        get_viewport().set_input_as_handled()
