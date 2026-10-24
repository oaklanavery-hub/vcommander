extends SceneTree

var failed := false
var db: Node
var path := "user://achievement_test_%d.json" % OS.get_process_id()

func _init() -> void:
    call_deferred("run")

func award(profile: CommanderProgress, commander: String, outcome: String) -> Dictionary:
    return profile.finish_match(profile.begin_match(commander), outcome)

func run() -> void:
    db = root.get_node("ContentDatabase")
    var profile := CommanderProgress.new(db, "")
    check(profile.available_cards().size() == 16, "four approved starters per Commander are available")
    for card in db.get_all_cards():
        check(profile.is_card_unlocked(card["id"]) == not card.has("mastery_unlock"), "only declared rewards are locked")
    check(not profile.is_card_unlocked("unknown"), "unknown card is never available")
    for i in range(4):
        award(profile, "commander_fire_01", "win")
    check(not profile.is_card_unlocked("card_fire_06"), "four wins do not bypass the level requirement")
    var receipt := award(profile, "commander_fire_01", "win")
    check(profile.is_card_unlocked("card_fire_06") and profile.available_cards().size() == 17, "Level 3 and wins unlock one new card")
    check(receipt["unlocked_cards"] == ["card_fire_06"] and receipt["achievements"].has("fire_adept"), "receipt carries newly earned unit and achievement")
    var repeated := profile.finish_match(receipt["match_id"], "loss")
    check(repeated == receipt and profile.record("commander_fire_01")["wins"] == 5, "repeat settlement preserves the exact original receipt")
    receipt["unlocked_cards"].clear()
    var entries := profile.achievement_entries()
    entries[0]["earned"] = false
    check(profile.is_card_unlocked("card_fire_06") and profile.achievement_entries()[0]["earned"], "returned entries/receipts cannot change entitlements")
    check(not award(profile, "commander_fire_01", "forfeit")["unlocked_cards"].size(), "later matches do not grant an earned unit again")
    for e in ["fire", "water", "earth", "slime"]:
        for i in range(10):
            award(profile, "commander_%s_01" % e, "win")
        check(profile.is_card_unlocked("card_%s_05" % e), "each Commander retains its starter companion")
    check(profile.available_cards().size() == 24, "all eight rewards expand the collection")
    check(earned(profile, "alliance"), "wins with all four Commanders earn coverage achievement")
    var losses := CommanderProgress.new(db, "")
    for i in range(20):
        award(losses, "commander_water_01", "loss")
    check(losses.record("commander_water_01")["level"] == 5 and not losses.is_card_unlocked("card_water_04"), "50-XP losses alone cannot satisfy the win requirement")
    for i in range(3):
        award(losses, "commander_water_01", "win")
    check(losses.is_card_unlocked("card_water_04"), "the exact third win completes an already met level requirement")
    var forfeits := CommanderProgress.new(db, "")
    for i in range(12):
        award(forfeits, "commander_earth_01", "forfeit")
    check(not earned(forfeits, "first_steps") and not earned(forfeits, "seasoned"), "forfeits cannot farm completed-match achievements")
    test_migration()
    test_unlock_boundaries()
    cleanup()
    if not failed:
        print("Achievement tests passed: all reward thresholds, permanent grants, exact-once receipts, legacy/backup migration, interruption recovery, corrupt entitlements, equipment/preset boundaries and future data IDs.")
    quit(1 if failed else 0)

func earned(profile: CommanderProgress, id: String) -> bool:
    for entry in profile.achievement_entries():
        if entry["id"] == id:
            return entry["earned"]
    return false

func test_migration() -> void:
    cleanup()
    var legacy := {"schema_version": 1, "match_serial": 7,
        "commanders": {"commander_fire_01": {"wins": 5, "losses": 2, "forfeits": 1, "xp": 525},
            "historical_commander": {"wins": 1, "losses": 0, "forfeits": 0, "xp": 100}},
        "active_match": {"id": "match:7", "commander_id": "commander_water_01"}}
    write_file(path, JSON.stringify(legacy))
    var profile := CommanderProgress.new(db, path)
    check(not profile.read_only and profile.last_save_error == OK and profile.is_card_unlocked("card_fire_06"), "legacy records backfill eligible unit on load")
    check(earned(profile, "fire_adept") and profile.record("commander_fire_01")["xp"] == 525 and profile.record("historical_commander")["xp"] == 100, "migration preserves XP and historical records while backfilling achievements")
    var persisted: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
    check(persisted["schema_version"] == 4 and persisted["active_match"] == legacy["active_match"], "schema migration preserves the pending match identity")
    profile.recover_interrupted_match()
    check(profile.record("commander_water_01")["forfeits"] == 1 and profile.is_card_unlocked("card_fire_06"), "interruption settles once without losing another Commander's reward")
    persisted = JSON.parse_string(FileAccess.get_file_as_string(path))
    persisted["achievements"].append("historical_badge")
    persisted["unlocked_cards"].append("historical_card")
    write_file(path, JSON.stringify(persisted))
    # Earned items remain permanent even if future tuning increases requirements.
    var original: Dictionary = db.cards["card_fire_06"]["mastery_unlock"].duplicate()
    db.cards["card_fire_06"]["mastery_unlock"]["level"] = 99
    profile = CommanderProgress.new(db, path)
    check(profile.is_card_unlocked("card_fire_06") and profile.unlocked_card_ids().has("historical_card"), "reload keeps permanent and unknown historical entitlements")
    check(profile.recover_interrupted_match().is_empty(), "migration/reload does not repeat an interruption")
    award(profile, "commander_fire_01", "loss")
    persisted = JSON.parse_string(FileAccess.get_file_as_string(path))
    check(persisted["achievements"].has("historical_badge"), "saving keeps historical achievement IDs")
    db.cards["card_fire_06"]["mastery_unlock"] = original
    write_file(path, "broken primary")
    profile = CommanderProgress.new(db, path)
    check(profile.recovered_from_backup and profile.is_card_unlocked("card_fire_06"), "backup recovery preserves rewards")
    cleanup()
    persisted["unlocked_cards"] = ["card_fire_06", "card_fire_06"]
    var invalid := JSON.stringify(persisted)
    write_file(path, invalid)
    profile = CommanderProgress.new(db, path)
    check(profile.read_only, "malformed duplicate entitlement save is protected")
    award(profile, "commander_fire_01", "win")
    check(FileAccess.get_file_as_string(path) == invalid, "corrupt save is never overwritten by session rewards")

func test_unlock_boundaries() -> void:
    var state := root.get_node("GameState")
    state.leave_match()
    state.commander_progress = CommanderProgress.new(db, "")
    state.select_commander("commander_fire_01")
    state.clear_army()
    check(not state.equip_card("card_fire_06") and state.army.size() == 0, "headless equipment refuses a locked reward")
    var cards: Array[String] = ["card_fire_01", "card_fire_02", "card_fire_03", "card_fire_06"]
    for id in cards:
        state.army.equip(id)
    check(not state.begin_match(718), "begin-match revalidates even a directly injected locked army")
    var presets := WarbandPresets.new(db, path + ".cfg", 4, state.commander_progress)
    check(presets.save_slot("commander_fire_01", 0, cards) != OK, "presets cannot store locked cards")
    # A valid historical preset must also be rejected before any army is cleared.
    var config := ConfigFile.new()
    config.set_value("commander_fire_01", "preset_0", cards)
    config.save(path + ".cfg")
    check(presets.load_slot("commander_fire_01", 0).is_empty(), "loading a locked historical preset is refused")
    for i in range(5):
        award(state.commander_progress, "commander_fire_01", "win")
    check(presets.load_slot("commander_fire_01", 0) == cards, "the same preset becomes legal after earning its unit")
    state.clear_army()
    for id in cards:
        check(state.equip_card(id), "unlocked mixed/theme equipment succeeds")
    check(state.is_full_set_active() and state.begin_match(718), "a reward replaces a starter in the normal four-card theme")
    for card in state.opponent.cards:
        check(state.commander_progress.is_card_unlocked(card["id"]), "AI uses the same available collection")
    state.leave_match()
    # New stable IDs work without adding core-code cases.
    db.cards["future_card"] = {"id": "future_card", "mastery_unlock": {"commander_id": "commander_fire_01", "level": 1, "wins": 1}}
    var future := CommanderProgress.new(db, "")
    check(not future.is_card_unlocked("future_card"), "new content starts locked")
    award(future, "commander_fire_01", "win")
    check(future.is_card_unlocked("future_card"), "future data-driven reward unlocks without a core change")
    db.cards.erase("future_card")

func write_file(file_path: String, value: String) -> void:
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
