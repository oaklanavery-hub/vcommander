extends SceneTree
var failed := false

class AudioProbe extends Node:
    var calls: Array = []
    func play_effect(cue: String, priority: int = 0) -> void:
        calls.append({"cue": cue, "priority": priority})

func _init() -> void:
    call_deferred("run")

func run() -> void:
    var db := root.get_node("ContentDatabase")
    var audio := root.get_node("GameAudio")
    var motions: Dictionary = {}
    for card in db.get_all_cards():
        var profile := CombatCues.profile(str(card["id"]))
        check(audio.EFFECTS.has(profile.get("death_sound", "")), "every companion has a distinct-type exported death cue")
        var actor := {"card_id": card["id"], "side": "player"}
        var before := JSON.stringify(actor)
        var start := UnitDeathMotion.pose(actor, 0, false)
        var midway := UnitDeathMotion.pose(actor, 0.25, false)
        var end := UnitDeathMotion.pose(actor, 0.5, false)
        motions[midway["death_motion"]] = true
        check(start["alpha"] == 1 and end["alpha"] == 0 and midway != start, "death motion fades completely inside the existing contact tail")
        var reduced := UnitDeathMotion.pose(actor, 0.25, true)
        check(reduced["width"] == 1 and reduced["height"] == 1 and reduced["lean"] == 0 and reduced["rise"] == 0, "reduced motion uses a static fade without collapse/travel")
        check(JSON.stringify(actor) == before, "death poses cannot mutate a replay actor")
        check(CombatCues.sound({"type": "defeat", "unit_id": "player:" + str(card["id"]) + ":0"}) == profile["death_sound"], "real defeat identity selects the content-defined sound")
        var attack := {"time": 2.0, "card_id": card["id"], "x": 0, "y": 0, "target_x": 2, "target_y": 0}
        var windup := UnitAttackMotion.pose(attack, 1.95)
        var strike := UnitAttackMotion.pose(attack, 2.0)
        var recovery := UnitAttackMotion.pose(attack, 2.3)
        check(windup["charge"] > 0 and strike["power"] == 1 and strike["settle"] == 0 and recovery["settle"] > 0.9, "anticipation, exact-time strike and settling are separate readable phases")
        check(float(UnitAttackMotion.pose(attack, 2.46)["settle"]) < 0.001, "settling returns to neutral before the next idle frame")
        for power in [-0.18, 0.5, 1.0]:
            var mesh := UnitAttackMotion.mesh(str(profile["rig"]), 0, power, false)
            var arrays := mesh.surface_get_arrays(0)
            var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
            var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
            for index in range(0, indices.size(), 3):
                check((vertices[indices[index + 1]] - vertices[indices[index]]).cross(vertices[indices[index + 2]] - vertices[indices[index]]).z > 0, "recovery keeps all pixel rig triangles continuous")
    check(motions.size() == 4, "roster covers collapse, wilt, dissolve and slime pop deaths")
    var cues := BattleAudio.new()
    root.add_child(cues)
    var probe := AudioProbe.new()
    root.add_child(probe)
    cues._audio_service = probe
    var admitted := 0
    for id in ["card_earth_04", "card_fire_03", "card_water_02", "card_water_04", "card_earth_01", "card_fire_02", "card_slime_02"]:
        if not cues.consume_event({"type": "attack", "card_id": id}, 1.0).is_empty():
            admitted += 1
    check(admitted == 5, "dense ordinary attacks have a bounded sound budget")
    for kind in ["pull", "sticky_link", "absorb_burst"]:
        check(not cues.consume_event({"type": "ability", "kind": kind}, 1.0).is_empty(), "important abilities survive a saturated attack budget")
    check(not cues.consume_event({"type": "commander_skill", "skill_type": "round_debuff"}, 1.0).is_empty(), "Commander cue retains reserved capacity after busy abilities")
    check(probe.calls.back()["priority"] == 3 and probe.calls.size() == 9, "priority reaches the real voice allocator with a bounded total")
    check(cues.consume_event({"type": "ability", "kind": "pull"}, 1.02).is_empty(), "identical high-priority cues still obey their cooldown")
    check(not cues.consume_event({"type": "attack", "card_id": "card_earth_04"}, 1.2).is_empty(), "next audio window admits ordinary attacks again")
    # Inspect allocation without starting hardware audio. Reserved voices are
    # chosen first for important cues and remain outside ordinary allocation.
    var important: AudioStreamPlayer = audio._effect_voice(2)
    var ordinary: AudioStreamPlayer = audio._effect_voice(0)
    check(audio._effects.find(important) >= 9 and audio._effects.find(ordinary) < 9, "important abilities and normal/UI sounds use separate initial voice capacity")
    cues.queue_free()
    probe.queue_free()
    await process_frame
    if not failed:
        print("Battle polish tests passed: four content-driven death types/cues, static reduced-motion fade, exact strike/recovery/continuous rigs, bounded attacks, reserved ability/Commander audio capacity and cooldowns.")
    quit(1 if failed else 0)

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)
