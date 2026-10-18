extends SceneTree

var failed := false

func _init() -> void:
    call_deferred("run")

func open_scene(path: String):
    change_scene_to_file(path)
    await scene_changed
    await process_frame
    await process_frame
    await process_frame
    var main: Control = current_scene.get_node("Margin/Main")
    check(main.get_global_rect().end.x <= 1281 and main.get_global_rect().end.y <= 721, "Slime screen fits the desktop: " + path + " " + str(main.get_global_rect()))
    check(main.get_global_rect().position.x >= 0 and main.get_global_rect().position.y >= 0, "Slime layout never grows past the top or left edge")
    return current_scene

func run() -> void:
    root.size = Vector2i(1280, 720)
    var db = root.get_node("ContentDatabase")
    var state = root.get_node("GameState")
    state.select_commander("commander_slime_01")
    state.clear_army()
    var gallery = await open_scene("res://scenes/commander_select/commander_select.tscn")
    check(gallery.commander_buttons.size() == db.get_all_commanders().size(), "new Commander is available in the gallery")
    check(gallery.bonus_label.text.contains("after a death") and gallery.skill_label.text.contains("50% HP"), "passive and active descriptions explain the actual Slime mechanics")
    for label in [gallery.description_label, gallery.bonus_label, gallery.skill_label]:
        check(label.get_global_rect().end.y <= 721, "Slime descriptions remain readable inside the viewport")
    gallery._open_army_builder()
    await scene_changed
    await process_frame
    await process_frame
    await process_frame
    var builder = current_scene
    check(state.is_full_set_active(), "Slime Princess starter warband activates her bonus")
    check(builder.army_status_label.text.contains("death spawns"), "builder does not present the triggered bonus as unconditional ATK")
    for card in db.get_cards_by_set("set_slime_01"):
        check(builder.available_card_buttons[str(card["id"])].tooltip_text.contains(str(card["ability"]["description"])), "unit mechanics are explained in collection tooltips")
    check(state.begin_match(1018), "Slime match starts legally")
    var draft = await open_scene("res://scenes/draft/draft.tscn")
    check(state.draft.use_commander_skill(), "Royal Jelly costs one normal Commander skill pick")
    check(state.draft.commander_skill_uses_remaining() == 1 and state.draft.selection_points == 2, "normal skill cost and twice-per-match allowance remain intact")
    while not state.draft.is_phase_complete():
        state.draft.auto_select()
    for card in db.get_cards_by_set("set_slime_01"):
        state.draft.unit_counts[str(card["id"])] = int(card["summon_amount"])
    var counts: Dictionary = state.draft.unit_counts.duplicate()
    draft._refresh_all()
    check(draft.army_summary.text.contains("death spawns"), "draft summary describes conditional attack correctly")
    check(state.run_battle(), "Slime battle resolves")
    check(state.draft.unit_counts == counts, "splits and revived bodies never increase persistent recruited counts")
    var combat = await open_scene("res://scenes/combat/combat.tscn")
    combat.set_process(false)
    check(combat._prelude.active() and combat._speed_index == 0, "Royal Jelly has a pre-battle opening and battle defaults to 1x")
    combat._advance_prelude(1.4)
    check(is_zero_approx(combat._playback_time), "armies and clock wait for Royal Jelly to finish")
    check(combat.battlefield.prelude_skills.any(func(skill): return skill.get("skill_type") == "army_revival"), "Royal Jelly visual effect uses generic skill metadata")
    combat._advance_prelude(BattlePrelude.DURATION)
    check(not combat._prelude.active() and not combat.speed_button.disabled, "battle becomes playable after the blessing finishes")
    check(CombatCues.profile("card_slime_02")["projectile"] == "slime_green", "green Cannon fires green slime")
    check(CombatCues.profile("card_slime_03")["impact_style"] == "slime_white", "white Slime Ball has white attack feedback")
    check(CombatCues.profile("card_slime_04")["impact_style"] == "slime_pink", "pink Barrel has pink feedback")
    check(CombatCues.sound({"type": "spawn", "source": "revival"}) == "slime_rebirth", "revival has a distinct sound")
    test_between_frame_births()
    if not failed:
        print("Slime presentation tests passed: gallery, descriptions, legal warband/draft, pre-battle clock, persistent counts, unit colours, birth timing and ten-second pool visuals.")
    quit(1 if failed else 0)

func test_between_frame_births() -> void:
    var replay := BattleReplay.new()
    var child := {"id": "player:child:spawn1", "x": 4.0, "y": 3.0, "hp": 100, "max_hp": 100, "visual_scale": 0.68, "spawned_at": 0.1}
    var area := {"type": "damage_area", "created_at": 0.1, "duration": 10.0, "remaining": 10.0}
    replay.configure([], [
        {"type": "spawn", "time": 0.1, "unit_id": child["id"], "unit": child},
        {"type": "damage", "time": 0.15, "target_id": child["id"], "hp_after": 0},
        {"type": "ability", "time": 0.1, "kind": "death_area", "area": area}
    ])
    check(replay.births_since(0, 0.09).is_empty(), "children never appear before their recorded birth")
    check(replay.births_since(0, 0.12).size() == 1, "a child appears between periodic snapshots immediately after birth")
    check(replay.births_since(0, 0.16).is_empty(), "short-lived child disappears at actual damage/death time")
    check(replay.death_areas_at(0.09).is_empty() and replay.death_areas_at(0.12).size() == 1, "pool appears at its event time between frames")
    check(replay.death_areas_at(10.09).size() == 1 and replay.death_areas_at(10.1).is_empty(), "pool stays visible for exactly ten seconds")

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)
