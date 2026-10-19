class_name PrivateRoomServer
extends RefCounted

const MAX_PEERS := 16
const HANDSHAKE_SECONDS := 10.0
const MESSAGES_PER_SECOND := 12.0
const BURST_MESSAGES := 24.0

var service: PrivateRoomService
var port := 0
var time_source: Callable
var _listener := TCPServer.new()
var _peers: Dictionary = {}
var _next_peer := 1
var _jobs: Dictionary = {}

func start(content: Object, requested_port: int = 8080, address: String = "127.0.0.1") -> Error:
    if _listener.is_listening():
        return ERR_ALREADY_IN_USE
    var error := _listener.listen(requested_port, address)
    if error == OK:
        service = PrivateRoomService.new(content)
        port = _listener.get_local_port()
    return error

func poll() -> void:
    if not _listener.is_listening():
        return
    var now: float = time_source.call() if time_source.is_valid() else Time.get_ticks_msec() / 1000.0
    while _listener.is_connection_available():
        var stream := _listener.take_connection()
        if _peers.size() >= MAX_PEERS:
            stream.disconnect_from_host()
            continue
        var socket := WebSocketPeer.new()
        socket.inbound_buffer_size = PrivateProtocol.MAX_COMMAND_BYTES
        socket.outbound_buffer_size = PrivateProtocol.MAX_WIRE_BYTES + 65536
        socket.max_queued_packets = 8
        socket.heartbeat_interval = 5.0
        if socket.accept_stream(stream) != OK:
            stream.disconnect_from_host()
            continue
        _peers[_next_peer] = {"socket": socket, "created": now, "last": now, "budget": BURST_MESSAGES, "replay_at": -10.0, "replay_round": -1}
        _next_peer += 1
    # Expire deadlines before consuming messages received at/after the boundary.
    _send(service.tick(now))
    for peer_id in _peers.keys():
        var entry: Dictionary = _peers[peer_id]
        var socket: WebSocketPeer = entry["socket"]
        socket.poll()
        var state := socket.get_ready_state()
        if state == WebSocketPeer.STATE_CLOSED:
            _drop(peer_id, now)
            continue
        if now - float(entry["created"]) > HANDSHAKE_SECONDS and not service.seats.has(peer_id):
            socket.close(1008, "Session timeout")
            _drop(peer_id, now)
            continue
        if state != WebSocketPeer.STATE_OPEN:
            continue
        entry["budget"] = minf(BURST_MESSAGES, float(entry["budget"]) + (now - float(entry["last"])) * MESSAGES_PER_SECOND)
        entry["last"] = now
        while socket.get_available_packet_count() > 0:
            var packet := socket.get_packet()
            entry["budget"] -= 1.0
            var command := PrivateProtocol.read_json(packet)
            if not socket.was_string_packet() or entry["budget"] < 0 or not PrivateProtocol.valid_command(command):
                socket.close(1008, "Invalid or excessive commands")
                _drop(peer_id, now)
                break
            if command["type"] == "replay":
                if entry["replay_round"] == int(command["round"]) and now - float(entry["replay_at"]) < 2.0:
                    continue
                entry["replay_at"] = now
                entry["replay_round"] = int(command["round"])
            _send(service.handle(peer_id, command, now))
    for code in _jobs.keys():
        var job: Dictionary = _jobs[code]
        var thread: Thread = job["thread"]
        if not thread.is_alive():
            var result: Dictionary = thread.wait_to_finish()
            _jobs.erase(code)
            _send(service.finish_battle(code, job["round"], result, now))
    for request in service.pending_battles(now):
        var thread := Thread.new()
        var error := thread.start(_simulate.bind(request))
        if error != OK:
            stop()
            return
        _jobs[request["room"]] = {"thread": thread, "round": request["round"]}

func stop() -> void:
    _listener.stop()
    for entry in _peers.values():
        entry["socket"].close(-1)
    _peers.clear()
    for job in _jobs.values():
        job["thread"].wait_to_finish()
    _jobs.clear()
    service = null

func _simulate(request: Dictionary) -> Dictionary:
    # Independent simulator and copied inputs; workers never access rooms/nodes.
    return CombatSimulator.new().simulate(request["player"], request["opponent"], request["seed"], request["balance"])

func _drop(peer_id: int, now: float) -> void:
    if not _peers.has(peer_id):
        return
    _peers[peer_id]["socket"].close(-1)
    _peers.erase(peer_id)
    _send(service.disconnect_peer(peer_id, now))

func _send(messages: Array) -> void:
    for message in messages:
        var peer_id: int = message["peer"]
        if not _peers.has(peer_id):
            continue
        var socket: WebSocketPeer = _peers[peer_id]["socket"]
        if socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
            continue
        var error: Error
        if message.has("packet"):
            error = socket.put_packet(message["packet"])
        else:
            error = socket.send_text(JSON.stringify(message["message"]))
        if error != OK:
            # No unbounded application queue. Reconnect requests a fresh state/replay.
            socket.close(-1)
