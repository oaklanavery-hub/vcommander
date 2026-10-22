extends "res://tools/capture_progression.gd"

func run() -> void:
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with("--output-dir="):
            output_dir = argument.trim_prefix("--output-dir=")
    if not output_dir.is_absolute_path():
        output_dir = ProjectSettings.globalize_path("res://" + output_dir)
    DirAccess.make_dir_recursive_absolute(output_dir)
    root.size = Vector2i(1280, 720)
    var db := root.get_node("ContentDatabase")
    var state := root.get_node("GameState")
    var menu := root.get_node("GameMenu")
    # A synthetic verifier and in-memory credential: never load the owner's key.
    var fixture_key := "native-fixture-access-0123456789abcdef"
    state.developer_access = DeveloperAccess.new("", fixture_key.sha256_text())
    state.developer_access.changed.connect(state._on_collection_access_changed)
    state.commander_progress = CommanderProgress.new(db, "", state.developer_access)
    state.select_commander("commander_fire_01")
    state.clear_army()
    await journal("lineup_rewards_fire", "commander_fire_01")
    var journal_script = load("res://scripts/presentation/progress_journal.gd")
    journal_script.initial_commander = ""
    change_scene_to_file("res://scenes/progression/progress_journal.tscn")
    await scene_changed
    for i in range(3):
        await process_frame
    current_scene.scroll.scroll_vertical = int(current_scene.grid.size.y)
    await save_image("lineup_rewards_scrolled")
    change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
    await scene_changed
    menu.open_developer_access()
    await save_image("developer_inactive")
    if state.activate_developer_access(fixture_key) != OK:
        push_error("Isolated developer visual fixture could not activate")
        quit(1)
        return
    menu.open_developer_access()
    await save_image("developer_active")
    menu.close()
    for id in ["card_fire_01", "card_fire_02", "card_fire_06", "card_fire_04"]:
        state.equip_card(id)
    await collection("developer_collection")
    await journal("developer_rewards", "commander_fire_01")
    for name in ["lineup_rewards_fire", "lineup_rewards_scrolled", "developer_inactive", "developer_active", "developer_collection", "developer_rewards"]:
        if not captured.has(name):
            push_error("Missing collection access view: " + name)
            quit(1)
            return
    print("Collection access native views: ordered mastery tiers, scrolled eight-card journal, private credential entry, active access, full collection and truthful developer reward progress.")
    quit(0)
