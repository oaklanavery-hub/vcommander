class_name CombatTerrain
extends RefCounted
## Bounded visibility graph for temporary surface barriers. No scene or content IDs.

static func point(record: Dictionary, prefix: String) -> Vector2:
    return Vector2(float(record[prefix + "_x"]), float(record[prefix + "_y"]))

static func segment_distance(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> float:
    if Geometry2D.segment_intersects_segment(a, b, c, d) != null:
        return 0.0
    return minf(minf(a.distance_to(Geometry2D.get_closest_point_to_segment(a, c, d)), b.distance_to(Geometry2D.get_closest_point_to_segment(b, c, d))), minf(c.distance_to(Geometry2D.get_closest_point_to_segment(c, a, b)), d.distance_to(Geometry2D.get_closest_point_to_segment(d, a, b))))

static func clear_line(a: Vector2, b: Vector2, walls: Array, clearance: float) -> bool:
    for wall in walls:
        if segment_distance(a, b, point(wall, "from"), point(wall, "to")) < clearance - 0.0001:
            return false
    return true

static func route(origin: Vector2, goal: Vector2, walls: Array, bounds: Rect2, clearance: float) -> Array[Vector2]:
    if clear_line(origin, goal, walls, clearance):
        return [goal]
    var nodes: Array[Vector2] = [origin, goal]
    # Four corner nodes per capsule, offset past each end. Rebuilt only when a
    # barrier changes or a moving target invalidates a unit's cached route.
    for wall in walls:
        var a := point(wall, "from")
        var b := point(wall, "to")
        var axis := (b - a).normalized()
        var normal := axis.orthogonal()
        for end in [a - axis * clearance * 1.6, b + axis * clearance * 1.6]:
            for sign_value in [-1.0, 1.0]:
                var node: Vector2 = end + normal * clearance * 1.6 * sign_value
                if bounds.has_point(node) and clear_line(node, node, walls, clearance):
                    nodes.append(node)
    var distance := PackedFloat64Array()
    var previous := PackedInt32Array()
    var visited := PackedByteArray()
    distance.resize(nodes.size())
    distance.fill(INF)
    previous.resize(nodes.size())
    previous.fill(-1)
    visited.resize(nodes.size())
    distance[0] = 0.0
    for iteration in range(nodes.size()):
        var best := -1
        for index in range(nodes.size()):
            if visited[index] == 0 and (best < 0 or distance[index] < distance[best]):
                best = index
        if best < 0 or is_inf(distance[best]):
            break
        if best == 1:
            var path: Array[Vector2] = []
            var cursor := 1
            while cursor > 0:
                path.push_front(nodes[cursor])
                cursor = previous[cursor]
            return path
        visited[best] = 1
        for index in range(nodes.size()):
            if visited[index] != 0 or index == best:
                continue
            var candidate := distance[best] + nodes[best].distance_to(nodes[index])
            if candidate < distance[index] and clear_line(nodes[best], nodes[index], walls, clearance):
                distance[index] = candidate
                previous[index] = best
    return []
