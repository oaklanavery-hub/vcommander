extends SceneTree

var failed := false
var db: Node
var test_path := "user://mastery_test_%d.json" % OS.get_process_id()

func _init() -> void:
    call_deferred("run")

func run() -> void:
    db = root.get_node("ContentDatabase")
    test_rewards()
    test_storage()
    test_invalid_data()
    cleanup()
    if not failed:
        print("Commander progress tests passed: permanent levels, performance-weighted XP, separate records, forfeits, exact-once settlement, persistence, interruption recovery, backup and invalid-save protection.")
    quit(1 if failed else 0)

func apply(profile: CommanderProgress, commander: String, outcome: String) -> Dictionary:
    var id := profile.begin_match(commander)
    check(not id.is_empty(), "a known Commander starts a profile match")
    return profile.finish_match(id, outcome)

func test_rewards() -> void:
    var profile := CommanderProgress.new(db, "")
    var ids: Array = db.commanders.keys()
    var first := str(ids[0])
    var second := str(ids[1])
    var fresh := profile.record(first)
    check(fresh["level"] == 1 and fresh["played"] == 0 and fresh["xp"] == 0, "new Commanders start at Level 1 with an empty record")
    check(profile.begin_match("unknown_commander").is_empty(), "unknown Commander cannot receive records")
    var id := profile.begin_match(first)
    check(profile.record(first)["played"] == 0 and profile.begin_match(second).is_empty(), "opening a match grants nothing and cannot replace an active match")
    check(profile.finish_match("wrong_match", "win").is_empty() and profile.finish_match(id, "draw").is_empty(), "invalid results cannot settle the pending match")
    var receipt := profile.finish_match(id, "win")
    check(receipt["xp_awarded"] == 100 and receipt["after"]["played"] == 1, "a complete match win awards 100 XP once")
    profile.finish_match(id, "loss")
    profile.finish_match(id, "forfeit")
    check(profile.record(first)["wins"] == 1 and profile.record(first)["losses"] == 0, "repeated settlement cannot change a completed win or award twice")
    for i in range(29):
        apply(profile, first, "win")
    for i in range(10):
        apply(profile, first, "loss")
    for i in range(20):
        apply(profile, second, "win")
        apply(profile, second, "loss")
    var strong := profile.record(first)
    var mixed := profile.record(second)
    check(strong["played"] == 40 and strong["wins"] == 30 and strong["losses"] == 10 and strong["win_rate"] == 75, "per-Commander counts and win rate use whole matches")
    check(strong["xp"] == 3500 and strong["level"] == 15 and strong["xp_in_level"] == 0, "250 XP earns each permanent level")
    check(mixed["played"] == 40 and mixed["xp"] == 3000 and mixed["level"] == 13, "better win ratio earns more mastery at equal match count")
    var forfeited := apply(profile, first, "forfeit")
    check(forfeited["xp_awarded"] == 0 and forfeited["after"]["losses"] == 11 and forfeited["after"]["forfeits"] == 1, "forfeit counts as a loss with zero XP")
    check(forfeited["after"]["level"] == strong["level"], "losses and forfeits cannot remove earned levels")
    var copied := profile.record(first)
    copied["xp"] = 999999
    receipt["after"]["xp"] = 999999
    var pending := profile.begin_match(second)
    var pending_copy := profile.active_match()
    pending_copy["commander_id"] = first
    check(profile.record(first)["xp"] == 3500 and profile.active_match()["commander_id"] == second, "returned records, receipts and pending state do not expose writable profile data")
    profile.finish_match(pending, "loss")
    # Content IDs, including newly introduced Commanders, select records generically.
    db.commanders["commander_future"] = {"id": "commander_future"}
    apply(profile, "commander_future", "win")
    check(profile.record("commander_future")["xp"] == 100 and profile.record(first)["xp"] == 3500, "new Commander content receives an independent record without service changes")
    db.commanders.erase("commander_future")

func test_storage() -> void:
    cleanup()
    var commander := str(db.commanders.keys()[0])
    var profile := CommanderProgress.new(db, test_path)
    var receipt := apply(profile, commander, "win")
    check(profile.last_save_error == OK and FileAccess.file_exists(test_path + ".bak"), "atomic writes and backup succeed")
    var reloaded := CommanderProgress.new(db, test_path)
    check(reloaded.record(commander)["wins"] == 1 and reloaded.record(commander)["xp"] == 100, "records survive a fresh service instance")
    reloaded.finish_match(str(receipt["match_id"]), "win")
    check(reloaded.record(commander)["wins"] == 1, "reloading cannot replay an old reward")
    var pending := reloaded.begin_match(commander)
    check(pending != receipt["match_id"], "new matches retain distinct identities across reloads")
    reloaded = CommanderProgress.new(db, test_path)
    check(not reloaded.active_match().is_empty(), "first battle's pending identity persists")
    var recovered := reloaded.recover_interrupted_match()
    check(recovered["outcome"] == "forfeit" and reloaded.record(commander)["losses"] == 1 and reloaded.record(commander)["xp"] == 100, "interrupted matches recover as one zero-XP loss")
    reloaded = CommanderProgress.new(db, test_path)
    check(reloaded.recover_interrupted_match().is_empty() and reloaded.record(commander)["losses"] == 1, "reopening an interrupted game again never adds another forfeit")
    write_file(test_path, "broken primary")
    reloaded = CommanderProgress.new(db, test_path)
    check(reloaded.recovered_from_backup and reloaded.record(commander)["wins"] == 1 and reloaded.record(commander)["losses"] == 1, "current backup restores completed records without stale pending matches")
    apply(reloaded, commander, "loss")
    reloaded = CommanderProgress.new(db, test_path)
    check(not reloaded.read_only and not reloaded.recovered_from_backup and reloaded.record(commander)["xp"] == 150, "recovery repairs the primary on the next save")
    var blocked := CommanderProgress.new(db, "user://missing_mastery_directory_%d/profile.json" % OS.get_process_id())
    apply(blocked, commander, "win")
    check(blocked.last_save_error != OK and blocked.record(commander)["xp"] == 100 and blocked.storage_notice().contains("could not be saved"), "save failure preserves session progress and surfaces a warning")

func test_invalid_data() -> void:
    var commander := str(db.commanders.keys()[0])
    var invalid_profiles := [
        {"schema_version": 99, "match_serial": 0, "commanders": {}, "active_match": {}},
        {"schema_version": 1, "match_serial": -1, "commanders": {}, "active_match": {}},
        {"schema_version": 1, "match_serial": 0, "commanders": {commander: {"wins": 1.5, "losses": 0, "forfeits": 0, "xp": 100}}, "active_match": {}},
        {"schema_version": 1, "match_serial": 0, "commanders": {commander: {"wins": 0, "losses": 0, "forfeits": 1, "xp": 0}}, "active_match": {}},
        {"schema_version": 1, "match_serial": 0, "commanders": {}, "active_match": {"id": "match:999", "commander_id": commander}}
    ]
    for data in invalid_profiles:
        cleanup()
        var text := JSON.stringify(data)
        write_file(test_path, text)
        var profile := CommanderProgress.new(db, test_path)
        check(profile.read_only and profile.load_error != OK, "invalid or future-schema profile is protected")
        apply(profile, commander, "win")
        check(FileAccess.get_file_as_string(test_path) == text and profile.storage_notice().contains("temporary"), "invalid saves remain intact while temporary session play remains available")

func write_file(path: String, value: String) -> void:
    var file := FileAccess.open(path, FileAccess.WRITE)
    file.store_string(value)
    file.close()

func cleanup() -> void:
    for suffix in ["", ".bak", ".tmp"]:
        var absolute := ProjectSettings.globalize_path(test_path + suffix)
        if FileAccess.file_exists(absolute):
            DirAccess.remove_absolute(absolute)

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)
