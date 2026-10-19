class_name SharedBattleClock
extends RefCounted

const START_DELAY := 1.0
const CONTACT_TAIL := 0.55

static func opening_seconds(battle: Dictionary) -> float:
    return BattlePrelude.new(battle.get("pre_battle", {})).duration

static func duration_seconds(battle: Dictionary) -> float:
    var replay := BattleReplay.new()
    replay.configure(battle.get("frames", []), battle.get("events", []))
    return opening_seconds(battle) + maxf(float(battle.get("duration", 0)), replay.final_action_time()) + CONTACT_TAIL
