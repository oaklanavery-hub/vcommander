extends Node

signal settings_changed

const SETTINGS_PATH := "user://presentation.cfg"
const MUSIC := {"menu": "res://assets/audio/campfire.ogg", "battle": "res://assets/audio/crossing.ogg"}
const EFFECTS := {
    "hover": "res://assets/audio/hover.wav",
    "click": "res://assets/audio/click.wav",
    "pick": "res://assets/audio/pick.wav",
    "attack": "res://assets/audio/attack.wav",
    "defeat": "res://assets/audio/defeat.wav",
    "heal": "res://assets/audio/heal.wav",
    "commander_skill": "res://assets/audio/skill.wav",
    "victory": "res://assets/audio/victory.wav",
    "loss": "res://assets/audio/loss.wav"
}

var music_volume := 0.55
var effects_volume := 0.75
var reduced_motion := false
var show_hp_numbers := false
var _unlocked := false
var _context := "menu"
var _playing_context := ""
var _music := AudioStreamPlayer.new()
var _effects: Array[AudioStreamPlayer] = []
var _voice := 0
var _last_hover := 0
var _music_streams: Dictionary = {}
var _effect_streams: Dictionary = {}

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    load_settings()
    for key in MUSIC:
        _music_streams[key] = load(MUSIC[key])
    for key in EFFECTS:
        _effect_streams[key] = load(EFFECTS[key])
    add_child(_music)
    for index in range(5):
        var player := AudioStreamPlayer.new()
        add_child(player)
        _effects.append(player)
    get_tree().node_added.connect(_watch_button)

func _input(event: InputEvent) -> void:
    if (event is InputEventMouseButton and event.pressed) or (event is InputEventKey and event.pressed) or (event is InputEventScreenTouch and event.pressed):
        unlock()

func unlock() -> void:
    if _unlocked:
        return
    _unlocked = true
    set_context(_context)

func set_context(context: String) -> void:
    _context = context if MUSIC.has(context) else "menu"
    if not _unlocked or _playing_context == _context:
        return
    _playing_context = _context
    var stream := _music_streams[_context] as AudioStreamOggVorbis
    stream.loop = true
    _music.stream = stream
    _music.volume_db = linear_to_db(maxf(0.0001, music_volume)) - 8.0
    _music.play()

func play_effect(cue: String) -> void:
    if not _unlocked or effects_volume <= 0 or not EFFECTS.has(cue):
        return
    var player: AudioStreamPlayer = _effects[_voice % _effects.size()]
    _voice += 1
    player.stream = _effect_streams[cue]
    player.volume_db = linear_to_db(maxf(0.0001, effects_volume)) - (16.0 if cue == "hover" else 8.0)
    player.play()

func _watch_button(node: Node) -> void:
    if node is Button:
        node.pressed.connect(play_effect.bind("click"))
        node.mouse_entered.connect(_hover)

func _hover() -> void:
    var now := Time.get_ticks_msec()
    if now - _last_hover > 80:
        _last_hover = now
        play_effect("hover")

func set_music_volume(value: float) -> void:
    music_volume = clampf(value, 0.0, 1.0)
    _music.volume_db = linear_to_db(maxf(0.0001, music_volume)) - 8.0
    settings_changed.emit()

func set_effects_volume(value: float) -> void:
    effects_volume = clampf(value, 0.0, 1.0)
    for player in _effects:
        player.volume_db = linear_to_db(maxf(0.0001, effects_volume)) - 8.0
        if effects_volume <= 0:
            player.stop()
    settings_changed.emit()

func save_settings() -> void:
    var config := ConfigFile.new()
    for key in ["music_volume", "effects_volume", "reduced_motion", "show_hp_numbers"]:
        config.set_value("presentation", key, get(key))
    config.save(SETTINGS_PATH)

func load_settings() -> void:
    var config := ConfigFile.new()
    if config.load(SETTINGS_PATH) != OK:
        return
    music_volume = clampf(float(config.get_value("presentation", "music_volume", 0.55)), 0.0, 1.0)
    effects_volume = clampf(float(config.get_value("presentation", "effects_volume", 0.75)), 0.0, 1.0)
    reduced_motion = bool(config.get_value("presentation", "reduced_motion", false))
    show_hp_numbers = bool(config.get_value("presentation", "show_hp_numbers", false))

func stop_all() -> void:
    _music.stop()
    _playing_context = ""
    stop_effects()

func stop_effects() -> void:
    for player in _effects:
        player.stop()

func _exit_tree() -> void:
    stop_all()
    _music.stream = null
    for player in _effects:
        player.stream = null
    _music_streams.clear()
    _effect_streams.clear()
