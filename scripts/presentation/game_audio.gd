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
    "loss": "res://assets/audio/loss.wav",
    "arrow_release": "res://assets/audio/arrow_release.wav",
    "arrow_hit": "res://assets/audio/arrow_hit.wav",
    "fire_cast": "res://assets/audio/fire_cast.wav",
    "flame_breath": "res://assets/audio/flame_breath.wav",
    "water_cast": "res://assets/audio/water_cast.wav",
    "ice_cast": "res://assets/audio/ice_cast.wav",
    "seed_cast": "res://assets/audio/seed_cast.wav",
    "wood_hit": "res://assets/audio/wood_hit.wav",
    "claw": "res://assets/audio/claw.wav",
    "heavy_hit": "res://assets/audio/heavy_hit.wav",
    "magic_hit": "res://assets/audio/magic_hit.wav",
    "vine_pull": "res://assets/audio/vine_pull.wav",
    "meteor": "res://assets/audio/meteor.wav",
    "freeze": "res://assets/audio/freeze.wav",
    "plant_grow": "res://assets/audio/plant_grow.wav",
    "explosion": "res://assets/audio/explosion.wav",
    "healing_water": "res://assets/audio/healing_water.wav",
    "slime_bounce": "res://assets/audio/slime_bounce.wav",
    "slime_shot": "res://assets/audio/slime_shot.wav",
    "slime_splat": "res://assets/audio/slime_splat.wav",
    "slime_burst": "res://assets/audio/slime_burst.wav",
    "slime_rebirth": "res://assets/audio/slime_rebirth.wav",
    "ember_dash": "res://assets/audio/ember_dash.wav",
    "water_gush": "res://assets/audio/water_gush.wav",
    "earth_rumble": "res://assets/audio/earth_rumble.wav",
    "sticky_link": "res://assets/audio/sticky_link.wav",
    "body_fall": "res://assets/audio/body_fall.wav",
    "magic_dissolve": "res://assets/audio/magic_dissolve.wav",
    "slime_pop": "res://assets/audio/slime_pop.wav",
    "wood_fall": "res://assets/audio/wood_fall.wav"
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
    for index in range(12):
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

func play_effect(cue: String, priority: int = 0) -> void:
    if not _unlocked or effects_volume <= 0 or not EFFECTS.has(cue):
        return
    var player := _effect_voice(priority)
    if player == null:
        return
    _voice += 1
    player.stream = _effect_streams[cue]
    player.set_meta("priority", priority)
    player.set_meta("started", Time.get_ticks_msec())
    player.volume_db = linear_to_db(maxf(0.0001, effects_volume)) - (16.0 if cue == "hover" else (5.0 if priority >= 2 else 9.0))
    if priority >= 2:
        for other in _effects:
            if other != player and other.playing and int(other.get_meta("priority", 0)) < 2:
                other.volume_db = minf(other.volume_db, linear_to_db(maxf(0.0001, effects_volume)) - 13.0)
    player.play()

func _effect_voice(priority: int) -> AudioStreamPlayer:
    # Three voices stay available for important abilities; ordinary attacks or
    # menu sounds cannot interrupt a higher-priority cue already playing.
    var candidates: Array[AudioStreamPlayer] = []
    if priority >= 2:
        candidates.append_array(_effects.slice(9))
    candidates.append_array(_effects.slice(0, 9))
    var oldest: AudioStreamPlayer
    for player in candidates:
        if not player.playing:
            return player
        if int(player.get_meta("priority", 0)) > priority:
            continue
        if oldest == null or int(player.get_meta("started", 0)) < int(oldest.get_meta("started", 0)):
            oldest = player
    return oldest

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
    # Detach the decoder while the audio server can still drain playback.
    # Keeping it until _exit_tree can retain Ogg resources during shutdown.
    _music.stream = null
    _playing_context = ""
    stop_effects()

func stop_effects() -> void:
    for player in _effects:
        player.stop()
        player.stream = null

func _exit_tree() -> void:
    stop_all()
    _music_streams.clear()
    _effect_streams.clear()
