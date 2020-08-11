extends Spatial

export var playable_area_bounds: AABB = AABB(Vector3(-10,0,-10), Vector3(20, 4, 20))
export var reference_area_bounds: AABB = AABB(Vector3(190, 0, -10), Vector3(20, 4, 20))
export var time_limit: float = 90.0
