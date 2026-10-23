extends SceneTree

var failed := false

func _init() -> void:
    call_deferred("run")

func run() -> void:
    var insights := MatchInsights.new("")
    var round_info := {"round": 1, "winner": "draw", "reason": "timer", "duration": 120.0, "draft_seconds": 19.0, "army_capped": true}
    insights.record_round("default", {"commander": "fixture", "composition": "mixed", "specializations": false}, round_info)
    insights.record_round("default", {"commander": "fixture", "composition": "mixed", "specializations": false}, round_info)
    insights.record_round("prototype", {"commander": "fixture", "composition": "themed", "specializations": true}, {"round": 1, "winner": "player", "duration": 20.0})
    var ordinary := insights.summary(-1, 0)
    var prototype := insights.summary(-1, 1)
    check(ordinary["matches"] == 1 and ordinary["rounds"] == 1 and ordinary["army_capped_rounds"] == 1 and ordinary["mixed_matches"] == 1, "default observations and full-recruitment counts are deduplicated")
    check(prototype["matches"] == 1 and prototype["average_battle"] == 20 and prototype["themed_matches"] == 1 and prototype["timeouts"] == 0, "prototype and default samples stay distinguishable")
    var old: Dictionary = insights.entries[0].duplicate(true)
    for field in ["specializations", "composition", "army_capped_rounds"]:
        old.erase(field)
    check(insights._valid({"schema": 1, "entries": [old]}), "previous schema-1 observations remain readable")
    insights.entries.assign([old])
    check(insights.summary()["themed_matches"] == 0 and insights.summary()["mixed_matches"] == 0, "unknown historical composition is not fabricated")
    var invalid := old.duplicate(true)
    invalid["specializations"] = "yes"
    check(not insights._valid({"schema": 1, "entries": [invalid]}), "malformed prototype metadata is rejected")
    print("Strategy insights tests passed." if not failed else "TEST FAILED: strategy insights")
    quit(1 if failed else 0)

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)
