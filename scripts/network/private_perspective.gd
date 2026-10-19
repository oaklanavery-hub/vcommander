class_name PrivatePerspective
extends RefCounted

const X_FIELDS := ["x", "source_x", "target_x", "from_x", "to_x", "start_x"]

static func state_for_player(state: Dictionary) -> Dictionary:
    return _flip(state, 0.0) if state.get("you") == "opponent" else state.duplicate(true)

static func battle_for_player(battle: Dictionary, side: String) -> Dictionary:
    return _flip(battle, float(battle.get("battlefield", {}).get("width", 24))) if side == "opponent" else battle.duplicate(true)

static func _flip(value: Variant, width: float) -> Variant:
    if value is Dictionary:
        var result := {}
        for key in value:
            var target_key: String = _side(str(key))
            if str(key) in X_FIELDS and (value[key] is float or value[key] is int):
                result[target_key] = width - float(value[key])
            else:
                result[target_key] = _flip(value[key], width)
        return result
    if value is Array:
        var result: Array = []
        for item in value:
            result.append(_flip(item, width))
        return result
    if value is String:
        if value.begins_with("player:"):
            return "opponent:" + value.trim_prefix("player:")
        if value.begins_with("opponent:"):
            return "player:" + value.trim_prefix("opponent:")
        return _side(value)
    return value

static func _side(value: String) -> String:
    if value == "player":
        return "opponent"
    if value == "opponent":
        return "player"
    return value
