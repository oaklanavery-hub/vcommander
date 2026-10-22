extends SceneTree

const TEST_KEY := "ui-fixture-collection-access-0123456789abcdef"
var failed := false

func _init() -> void:
    call_deferred("run")

func scene(path: String):
    change_scene_to_file(path)
    await scene_changed
    for i in range(3):
        await process_frame
    return current_scene

func run() -> void:
    root.size = Vector2i(1280, 720)
    var db := root.get_node("ContentDatabase")
    var state := root.get_node("GameState")
    var menu := root.get_node("GameMenu")
    state.developer_access = DeveloperAccess.new("", TEST_KEY.sha256_text())
    state.developer_access.changed.connect(state._on_collection_access_changed)
    state.commander_progress = CommanderProgress.new(db, "", state.developer_access)
    state.select_commander("commander_fire_01")
    var builder = await scene("res://scenes/army_builder/army_builder.tscn")
    check(builder.available_card_buttons["card_fire_06"].locked and builder.available_card_buttons["card_fire_04"].locked, "fresh collection locks both tiers")
    menu.open_settings()
    check(find_text(menu._body, "Developer access"), "settings exposes credential entry")
    menu.open_developer_access()
    await process_frame
    check_bounds(menu._body, "inactive developer page")
    var input: LineEdit = menu._body.find_child("DeveloperKey", true, false)
    check(input != null and input.secret and input.max_length == 128, "private key entry is masked and bounded")
    input.text = "invalid"
    menu._body.find_child("ActivateDeveloperAccess", true, false).pressed.emit()
    check(menu._body.find_child("DeveloperStatus", true, false).text.contains("not valid") and builder.available_card_buttons["card_fire_06"].locked, "invalid activation gives feedback without unlocking")
    input.text = TEST_KEY
    menu._body.find_child("ActivateDeveloperAccess", true, false).pressed.emit()
    await process_frame
    check_bounds(menu._body, "active developer page")
    check(state.commander_progress.available_cards().size() == 24 and not builder.available_card_buttons["card_fire_06"].locked and builder.available_card_buttons["card_fire_04"].tooltip_text.contains("developer access"), "activation refreshes the visible collection immediately")
    check(not find_text(menu._body, TEST_KEY) and menu._body.find_child("DeveloperKey", true, false) == null, "active page never exposes the credential")
    menu.close()
    var journal_script = load("res://scripts/presentation/progress_journal.gd")
    journal_script.initial_commander = "commander_fire_01"
    var journal = await scene("res://scenes/progression/progress_journal.tscn")
    check(journal.displayed_ids == ["card_fire_06", "card_fire_04"] and journal.summary_label.text.contains("0 / 8 mastery rewards earned"), "journal keeps level order and truthful earned totals during developer access")
    check(find_text(journal.grid, "DEVELOPER ACCESS") and find_text(journal.grid, "Level 1 / 5"), "journal labels developer access while retaining real progress")
    var rewards: Array = state.commander_progress.mastery_rewards("commander_fire_01")
    check(not rewards[0]["earned"] and rewards[0]["unlocked"], "UI previews cannot convert access into earned rewards")
    builder = await scene("res://scenes/army_builder/army_builder.tscn")
    for id in ["card_fire_01", "card_fire_02", "card_fire_06", "card_fire_04"]:
        check(state.equip_card(id), "developer collection can build a normal four-card army")
    check(state.begin_match(217), "developer army starts through ordinary match validation")
    check(state.remove_developer_access() == ERR_BUSY and state.activate_developer_access(TEST_KEY) == ERR_BUSY and state.developer_access.is_enabled(), "headless state blocks access changes during a match")
    menu.open_developer_access()
    check(menu._body.find_child("RemoveDeveloperAccess", true, false) == null and find_text(menu._body, "Return to the title"), "in-match menu explains why access cannot change")
    menu.close()
    state.leave_match()
    menu.open_developer_access()
    menu._body.find_child("RemoveDeveloperAccess", true, false).pressed.emit()
    check(not state.developer_access.is_enabled() and builder.available_card_buttons["card_fire_06"].locked and state.army.size() == 2, "removal updates locks and removes only unearned equipped rewards")
    check(state.commander_progress.record("commander_fire_01")["xp"] == 0 and state.commander_progress.unlocked_card_ids().is_empty(), "developer browsing and unplayed drafts never manufacture progression")
    menu.close()
    if not failed:
        print("Developer access presentation tests passed: settings activation/invalid feedback, masking/bounds, immediate collection refresh, truthful reward journal, match lock and revocation cleanup.")
    quit(1 if failed else 0)

func find_text(node: Node, value: String) -> bool:
    if (node is Label or node is Button or node is LineEdit) and str(node.get("text")).contains(value):
        return true
    for child in node.get_children():
        if find_text(child, value):
            return true
    return false

func check_bounds(control: Control, label: String) -> void:
    var bounds := control.get_global_rect()
    check(bounds.position.x >= -1 and bounds.position.y >= -1 and bounds.end.x <= 1281 and bounds.end.y <= 721, label + " fits desktop")

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)
