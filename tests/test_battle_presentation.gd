extends SceneTree
var failed := false

func _init() -> void:
    call_deferred("run")

func run() -> void:
    root.size = Vector2i(1280, 720)
    var state = root.get_node("GameState")
    var db = root.get_node("ContentDatabase")
    state.select_commander("commander_fire_01")
    state.clear_army()
    for card in db.get_cards_by_set("set_fire_01"):
        state.equip_card(str(card["id"]))
    check(state.begin_match(1729), "fixture match starts")
    check(state.draft.use_commander_skill(), "Commander skill selected legally")
    while not state.draft.is_phase_complete():
        state.draft.auto_select()
    # Force the fixture rival's selected skill so both sides share one prelude.
    state.opponent.draft.commander_skill_used_this_round = true
    check(state.run_battle(), "skill battle resolves")
    var result: Dictionary = state.battle_result.duplicate(true)
    var prelude := BattlePrelude.new(result.get("pre_battle", {}))
    check(prelude.skills.size() == 2 and prelude.active(), "both skills share one pre-battle sequence")
    check(not prelude.before.is_empty() and not prelude.after.is_empty(), "simulation retains before/after skill snapshots")
    var losses: Dictionary = state.match_state.losses.duplicate()
    change_scene_to_file("res://scenes/combat/combat.tscn")
    await scene_changed
    await process_frame
    var combat = current_scene
    combat.set_process(false)
    check(combat._speed_index == 0 and combat.speed_button.text.contains("1x"), "new battle always starts at 1x")
    check(combat.get_node_or_null("Margin/Main/StatusRow/Skip") == null and not combat.has_method("_skip_to_result"), "skip control and shortcut path are removed")
    check(not combat.next_button.visible and combat.speed_button.disabled, "result and speed changes wait for skill completion")
    combat._process(0.6)
    check(is_zero_approx(combat._playback_time), "battle clock stays at zero while skill animation plays")
    var elapsed: float = combat._prelude.elapsed
    combat._toggle_pause()
    combat._process(1.0)
    check(is_equal_approx(combat._prelude.elapsed, elapsed), "pause also pauses the pre-battle sequence")
    combat._toggle_pause()
    combat._process(BattlePrelude.DURATION)
    check(not combat._prelude.active() and is_zero_approx(combat._playback_time), "skills finish before the first combat tick")
    check(not combat.speed_button.disabled and not combat.next_button.visible, "battle begins after the prelude")
    combat._process(0.1)
    check(combat._playback_time <= 0.101, "battle runs at 1x after skills")
    combat._process(combat._duration + 1.0)
    check(combat.next_button.visible, "normal replay completion reveals results")
    check(state.match_state.losses == losses and state.battle_result == result, "presentation timing never alters scored battle or losses")
    for commander in db.get_all_commanders():
        var cards: Array = db.get_cards_by_set(str(commander["signature_set_id"]))
        var counts := {}
        for card in cards:
            counts[str(card["id"])] = 1
        var side := {"id": "player", "commander": commander, "commander_skill_active": true, "cards": cards, "unit_counts": counts}
        var enemy := side.duplicate(true)
        enemy["id"] = "opponent"
        var sample: Dictionary = CombatSimulator.new().simulate(side, enemy, 53, {"match": {"round_time_seconds": 0.2}})
        var opening := BattlePrelude.new(sample["pre_battle"])
        check(opening.skills.size() == 2, "all Commander types have simultaneous visual prelude metadata")
        opening.advance(BattlePrelude.DURATION)
        check(opening.frame() == sample["frames"][0], "skill sequence ends at exact authoritative battle-start frame")
    if not failed:
        print("Battle presentation tests passed: 1x defaults, no skip, both pre-battle skills, frozen combat clock, pause and unchanged outcomes.")
    quit(1 if failed else 0)

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)
