extends SceneTree
var failed := false

func _init() -> void:
    call_deferred("run")

func run() -> void:
    root.size = Vector2i(1280, 720)
    var card := {"id": "future_card", "ability": {"type": "damage_link", "description": "A future ability."}}
    var unit := {"id": "p:future", "card_id": "future_card", "name": "Future companion", "side": "player", "hp": 37.5, "max_hp": 100, "attack": 1.2e100, "defense": 12, "attack_speed": 87, "movement_speed": 50, "range": 6, "sample_time": 2.0, "ability_cooldown": 4.0, "burning": true, "slowed": true}
    var original := JSON.stringify(unit)
    var data := UnitInspection.describe(unit, card, 3.0, true)
    check(data["hp"] == 37.5 and data["cooldown"] == "Ready in 3.0s" and data["description"] == "A future ability.", "sampled stats and elapsed cooldown remain exact and data driven")
    check(data["effects"].has("Damage over time") and data["effects"].has("Slowed") and data["effects"].has("Frozen Field · this round"), "active effects live in inspection, not actor labels")
    var effects: Array = UnitInspection.describe(unit.merged({"aura_slowed": true, "sticky_mark": {"target_ids": ["p:future", "p:other"], "shared_damage_pct": 50}}, true), card, 3.0)["effects"]
    check(effects.has("Freezing aura · attack speed reduced") and effects.has("Sticky link · 50% shared damage"), "aura and linked damage are visible alongside temporary slows")
    check(not UnitInspection.number(1.2e100).contains("inf") and UnitInspection.number(37.5) == "37.5", "fractional and unlimited-power numbers stay readable")
    check(JSON.stringify(unit) == original and UnitInspection.describe({}, {}, 0).is_empty(), "inspection neither mutates evidence nor invents empty actors")
    var field = load("res://scripts/combat/battlefield_view.gd").new()
    root.add_child(field)
    field.size = Vector2(900, 400)
    field._arena = Rect2(0, 0, 900, 400)
    var before := {"time": 0, "units": [unit.merged({"hp": 100, "x": 4.0, "y": 4.0}, true)]}
    var after := {"time": 1, "units": [unit.merged({"hp": 0, "x": 5.0, "y": 4.0}, true)]}
    var events := [{"type": "damage", "time": 0.5, "target_id": "p:future", "hp_after": 37.5}, {"type": "damage", "time": 1, "target_id": "p:future", "hp_after": 0}]
    field.replay.configure([before, after], events)
    field.replay_enabled = true
    field.set_playback(before, after, 0.4, 0.4)
    check(field.displayed_unit("p:future")["hp"] == 100, "inspection does not leak the next frame's damage")
    var link_event := {"type": "ability", "kind": "sticky_link", "unit_id": "o:caster", "time": 0.6, "link": {"source_id": "o:caster", "target_ids": ["p:future"], "expires_at": 0.9}}
    field.replay.configure([before, after], events + [link_event])
    check(field._sticky_mark("p:future").is_empty(), "a future link cannot appear in inspection early")
    field.set_playback(before, after, 0.5, 0.5)
    check(field.displayed_unit("p:future")["hp"] == 37.5, "current HP changes exactly at visible contact")
    field.set_playback(before, after, 0.7, 0.7)
    check(not field.displayed_unit("p:future")["sticky_mark"].is_empty(), "a between-frame cast marks the target at its actual event time")
    field.set_playback(before, after, 0.95, 0.95)
    check(field.displayed_unit("p:future")["sticky_mark"].is_empty(), "expired link marks disappear without waiting for a new frame")
    var shown: Dictionary = field.displayed_unit("p:future")
    check(field.unit_at(field._body_point(shown)).get("id") == "p:future" and field.unit_at(Vector2(899, 399)).is_empty(), "mouse/tap picking selects a visible body and ignores empty ground")
    field.set_playback(before, after, 1, 1)
    check(field.displayed_unit("p:future").is_empty(), "defeated bodies cannot retain living inspection data")
    field.queue_free()
    var state := root.get_node("GameState")
    var db := root.get_node("ContentDatabase")
    state.commander_progress = CommanderProgress.new(db, "")
    state.select_commander(str(db.get_all_commanders()[0]["id"]))
    state.equip_starter_army()
    check(state.begin_match(401), "ordinary match fixture starts")
    while not state.draft.is_phase_complete():
        state.draft.auto_select()
    check(state.run_battle(), "ordinary battle fixture resolves")
    var profile_before := JSON.stringify(state.commander_progress._data)
    var battle_before := JSON.stringify(state.battle_result)
    change_scene_to_file("res://scenes/combat/combat.tscn")
    await scene_changed
    await process_frame
    var screen = current_scene
    screen._paused = true
    screen._open_report()
    check(not screen.report_button.visible and not screen.report_view.overlay.visible and screen._report.is_empty(), "report remains unavailable until the full replay ends")
    var body: Dictionary = screen.battlefield.visible_units()[0]
    screen._inspect_unit(body)
    await process_frame
    check(screen.inspector.visible and screen.inspector.selected_id == body["id"], "click inspection opens beside the actual battle")
    check(screen.battlefield.get_global_rect().end.x <= screen.inspector.get_global_rect().position.x + 1, "inspection leaves the entire arena unobscured")
    screen._close_inspection()
    screen._paused = false
    screen._process(BattlePrelude.DURATION)
    screen._process(screen._duration + screen._tail_length + 1)
    check(screen._finished and screen.report_button.visible, "report becomes available only after contact and recovery finish")
    screen._open_report()
    await process_frame
    check(screen.report_view.overlay.visible and screen.report_view.selected_side == "player", "completed report opens on your army")
    screen.report_view._select_side("opponent")
    check(screen.report_view.selected_side == "opponent", "rival report uses the same recorded battle")
    screen.report_view.close()
    screen._open_report()
    check(JSON.stringify(state.commander_progress._data) == profile_before and JSON.stringify(state.battle_result) == battle_before, "repeated reports and inspection never award XP or rewrite results")
    screen.report_view.close()
    state.leave_match()
    if not failed:
        print("Battle inspection tests passed: current HP, safe cooldowns/effects/numbers, mouse/tap picking, no future damage/result leak, separate arena, both report sides and no reward mutation.")
    await process_frame
    quit(1 if failed else 0)

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)
