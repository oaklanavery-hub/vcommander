extends SceneTree

var failed := false
var db: Node
var state: Node

func _init() -> void:
    call_deferred("run")

func open_scene(path: String):
    change_scene_to_file(path)
    await scene_changed
    await process_frame
    await process_frame
    await process_frame
    check_bounds(current_scene.get_node("Margin/Main"), "screen")
    return current_scene

func award(commander: String, outcome: String) -> void:
    var id: String = state.commander_progress.begin_match(commander)
    state.commander_progress.finish_match(id, outcome)

func run() -> void:
    root.size = Vector2i(1280, 720)
    db = root.get_node("ContentDatabase")
    state = root.get_node("GameState")
    state.commander_progress = CommanderProgress.new(db, "")
    var audio = root.get_node("GameAudio")
    var reduced: bool = audio.reduced_motion
    audio.reduced_motion = false
    var gallery = await open_scene("res://scenes/commander_select/commander_select.tscn")
    check(gallery.mastery_panel.record_label.text.contains("0 matches") and gallery.mastery_panel.record_label.text.contains("Win rate —"), "new profiles show an empty record rather than an invented win rate")
    check(gallery.mastery_panel.level_label.text == "Lv. 1" and gallery.mastery_panel.notice_label.text.contains("device"), "new mastery and local-save guidance are visible")
    for commander in db.get_all_commanders():
        gallery._select_commander(str(commander["id"]))
        await process_frame
        check_bounds(gallery.mastery_panel, "Commander mastery panel")
        check_bounds(gallery.skill_label, "Commander active description")
        check_bounds(gallery.full_portrait, "full portrait")
    var commander := "commander_fire_01"
    award(commander, "win")
    award(commander, "win")
    gallery._select_commander(commander)
    check(gallery.mastery_panel.record_label.text.contains("2W / 0L") and gallery.mastery_panel.record_label.text.contains("100%"), "selected Commander displays its actual record")
    state.clear_army()
    for card in db.get_cards_by_set("set_fire_01"):
        state.equip_card(str(card["id"]))
    check(state.begin_match(3187), "match begins")
    while not state.draft.is_phase_complete():
        state.draft.auto_select()
    state.match_state.start(1)
    for card in db.get_cards_by_set("set_fire_01"):
        state.draft.unit_counts[str(card["id"])] = int(card["unit_cap"])
    for buff in db.get_all_buffs():
        state.draft.buff_stacks[str(buff["id"])] = 3
    state.opponent.draft.unit_counts.clear()
    state.opponent.draft.unit_counts[str(state.opponent.get_side()["cards"][0]["id"])] = 1
    check(state.run_battle() and state.match_state.is_complete(), "a real complete match produces a reward receipt")
    var stats: Dictionary = state.commander_progress.record(commander)
    var combat = await open_scene("res://scenes/combat/combat.tscn")
    combat.set_process(false)
    check(not combat.mastery_panel.visible, "final mastery result remains hidden while its battle is playing")
    combat._finish_replay()
    combat.mastery_panel.set_process(false)
    check(combat.mastery_panel.visible and combat.mastery_panel.level_label.text.contains("+100 XP"), "completed-match results reveal the XP reward")
    check(combat.mastery_panel.level_label.text.contains("Lv. 1"), "normal reward animation begins at the previous level")
    combat.mastery_panel._process(0.9)
    check(combat.mastery_panel.level_label.text.contains("Lv. 2") and combat.mastery_panel.progress_bar.value == 50 and combat.mastery_panel.xp_label.text.contains("Level up!"), "reward animation crosses the level threshold and settles on exact progress")
    await process_frame
    await process_frame
    check_bounds(combat.get_node("Margin/Main"), "final result screen")
    check_bounds(combat.mastery_panel, "reward panel")
    combat._finish_replay()
    combat.mastery_panel.show_reward(state.mastery_reward)
    combat.mastery_panel.finish_animation()
    check(state.commander_progress.record(commander) == stats, "repeated UI/result animation cannot grant extra XP")
    audio.reduced_motion = true
    combat.mastery_panel.show_reward(state.mastery_reward)
    check(not combat.mastery_panel.is_processing() and combat.mastery_panel.progress_bar.value == 50, "reduced motion immediately displays final reward progress")
    audio.reduced_motion = reduced
    state.commander_progress.read_only = true
    var profile_view = load("res://scripts/presentation/commander_mastery_panel.gd").new()
    profile_view.configure(state.commander_progress, db, audio)
    root.add_child(profile_view)
    profile_view.show_record(commander)
    check(profile_view.notice_label.text.contains("temporary"), "profile read/save failure has visible player guidance")
    profile_view.queue_free()
    state.commander_progress.read_only = false
    state.leave_match()
    state.commander_progress.begin_match(commander)
    state.match_started = true
    state.match_state.start()
    var menu = root.get_node("GameMenu")
    menu.confirm_leave()
    check(menu._body.get_child(1).text.contains("counts as a loss") and menu._body.get_child(1).text.contains("no mastery XP"), "leaving a played match explains its forfeit before confirmation")
    menu.close()
    state.commander_progress.recover_interrupted_match()
    state.leave_match()
    audio.reduced_motion = reduced
    if not failed:
        print("Mastery presentation tests passed: empty/populated gallery, all Commander bounds, hidden battle reward, animated level-up, reduced motion, exact-once UI, storage notice and forfeit guidance.")
    quit(1 if failed else 0)

func check_bounds(control: Control, label: String) -> void:
    var bounds := control.get_global_rect()
    check(bounds.position.x >= -1 and bounds.position.y >= -1 and bounds.end.x <= 1281 and bounds.end.y <= 721, label + " fits desktop: " + str(bounds))

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)
