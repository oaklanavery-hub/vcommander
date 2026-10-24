extends SceneTree

var failed := false
var db: Node
var path := "user://lineup_test_%d.json" % OS.get_process_id()
const LINEUPS := {
    "fire": {"starters": [1, 2, 3, 5], "first": 6, "second": 4},
    "water": {"starters": [1, 2, 3, 5], "first": 4, "second": 6},
    "earth": {"starters": [1, 3, 4, 5], "first": 2, "second": 6},
    "slime": {"starters": [1, 2, 3, 5], "first": 4, "second": 6}
}

func _init() -> void:
    call_deferred("run")

func award(profile: CommanderProgress, commander: String, outcome: String) -> Dictionary:
    return profile.finish_match(profile.begin_match(commander), outcome)

func run() -> void:
    db = root.get_node("ContentDatabase")
    var profile := CommanderProgress.new(db, "")
    check(profile.available_cards().size() == 16, "a fresh profile has sixteen starters")
    for element in LINEUPS:
        var commander := "commander_%s_01" % element
        var lineup: Dictionary = LINEUPS[element]
        var starters: Array[Dictionary] = []
        for index in lineup["starters"]:
            var card: Dictionary = db.get_card("card_%s_%02d" % [element, index])
            check(not card.has("mastery_unlock") and profile.is_card_unlocked(card["id"]), "approved starter: " + str(card["id"]))
            starters.append(card)
        check(SetBonusChecker.is_complete(starters, "set_%s_01" % element, 4), "every starting lineup activates its signature set")
        var first := "card_%s_%02d" % [element, lineup["first"]]
        var second := "card_%s_%02d" % [element, lineup["second"]]
        var first_requirement: Dictionary = db.get_card(first)["mastery_unlock"]
        var second_requirement: Dictionary = db.get_card(second)["mastery_unlock"]
        check(first_requirement["commander_id"] == commander and int(first_requirement["level"]) == 3 and int(first_requirement["wins"]) == 3, "approved first reward: " + first)
        check(second_requirement["commander_id"] == commander and int(second_requirement["level"]) == 5 and int(second_requirement["wins"]) == 6, "approved second reward: " + second)
        for i in range(4):
            award(profile, commander, "win")
        check(not profile.is_card_unlocked(first), "400 XP with enough wins still locks the Level 3 reward")
        var receipt := award(profile, commander, "win")
        check(receipt["unlocked_cards"] == [first] and profile.is_card_unlocked(first), "500 XP grants exactly the first reward")
        for i in range(4):
            award(profile, commander, "win")
        check(not profile.is_card_unlocked(second), "900 XP with enough wins still locks the Level 5 reward")
        receipt = award(profile, commander, "win")
        check(receipt["unlocked_cards"] == [second], "1000 XP grants exactly the second reward")
        var losses := CommanderProgress.new(db, "")
        for i in range(40):
            award(losses, commander, "loss")
        for i in range(2):
            award(losses, commander, "win")
        check(not losses.is_card_unlocked(first) and not losses.is_card_unlocked(second), "Level 5 cannot replace required wins")
        check(award(losses, commander, "win")["unlocked_cards"] == [first], "third win meets first reward's independent win boundary")
        for i in range(2):
            award(losses, commander, "win")
        check(not losses.is_card_unlocked(second), "five wins cannot satisfy the second reward")
        check(award(losses, commander, "win")["unlocked_cards"] == [second], "sixth win meets second reward's independent win boundary")
    check(profile.available_cards().size() == 24, "all eight earned rewards become available")
    var spore: Dictionary = db.get_card("card_earth_05")
    check(spore["summon_amount"] == 2 and spore["unit_cap"] == 4 and spore["stats"]["attack"] == 92 and spore["stats"]["health"] == 360, "Spore Sage is a 2/4 starter with unchanged combat stats")
    test_migration()
    cleanup()
    if not failed:
        print("Mastery lineup tests passed: exact starters, both independent level/win boundaries for all eight rewards, Spore 2/4, legacy/current/corrupt/future/backup saves and preset ownership.")
    quit(1 if failed else 0)

func test_migration() -> void:
    for version in [1, 2]:
        cleanup()
        var old := {"schema_version": version, "match_serial": 4, "commanders": {},
            "active_match": {"id": "match:4", "commander_id": "commander_water_01"}}
        if version == 2:
            old["achievements"] = ["historical_badge"]
            old["unlocked_cards"] = ["historical_card", "card_fire_05"]
        write_profile(old)
        var migrated := CommanderProgress.new(db, path)
        check(migrated.available_cards().size() == 24 and migrated.record("commander_fire_01")["played"] == 0, "old ordinary ownership survives without fabricating records")
        var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
        check(saved["schema_version"] == 4 and saved["active_match"] == old["active_match"], "migration saves schema 4 and preserves pending identity")
        for id in db.get_mastery_rules()["legacy_available_cards"]:
            check(migrated.unlocked_card_ids().has(id), "legacy ordinary card is a permanent entitlement")
        if version == 2:
            check(saved["achievements"].has("historical_badge") and saved["unlocked_cards"].has("historical_card") and saved["unlocked_cards"].has("card_fire_05"), "historical and earned IDs are retained")
        var presets := WarbandPresets.new(db, path + ".cfg", 4, migrated)
        var previous: Array[String] = ["card_fire_01", "card_fire_02", "card_fire_03", "card_fire_04"]
        check(presets.save_slot("commander_fire_01", 0, previous) == OK and presets.load_slot("commander_fire_01", 0) == previous, "existing four-card presets remain legal after migration")
        write_text(path, "broken")
        var recovered := CommanderProgress.new(db, path)
        check(recovered.recovered_from_backup and recovered.available_cards().size() == 24, "current backup retains grandfathered ownership")
        check(not recovered.recover_interrupted_match().is_empty() and recovered.recover_interrupted_match().is_empty(), "migration/backup still recovers one forfeit exactly once")
    cleanup()
    var missing := CommanderProgress.new(db, path)
    check(missing.available_cards().size() == 16 and missing.unlocked_card_ids().is_empty(), "missing files do not qualify as an old collection")
    var current := {"schema_version": 3, "match_serial": 0, "commanders": {}, "active_match": {}, "achievements": [], "unlocked_cards": []}
    write_profile(current)
    check(CommanderProgress.new(db, path).available_cards().size() == 16, "current schema never replays legacy grants")
    for invalid in [{"schema_version": 1, "match_serial": 0, "commanders": {"bad": {}}, "active_match": {}},
            {"schema_version": 5, "match_serial": 0, "commanders": {}, "active_match": {}, "achievements": [], "unlocked_cards": []}]:
        cleanup()
        write_profile(invalid)
        var bytes := FileAccess.get_file_as_string(path)
        var protected := CommanderProgress.new(db, path)
        check(protected.read_only and protected.available_cards().size() == 16 and FileAccess.get_file_as_string(path) == bytes, "invalid/future saves are protected and receive no legacy grants")

func write_profile(value: Dictionary) -> void:
    write_text(path, JSON.stringify(value))

func write_text(file_path: String, value: String) -> void:
    var file := FileAccess.open(file_path, FileAccess.WRITE)
    file.store_string(value)
    file.close()

func cleanup() -> void:
    for suffix in ["", ".bak", ".tmp", ".cfg"]:
        var absolute := ProjectSettings.globalize_path(path + suffix)
        if FileAccess.file_exists(absolute):
            DirAccess.remove_absolute(absolute)

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)
