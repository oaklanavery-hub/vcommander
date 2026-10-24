class_name UnitUpgradeForge
extends RefCounted
## Presentation only. Prices, ownership, spending and guards belong to the profile/state.

static func open(menu, selected_id := "", notice := "", element_filter := "") -> void:
    var profile: CommanderProgress = GameState.commander_progress
    var cards := ContentDatabase.get_all_cards()
    if selected_id.is_empty():
        var theme := str(GameState.get_selected_commander().get("element", "fire"))
        for candidate in cards:
            if str(candidate.get("element", "")) == theme:
                selected_id = str(candidate["id"])
                break
    var card := ContentDatabase.get_card(selected_id)
    if card.is_empty():
        return
    if element_filter.is_empty():
        element_filter = str(card["element"])
    var definition: Dictionary = ContentDatabase.get_upgrade_rules()["units"][selected_id]
    var upgraded := UnitUpgrades.changed_card(card, definition)
    var cost := profile.upgrade_cost()
    var owned := profile.unit_level(selected_id) == 2
    menu._page("The unit forge", "Give your companions a new look and ability. Spending XP keeps your Commander mastery, levels and rewards.")
    menu._body.add_theme_constant_override("separation", 8)
    var wallet: Label = menu._paragraph("%d XP available  ·  %s upgrade %d XP" % [profile.upgrade_balance(), "First" if profile.upgraded_unit_ids().is_empty() else "Next", cost], 21)
    wallet.name = "UpgradeBalance"
    wallet.add_theme_color_override("font_color", Color("f2d58e"))
    var selectors := HBoxContainer.new()
    selectors.add_theme_constant_override("separation", 10)
    menu._body.add_child(selectors)
    var elements := OptionButton.new()
    elements.name = "ForgeElement"
    elements.custom_minimum_size = Vector2(150, 40)
    for element in ["all", "fire", "water", "earth", "slime"]:
        elements.add_item("All elements" if element == "all" else str(element).capitalize())
        elements.set_item_metadata(elements.item_count - 1, element)
        if element == element_filter:
            elements.select(elements.item_count - 1)
    elements.item_selected.connect(func(index: int):
        var value := str(elements.get_item_metadata(index))
        for candidate in cards:
            if value == "all" or candidate["element"] == value:
                menu.open_unit_upgrades(str(candidate["id"]), "", value)
                break)
    selectors.add_child(elements)
    var units := OptionButton.new()
    units.name = "ForgeUnit"
    units.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    units.custom_minimum_size.y = 40
    units.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    for candidate in cards:
        if element_filter != "all" and candidate["element"] != element_filter:
            continue
        var id := str(candidate["id"])
        var status := " · Lv. 2" if profile.unit_level(id) == 2 else (" · Locked" if not profile.is_card_unlocked(id) else "")
        units.add_item(str(candidate["display_name"]) + status)
        units.set_item_metadata(units.item_count - 1, id)
        if id == selected_id:
            units.select(units.item_count - 1)
    units.item_selected.connect(func(index: int): menu.open_unit_upgrades(str(units.get_item_metadata(index)), "", element_filter))
    selectors.add_child(units)
    var comparison := HBoxContainer.new()
    comparison.name = "UpgradeComparison"
    comparison.alignment = BoxContainer.ALIGNMENT_CENTER
    comparison.add_theme_constant_override("separation", 28)
    menu._body.add_child(comparison)
    for level in [1, 2]:
        var column := VBoxContainer.new()
        column.add_theme_constant_override("separation", 3)
        var label := ScreenStyle.label("Lv. 1" if level == 1 else ("Lv. 2 · Owned" if owned else "Lv. 2 · Preview"), 16)
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        column.add_child(label)
        var tile := CardTile.new()
        tile.name = "ForgeLevel%d" % level
        tile.set_content(card if level == 1 else upgraded)
        tile.custom_minimum_size = Vector2(168, 174)
        tile.focus_mode = Control.FOCUS_NONE
        tile.mouse_default_cursor_shape = Control.CURSOR_ARROW
        column.add_child(tile)
        comparison.add_child(column)
    menu._paragraph(str(definition["name"]), 21)
    menu._paragraph(str(definition["description"]), 16).name = "UpgradeDescription"
    var reason := "Applies to this unit type in your next adventure. Your rival receives the same upgraded collection."
    var blocked := false
    if owned:
        blocked = true
        reason = "This unit's Lv. 2 look and ability are unlocked permanently."
    elif not profile.is_card_unlocked(selected_id):
        blocked = true
        reason = "Unlock this companion first. " + profile.unlock_description(selected_id)
    elif GameState.has_pending_adventure() or OnlineSession.active:
        blocked = true
        reason = "Finish or retire your current adventure before buying upgrades. Its units keep the levels they started with."
    elif profile.read_only:
        blocked = true
        reason = profile.storage_notice()
    elif profile.upgrade_balance() < cost:
        blocked = true
        reason = "%d more XP needed. A completed win earns 100 XP; a completed loss earns 50 XP." % [cost - profile.upgrade_balance()]
    var purchase: Button = menu._button("Lv. 2 unlocked" if owned else "Upgrade to Lv. 2 · %d XP" % cost, func():
        var result := GameState.purchase_unit_upgrade(selected_id, cost)
        if result.get("ok", false):
            GameAudio.play_effect("skill")
        menu.open_unit_upgrades(selected_id, "%s upgraded to Lv. 2!" % card["display_name"] if result.get("ok", false) else str(result.get("reason", "Could not save the upgrade. Try again.")), element_filter), true)
    purchase.name = "Upgrade_" + selected_id
    purchase.disabled = blocked
    purchase.tooltip_text = reason
    menu._paragraph(notice if not notice.is_empty() else reason, 15).name = "UpgradeNotice"
    menu._button("Back to game", menu.close).name = "CloseForge"
    units.grab_focus()
