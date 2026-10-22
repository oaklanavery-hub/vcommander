extends SceneTree

var failed := false
var guide: Node
var state: Node
var menu: Node
const TEST_PATH := "user://test_first_match_guide.cfg"

func _init() -> void:
    call_deferred("run")

func settle() -> void:
    await process_frame
    await process_frame

func expect_step(step: String) -> void:
    await settle()
    check(guide.active and guide.current_step == step and guide.overlay.visible and paused, "real action reaches pausing guide step: " + step)
    var panel: Control = guide.overlay.find_child("CoachPanel", true, false)
    if panel != null:
        var bounds := panel.get_global_rect()
        check(bounds.position.x >= -1 and bounds.position.y >= -1 and bounds.end.x <= 1281 and bounds.end.y <= 721, "coach panel stays within the viewport")
    guide.continue_step()
    await settle()
    check(not guide.overlay.visible and not paused, "continuing notes restores local clocks")

func run() -> void:
    root.size = Vector2i(1280, 720)
    guide = root.get_node("FirstMatchGuide")
    state = root.get_node("GameState")
    menu = root.get_node("GameMenu")
    var db := root.get_node("ContentDatabase")
    state.commander_progress = CommanderProgress.new(db, "")
    check(guide.preference_path.is_empty() and not guide.active and not guide.completed, "automation never touches player tutorial preferences or auto-starts guidance")
    change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
    await scene_changed
    await settle()
    menu.open_help()
    menu._start_guided_match()
    await scene_changed
    await expect_step("commander")
    current_scene._open_army_builder()
    await scene_changed
    await expect_step("warband")
    check(state.army.is_full(), "guide uses the real legal starter warband")
    current_scene.seed_input.text = "7303"
    current_scene._begin_draft()
    await scene_changed
    await settle()
    var draft = current_scene
    var clock: float = draft._time_left
    await create_timer(0.12, true).timeout
    check(draft._time_left == clock, "reading a coach panel holds the actual selection timer")
    await expect_step("draft")
    draft._select_offer(0)
    await expect_step("skill")
    draft._use_commander_skill()
    check(state.draft.commander_skill_used_this_round and state.draft.commander_skill_uses == 1, "tutorial skill uses the actual selection and match allowance")
    while not state.draft.is_phase_complete():
        draft._select_offer(0)
    await expect_step("ready")
    check(state.commander_progress.active_match().is_empty(), "draft notes cannot start a tracked match or grant mastery")
    draft._start_battle()
    await scene_changed
    await settle()
    var combat = current_scene
    check(combat._prelude.active() and combat._playback_time == 0 and combat._speed_index == 0, "actual Commander opening and default 1× are preserved")
    await expect_step("battle")
    combat._paused = true
    combat._inspect_unit(combat.battlefield.visible_units()[0])
    check(combat.inspector.visible, "player can use real inspection during the guided battle")
    combat._paused = false
    combat._process(BattlePrelude.DURATION)
    combat._process(combat._duration + combat._tail_length + 0.2)
    await expect_step("report")
    var before := JSON.stringify(state.commander_progress._data)
    guide.preference_path = TEST_PATH
    combat._open_report()
    await expect_step("complete")
    check(guide.completed and not guide.active and guide.last_save_error == OK, "only opening a completed report finishes and saves the optional guide")
    check(JSON.stringify(state.commander_progress._data) == before, "guide completion never settles a match, grants XP or unlocks cards")
    guide.completed = false
    guide.load_preference()
    check(guide.completed, "completion is retained independently of the Commander profile")
    combat.report_view.close()
    menu.open_help()
    menu._start_guided_match()
    await settle()
    check(menu.overlay.visible and not guide.active and menu._leave_callback.is_valid(), "replaying guidance during a played match requires the existing forfeit confirmation")
    menu.close()
    check(not guide.active and not menu._leave_callback.is_valid() and JSON.stringify(state.commander_progress._data) == before, "cancelling leaves no stale restart callback or forged loss")
    menu.open_help()
    menu._start_guided_match()
    menu._leave()
    await scene_changed
    await settle()
    check(guide.active and current_scene.name == "CommanderSelect" and state.commander_progress.record(state.selected_commander_id)["forfeits"] == 1, "confirmed restart records the normal forfeit exactly once and starts guidance")
    guide.stop()
    check(not paused and not guide.overlay.visible, "ending guidance restores the original pause state")
    var online := root.get_node("OnlineSession")
    online.active = true
    guide.start()
    check(not guide.active and not paused, "guide cannot pause a private online session")
    online.active = false
    guide.start()
    paused = true
    guide.announce("commander")
    await settle()
    guide.continue_step()
    check(paused, "coach panels restore an already paused context")
    guide.stop()
    paused = false
    var config := ConfigFile.new()
    config.set_value("guide", "schema", 99)
    config.set_value("guide", "completed", true)
    config.save(TEST_PATH)
    guide.load_preference()
    check(not guide.completed, "an unknown preference schema cannot claim guide completion")
    guide.preference_path = ""
    for path in [TEST_PATH, TEST_PATH + ".tmp"]:
        if FileAccess.file_exists(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    if not failed:
        print("First-match guide tests passed: real Commander/army/draft/skill/opening/inspection/report flow, paused clocks, optional exit/replay, exact ordinary forfeit, no XP/entitlements, isolated persistence and online exclusion.")
    await settle()
    quit(1 if failed else 0)

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)
