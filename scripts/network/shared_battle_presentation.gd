class_name SharedBattlePresentation
extends RefCounted

var session: Node
var _shared_elapsed := 0.0

func _init(session_node: Node) -> void:
    session = session_node

func attach(screen: Control) -> void:
    screen.speed_button.hide()
    screen.pause_button.hide()
    screen.back_button.text = "Leave friend match"
    screen.title_label.text = "Room %s • Battle %d • Shared 1×" % [session.client.room, screen._source.match_state.round_number]

func advance(screen: Control, _delta: float) -> void:
    var state: Dictionary = session.client.state
    if state.is_empty():
        return
    var other := "opponent" if state.get("you") == "player" else "player"
    var rival_disconnected: bool = not state.get("connected", {}).get(other, true)
    screen.seed_label.visible = not session.client.connected() or rival_disconnected
    screen.seed_label.text = "Reconnecting… 60s grace"
    if rival_disconnected:
        var deadline := float(state.get("server_time", 0)) + float(state.get("reconnect_seconds", {}).get(other, 0))
        screen.seed_label.text = "Rival reconnecting • %ds" % maxi(0, ceili(deadline - session.client.server_time()))
    var elapsed := maxf(_shared_elapsed, maxf(0.0, session.client.server_time() - float(state.get("play_at", 0))))
    _shared_elapsed = elapsed
    if float(state.get("play_at", 0)) <= 0 or session.client.server_time() < float(state["play_at"]):
        screen.battle_timer.text = "Shared battle starts in %d…" % maxi(1, ceili(float(state.get("play_at", 0)) - session.client.server_time()))
        return
    if screen._prelude.active():
        screen._advance_prelude(maxf(0, minf(elapsed, screen._prelude.duration) - screen._prelude.elapsed))
        if screen._prelude.active():
            return
    screen._playback_time = clampf(elapsed - screen._prelude.duration, 0, screen._duration)
    screen._end_elapsed = clampf(elapsed - screen._prelude.duration - screen._duration, 0, screen._tail_length)
    screen._advance_frames()
    screen._advance_events()
    screen._update_timer_label()
    if state.get("phase") in ["replay", "complete"] and elapsed + 0.03 >= screen._prelude.duration + screen._duration + screen._tail_length:
        screen._finish_replay()
    if screen._finished:
        screen.next_button.disabled = not session.can_act() or bool(state.get("acknowledged", false))
        if state.get("acknowledged", false):
            screen.next_button.text = "Waiting for your friend…"

func finish(screen: Control) -> void:
    if screen._finished:
        return
    screen._finished = true
    screen._source.update(session.client.state)
    screen.battlefield.replay_complete = true
    screen.battlefield.finish_replay()
    screen.reveal_report()
    screen._hearts_meter.refresh(screen._source.match_state)
    var winner := str(screen._source.battle_result.get("winner", "draw"))
    GameAudio.play_effect("victory" if winner == "player" else "loss")
    screen.result_label.text = "Round won!" if winner == "player" else ("Round lost. An extra pick awaits." if winner == "opponent" else "Draw. Both armies lose a heart.")
    if screen._source.match_state.is_complete():
        screen.result_label.text = "Friend match won!" if screen._source.match_state.winner == "player" else "Your friend wins this match."
        screen.result_label.text += "  •  Unranked playtest"
        screen.next_button.text = "Back to warband"
    else:
        screen.next_button.text = "Continue to round %d" % (screen._source.match_state.round_number + 1)
    screen.next_button.show()

func next_round(screen: Control) -> void:
    if screen._source.match_state.is_complete():
        session.leave()
        screen.get_tree().change_scene_to_file("res://scenes/army_builder/army_builder.tscn")
    else:
        session.act("continue")
