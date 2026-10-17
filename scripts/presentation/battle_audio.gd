class_name BattleAudio
extends Node

static var sound_enabled := false
var _player := AudioStreamPlayer.new()
var _sounds: Dictionary = {}
var _last_sound_time := -1.0

func _ready() -> void:
    add_child(_player)
    _player.volume_db = -20.0
    _sounds["attack"] = _tone(420.0, 0.055)
    _sounds["defeat"] = _tone(180.0, 0.11)
    _sounds["commander_skill"] = _tone(660.0, 0.3)
    _sounds["heal"] = _tone(880.0, 0.07)

func _tone(frequency: float, duration: float) -> AudioStreamWAV:
    var rate := 22050
    var length := int(float(rate) * duration)
    var data := PackedByteArray()
    data.resize(length * 2)
    for index in range(length):
        var time := float(index) / float(rate)
        var envelope := (1.0 - float(index) / float(length)) * minf(1.0, time * 150.0)
        var sample := sin(time * frequency * TAU) * envelope * 0.5
        data.encode_s16(index * 2, int(sample * 32767.0))
    var result := AudioStreamWAV.new()
    result.format = AudioStreamWAV.FORMAT_16_BITS
    result.mix_rate = rate
    result.data = data
    return result

func consume_event(event: Dictionary) -> void:
    if not sound_enabled:
        return
    var type := str(event.get("type", ""))
    var time := float(event.get("time", 0))
    if not _sounds.has(type) or time - _last_sound_time < 0.09:
        return
    _last_sound_time = time
    _player.stream = _sounds[type]
    _player.play()

func stop_all() -> void:
    _player.stop()
    _player.stream = null

func _exit_tree() -> void:
    stop_all()
    _sounds.clear()
