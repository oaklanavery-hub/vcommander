extends SceneTree

var failed := false
var source: Node
var db: Node

func _init() -> void:
    call_deferred("run")

func fixture(snapshot: Dictionary) -> Node:
    var state = load("res://scripts/core/game_state.gd").new()
    root.add_child(state)
    state.commander_progress = CommanderProgress.new(db, "")
    state.commander_progress._data = source.commander_progress._data.duplicate(true)
    state.commander_progress.last_receipt = source.commander_progress.last_receipt.duplicate(true)
    state.local_store = LocalMatchStore.new("")
    state.local_store.save(JSON.parse_string(JSON.stringify(snapshot)))
    return state

func run() -> void:
    db = root.get_node("ContentDatabase")
    source = load("res://scripts/core/game_state.gd").new()
    root.add_child(source)
    source.local_store = LocalMatchStore.new("")
    source.commander_progress = CommanderProgress.new(db, "")
    for index in range(20):
        source.commander_progress.finish_match(source.commander_progress.begin_match("commander_fire_01"), "win")
    for id in ["card_fire_01", "card_fire_02", "card_fire_03", "card_fire_05"]:
        check(source.purchase_unit_upgrade(id, source.commander_progress.upgrade_cost())["ok"], "between-adventure purchases succeed through GameState")
    var balance: int = source.commander_progress.upgrade_balance()
    var mastery: Dictionary = source.commander_progress.record("commander_fire_01")
    source.select_commander("commander_fire_01")
    source.equip_starter_army()
    check(source.begin_match(65537), "an upgraded adventure starts normally")
    check(source.get_player_combat_side()["unit_upgrades"] == source.opponent.get_side()["unit_upgrades"], "AI receives the exact same purchased upgrade options")
    var before: Array = source.commander_progress.upgraded_unit_ids()
    check(not source.purchase_unit_upgrade("card_fire_04", 400)["ok"] and source.commander_progress.upgraded_unit_ids() == before, "opening drafts lock purchases before a mastery match identity exists")
    source.draft.select_offer(0)
    source.update_draft_clock(14.5)
    var saved: Dictionary = source.local_store.candidates()[0]
    var restored := fixture(saved)
    check(restored.resume_match() and restored.active_unit_upgrades == source.active_unit_upgrades, "a saved draft retains its frozen upgrade collection")
    check(restored.draft.snapshot() == source.draft.snapshot() and restored.opponent_public_side == source.opponent_public_side, "upgrade recovery preserves exact offers/RNG and prior-public rival picks")
    check(restored.commander_progress.upgrade_balance() == balance and restored.commander_progress.record("commander_fire_01") == mastery, "draft resume neither charges again nor changes mastery")
    restored.free()
    while not source.draft.is_phase_complete():
        source.draft.auto_select()
    check(source.run_battle(), "upgraded combat resolves through the real adventure lifecycle")
    var result: Dictionary = source.local_store.candidates()[0]
    var evidence: String = JSON.stringify(source.battle_result).sha256_text()
    check(source.battle_result["frames"][0]["units"].filter(func(unit): return unit["side"] == "player").all(func(unit): return unit.get("unit_level") == 2), "actual recruited player bodies carry the purchased Lv. 2 appearance")
    restored = fixture(result)
    check(restored.resume_match() and JSON.stringify(restored.battle_result).sha256_text() == evidence, "upgraded battle events, frames, procs and visuals reconstruct identically")
    check(restored.match_state.losses == source.match_state.losses and restored.commander_progress.upgrade_balance() == source.commander_progress.upgrade_balance(), "replaying an upgraded round cannot cost another heart or duplicate currency")
    restored.free()
    var bad := result.duplicate(true)
    bad["unit_upgrades"].append("card_water_01")
    restored = fixture(bad)
    check(not restored.resume_match(), "checkpoint metadata cannot inject an unpurchased upgrade")
    restored.free()
    bad = result.duplicate(true)
    bad["public_side"]["unit_upgrades"][0]["ability_overrides"] = {"attack_pct": 999999}
    restored = fixture(bad)
    check(restored.resume_match() and restored.opponent_public_side == source.opponent_public_side, "public upgrade definitions are rebuilt from trusted content, not saved arbitrary patches")
    restored.free()
    # An old adventure keeps its base-unit input, even on a profile that now has
    # purchases. Old content fingerprints omit the new optional upgrade catalog.
    var old := result.duplicate(true)
    old.erase("unit_upgrades")
    old["content"] = source._content_fingerprint(false)
    old["public_side"].erase("unit_upgrades")
    restored = fixture(old)
    check(restored.resume_match() and restored.active_unit_upgrades.is_empty(), "v0.19 adventures remain base-unit adventures on migration")
    check(restored.battle_result["frames"][0]["units"].all(func(unit): return not unit.has("unit_level")), "old replay appearance is not silently upgraded by current ownership")
    restored.free()
    source.leave_match()
    check(source.purchase_unit_upgrade("card_fire_04", 400)["ok"], "the forge becomes available when the pending adventure is retired")
    source.free()
    if not failed:
        print("Unit upgrade recovery tests passed: real purchase guards, fair AI options, frozen drafts, exact upgraded replay/RNG/visuals, unchanged wallet/hearts/mastery, trusted public definitions and base-unit legacy migration.")
    quit(1 if failed else 0)

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)
