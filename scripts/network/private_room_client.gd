class_name PrivateRoomClient
extends Node

signal state_changed(state: Dictionary)
signal battle_received(round_number: int, replay: Dictionary)
signal failed(code: String)
signal connection_changed(connected: bool)

var state: Dictionary = {}
var room := ""
var fingerprint := ""
var _token := ""
var _socket: WebSocketPeer
var _was_open := false
var _last_sync := 0.0

func _init() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS

func open(url: String, content: Object) -> Error:
    if _socket != null:
        return ERR_ALREADY_IN_USE
    # HTTPS browser play requires WSS; plaintext is only a loopback development aid.
    if not url.begins_with("wss://") and not url.begins_with("ws://127.0.0.1:") and not url.begins_with("ws://localhost:"):
        return ERR_INVALID_PARAMETER
    fingerprint = PrivateProtocol.content_hash(content)
    var socket := WebSocketPeer.new()
    socket.inbound_buffer_size = PrivateProtocol.MAX_WIRE_BYTES + 65536
    socket.outbound_buffer_size = PrivateProtocol.MAX_COMMAND_BYTES + 1024
    socket.max_queued_packets = 16
    var error := socket.connect_to_url(url)
    if error == OK:
        _socket = socket
        _last_sync = Time.get_ticks_msec() / 1000.0
    return error

func create_room(commander_id: String, cards: Array) -> bool:
    return send({"type": "create", "content": fingerprint, "commander": commander_id, "cards": cards})

func join_room(code: String, commander_id: String, cards: Array) -> bool:
    return send({"type": "join", "content": fingerprint, "room": code.strip_edges().to_upper(), "commander": commander_id, "cards": cards})

func resume_room() -> bool:
    return send({"type": "resume", "content": fingerprint, "room": room, "token": _token})

func act(kind: String, index: int = -1) -> bool:
    var command := {"type": kind, "round": state.get("round", 0), "revision": state.get("revision", 0)}
    if kind == "pick":
        command["index"] = index
    return send(command)

func send(command: Dictionary) -> bool:
    if not connected():
        return false
    var copy := command.duplicate(true)
    copy["v"] = PrivateProtocol.VERSION
    if not PrivateProtocol.valid_command(copy):
        return false
    return _socket.send_text(JSON.stringify(copy)) == OK

func connected() -> bool:
    return _socket != null and _socket.get_ready_state() == WebSocketPeer.STATE_OPEN

func close(forget_session: bool = false) -> void:
    if _socket != null:
        _socket.close(-1)
    _socket = null
    if _was_open:
        connection_changed.emit(false)
    _was_open = false
    if forget_session:
        _token = ""
        room = ""
        state.clear()

func _process(_delta: float) -> void:
    poll()

func poll() -> void:
    if _socket == null:
        return
    _socket.poll()
    if _socket.get_ready_state() == WebSocketPeer.STATE_CLOSED:
        close()
        failed.emit("connection_closed")
        return
    if not connected():
        return
    if not _was_open:
        _was_open = true
        connection_changed.emit(true)
    while _socket != null and _socket.get_available_packet_count() > 0:
        var packet := _socket.get_packet()
        var text := _socket.was_string_packet()
        var message := PrivateProtocol.read_json(packet, 65536) if text else PrivateProtocol.read_replay(packet)
        if message.get("v") != PrivateProtocol.VERSION:
            close()
            failed.emit("invalid_response")
            return
        match message.get("type"):
            "session":
                room = str(message["room"])
                _token = str(message["token"])
            "state":
                if message.get("content") != fingerprint:
                    close()
                    failed.emit("content_mismatch")
                    return
                state = message.duplicate(true)
                state_changed.emit(state.duplicate(true))
            "battle":
                battle_received.emit(int(message["round"]), message["replay"].duplicate(true))
            "error":
                if message.get("code") in ["room_expired", "replay_too_large"]:
                    close(true)
                failed.emit(str(message["code"]))
    var now := Time.get_ticks_msec() / 1000.0
    if now - _last_sync >= 5.0:
        _last_sync = now
        if not state.is_empty():
            send({"type": "sync"})

func _exit_tree() -> void:
    close()
