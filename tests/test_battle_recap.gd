extends SceneTree

var failed := false

func _init() -> void:
    call_deferred("run")

func unit(id: String, role: String) -> Dictionary:
    return {"id": id, "side": "player", "role": role, "card_id": id, "name": id}

func run() -> void:
    var tank := unit("tank", "tank")
    var child := unit("child", "tank")
    var healer := unit("healer", "healer")
    var result := {"duration": 20.0, "winner": "opponent", "reason": "elimination", "events": [
        {"type": "spawn", "time": 0, "unit": tank},
        {"type": "spawn", "time": 0, "unit": healer},
        {"type": "defeat", "time": 2, "unit_id": "tank"},
        {"type": "spawn", "time": 2, "source": "death_split", "unit": child},
        {"type": "damage", "time": 5, "target_id": "healer", "source_side": "opponent", "source": "sticky_share", "hp_loss": 50.0},
        {"type": "damage", "time": 6, "target_id": "healer", "source_side": "opponent", "source": "attack", "hp_loss": 20.0},
        {"type": "defeat", "time": 12, "unit_id": "child"}
    ]}
    var before := JSON.stringify(result)
    var recap := BattleReport.recap(result, "player")
    check(recap["facts"][0] == "Frontline gone at 12.0s; 1 ranged/support bodies remained.", "frontline fact uses the final simultaneous death/spawn state, not a transient loss before a split")
    check(recap["facts"][1].contains("71%") and recap["facts"][1].contains("Linked"), "linked-damage share uses effective incoming HP loss")
    check(recap["suggestion"].contains("option to test"), "advice is distinct from recorded facts and is not a claimed cause of defeat")
    check(JSON.stringify(result) == before and recap == BattleReport.recap(result, "player"), "recap is deterministic and read-only")
    var assassin := unit("assassin", "melee")
    assassin["ability_type"] = "backline_transit"
    var ranged := unit("ranged", "range")
    var timeout := {"duration": 120, "reason": "timer", "events": [{"type": "spawn", "time": 0, "unit": assassin}, {"type": "spawn", "time": 0, "unit": ranged}]}
    recap = BattleReport.recap(timeout, "player")
    check(recap["facts"][0].contains("No frontline") and recap["facts"][1].contains("120s"), "a flanking assassin is not misreported as a protected opening frontline; timer facts use actual duration")
    check(BattleReport.recap({}, "player")["facts"].is_empty(), "missing evidence creates no invented battle explanation")
    check(BattleReport.recap(result, "opponent")["facts"].is_empty(), "one side's facts never get attributed to the other side")
    if not failed:
        print("Battle recap tests passed: simultaneous splits/revivals, exact timestamps/HP shares, side attribution, timeout/assassin semantics, immutable evidence and explicitly optional advice.")
    quit(1 if failed else 0)

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)
