extends "res://tools/capture_battle_fx.gd"

class DeathStudy extends Control:
    var examples: Array[Dictionary] = []
    var reduced := false
    var display_font: Font
    func _ready() -> void:
        display_font = load("res://scripts/presentation/screen_style.gd").DISPLAY_FONT
        mouse_filter = Control.MOUSE_FILTER_IGNORE
        set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        var seen := {}
        for card in get_node("/root/ContentDatabase").get_all_cards():
            var motion := str(CombatCues.profile(str(card["id"]))["death_motion"])
            if not seen.has(motion):
                seen[motion] = true
                examples.append(card)
    func _draw() -> void:
        draw_rect(Rect2(Vector2.ZERO, size), Color("252f25"))
        draw_string(display_font, Vector2(60, 65), "Companion motion · " + ("Reduced motion" if reduced else "Death phases"), HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color("ecd39f"))
        for column in range(examples.size()):
            var card: Dictionary = examples[column]
            var motion := str(CombatCues.profile(str(card["id"]))["death_motion"])
            var x := 190.0 + column * 295
            draw_string(display_font, Vector2(x - 80, 125), motion.capitalize(), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("f5e3bd"))
            for row in range(3):
                var age: float = [0.0, 0.14, 0.33][row]
                var point := Vector2(x, 260 + row * 175)
                var actor := {"card_id": card["id"], "side": "player"}
                var pose := UnitDeathMotion.pose(actor, age, reduced)
                draw_line(point + Vector2(-90, 5), point + Vector2(90, 5), Color("70684b"), 1)
                PixelUnitArt.draw_unit(self, point, str(card["role"]), str(card["element"]), 5.0, false, 0, str(card["id"]), pose)
                UnitDeathMotion.draw_particles(self, point, actor, age, reduced)
                draw_string(ThemeDB.fallback_font, point + Vector2(-30, 30), "%.2fs" % age, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("c6c7b5"))

func run() -> void:
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with("--output-dir="):
            output_dir = argument.trim_prefix("--output-dir=")
    if not output_dir.is_absolute_path():
        output_dir = ProjectSettings.globalize_path("res://" + output_dir)
    DirAccess.make_dir_recursive_absolute(output_dir)
    root.size = Vector2i(1280, 720)
    var scene = await prepare("water", true)
    scene._advance_prelude(BattlePrelude.DURATION)
    seek(scene, 3.5)
    var bodies: Array[Dictionary] = scene.battlefield.visible_units()
    scene._inspect_unit(bodies[0])
    await save_image("learning_inspection")
    scene._close_inspection()
    scene._process(scene._duration + scene._tail_length + 1)
    scene._open_report()
    await save_image("learning_report_player")
    scene.report_view._select_side("opponent")
    await save_image("learning_report_rival")
    root.size = Vector2i(1024, 640)
    await save_image("learning_report_compact")
    root.size = Vector2i(1280, 720)
    var large: Dictionary = scene._report.duplicate(true)
    large["sides"]["player"]["rows"][0]["damage"] = 1e100
    large["sides"]["player"]["totals"]["damage"] = 1e100
    scene.report_view.open(large, 1)
    await save_image("learning_report_large")
    scene.report_view.close()
    var guide := root.get_node("FirstMatchGuide")
    var menu := root.get_node("GameMenu")
    var state := root.get_node("GameState")
    state.leave_match()
    change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
    await scene_changed
    menu.open_help()
    await save_image("learning_help")
    menu._start_guided_match()
    await scene_changed
    await save_image("learning_guide_commander")
    guide.continue_step()
    current_scene._open_army_builder()
    await scene_changed
    await save_image("learning_guide_warband")
    guide.continue_step()
    current_scene.seed_input.text = "7303"
    current_scene._begin_draft()
    await scene_changed
    await save_image("learning_guide_draft")
    guide.continue_step()
    var draft = current_scene
    draft._select_offer(0)
    await save_image("learning_guide_skill")
    guide.continue_step()
    while not state.draft.is_phase_complete():
        draft._select_offer(0)
    await save_image("learning_guide_ready")
    guide.continue_step()
    draft._start_battle()
    await scene_changed
    current_scene.set_process(false)
    await save_image("learning_guide_battle")
    guide.continue_step()
    current_scene._process(BattlePrelude.DURATION)
    current_scene._process(current_scene._duration + current_scene._tail_length + 1)
    await save_image("learning_guide_report")
    guide.continue_step()
    current_scene._open_report()
    await save_image("learning_guide_complete")
    guide.continue_step()
    current_scene.report_view.close()
    var study := DeathStudy.new()
    root.add_child(study)
    await save_image("learning_death_phases")
    study.reduced = true
    study.queue_redraw()
    await save_image("learning_death_reduced")
    study.queue_free()
    print("Battle learning native views: live inspection, both reports/compact/large values, Help, eight actual guided steps and four death motion types/full/reduced.")
    quit(0)
