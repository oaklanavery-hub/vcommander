extends SceneTree

var failed := false
var db: Node
const TEST_PATH := "user://test_unit_upgrade_profile.json"

func _init() -> void:
    call_deferred("run")

func settle(profile: CommanderProgress, commander: String, outcome: String) -> Dictionary:
    return profile.finish_match(profile.begin_match(commander), outcome)

func run() -> void:
    db = root.get_node("ContentDatabase")
    cleanup()
    var profile := CommanderProgress.new(db, "")
    check(profile.upgrade_balance() == 0 and profile.upgrade_cost() == 200, "fresh profiles have a 200 XP first purchase and no invented currency")
    settle(profile, "commander_fire_01", "win")
    var receipt := settle(profile, "commander_water_01", "win")
    var records: Dictionary = profile._data["commanders"].duplicate(true)
    check(profile.purchase_unit_upgrade("card_fire_01", 200)["ok"], "XP from different Commanders pays for one permanent unit upgrade")
    check(profile.upgrade_balance() == 0 and profile.unit_level("card_fire_01") == 2 and profile.upgrade_cost() == 400, "the first discount is once per profile")
    check(profile._data["commanders"] == records, "spending never decreases lifetime XP, levels, wins or unlock progress")
    profile.finish_match(str(receipt["match_id"]), "win")
    check(profile.upgrade_balance() == 0, "replaying a settlement cannot replenish spent XP")
    for index in range(6):
        settle(profile, "commander_water_01", "win")
    check(not profile.purchase_unit_upgrade("card_fire_04", 400)["ok"], "locked units cannot be purchased even when the shared wallet can afford them")
    check(not profile.purchase_unit_upgrade("card_water_01", 200)["ok"] and profile.upgrade_balance() == 600, "a stale first-price quote cannot charge an unexpected 400 XP")
    check(profile.purchase_unit_upgrade("card_water_01", 400)["ok"] and profile.upgrade_balance() == 200, "subsequent upgrades cost the normal 400 XP")
    check(not profile.purchase_unit_upgrade("card_water_01", 400)["ok"] and profile.upgrade_balance() == 200, "duplicate clicks cannot buy or charge twice")
    var pending := profile.begin_match("commander_fire_01")
    check(not profile.purchase_unit_upgrade("card_fire_02", 400)["ok"], "a tracked adventure locks the purchase ledger")
    profile.finish_match(pending, "forfeit")
    check(profile.upgrade_balance() == 200, "forfeits grant neither mastery nor spendable XP")
    receipt = settle(profile, "commander_fire_01", "loss")
    check(receipt["xp_awarded"] == 50 and profile.upgrade_balance() == 250 and receipt["upgrade_xp_after"] == 250, "completed losses credit 50 XP once to mastery and the derived shared wallet")
    profile.path = TEST_PATH
    profile._save_profile()
    var reloaded := CommanderProgress.new(db, TEST_PATH)
    check(reloaded.unit_level("card_fire_01") == 2 and reloaded.unit_level("card_water_01") == 2 and reloaded.upgrade_balance() == 250, "paid upgrades and spend totals survive file reload")
    reloaded.finish_match(str(receipt["match_id"]), "loss")
    check(reloaded.upgrade_balance() == 250, "persisted receipts cannot duplicate currency after a restart")
    var canonical := reloaded._data.duplicate(true)
    for corrupt in ["duplicate", "unknown", "negative", "overspend", "fractional"]:
        var bad := canonical.duplicate(true)
        match corrupt:
            "duplicate": bad["unit_upgrades"].append(bad["unit_upgrades"][0].duplicate())
            "unknown": bad["unit_upgrades"][0]["unit_id"] = "missing_unit"
            "negative": bad["unit_upgrades"][0]["xp_cost"] = -1
            "overspend": bad["unit_upgrades"][0]["xp_cost"] = 100000
            "fractional": bad["unit_upgrades"][0]["xp_cost"] = 1.5
        write_profile(bad)
        check(reloaded._read_profile(TEST_PATH).is_empty(), "invalid purchase ledgers are rejected: " + corrupt)
    var old := {"schema_version": 3, "match_serial": 0, "active_match": {}, "commanders": {"commander_fire_01": {"wins": 1, "losses": 1, "forfeits": 0, "xp": 125}}, "achievements": [], "unlocked_cards": []}
    write_profile(old)
    # Remove the current backup to exercise the exact old primary.
    DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH + ".bak"))
    reloaded = CommanderProgress.new(db, TEST_PATH)
    check(reloaded.upgrade_balance() == 125 and reloaded.upgraded_unit_ids().is_empty() and reloaded.record("commander_fire_01")["xp"] == 125, "schema-3 migration exposes historical XP without repricing old losses or fabricating purchases")
    check(not reloaded.is_card_earned("card_fire_04"), "schema-3 migration never grants the schema-1/2 legacy collection")
    reloaded = CommanderProgress.new(db, TEST_PATH)
    check(reloaded.upgrade_balance() == 125, "repeated migration/reload cannot credit historical XP twice")
    var blocked := CommanderProgress.new(db, "")
    for index in range(3):
        settle(blocked, "commander_fire_01", "win")
    blocked.path = "user://missing_upgrade_directory_%d/profile.json" % OS.get_process_id()
    var before := blocked._data.duplicate(true)
    check(not blocked.purchase_unit_upgrade("card_fire_01", 200)["ok"] and blocked._data == before and blocked.upgrade_balance() == 300, "failed atomic writes roll back both ownership and spending")
    var catalog: Dictionary = db.get_upgrade_rules()
    var definitions := UnitUpgrades.definitions(catalog, db.cards.keys())
    var original: Array = db.get_all_cards().duplicate(true)
    var side := {"cards": original.duplicate(true), "unit_upgrades": definitions}
    var upgraded := UnitUpgrades.apply_side(side)
    check(UnitUpgrades.apply_side(upgraded) == upgraded and side["cards"] == original and db.get_all_cards() == original, "upgrade transformations apply once to copies and never mutate base content")
    check(upgraded["cards"].all(func(card): return card.get("unit_level") == 2), "all 24 reference units have a permanent Lv. 2 transformation")
    cleanup()
    if not failed:
        print("Unit upgrade progression tests passed: 200/400 pricing, shared/backfilled XP, unchanged mastery, 50 XP losses, exact-once receipts, quotes/locks/duplicate clicks, migration, persistence, corrupt ledgers and failed-write rollback.")
    quit(1 if failed else 0)

func write_profile(value: Dictionary) -> void:
    var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
    file.store_string(JSON.stringify(value))
    file.close()

func cleanup() -> void:
    for suffix in ["", ".bak", ".tmp"]:
        var absolute := ProjectSettings.globalize_path(TEST_PATH + suffix)
        if FileAccess.file_exists(absolute):
            DirAccess.remove_absolute(absolute)

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)
