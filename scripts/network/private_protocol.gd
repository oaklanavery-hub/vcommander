class_name PrivateProtocol
extends RefCounted

const VERSION := 1
const MAX_COMMAND_BYTES := 8192
const MAX_REPLAY_BYTES := 64 * 1024 * 1024
const MAX_WIRE_BYTES := 8 * 1024 * 1024

static func content_hash(content: Object) -> String:
    var sets: Array = []
    var ids: Array = content.sets.keys()
    ids.sort()
    for id in ids:
        sets.append(content.sets[id])
    return JSON.stringify({"commanders": content.get_all_commanders(), "cards": content.get_all_cards(),
        "sets": sets, "buffs": content.get_all_buffs(), "balance": content.get_game_balance()}, "", true).sha256_text()

static func read_json(packet: PackedByteArray, limit: int = MAX_COMMAND_BYTES) -> Dictionary:
    if packet.is_empty() or packet.size() > limit:
        return {}
    var parser := JSON.new()
    if parser.parse(packet.get_string_from_utf8()) != OK or not parser.data is Dictionary:
        return {}
    return parser.data

static func valid_command(command: Dictionary) -> bool:
    if not _whole(command.get("v"), VERSION, VERSION) or not command.get("type") is String:
        return false
    var kind: String = command["type"]
    if kind in ["create", "join"]:
        if not command.get("content") is String or not command.get("commander") is String or not command.get("cards") is Array:
            return false
        if command["cards"].size() != 4 or command["commander"].length() > 128:
            return false
        for id in command["cards"]:
            if not id is String or id.is_empty() or id.length() > 128:
                return false
    if kind in ["join", "resume"] and (not command.get("room") is String or command["room"].length() != 6):
        return false
    if kind == "resume" and (not command.get("content") is String or not command.get("token") is String or command["token"].length() != 64):
        return false
    if kind in ["pick", "skill", "continue", "replay"] and not _whole(command.get("round"), 1, 1000000):
        return false
    if kind in ["pick", "skill"] and not _whole(command.get("revision"), 1, 10000000):
        return false
    if kind == "pick" and not _whole(command.get("index"), 0, 2):
        return false
    return kind in ["create", "join", "resume", "pick", "skill", "continue", "replay", "sync"]

static func replay_packet(round_number: int, result: Dictionary) -> PackedByteArray:
    var raw := JSON.stringify({"v": VERSION, "type": "battle", "round": round_number, "replay": result}).to_utf8_buffer()
    if raw.size() > MAX_REPLAY_BYTES:
        return PackedByteArray()
    var packed := raw.compress(FileAccess.COMPRESSION_GZIP)
    return packed if packed.size() <= MAX_WIRE_BYTES else PackedByteArray()

static func read_replay(packet: PackedByteArray) -> Dictionary:
    if packet.size() < 18 or packet.size() > MAX_WIRE_BYTES or packet[0] != 0x1f or packet[1] != 0x8b:
        return {}
    var raw := packet.decompress_dynamic(MAX_REPLAY_BYTES, FileAccess.COMPRESSION_GZIP)
    var message := read_json(raw, MAX_REPLAY_BYTES)
    if message.get("v") != VERSION or message.get("type") != "battle" or not message.get("replay") is Dictionary:
        return {}
    return message

static func _whole(value: Variant, minimum: int, maximum: int) -> bool:
    return (value is int or value is float) and is_finite(float(value)) and float(value) == floorf(float(value)) and value >= minimum and value <= maximum
