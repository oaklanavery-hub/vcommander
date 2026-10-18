extends SceneTree
var failed := false

func _init() -> void:
    call_deferred("run")

func open_scene(path: String):
    change_scene_to_file(path)
    await scene_changed
    await process_frame
    await process_frame
    var scene = current_scene
    var main: Control = scene.get_node("Margin/Main")
    var bounds := main.get_global_rect()
    check(bounds.end.x <= root.size.x + 1 and bounds.end.y <= root.size.y + 1, "screen fits desktop viewport: " + path + " bounds=" + str(bounds))
    return scene

func run() -> void:
    root.size = Vector2i(1280, 720)
    var state = root.get_node("GameState")
    var db = root.get_node("ContentDatabase")
    await open_scene("res://scenes/commander_select/commander_select.tscn")
    state.select_commander("commander_fire_01")
    state.clear_army()
    var builder = await open_scene("res://scenes/army_builder/army_builder.tscn")
    for card in db.get_cards_by_set("set_fire_01"):
        builder._equip_card(str(card["id"]))
        await process_frame
    check(not builder.begin_draft_button.disabled, "ready army enables match")
    state.begin_match(1729)
    var draft_screen = await open_scene("res://scenes/draft/draft.tscn")
    while not state.draft.is_phase_complete():
        draft_screen._select_offer(0)
        await process_frame
    check(draft_screen.battle_button.visible, "finished draft enables battle")
    state.run_battle()
    var combat = await open_scene("res://scenes/combat/combat.tscn")
    check(not combat.next_button.visible, "round transition waits for replay completion")
    var scored_losses: Dictionary = state.match_state.losses.duplicate()
    combat._toggle_pause()
    check(combat._paused, "replay pause available")
    combat._toggle_motion()
    combat._toggle_hp()
    combat._toggle_sound()
    combat._toggle_details()
    check(state.match_state.losses == scored_losses, "presentation controls never change results")
    combat._paused = false
    combat._process(BattlePrelude.DURATION)
    combat._process(combat._duration + combat._tail_length + 0.1)
    await process_frame
    check(combat.next_button.visible, "result enables next round")
    var main: Control = combat.get_node("Margin/Main")
    check(main.get_global_rect().end.y <= root.size.y + 1, "combat result fits viewport: " + str(main.get_global_rect()))
    check(state.begin_next_round(), "round two available")
    combat._toggle_sound()
    combat._toggle_motion()
    combat._toggle_hp()
    var second_draft = await open_scene("res://scenes/draft/draft.tscn")
    for buff in db.get_all_buffs():
        state.draft.buff_stacks[str(buff["id"])] = 3
        state.opponent.draft.buff_stacks[str(buff["id"])] = 3
    state.opponent_public_side = state.opponent.get_side()
    second_draft._refresh_all()
    await process_frame
    await process_frame
    check(second_draft.opponent_summary.get_content_height() <= second_draft.opponent_summary.size.y + 1, "full rival state visible: content=" + str(second_draft.opponent_summary.get_content_height()) + " height=" + str(second_draft.opponent_summary.size.y) + " text=" + second_draft.opponent_summary.text)
    check(second_draft.buff_summary.get_content_height() <= second_draft.buff_summary.size.y + 1, "all active player Buff stacks visible")
    check(second_draft.round_label.text.contains("Round 2"), "UI displays current round")
    if not failed:
        print("Scene flow tests passed: Commander, builder, draft, combat, result, next round at 1280×720.")
    await physics_frame
    await physics_frame
    quit(1 if failed else 0)

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)
