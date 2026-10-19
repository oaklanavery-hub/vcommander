extends Node

signal changed

var client := PrivateRoomClient.new()
var endpoint := ""
var active := false
var status := "Create a room or enter your friend's code."
var replay: Dictionary = {}
var replay_round := 0
var _intent := ""
var _code := ""
var _commander := ""
var _cards: Array = []
var _started_at := 0.0
var _retry_at := 0.0
var _retry_delay := 0.5
var _opened_at := 0.0
var _requested_at := -10.0
var _request_round := 0
var _pending_action := false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    endpoint = str(ProjectSettings.get_setting("network/private_room_url", ""))
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with("--pvp-url="):
            endpoint = argument.trim_prefix("--pvp-url=")
    if OS.has_feature("web"):
        var requested = JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('pvp_server') || ''", true)
        if requested is String and not requested.is_empty():
            endpoint = requested
    add_child(client)
    client.state_changed.connect(_receive_state)
    client.battle_received.connect(_receive_battle)
    client.connection_changed.connect(_connection)
    client.failed.connect(_failed)

func start(intent: String, code: String = "") -> bool:
    if active:
        return false
    if endpoint.is_empty():
        status = "The friend playtest server is not online yet."
        changed.emit()
        return false
    if intent == "resume" and not client.has_session():
        return false
    if intent != "resume":
        client.close(true)
        replay.clear()
        replay_round = 0
        _commander = GameState.selected_commander_id
        _cards = GameState.army.get_cards()
    else:
        client.close()
    _intent = intent
    _code = code.strip_edges().to_upper()
    active = true
    _pending_action = false
    _request_round = 0
    _retry_delay = 0.5
    _started_at = Time.get_ticks_msec() / 1000.0
    _retry_at = _started_at
    status = "Connecting… The free server may take about a minute to wake."
    changed.emit()
    return true

func leave() -> void:
    active = false
    client.close()
    status = "Room left. You can reconnect within 60 seconds before a forfeit."
    changed.emit()

func act(kind: String, index: int = -1) -> bool:
    if not active or _pending_action or not client.connected():
        return false
    if client.act(kind, index):
        _pending_action = true
        changed.emit()
        return true
    return false

func can_act() -> bool:
    return active and client.connected() and not _pending_action

func _process(_delta: float) -> void:
    if not active:
        return
    var now := Time.get_ticks_msec() / 1000.0
    if not client.connected() and now - _started_at > 95.0:
        active = false
        client.close()
        status = "The server could not be reached. Try again in a moment."
        changed.emit()
        return
    if client._socket != null and not client.connected() and now - _opened_at > 15.0:
        client.close()
    if client._socket == null and now >= _retry_at:
        _opened_at = now
        _retry_at = now + _retry_delay
        _retry_delay = minf(8.0, _retry_delay * 2)
        if client.open(endpoint, ContentDatabase) != OK:
            _failed("invalid_endpoint")
    if client.connected() and client.state.get("replay_available", false):
        var round_number := int(client.state.get("round", 0))
        if replay_round != round_number and now - _requested_at >= 2.1:
            _requested_at = now
            _request_round = round_number
            client.send({"type": "replay", "round": round_number})

func _connection(connected: bool) -> void:
    if not active:
        return
    if connected:
        _retry_delay = 0.5
        if client.has_session():
            client.resume_room()
        elif _intent == "create":
            client.create_room(_commander, _cards)
        else:
            client.join_room(_code, _commander, _cards)
    else:
        _pending_action = false
        _started_at = Time.get_ticks_msec() / 1000.0
        _retry_at = _started_at + 0.5
        status = "Connection lost. Reconnecting… Your seat is held for 60 seconds."
    changed.emit()

func _receive_state(state: Dictionary) -> void:
    _pending_action = false
    if replay_round != 0 and replay_round != int(state.get("round", 0)):
        replay.clear()
        replay_round = 0
    match state.get("phase"):
        "waiting": status = "Share your room code with a friend."
        "draft": status = "Choose your next recruits." if int(state.get("points", 0)) > 0 else "Your army is ready. Waiting for your friend…"
        "simulating": status = "Preparing the battlefield…"
        "loading": status = "Both armies are ready. Preparing the shared battle…"
        "playing": status = "Shared battle • 1×"
        "replay": status = "Round complete. Both players continue to the next draft."
        "complete": status = "Friend match complete. No mastery or ranked rewards."
    if state.get("phase") == "loading" and replay_round == int(state["round"]) and not state.get("loaded", false):
        client.act("ready")
    changed.emit()

func _receive_battle(round_number: int, battle: Dictionary) -> void:
    if round_number != int(client.state.get("round", 0)) or round_number != _request_round:
        return
    replay = battle.duplicate(true)
    replay_round = round_number
    if client.state.get("phase") == "loading" and not client.state.get("loaded", false):
        client.act("ready")
    changed.emit()

func _failed(code: String) -> void:
    if code == "connection_closed":
        return
    _pending_action = false
    if code == "stale_or_illegal_action":
        client.send({"type": "sync"})
        return
    var messages := {"room_unavailable": "That room is full or no longer available. Check the code and try again.",
        "content_mismatch": "Your game version differs from the server. Refresh the game and try again.",
        "server_full": "All friend rooms are busy. Please try again shortly.",
        "session_unavailable": "This seat is no longer available. Create or join a new room.",
        "room_expired": "This room has closed. Create a new room to play again.",
        "replay_too_large": "This battle could not be loaded. Please create a new room.",
        "invalid_endpoint": "The friend playtest server is not ready yet."}
    status = messages.get(code, "The room could not be opened. Please try again.")
    active = false
    client.close()
    changed.emit()
