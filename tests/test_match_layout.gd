extends SceneTree
var failed := false

func _init() -> void:
    call_deferred("run")

func settle() -> void:
    for index in range(4):
        await process_frame

func check(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("TEST FAILED: " + message)

func inside(child: Control, parent: Control) -> bool:
    return parent.get_global_rect().grow(1).encloses(child.get_global_rect())

func run() -> void:
    root.size = Vector2i(1280, 720)
    var state := root.get_node("GameState")
    var db := root.get_node("ContentDatabase")
    state.commander_progress = CommanderProgress.new(db, "")
    state.select_commander("commander_slime_01")
    state.equip_starter_army()
    check(state.begin_match(281), "layout fixture starts a normal seeded match")
    var hidden_before := JSON.stringify(state.opponent_public_side)
    change_scene_to_file("res://scenes/draft/draft.tscn")
    await scene_changed
    current_scene.set_process(false)
    await settle()
    var draft = current_scene
    var arena: Control = draft.get_node("Margin/Main/Board/Padding/Arena")
    var panel: Control = arena.get_node("DraftCenter/OfferPanel")
    var draft_top: Rect2 = draft._hearts_meter.get_global_rect()
    var roster_x: float = draft.player_roster.get_global_rect().position.x
    check(inside(panel, arena) and inside(draft.offer_row, panel), "centered draft window and all three offers fit between the rosters")
    check(draft.offer_row.get_child_count() == 3, "three legal draft choices remain available")
    check(draft.player_roster.get_global_rect().end.x <= arena.get_global_rect().position.x and arena.get_global_rect().end.x <= draft.opponent_roster.get_global_rect().position.x, "roster rails never cover draft ground")
    check(not draft._hearts_meter.health_available and draft.opponent_roster.hidden_picks, "draft HUD cannot expose health or new opposing picks")
    var card_id := str(state.draft.current_offer[0]["id"])
    draft._select_offer(0)
    await settle()
    check(draft.player_roster.highlighted_card == card_id and draft.player_roster.config["unit_counts"][card_id] == state.draft.get_unit_count(card_id), "recruit updates and highlights its persistent roster entry")
    check(JSON.stringify(state.opponent_public_side) == hidden_before and draft.opponent_roster.config == state.opponent_public_side, "player picks leave the rival public snapshot unchanged")
    while not state.draft.is_phase_complete():
        draft._select_offer(0)
    await settle()
    check(draft.battle_button.visible and inside(panel, arena), "ready state retains a centered, reachable battle button")
    check(state.run_battle(), "drafted fixture resolves through the ordinary simulator")
    var result_before := JSON.stringify(state.battle_result)
    change_scene_to_file("res://scenes/combat/combat.tscn")
    await scene_changed
    current_scene.set_process(false)
    await settle()
    var battle = current_scene
    check(battle._hearts_meter.get_global_rect() == draft_top and battle.player_roster.get_global_rect().position.x == roster_x, "round/lives strip and roster positions stay consistent between phases")
    check(battle.battlefield.external_rosters and battle.player_roster.get_global_rect().end.x <= battle.battlefield.get_global_rect().position.x and battle.battlefield.get_global_rect().end.x <= battle.opponent_roster.get_global_rect().position.x, "both battle rosters remain outside the playable field")
    check(battle._hearts_meter.health_available and not battle.report_button.visible and battle._speed_index == 0, "battle begins with current health, hidden report and normal speed")
    battle._advance_prelude(BattlePrelude.DURATION)
    battle._playback_time = minf(3, battle._duration * 0.5)
    battle._advance_frames()
    var totals := {"player": 0.0, "opponent": 0.0}
    for unit in battle.battlefield.visible_units():
        totals[str(unit["side"])] += maxf(0, float(unit["hp"]))
    check(battle._hearts_meter.army_health == totals, "army bar totals only currently displayed living HP, including descendants/summons")
    battle._inspect_unit(battle.battlefield.visible_units()[0])
    await settle()
    check(battle.inspector.visible and battle.battlefield.get_global_rect().end.x <= battle.inspector.get_global_rect().position.x, "inspection reserves space beside the entire arena")
    check(inside(battle.inspector, battle.get_node("Margin/Main")), "inspector remains inside the desktop screen")
    battle._close_inspection()
    battle._process(battle._duration + battle._tail_length + 1)
    await settle()
    check(battle.next_button.visible and battle.report_button.visible and battle._hearts_meter.displayed_losses == state.match_state.losses, "full playback reveals the result controls and correct remaining hearts")
    check(root.get_visible_rect().grow(1).encloses(battle.get_node("Margin/Main").get_global_rect()), "battle result fits the desktop viewport")
    check(JSON.stringify(state.battle_result) == result_before, "layout, health and inspection never rewrite combat evidence")
    check(state.begin_next_round(), "next draft retains normal match progression")
    for buff in db.get_all_buffs():
        state.draft.buff_stacks[str(buff["id"])] = 17
        state.opponent.draft.buff_stacks[str(buff["id"])] = 19
    state.opponent_public_side = state.opponent.get_side()
    change_scene_to_file("res://scenes/draft/draft.tscn")
    await scene_changed
    current_scene.set_process(false)
    await settle()
    draft = current_scene
    check(draft.player_roster.buffs.text.count("×17") == 5 and draft.opponent_roster.buffs.text.count("×19") == 5, "both rosters retain every unlimited power stack")
    check(draft.player_roster.summary.text.contains("death spawns") and draft.opponent_roster.summary.text.contains("Skill uses"), "theme effect and skill budget stay visible beside the draft")
    check(draft.player_roster.buffs.get_content_height() <= draft.player_roster.buffs.size.y + 1, "all five player power rows have readable room")
    check(inside(draft.player_roster.buffs, draft.player_roster) and inside(draft.opponent_roster.buffs, draft.opponent_roster), "all five power stacks fit in both desktop roster panels without scrolling")
    check(not draft.player_roster.scroll.get_v_scroll_bar().visible and not draft.opponent_roster.scroll.get_v_scroll_bar().visible, "desktop draft rosters fit their complete contents without a scrollbar")
    state.leave_match()
    if not failed:
        print("Match layout tests passed: persistent two-phase geometry, legal draft/ready, hidden rival picks, roster highlights, current HP only, unobstructed inspection, full result and all power stacks.")
    quit(1 if failed else 0)
