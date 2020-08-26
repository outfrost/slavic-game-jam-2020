class_name Level
extends Spatial

export var playable_area_bounds: AABB = AABB(Vector3(-10,0,-10), Vector3(20, 4, 20))
export var reference_area_bounds: AABB = AABB(Vector3(190, 0, -10), Vector3(20, 4, 20))
export var time_limit: float = 90.0
export var freeze_time: float = 5.0
export var scan_step: float = 0.25

var reference_scan: Array

func _ready() -> void:
	reference_scan = scan_aabb(reference_area_bounds)

# TODO Figure out if more granular collision scanning (as originally intended)
# is feasible, and if so how.

func scan_level() -> float:
	var final_scan = scan_aabb(playable_area_bounds)
	var mean_diff = 0.0
	var cell_count = 0
	for x in range(0, min(final_scan.size(), reference_scan.size())):
		var plane_final = final_scan[x]
		var plane_ref = reference_scan[x]
		for y in range(0, min(plane_final.size(), plane_ref.size())):
			var line_final = plane_final[y]
			var line_ref = plane_ref[y]
			for z in range(0, min(line_final.size(), line_ref.size())):
				var point_final = line_final[z]
				var point_ref = line_ref[z]
#				if point_final > 0.0:
#					print(point_final)
#				mean_diff += abs(point_final - point_ref)
				if point_final || point_ref:
					mean_diff += float(point_final != point_ref)
					cell_count += 1
	mean_diff /= cell_count
	var similarity = 1.0 - mean_diff * mean_diff
	return similarity

func scan_aabb(aabb: AABB) -> Array:
	var steps_x = int(ceil(aabb.size.x / scan_step))
	var steps_y = int(ceil(aabb.size.y / scan_step))
	var steps_z = int(ceil(aabb.size.z / scan_step))

	var physics_direct_state = get_tree().root.get_world().get_direct_space_state()
	var query = PhysicsShapeQueryParameters.new()
	query.collision_mask = 2 # 0b010
	query.collide_with_areas = true
	query.margin = 0.04
	var shape = BoxShape.new()
	shape.extents = Vector3.ONE * scan_step * 0.5
	query.set_shape(shape)

	var planes = []
#	var max_distance = sqrt(3 * scan_step * scan_step)

	for x in range(0, steps_x):
		var lines = []
		for y in range(0, steps_y):
			var points = []
			for z in range(0, steps_z):
				var pos: Vector3 = shape.extents + Vector3(x * scan_step, y * scan_step, z * scan_step)
				query.transform = Transform.IDENTITY.translated(
					aabb.position + pos)
				var result = physics_direct_state.collide_shape(query)
#				var cell_value = 0.0
#				for point in result:
#					var distance = ((point as Vector3) - pos).length()
#					var value = clamp(inverse_lerp(max_distance, 0.0, distance), 0.0, 1.0)
#					cell_value = max(cell_value, value)
				var cell_value: bool = result.size() > 0
				points.append(cell_value)
			lines.append(points)
		planes.append(lines)

	return planes

func spawn_cube(origin: Vector3, size: float) -> void:
	var box = MeshInstance.new()
	var cube_mesh = CubeMesh.new()
	cube_mesh.size = Vector3.ONE * size
	box.mesh = cube_mesh
	box.transform = Transform.IDENTITY.translated(origin)
	add_child(box)
