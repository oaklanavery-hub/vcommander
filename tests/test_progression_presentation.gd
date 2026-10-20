extends SceneTree

var failed := false
var state: Node
var db: Node

func _init() -> void:
    call_deferred("run")

func scene(path: String):
    change_scene_to_file(path)
    await scene_changed
    for i in range(3):
        await process_frame
    check_bounds(current_scene.get_node("Margin/Main"), path)
    return current_scene

func run() -> void:
    root.size = Vector2i(1280, 720)
    db = root.get_node("ContentDatabase")
    state = root.get_node("GameState")
    state.commander_progress = CommanderProgress.new(db, "")
    var session := root.get_node("OnlineSession")
    check(not session.available and not session.start("create") and not session.active and session.client._socket == null, "Coming Soon blocks connection before any socket is opened")
    var title = await scene("res://scenes/main_menu/main_menu.tscn")
    check(title.has_node("Margin/Main/Achievements"), "title exposes achievements and rewards")
    title.get_node("Margin/Main/Achievements").pressed.emit()
    await scene_changed
    for i in range(3):
        await process_frame
    var journal = current_scene
    check_bounds(journal.get_node("Margin/Main"), "journal")
    check(journal.displayed_ids.size() == 4 and journal.summary_label.text.contains("0 / 18"), "new profile sees four rewards and all eighteen achievements")
    check(journal.grid.get_child_count() == 4 and journal.grid.columns == 2, "reward cards use two readable columns")
    journal._select_tab(1)
    check(journal.displayed_ids.size() == 18, "achievement view includes every milestone")
    var filter_index := 0
    for index in range(journal.filter_select.item_count):
        if journal.filter_select.get_item_metadata(index) == "commander_fire_01":
            filter_index = index
    journal._select_filter(filter_index)
    check(journal.displayed_ids.size() == 9, "Commander filter retains global milestones and that Commander's achievements")
    journal._select_tab(0)
    check(journal.displayed_ids == ["card_fire_05"], "reward filter shows the selected Commander's own unit")
    journal.get_node("Margin/Main/Header/Back").pressed.emit()
    await scene_changed
    check(current_scene.name == "MainMenu", "Back returns to the journal's entry screen")
    state.select_commander("commander_fire_01")
    state.clear_army()
    var builder = await scene("res://scenes/army_builder/army_builder.tscn")
    check(builder.friend_button.visible and builder.friend_button.disabled and builder.friend_button.text.contains("Coming Soon"), "warband clearly exposes paused PvP")
    var locked = builder.available_card_buttons["card_fire_05"]
    check(locked.locked and locked.tooltip_text.contains("Level 3") and locked.tooltip_text.contains("3 wins"), "locked collection previews explain the exact requirement")
    locked.pressed.emit()
    await scene_changed
    for i in range(3):
        await process_frame
    check(current_scene.name == "ProgressJournal" and current_scene.displayed_ids == ["card_fire_05"] and state.army.size() == 0, "locked-card click opens its reward without equipping it")
    current_scene.get_node("Margin/Main/Header/Back").pressed.emit()
    await scene_changed
    check(current_scene.name == "ArmyBuilder", "reward preview returns to the collection")
    var receipt: Dictionary = {}
    for i in range(5):
        var match_id: String = state.commander_progress.begin_match("commander_fire_01")
        receipt = state.commander_progress.finish_match(match_id, "win")
    builder = await scene("res://scenes/army_builder/army_builder.tscn")
    check(not builder.available_card_buttons["card_fire_05"].locked, "earned companion appears available in the same collection")
    builder.available_card_buttons["card_fire_05"].pressed.emit()
    check(state.army.contains("card_fire_05"), "earned companion equips with the ordinary card action")
    var panel = load("res://scripts/presentation/commander_mastery_panel.gd").new()
    panel.configure(state.commander_progress, db, root.get_node("GameAudio"))
    root.add_child(panel)
    panel.show_reward(receipt)
    check(panel.reward_label.visible and panel.reward_label.text.contains("Ash Phoenix") and panel.reward_label.text.contains("achievement"), "result notification identifies both the new unit and achievement")
    panel.finish_animation()
    var before: Dictionary = state.commander_progress.record("commander_fire_01")
    panel.show_reward(receipt)
    panel.finish_animation()
    check(state.commander_progress.record("commander_fire_01") == before, "showing rewards twice never changes progress")
    panel.show_record("commander_fire_01")
    check(panel.xp_label.text.contains("Unlocked: Ash Phoenix") and not panel.reward_label.visible, "gallery shows earned unit instead of a stale result announcement")
    panel.queue_free()
    var room = await scene("res://scenes/online/private_room.tscn")
    check(room.create_button.disabled and room.join_button.disabled and room.status_label.text.contains("Coming Soon"), "direct room scene is also unavailable")
    if not failed:
        print("Progression presentation tests passed: title/journal navigation and bounds, filters, locked previews, Coming Soon entry/transport, earned equipment, reward feedback and exact-once UI.")
    quit(1 if failed else 0)

func check_bounds(control: Control, label: String) -> void:
    var bounds := control.get_global_rect()
    check(bounds.position.x >= -1 and bounds.position.y >= -1 and bounds.end.x <= 1281 and bounds.end.y <= 721, label + " fits desktop " + str(bounds))

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)
