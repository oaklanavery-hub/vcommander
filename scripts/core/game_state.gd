extends Node

const ArmyLoadoutScript = preload("res://scripts/army/army_loadout.gd")
const SetBonusCheckerScript = preload("res://scripts/commanders/set_bonus_checker.gd")
const DraftSystemScript = preload("res://scripts/draft/draft_system.gd")

var selected_commander_id := ""
var army = ArmyLoadoutScript.new(4)
var draft = DraftSystemScript.new()
var match_seed := 0
var match_started := false

func select_commander(commander_id: String) -> bool:
    if ContentDatabase.get_commander(commander_id).is_empty():
        return false
    if selected_commander_id != commander_id:
        army.clear()
        match_started = false
    selected_commander_id = commander_id
    return true

func get_selected_commander() -> Dictionary:
    return ContentDatabase.get_commander(selected_commander_id)

func get_selected_signature_set() -> Dictionary:
    var commander := get_selected_commander()
    if commander.is_empty():
        return {}
    return ContentDatabase.get_signature_set(str(commander.get("signature_set_id", "")))

func equip_card(card_id: String) -> bool:
    if ContentDatabase.get_card(card_id).is_empty():
        return false
    match_started = false
    return army.equip(card_id)

func unequip_card_at(index: int) -> bool:
    match_started = false
    return army.unequip_at(index)

func clear_army() -> void:
    match_started = false
    army.clear()

func get_signature_progress() -> int:
    var signature_set := get_selected_signature_set()
    if signature_set.is_empty():
        return 0
    return SetBonusCheckerScript.progress(
        ContentDatabase.get_cards_by_ids(army.get_cards()),
        str(signature_set.get("id", ""))
    )

func get_signature_required_count() -> int:
    var signature_set := get_selected_signature_set()
    return int(signature_set.get("required_count", 4)) if not signature_set.is_empty() else 4

func is_full_set_active() -> bool:
    var signature_set := get_selected_signature_set()
    if signature_set.is_empty():
        return false
    return SetBonusCheckerScript.is_complete(
        ContentDatabase.get_cards_by_ids(army.get_cards()),
        str(signature_set.get("id", "")),
        int(signature_set.get("required_count", 4))
    )

func begin_match(seed_value: int) -> bool:
    if selected_commander_id.is_empty() or not army.is_full():
        return false
    match_seed = seed_value
    draft.configure(
        army.get_cards(),
        ContentDatabase.get_cards_by_ids(army.get_cards()),
        ContentDatabase.get_all_buffs(),
        match_seed
    )
    draft.begin_round(true, false, false)
    match_started = true
    return true
