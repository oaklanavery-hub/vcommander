class_name PrivateRoomService
extends RefCounted

const MAX_ROOMS := 4
const IDLE_SECONDS := 600.0
const LIFETIME_SECONDS := 3600.0
const RECONNECT_SECONDS := 60.0
const CODE_ALPHABET := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"

var rooms: Dictionary = {}
var seats: Dictionary = {}
var fingerprint: String
var _content: Object
var _crypto := Crypto.new()
var _seed_source: Callable

func _init(content: Object, seed_source: Callable = Callable()) -> void:
    _content = content
    _seed_source = seed_source
    fingerprint = PrivateProtocol.content_hash(content)

func handle(peer_id: int, command: Dictionary, now: float) -> Array:
    if not PrivateProtocol.valid_command(command):
        return _error(peer_id, "invalid_command")
    var kind: String = command["type"]
    if kind == "clock":
        return [{"peer": peer_id, "message": {"v": PrivateProtocol.VERSION, "type": "clock", "at": command["at"], "server_time": now}}]
    if kind in ["create", "join", "resume"]:
        if seats.has(peer_id):
            return _error(peer_id, "already_seated")
        if command["content"] != fingerprint:
            return _error(peer_id, "content_mismatch")
        return _enter(peer_id, command, now)
    if not seats.has(peer_id):
        return _error(peer_id, "not_seated")
    var seat: Dictionary = seats[peer_id]
    var code: String = seat["room"]
    var room: Dictionary = rooms[code]
    var game: PrivateMatch = room["game"]
    if kind == "sync":
        return [_state(peer_id, now)]
    if kind == "replay":
        if int(command["round"]) != game.match_state.round_number or room["packet"].is_empty():
            return _error(peer_id, "replay_unavailable")
        return [{"peer": peer_id, "packet": room["packet"]}]
    if not game.act(seat["side"], command, now):
        return _error(peer_id, "stale_or_illegal_action")
    if game.phase == "draft":
        room["packet"] = PackedByteArray()
    room["active_at"] = now
    return _states(code, now)

func disconnect_peer(peer_id: int, now: float) -> Array:
    if not seats.has(peer_id):
        return []
    var seat: Dictionary = seats[peer_id]
    rooms[seat["room"]]["peers"][seat["side"]] = 0
    rooms[seat["room"]]["disconnected_at"][seat["side"]] = now
    seats.erase(peer_id)
    return _states(seat["room"], now)

func tick(now: float) -> Array:
    var messages: Array = []
    for code in rooms.keys():
        var room: Dictionary = rooms[code]
        if now - float(room["created_at"]) >= LIFETIME_SECONDS or now - float(room["active_at"]) >= IDLE_SECONDS:
            for peer_id in room["peers"].values():
                if int(peer_id) > 0:
                    messages.append_array(_error(peer_id, "room_expired"))
                    seats.erase(peer_id)
            rooms.erase(code)
        else:
            var changed := _settle_disconnects(room, now)
            if room["game"].tick(now):
                changed = true
            if changed:
                room["active_at"] = now
                messages.append_array(_states(code, now))
    return messages

func pending_battles(now: float) -> Array:
    var requests: Array = []
    for code in rooms:
        var request: Dictionary = rooms[code]["game"].battle_request()
        if not request.is_empty():
            rooms[code]["packet"] = PackedByteArray()
            request["room"] = code
            requests.append(request)
    return requests

func finish_battle(code: String, round_number: int, result: Dictionary, now: float) -> Array:
    if not rooms.has(code):
        return []
    var game: PrivateMatch = rooms[code]["game"]
    if not game.accept_battle(round_number, result):
        return []
    rooms[code]["packet"] = PrivateProtocol.replay_packet(round_number, result)
    if rooms[code]["packet"].is_empty():
        # Resource-bound failure never produces a fabricated result or reward.
        var messages: Array = []
        for peer_id in rooms[code]["peers"].values():
            if int(peer_id) > 0:
                messages.append_array(_error(peer_id, "replay_too_large"))
                seats.erase(peer_id)
        rooms.erase(code)
        return messages
    rooms[code]["active_at"] = now
    return _states(code, now)

func _enter(peer_id: int, command: Dictionary, now: float) -> Array:
    var kind: String = command["type"]
    var code: String = str(command.get("room", ""))
    var side := "opponent"
    if kind == "create":
        if rooms.size() >= MAX_ROOMS:
            return _error(peer_id, "server_full")
        code = _new_code()
        side = "player"
        var seed_value: int = _seed_source.call() if _seed_source.is_valid() else _crypto.generate_random_bytes(4).decode_u32(0)
        var game := PrivateMatch.new(_content, seed_value)
        if not game.add_side(side, command["commander"], command["cards"], now):
            return _error(peer_id, "invalid_loadout")
        rooms[code] = {"game": game, "peers": {}, "tokens": {}, "packet": PackedByteArray(), "created_at": now, "active_at": now,
            "disconnected_at": {"player": -1.0, "opponent": -1.0}}
    elif not rooms.has(code):
        return _error(peer_id, "room_unavailable")
    var room: Dictionary = rooms[code]
    if kind == "join":
        if room["tokens"].has(side):
            return _error(peer_id, "room_unavailable")
        if not room["game"].add_side(side, command["commander"], command["cards"], now):
            return _error(peer_id, "invalid_loadout")
    elif kind == "resume":
        _settle_disconnects(room, now)
        side = ""
        for candidate in room["tokens"]:
            if room["tokens"][candidate] == command["token"]:
                side = candidate
        if side.is_empty() or int(room["peers"].get(side, 0)) != 0:
            return _error(peer_id, "session_unavailable")
    var messages: Array = []
    if kind != "resume":
        var token := _crypto.generate_random_bytes(32).hex_encode()
        room["tokens"][side] = token
        messages.append({"peer": peer_id, "message": {"v": PrivateProtocol.VERSION, "type": "session", "room": code, "token": token}})
    room["peers"][side] = peer_id
    room["disconnected_at"][side] = -1.0
    room["active_at"] = now
    seats[peer_id] = {"room": code, "side": side}
    messages.append_array(_states(code, now))
    return messages

func _state(peer_id: int, now: float) -> Dictionary:
    var seat: Dictionary = seats[peer_id]
    var room: Dictionary = rooms[seat["room"]]
    var state: Dictionary = room["game"].view_for(seat["side"], now)
    var reconnect := {}
    for side in PrivateMatch.SIDES:
        var disconnected_at: float = room["disconnected_at"][side]
        reconnect[side] = maxf(0.0, disconnected_at + RECONNECT_SECONDS - now) if disconnected_at >= 0 else 0.0
    state.merge({"v": PrivateProtocol.VERSION, "type": "state", "room": seat["room"], "content": fingerprint, "reconnect_seconds": reconnect,
        "connected": {"player": int(room["peers"].get("player", 0)) > 0, "opponent": int(room["peers"].get("opponent", 0)) > 0}})
    return {"peer": peer_id, "message": state}

func _settle_disconnects(room: Dictionary, now: float) -> bool:
    var game: PrivateMatch = room["game"]
    if game.phase in ["waiting", "complete"]:
        return false
    var due := {}
    for side in PrivateMatch.SIDES:
        var disconnected_at: float = room["disconnected_at"][side]
        if disconnected_at >= 0 and now >= disconnected_at + RECONNECT_SECONDS:
            due[side] = disconnected_at + RECONNECT_SECONDS
    if due.is_empty():
        return false
    var first_side := str(due.keys()[0])
    for side in due:
        if float(due[side]) < float(due[first_side]):
            first_side = side
    var deadline: float = due[first_side]
    # Settle earlier battle events before the disconnect deadline, even when a
    # stalled process catches up multiple boundaries in one poll.
    if game.phase == "playing" and game.play_until <= deadline:
        game.tick(game.play_until)
        if game.phase == "complete":
            return true
    if due.size() == 2 and float(due["player"]) == float(due["opponent"]):
        game.phase = "complete"
        game.match_state.phase = "complete"
        game.end_reason = "both_disconnected"
        return true
    return game.forfeit(first_side)

func _states(code: String, now: float) -> Array:
    var messages: Array = []
    for peer_id in rooms[code]["peers"].values():
        if int(peer_id) > 0:
            messages.append(_state(peer_id, now))
    return messages

func _error(peer_id: int, code: String) -> Array:
    return [{"peer": peer_id, "message": {"v": PrivateProtocol.VERSION, "type": "error", "code": code}}]

func _new_code() -> String:
    while true:
        var bytes := _crypto.generate_random_bytes(6)
        var code := ""
        for byte in bytes:
            code += CODE_ALPHABET[int(byte) % CODE_ALPHABET.length()]
        if not rooms.has(code):
            return code
    return ""
