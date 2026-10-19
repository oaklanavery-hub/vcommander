class_name CommanderMasteryPanel
extends PanelContainer

var title_label := Label.new()
var level_label := Label.new()
var record_label := Label.new()
var progress_bar := ProgressBar.new()
var xp_label := Label.new()
var notice_label := Label.new()
var _reward: Dictionary = {}
var _elapsed := 0.0
var _record_mode := true
var _profile: CommanderProgress
var _content: Object
var _audio: Object

func configure(profile: CommanderProgress, content: Object, audio: Object) -> void:
    _profile = profile
    _content = content
    _audio = audio

func _init() -> void:
    add_theme_stylebox_override("panel", ScreenStyle.frame(Color("152e29"), Color("897b50"), 9))
    var body := VBoxContainer.new()
    body.add_theme_constant_override("separation", 5)
    add_child(body)
    var header := HBoxContainer.new()
    header.add_theme_constant_override("separation", 8)
    body.add_child(header)
    title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    title_label.add_theme_color_override("font_color", Color("e6cc91"))
    title_label.add_theme_font_size_override("font_size", 13)
    header.add_child(title_label)
    level_label.add_theme_font_size_override("font_size", 18)
    level_label.add_theme_color_override("font_color", Color("f1d99e"))
    header.add_child(level_label)
    record_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    record_label.add_theme_font_size_override("font_size", 14)
    body.add_child(record_label)
    progress_bar.show_percentage = false
    progress_bar.custom_minimum_size.y = 9
    var track := ScreenStyle.frame(Color("0e201d"), Color("43554b"), 4)
    track.set_border_width_all(1)
    track.set_content_margin_all(0)
    var fill := ScreenStyle.frame(Color("dfbd78"), Color.TRANSPARENT, 4)
    fill.set_border_width_all(0)
    fill.set_content_margin_all(0)
    progress_bar.add_theme_stylebox_override("background", track)
    progress_bar.add_theme_stylebox_override("fill", fill)
    body.add_child(progress_bar)
    xp_label.add_theme_font_size_override("font_size", 12)
    xp_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    body.add_child(xp_label)
    notice_label.add_theme_font_size_override("font_size", 11)
    notice_label.add_theme_color_override("font_color", Color("a8bcae"))
    notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    body.add_child(notice_label)
    set_process(false)

func _ready() -> void:
    set_process(false)

func show_record(commander_id: String) -> void:
    _record_mode = true
    _reward.clear()
    set_process(false)
    title_label.text = "COMMANDER MASTERY"
    var stats: Dictionary = _profile.record(commander_id)
    _show_stats(stats)
    _show_progress(int(stats["xp"]))
    xp_label.text += "\nPermanent levels · Win +100 / Loss +25 XP"
    notice_label.text = _profile.storage_notice()
    show()

func show_reward(receipt: Dictionary) -> void:
    if receipt.is_empty():
        hide()
        return
    _record_mode = false
    _reward = receipt.duplicate(true)
    _elapsed = 0
    var commander: Dictionary = _content.get_commander(str(receipt["commander_id"]))
    title_label.text = str(commander.get("display_name", "Commander")) + " · MASTERY"
    title_label.add_theme_font_size_override("font_size", 16)
    _show_stats(receipt["after"])
    notice_label.text = _profile.storage_notice()
    _show_progress(int(receipt["before"]["xp"]))
    show()
    set_process(true)
    if _audio.reduced_motion:
        finish_animation()

func _show_stats(stats: Dictionary) -> void:
    var rate := "%0.0f%% win rate" % float(stats["win_rate"]) if int(stats["played"]) > 0 else "Win rate —"
    record_label.text = "%d matches · %dW / %dL" % [int(stats["played"]), int(stats["wins"]), int(stats["losses"])]
    record_label.text += ("\n" if _record_mode else " · ") + rate
    if int(stats["forfeits"]) > 0:
        record_label.text += " · %d forfeits" % int(stats["forfeits"])

func _show_progress(xp: int) -> void:
    var progress: Dictionary = _profile.progress_at(xp)
    progress_bar.max_value = int(progress["xp_per_level"])
    progress_bar.value = int(progress["xp_in_level"])
    level_label.text = "Lv. %d" % int(progress["level"])
    if not _record_mode:
        level_label.text = "+%d XP · " % int(_reward["xp_awarded"]) + level_label.text
    xp_label.text = "%d / %d XP toward Level %d" % [int(progress["xp_in_level"]), int(progress["xp_per_level"]), int(progress["level"]) + 1]
    if not _record_mode and int(progress["level"]) > int(_reward["before"]["level"]):
        xp_label.text = "Level up!  " + xp_label.text

func _process(delta: float) -> void:
    if _reward.is_empty() or _record_mode:
        set_process(false)
        return
    if _audio.reduced_motion:
        finish_animation()
        return
    _elapsed = minf(0.9, _elapsed + delta)
    var blend := smoothstep(0, 1, _elapsed / 0.9)
    _show_progress(int(round(lerpf(float(_reward["before"]["xp"]), float(_reward["after"]["xp"]), blend))))
    if _elapsed >= 0.9:
        finish_animation()

func finish_animation() -> void:
    if not _reward.is_empty():
        _show_progress(int(_reward["after"]["xp"]))
    set_process(false)
