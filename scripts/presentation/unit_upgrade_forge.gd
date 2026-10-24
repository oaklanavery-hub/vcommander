class_name UnitUpgradeForge
extends Control
## Dedicated collection UI. The profile/state retain all purchase authority.

const SCENE_PATH := "res://scenes/progression/unit_forge.tscn"
const TITLE_SCENE := "res://scenes/main_menu/main_menu.tscn"
const BUILDER_SCENE := "res://scenes/army_builder/army_builder.tscn"
static var return_scene := TITLE_SCENE
static var initial_unit_id := ""

var selected_unit_id := ""
var element_filter := ""
var unit_buttons: Dictionary = {}
var margin: MarginContainer
var main: VBoxContainer
var summary: PanelContainer
var recipe: HBoxContainer
var original_tile: CardTile
var upgraded_tile: CardTile
var cost_label: Label
var cost_caption: Label
var discount_label: Label
var cost_column: VBoxContainer
var unit_heading: Label
var description_label: Label
var description_scroll: ScrollContainer
var purchase_button: Button
var notice_label: Label
var filter_select: OptionButton
var balance_label: Label
var collection_scroll: ScrollContainer
var cards_grid: GridContainer
var back_button: Button
var _quoted_cost := 0
var _notice := ""
var _purchasing := false

static func open(tree: SceneTree, source: String = TITLE_SCENE, unit_id := "") -> void:
    return_scene = source if source in [TITLE_SCENE, BUILDER_SCENE] else TITLE_SCENE
    initial_unit_id = unit_id
    tree.change_scene_to_file(SCENE_PATH)

func _ready() -> void:
    ScreenStyle.ensure_font_fallbacks()
    GameAudio.set_context("menu")
    var backdrop = load("res://scripts/presentation/pixel_backdrop.gd").new()
    add_child(backdrop)
    margin = MarginContainer.new()
    margin.name = "Margin"
    add_child(margin)
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    main = VBoxContainer.new()
    main.name = "Main"
    main.add_theme_constant_override("separation", 12)
    margin.add_child(main)
    _build_header()
    _build_summary()
    _build_collection()
    selected_unit_id = initial_unit_id
    if ContentDatabase.get_card(selected_unit_id).is_empty():
        var theme := str(GameState.get_selected_commander().get("element", ""))
        var cards := ContentDatabase.get_all_cards()
        selected_unit_id = str(cards[0]["id"])
        for card in cards:
            if card.get("element") == theme:
                selected_unit_id = str(card["id"])
                break
    GameState.collection_changed.connect(_refresh)
    GameAudio.settings_changed.connect(_fit_layout)
    resized.connect(_fit_layout)
    _refresh()
    _fit_layout.call_deferred()
    filter_select.grab_focus()

func _build_header() -> void:
    var header := HBoxContainer.new()
    header.name = "Header"
    header.add_theme_constant_override("separation", 16)
    main.add_child(header)
    var title := ScreenStyle.label("THE UNIT FORGE", 32)
    title.add_theme_color_override("font_color", Color("f3d59a"))
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(title)
    back_button = Button.new()
    back_button.name = "Back"
    back_button.text = "Back"
    back_button.custom_minimum_size = Vector2(112, 44)
    back_button.pressed.connect(go_back)
    header.add_child(back_button)

func _build_summary() -> void:
    summary = PanelContainer.new()
    summary.name = "ForgeWorkbench"
    summary.add_theme_stylebox_override("panel", ScreenStyle.frame(Color("302b23"), Color("a48855"), 16))
    main.add_child(summary)
    var row := HBoxContainer.new()
    row.name = "ComparisonAndDetails"
    row.add_theme_constant_override("separation", 24)
    summary.add_child(row)
    recipe = HBoxContainer.new()
    recipe.name = "UpgradeRecipe"
    recipe.alignment = BoxContainer.ALIGNMENT_CENTER
    recipe.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    recipe.add_theme_constant_override("separation", 10)
    row.add_child(recipe)
    original_tile = _preview_card("ForgeLevel1", "LEVEL 1")
    _operator("+")
    cost_column = VBoxContainer.new()
    cost_column.name = "UpgradeCost"
    cost_column.alignment = BoxContainer.ALIGNMENT_CENTER
    cost_column.add_theme_constant_override("separation", 7)
    recipe.add_child(cost_column)
    cost_caption = _center_label("UPGRADE COST", 13)
    cost_column.add_child(cost_caption)
    var price := PanelContainer.new()
    price.add_theme_stylebox_override("panel", ScreenStyle.frame(Color("24251e"), Color("aa925d"), 9))
    cost_column.add_child(price)
    cost_label = _center_label("", 28)
    cost_label.name = "UpgradePrice"
    cost_label.add_theme_color_override("font_color", Color("f2d58e"))
    price.add_child(cost_label)
    discount_label = _center_label("First upgrade bonus", 12)
    discount_label.name = "FirstUpgradeBonus"
    cost_column.add_child(discount_label)
    _operator("=")
    upgraded_tile = _preview_card("ForgeLevel2", "LEVEL 2")
    var details := VBoxContainer.new()
    details.name = "UnitDetails"
    details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    details.add_theme_constant_override("separation", 7)
    row.add_child(details)
    unit_heading = ScreenStyle.label("", 21)
    unit_heading.name = "UpgradeHeading"
    unit_heading.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    details.add_child(unit_heading)
    description_scroll = ScrollContainer.new()
    description_scroll.name = "DescriptionScroll"
    description_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    description_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    description_scroll.follow_focus = true
    details.add_child(description_scroll)
    description_label = ScreenStyle.label("", 16)
    description_label.name = "UpgradeDescription"
    description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    description_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    description_scroll.add_child(description_label)
    purchase_button = Button.new()
    purchase_button.custom_minimum_size.y = 44
    ScreenStyle.primary(purchase_button)
    purchase_button.pressed.connect(_purchase)
    details.add_child(purchase_button)
    notice_label = ScreenStyle.label("", 14)
    notice_label.name = "UpgradeNotice"
    notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    notice_label.max_lines_visible = 2
    notice_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    notice_label.custom_minimum_size.y = 40
    details.add_child(notice_label)

func _preview_card(node_name: String, heading: String) -> CardTile:
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 4)
    column.add_child(_center_label(heading, 14))
    var tile := CardTile.new()
    tile.name = node_name
    tile.set_content(ContentDatabase.get_all_cards()[0])
    tile.custom_minimum_size = Vector2(144, 184)
    tile.focus_mode = Control.FOCUS_NONE
    tile.mouse_default_cursor_shape = Control.CURSOR_ARROW
    column.add_child(tile)
    recipe.add_child(column)
    return tile

func _operator(symbol: String) -> void:
    var label := _center_label(symbol, 40)
    label.custom_minimum_size.x = 28
    label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    label.add_theme_color_override("font_color", Color("d4b879"))
    recipe.add_child(label)

func _center_label(value: String, font_size: int) -> Label:
    var label := ScreenStyle.label(value, font_size)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    return label

func _build_collection() -> void:
    var controls := HBoxContainer.new()
    controls.name = "CollectionControls"
    controls.add_theme_constant_override("separation", 16)
    main.add_child(controls)
    filter_select = OptionButton.new()
    filter_select.name = "ForgeElement"
    filter_select.custom_minimum_size = Vector2(230, 40)
    filter_select.add_item("All Commanders")
    filter_select.set_item_metadata(0, "")
    for commander in ContentDatabase.get_all_commanders():
        filter_select.add_item(str(commander["display_name"]))
        filter_select.set_item_metadata(filter_select.item_count - 1, commander["element"])
    filter_select.item_selected.connect(_filter_selected)
    controls.add_child(filter_select)
    balance_label = ScreenStyle.label("", 21)
    balance_label.name = "UpgradeBalance"
    balance_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    balance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    balance_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    balance_label.add_theme_color_override("font_color", Color("f2d58e"))
    balance_label.add_theme_color_override("font_outline_color", Color("16170f"))
    balance_label.add_theme_constant_override("outline_size", 4)
    controls.add_child(balance_label)
    var divider := HSeparator.new()
    divider.name = "CollectionDivider"
    main.add_child(divider)
    collection_scroll = ScrollContainer.new()
    collection_scroll.name = "ForgeCollection"
    collection_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    collection_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    collection_scroll.follow_focus = true
    main.add_child(collection_scroll)
    cards_grid = GridContainer.new()
    cards_grid.name = "UnitCards"
    cards_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    cards_grid.add_theme_constant_override("h_separation", 10)
    cards_grid.add_theme_constant_override("v_separation", 14)
    collection_scroll.add_child(cards_grid)
    for card in ContentDatabase.get_all_cards():
        var id := str(card["id"])
        var tile := CardTile.new()
        tile.name = id
        tile.set_content(card)
        tile.custom_minimum_size = Vector2(132, 180)
        tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        tile.toggle_mode = true
        tile.pressed.connect(select_unit.bind(id))
        unit_buttons[id] = tile
        cards_grid.add_child(tile)
    collection_scroll.resized.connect(_fit_columns)

func _fit_layout() -> void:
    if not is_instance_valid(margin):
        return
    var compact := size.x < 1120 or size.y < 640
    for side in ["left", "right", "top", "bottom"]:
        margin.add_theme_constant_override("margin_" + side, 16 if compact else 24)
    original_tile.custom_minimum_size = Vector2(112, 148) if compact else Vector2(144, 184)
    upgraded_tile.custom_minimum_size = original_tile.custom_minimum_size
    cost_column.custom_minimum_size.x = 136 if compact else 150
    recipe.add_theme_constant_override("separation", 7 if compact else 10)
    description_scroll.custom_minimum_size.y = 64 if compact else 88
    _fit_columns.call_deferred()

func _fit_columns() -> void:
    if is_instance_valid(cards_grid):
        # Base columns on the viewport, not a grid-expanded scroll minimum.
        var available := size.x - margin.get_theme_constant("margin_left") - margin.get_theme_constant("margin_right") - 18
        cards_grid.columns = clampi(int((available + 10) / 142), 1, 8)

func _filter_selected(index: int) -> void:
    element_filter = str(filter_select.get_item_metadata(index))
    _notice = ""
    var current := ContentDatabase.get_card(selected_unit_id)
    if not element_filter.is_empty() and current.get("element") != element_filter:
        for card in ContentDatabase.get_all_cards():
            if card.get("element") == element_filter:
                selected_unit_id = str(card["id"])
                break
    collection_scroll.scroll_vertical = 0
    _refresh()

func select_unit(id: String) -> void:
    if not unit_buttons.has(id):
        return
    selected_unit_id = id
    _notice = ""
    description_scroll.scroll_vertical = 0
    _refresh()

func _refresh() -> void:
    var profile: CommanderProgress = GameState.commander_progress
    balance_label.text = "AVAILABLE XP: %d" % profile.upgrade_balance()
    balance_label.tooltip_text = "Shared XP earned across Commanders. Spending keeps lifetime mastery, levels, records and rewards."
    for id in unit_buttons:
        var card := ContentDatabase.get_card(str(id))
        var tile: CardTile = unit_buttons[id]
        tile.locked = not profile.is_card_unlocked(str(id))
        if profile.unit_level(str(id)) == 2:
            card = UnitUpgrades.changed_card(card, ContentDatabase.get_upgrade_rules()["units"][id])
        tile.set_content(card)
        tile.visible = element_filter.is_empty() or card.get("element") == element_filter
        tile.set_pressed_no_signal(id == selected_unit_id)
        if tile.locked:
            tile.tooltip_text += "\n\n" + profile.unlock_description(str(id))
        tile.queue_redraw()
    var base := ContentDatabase.get_card(selected_unit_id)
    var upgrade: Dictionary = ContentDatabase.get_upgrade_rules()["units"][selected_unit_id]
    var owned := profile.unit_level(selected_unit_id) == 2
    original_tile.set_content(base)
    upgraded_tile.set_content(UnitUpgrades.changed_card(base, upgrade))
    ScreenStyle.card(original_tile, str(base["element"]))
    ScreenStyle.card(upgraded_tile, str(base["element"]))
    unit_heading.text = str(base["display_name"]) + " · " + str(upgrade["name"])
    unit_heading.tooltip_text = unit_heading.text
    description_label.text = str(upgrade["description"])
    _quoted_cost = profile.upgrade_cost()
    cost_caption.text = "UPGRADE OWNED" if owned else "UPGRADE COST"
    cost_label.text = "Owned" if owned else "%d XP" % _quoted_cost
    discount_label.visible = not owned and profile.upgraded_unit_ids().is_empty()
    purchase_button.name = "Upgrade_" + selected_unit_id
    purchase_button.text = "Lv. 2 unlocked" if owned else "Upgrade unit · %d XP" % _quoted_cost
    var reason := "Applies next adventure. Your rival receives the same upgraded collection."
    var blocked := false
    if owned:
        blocked = true
        reason = "This unit's Lv. 2 look and ability are unlocked permanently."
    elif not profile.is_card_unlocked(selected_unit_id):
        blocked = true
        reason = "Unlock this companion first. " + profile.unlock_description(selected_unit_id)
    elif GameState.has_pending_adventure() or OnlineSession.active:
        blocked = true
        reason = "Finish or retire your current adventure before buying upgrades. Its starting unit levels are preserved."
    elif profile.read_only:
        blocked = true
        reason = profile.storage_notice()
    elif profile.upgrade_balance() < _quoted_cost:
        blocked = true
        var rewards: Dictionary = ContentDatabase.get_mastery_rules()["match_xp"]
        reason = "%d more XP needed. Win +%d XP; completed loss +%d XP." % [_quoted_cost - profile.upgrade_balance(), rewards["win"], rewards["loss"]]
    purchase_button.disabled = blocked or _purchasing
    purchase_button.tooltip_text = reason
    notice_label.text = _notice if not _notice.is_empty() else reason
    notice_label.tooltip_text = notice_label.text
    notice_label.add_theme_color_override("font_color", Color("efd38e") if not _notice.is_empty() else Color("c9c7ad"))

func _purchase() -> void:
    if _purchasing:
        return
    _purchasing = true
    purchase_button.disabled = true
    var result := GameState.purchase_unit_upgrade(selected_unit_id, _quoted_cost)
    _purchasing = false
    if result.get("ok", false):
        GameAudio.play_effect("skill")
        _notice = "%s upgraded to Lv. 2!" % ContentDatabase.get_card(selected_unit_id)["display_name"]
    else:
        _notice = str(result.get("reason", "Could not save the upgrade. Try again."))
    _refresh()

func go_back() -> void:
    get_tree().change_scene_to_file(return_scene)

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
        get_viewport().set_input_as_handled()
        go_back()
