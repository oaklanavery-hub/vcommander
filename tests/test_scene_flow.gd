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
    combat._skip_to_result()
    await process_frame
    check(combat.next_button.visible, "result enables next round")
    var main: Control = combat.get_node("Margin/Main")
    check(main.get_global_rect().end.y <= root.size.y + 1, "combat result fits viewport: " + str(main.get_global_rect()))
    check(state.begin_next_round(), "round two available")
    var second_draft = await open_scene("res://scenes/draft/draft.tscn")
    check(second_draft.round_label.text.contains("Round 2"), "UI displays current round")
    if not failed:
        print("Scene flow tests passed: Commander, builder, draft, combat, result, next round at 1280×720.")
    quit(1 if failed else 0)

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)
