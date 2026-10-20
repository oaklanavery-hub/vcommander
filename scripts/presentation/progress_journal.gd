class_name ProgressJournal
extends Control

static var return_scene := "res://scenes/main_menu/main_menu.tscn"
static var initial_commander := ""
var filter := ""
var tab := 0
var grid: GridContainer
var scroll: ScrollContainer
var summary_label: Label
var filter_select: OptionButton
var tab_buttons: Array[Button] = []
var displayed_ids: Array[String] = []

static func open(tree: SceneTree, source: String, commander: String = "") -> void:
    return_scene = source
    initial_commander = commander
    tree.change_scene_to_file("res://scenes/progression/progress_journal.tscn")

func _ready() -> void:
    filter = initial_commander
    var margin := MarginContainer.new()
    margin.name = "Margin"
    add_child(margin)
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.offset_left = 24
    margin.offset_top = 24
    margin.offset_right = -24
    margin.offset_bottom = -24
    var main := VBoxContainer.new()
    main.name = "Main"
    main.add_theme_constant_override("separation", 12)
    margin.add_child(main)
    var header := HBoxContainer.new()
    header.name = "Header"
    header.add_theme_constant_override("separation", 16)
    main.add_child(header)
    var back := Button.new()
    back.name = "Back"
    back.text = "← Back"
    back.custom_minimum_size = Vector2(100, 44)
    back.pressed.connect(func(): get_tree().change_scene_to_file(return_scene))
    header.add_child(back)
    var title := ScreenStyle.label("ACHIEVEMENTS & REWARDS", 30)
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(title)
    var hero := PanelContainer.new()
    hero.add_theme_stylebox_override("panel", ScreenStyle.frame(Color("192e2a"), Color("8e8057"), 12))
    main.add_child(hero)
    var hero_body := VBoxContainer.new()
    hero_body.add_theme_constant_override("separation", 4)
    hero.add_child(hero_body)
    summary_label = ScreenStyle.label("", 22)
    summary_label.add_theme_color_override("font_color", Color("f3d99e"))
    hero_body.add_child(summary_label)
    hero_body.add_child(_text("Every Commander has a story. Earn new companions as yours grows.", 16))
    var navigation := HBoxContainer.new()
    navigation.add_theme_constant_override("separation", 10)
    main.add_child(navigation)
    for index in range(2):
        var button := Button.new()
        button.text = ["Mastery rewards", "Achievements"][index]
        button.custom_minimum_size = Vector2(190, 42)
        button.toggle_mode = true
        button.pressed.connect(_select_tab.bind(index))
        navigation.add_child(button)
        tab_buttons.append(button)
    var gap := Control.new()
    gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    navigation.add_child(gap)
    filter_select = OptionButton.new()
    filter_select.name = "CommanderFilter"
    filter_select.custom_minimum_size.x = 230
    filter_select.add_item("All Commanders")
    filter_select.set_item_metadata(0, "")
    for commander in ContentDatabase.get_all_commanders():
        filter_select.add_item(str(commander["display_name"]))
        var index := filter_select.item_count - 1
        filter_select.set_item_metadata(index, commander["id"])
        if filter == commander["id"]:
            filter_select.select(index)
    filter_select.item_selected.connect(_select_filter)
    navigation.add_child(filter_select)
    scroll = ScrollContainer.new()
    scroll.name = "JournalScroll"
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.follow_focus = true
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    main.add_child(scroll)
    grid = GridContainer.new()
    grid.name = "Entries"
    grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    grid.add_theme_constant_override("h_separation", 12)
    grid.add_theme_constant_override("v_separation", 12)
    scroll.add_child(grid)
    var notice := _text(GameState.commander_progress.storage_notice(), 12)
    notice.add_theme_color_override("font_color", Color("a4b8ab"))
    main.add_child(notice)
    ScreenStyle.apply(self)
    _render()
    back.grab_focus()

func _select_tab(index: int) -> void:
    tab = index
    scroll.scroll_vertical = 0
    _render()

func _select_filter(index: int) -> void:
    filter = str(filter_select.get_item_metadata(index))
    scroll.scroll_vertical = 0
    _render()

func _render() -> void:
    for child in grid.get_children():
        grid.remove_child(child)
        child.queue_free()
    displayed_ids.clear()
    var profile: CommanderProgress = GameState.commander_progress
    var entries := profile.achievement_entries()
    var earned := 0
    var unlocked := 0
    var rewards := 0
    for entry in entries:
        if entry["earned"]:
            earned += 1
    for card in ContentDatabase.get_all_cards():
        if card.has("mastery_unlock"):
            rewards += 1
            if profile.is_card_unlocked(str(card["id"])):
                unlocked += 1
    summary_label.text = "%d / %d achievements earned   ·   %d / %d companions unlocked" % [earned, entries.size(), unlocked, rewards]
    for index in range(tab_buttons.size()):
        tab_buttons[index].set_pressed_no_signal(index == tab)
    grid.columns = 2 if tab == 0 else 3
    if tab == 0:
        for card in ContentDatabase.get_all_cards():
            var reward := profile.card_reward(str(card["id"]))
            if not reward.is_empty() and (filter.is_empty() or filter == reward["commander_id"]):
                _reward_card(card, reward)
    else:
        for entry in entries:
            if filter.is_empty() or str(entry.get("commander_id", "")).is_empty() or filter == entry.get("commander_id"):
                _achievement_card(entry)

func _panel(earned: bool) -> VBoxContainer:
    var panel := PanelContainer.new()
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    panel.add_theme_stylebox_override("panel", ScreenStyle.frame(Color("213d32") if earned else Color("1b2b2b"), Color("b4a168") if earned else Color("57685d"), 12))
    grid.add_child(panel)
    var body := VBoxContainer.new()
    body.add_theme_constant_override("separation", 7)
    panel.add_child(body)
    return body

func _reward_card(card: Dictionary, reward: Dictionary) -> void:
    displayed_ids.append(str(card["id"]))
    var body := _panel(reward["unlocked"])
    body.custom_minimum_size.y = 180
    var commander := ContentDatabase.get_commander(str(reward["commander_id"]))
    var eyebrow := _text(str(commander["display_name"]).to_upper() + ("  ·  UNLOCKED" if reward["unlocked"] else "  ·  MASTERY REWARD"), 12)
    eyebrow.add_theme_color_override("font_color", Color("e0c18a"))
    body.add_child(eyebrow)
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 14)
    row.size_flags_vertical = Control.SIZE_EXPAND_FILL
    body.add_child(row)
    var portrait := CardPortrait.new()
    portrait.custom_minimum_size = Vector2(122, 122)
    portrait.set_content(card, false)
    row.add_child(portrait)
    var details := VBoxContainer.new()
    details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    details.add_theme_constant_override("separation", 5)
    row.add_child(details)
    details.add_child(_text(str(card["display_name"]), 24))
    details.add_child(_text("%s  ·  Recruit %d / Max %d" % [str(card["role"]).capitalize(), int(card["summon_amount"]), int(card["unit_cap"])], 13))
    details.add_child(_text(str(card.get("ability", {}).get("description", "")), 14))
    var progress := "Available in your collection. Choose it while building a warband." if reward["unlocked"] else "Level %d / %d   ·   Wins %d / %d" % [mini(int(reward["level"]), int(reward["required_level"])), int(reward["required_level"]), mini(int(reward["wins"]), int(reward["required_wins"])), int(reward["required_wins"])]
    body.add_child(_text(progress, 14))
    var stats: Dictionary = GameState.commander_progress.record(str(reward["commander_id"]))
    var required_xp := (int(reward["required_level"]) - 1) * int(stats["xp_per_level"])
    var value := 1.0 if reward["unlocked"] else 0.5 * (minf(1.0, float(stats["xp"]) / maxi(1, required_xp)) + minf(1.0, float(reward["wins"]) / int(reward["required_wins"])))
    body.add_child(_bar(value))

func _achievement_card(entry: Dictionary) -> void:
    displayed_ids.append(str(entry["id"]))
    var body := _panel(entry["earned"])
    body.custom_minimum_size.y = 145
    var eyebrow := _text("★  EARNED" if entry["earned"] else "◇  IN PROGRESS", 12)
    eyebrow.add_theme_color_override("font_color", Color("e8c77f") if entry["earned"] else Color("a5baaa"))
    body.add_child(eyebrow)
    body.add_child(_text(str(entry["display_name"]), 21))
    var detail := _text(str(entry["description"]), 14)
    detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
    body.add_child(detail)
    var progress: Array[String] = []
    var value := 0.0
    for condition in entry["progress"]:
        var amount := mini(int(condition["value"]), int(condition["target"]))
        progress.append("%s %d / %d" % [str(condition["metric"]).replace("_", " ").capitalize(), amount, int(condition["target"])])
        value += float(amount) / int(condition["target"])
    body.add_child(_text("Completed" if entry["earned"] else "  ·  ".join(progress), 12))
    body.add_child(_bar(1.0 if entry["earned"] else value / maxi(1, entry["progress"].size())))

func _text(value: String, font_size: int) -> Label:
    var label := ScreenStyle.label(value, font_size)
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    return label

func _bar(value: float) -> ProgressBar:
    var bar := ProgressBar.new()
    bar.custom_minimum_size.y = 8
    bar.show_percentage = false
    bar.max_value = 1
    bar.value = value
    var fill := ScreenStyle.frame(Color("d6bd79"), Color.TRANSPARENT, 4)
    fill.set_border_width_all(0)
    fill.set_content_margin_all(0)
    var track := ScreenStyle.frame(Color("0d1c1b"), Color.TRANSPARENT, 4)
    track.set_content_margin_all(0)
    bar.add_theme_stylebox_override("background", track)
    bar.add_theme_stylebox_override("fill", fill)
    return bar
