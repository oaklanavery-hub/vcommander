extends SceneTree

const TEST_KEY := "fixture-only-collection-access-0123456789abcdef"
var failed := false
var path := "user://developer_access_test_%d.cfg" % OS.get_process_id()

func _init() -> void:
    call_deferred("run")

func run() -> void:
    cleanup()
    var db := root.get_node("ContentDatabase")
    var state := root.get_node("GameState")
    check(state.developer_access.path.is_empty() and not state.developer_access.is_enabled(), "script startup never reads the developer's real credential")
    check(state.commander_progress.available_cards().size() == 16, "exported/default scripted entry keeps normal collection gates")
    check(str(ProjectSettings.get_setting(DeveloperAccess.VERIFIER_SETTING, "")).length() == 64 and str(ProjectSettings.get_setting(DeveloperAccess.VERIFIER_SETTING, "")) != TEST_KEY.sha256_text(), "production has a verifier distinct from the public synthetic fixture")
    var access := DeveloperAccess.new(path, TEST_KEY.sha256_text())
    var profile := CommanderProgress.new(db, path + ".json", access)
    check(not access.is_enabled() and access.activate("wrong") == ERR_UNAUTHORIZED and profile.available_cards().size() == 16, "missing/invalid credentials do not grant access")
    check(access.activate("  " + TEST_KEY + "\n") == OK and access.is_enabled() and profile.available_cards().size() == 24, "only a matching private credential grants the complete collection")
    check(not profile.is_card_unlocked("unknown") and profile.unlocked_card_ids().is_empty(), "developer access neither invents unknown cards nor permanent entitlements")
    for commander in db.get_all_commanders():
        check(profile.record(commander["id"])["xp"] == 0 and profile.record(commander["id"])["played"] == 0, "access never forges mastery or matches")
    for entry in profile.achievement_entries():
        check(not entry["earned"], "access never grants achievements")
    for reward in profile.mastery_rewards():
        check(reward["unlocked"] and not reward["earned"], "preview access stays distinct from earned reward status")
    var credential_bytes := FileAccess.get_file_as_string(path)
    check(access.activate("fixture-invalid-key-0123456789abcdef") == ERR_UNAUTHORIZED and FileAccess.get_file_as_string(path) == credential_bytes and access.is_enabled(), "invalid attempts never replace a valid saved credential")
    check(DeveloperAccess.new(path, TEST_KEY.sha256_text()).is_enabled(), "the credential is revalidated after restarting")
    check(not DeveloperAccess.new(path, "").is_enabled() and not DeveloperAccess.new(path, "0".repeat(64)).is_enabled(), "missing/rotated verifiers refuse an old credential")
    var receipt := {}
    for i in range(5):
        receipt = profile.finish_match(profile.begin_match("commander_fire_01"), "win")
    check(receipt["unlocked_cards"] == ["card_fire_06"] and profile.is_card_earned("card_fire_06") and not profile.is_card_earned("card_fire_04"), "normal rewards still grant exactly once while developer access is enabled")
    var records := profile.record("commander_fire_01")
    check(records["wins"] == 5 and records["xp"] == 500 and not FileAccess.get_file_as_string(path + ".json").contains(TEST_KEY), "mastery stores actual outcomes without the credential")
    check(access.remove() == OK and not access.is_enabled() and not FileAccess.file_exists(path), "removal deletes only the saved developer credential")
    check(profile.available_cards().size() == 17 and profile.is_card_earned("card_fire_06") and profile.record("commander_fire_01") == records, "removal retains earned cards and actual match records")
    check(not DeveloperAccess.new(path, TEST_KEY.sha256_text()).is_enabled(), "revoked access stays off after restart")
    var reloaded := CommanderProgress.new(db, path + ".json")
    check(reloaded.available_cards().size() == 17 and reloaded.record("commander_fire_01") == records, "a saved normal profile never inherits developer access")
    var blocked := DeveloperAccess.new("user://missing_access_directory_%d/access.cfg" % OS.get_process_id(), TEST_KEY.sha256_text())
    check(blocked.activate(TEST_KEY) != OK and not blocked.is_enabled(), "save failure is reported and does not claim persistent activation")
    for text in ['[access]\nschema_version=1\nenabled=true\n', '[access]\nschema_version=99\nkey="%s"\n' % TEST_KEY, "corrupt"]:
        var file := FileAccess.open(path, FileAccess.WRITE)
        file.store_string(text)
        file.close()
        check(not DeveloperAccess.new(path, TEST_KEY.sha256_text()).is_enabled() and FileAccess.get_file_as_string(path) == text, "flags/future/corrupt credential files never grant access or overwrite themselves")
    cleanup()
    if not failed:
        print("Developer access tests passed: default/export isolation, private verifier, invalid keys, persistence/revocation, truthful earned rewards/records, save failure and malformed credentials.")
    quit(1 if failed else 0)

func cleanup() -> void:
    for suffix in ["", ".tmp", ".json", ".json.bak", ".json.tmp"]:
        var absolute := ProjectSettings.globalize_path(path + suffix)
        if FileAccess.file_exists(absolute):
            DirAccess.remove_absolute(absolute)

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)
