extends SceneTree

var failed := false

func _init() -> void:
    call_deferred("run")

func check(ok: bool, message: String) -> void:
    if not ok:
        failed = true
        push_error("TEST FAILED: " + message)

func run() -> void:
    var db := root.get_node("ContentDatabase")
    var progress := CommanderProgress.new(db, "")
    var units: Array = []
    for element in ["fire", "water", "earth", "slime"]:
        var card: Dictionary = db.get_card("card_%s_06" % element)
        check(card["summon_amount"] == 2 and card["unit_cap"] == 4 and not progress.is_card_unlocked(card["id"]), "specialist is a previewable mastery 2/4 card: " + element)
        var frame := PixelAtlasArt.icon("units", str(card["id"]))
        check(frame != null, "new art survives source and pack imports: " + element)
    var transit := {"from_x": 4.0, "from_y": 7.0, "to_x": 20.0, "to_y": 7.0, "started_at": 5.0, "ends_at": 5.8, "mode": "flame", "invulnerable": true}
    var event := {"type": "ability", "kind": "backline_transit", "unit_id": "player:future:0", "transit": transit}
    check(AssassinEffects.transit_at([event], "player:future:0", 4.99).is_empty(), "actor never transforms before its authoritative cast")
    check(not AssassinEffects.transit_at([event], "player:future:0", 5.4).is_empty() and AssassinEffects.transit_at([event], "player:future:0", 5.8).is_empty(), "transform occupies exactly the recorded interval")
    for pair in [["flame", "ember_dash"], ["gush", "water_gush"], ["burrow", "earth_rumble"]]:
        var cue: Dictionary = event.duplicate(true)
        cue["transit"]["mode"] = pair[0]
        check(CombatCues.sound(cue) == pair[1] and FileAccess.file_exists("res://assets/audio/%s.wav" % pair[1]), "travel has its matching packed sound")
    check(CombatCues.sound({"type": "ability", "kind": "sticky_link"}) == "sticky_link", "Sticky cast has a distinct cue")
    var battle := {"battlefield": {"width": 24}, "frames": [{"units": [{"id": "player:future:0", "transit": transit}], "obstacles": [{"from_x": 5, "to_x": 19, "from_y": 4, "to_y": 8}], "links": [{"side": "player", "target_ids": ["opponent:enemy:0", "opponent:enemy:1"]}]}]}
    var original := battle.duplicate(true)
    var guest := PrivatePerspective.battle_for_player(battle, "opponent")
    check(guest["frames"][0]["units"][0]["transit"]["to_x"] == 4 and guest["frames"][0]["obstacles"][0]["from_x"] == 19, "guest view mirrors transit and crack endpoints")
    check(guest["frames"][0]["links"][0]["target_ids"][0] == "player:enemy:0" and battle == original, "guest links use mirrored identities without mutating authority")
    check(AssassinEffects.number(1e100).contains("e") and not AssassinEffects.number(1e100).contains("-922"), "very late-game stat labels avoid integer overflow")
    if not failed:
        print("Specialist presentation tests passed: collection/art/export, exact transform intervals, matching sounds, guest terrain/link mirroring and numeric labels.")
    quit(1 if failed else 0)
