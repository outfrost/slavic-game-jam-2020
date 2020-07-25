extends Spatial

const util = preload("res://util/util.gd")
const Level = preload("res://Levels/Level.gd")
const ScannerProbe = preload("res://functional/ScannerProbe.tscn")

var current_level = 0
var current_camera = 0
var dev_cameras: Array
var camera_perspective: Camera
var cam_pers_offset: Vector3
var robot: Spatial
var level_dimension_squared: float

var furniture_scan_result: PoolByteArray
var scanner_collision_objects: Array
var scanner_probe: KinematicBody

export var Levels: Array

var current_level_container: Node

var items_count = 0
var furniture_bounds = AABB(Vector3(0,0,0), Vector3(0,0,0))

func remove_recursive(node):
	for N in node.get_children():
		remove_recursive(N)
		node.remove_child(N)

func SpawnLevel() -> void:
	remove_recursive(current_level_container)
	#for node in current_level_container.get_children():
	#	current_level_container.remove_child(node)
	var level_instance = (Levels[current_level] as PackedScene).instance()
	current_level_container.add_child(level_instance)
	var level_dimension = level_instance.playable_area_bounds.get_longest_axis_size()
	level_dimension_squared = level_dimension * level_dimension
	
	
	
	
	var bounds_size = level_instance.playable_area_bounds.size
	var scanner_position_base = -level_instance.playable_area_bounds.end# + Vector3(bounds_size.x/2, 0, bounds_size.z / 2)
	var scanning_probes_count = ceil(bounds_size.x) * ceil(bounds_size.y) * ceil(bounds_size.z)
	
	var scanner_probe_size = 2
	var space = self.get_world().space
	var physics_direct_state = PhysicsServer.space_get_direct_state(space)
	#var box_shape = BoxShape.new().set_extents(Vector3(0.5, 0.5, 0.5))
	var box_shape = BoxShape.new().set_extents(Vector3(1, 1, 1) * scanner_probe_size/2 )
	var query = PhysicsShapeQueryParameters.new()
	query.collide_with_areas = true
	query.margin = 2.0
	query.set_shape(box_shape)
	#print(bounds_size)
	var matches_total = 0
	#furniture_scan_result.resize(ceil(bounds_size.x) * ceil(bounds_size.y) * ceil(bounds_size.z))
	
	var sure_colliding_spot = Vector3(-10, 2, 0)
	query.transform = Transform(Vector3(0,0,0), Vector3(0,0,0), Vector3(0,0,0), sure_colliding_spot)
	var instersection_result = physics_direct_state.intersect_shape(query, 5)
	print(instersection_result.size())
	print("^should be > 0")
	
	
	
	var _time_before = OS.get_ticks_msec()
	if(false):
		for x in range(min(100, ceil(bounds_size.x/scanner_probe_size))):
			for y in range(min(100, ceil(bounds_size.y/scanner_probe_size))):
				for z in range(ceil(bounds_size.z/scanner_probe_size)):
					query.transform = Transform(Vector3(0,0,0), Vector3(0,0,0), Vector3(0,0,0), scanner_position_base + Vector3(x*2,y*2,z*2))
					instersection_result = physics_direct_state.intersect_shape(query, 5)
					if(instersection_result.size() > 0):
						#furniture_scan_result[x*scanner_probe_size + y * scanner_probe_size  * x + z * scanner_probe_size * x * y] = 1
						matches_total = matches_total + 1
		print(matches_total)
					#scanner_probe.transform = Transform.IDENTITY
					#scanner_probe.move_and_collide()
					#scanner_probe.translate(scanner_position_base + Vector3(x,y,z))
					
					#var new_probe = ScannerProbe.instance()
					#new_probe.transform = Transform.IDENTITY
					#new_probe.translate(scanner_position_base + Vector3(x,1,y))
					#self.add_child(new_probe)
					
					#var new_collision_shape: CollisionShape = CollisionShape.new()
					#new_collision_shape.transform = Transform.IDENTITY
					#new_collision_shape.translate(scanner_position_base + Vector3(x,y,z))
					#var shape_owner = current_level_container.create_shape_owner(current_level_container)
					#Spatial.shape_owner_add_shape(shape_owner, new_collision_shape)
					#current_level_container.add_shape(new_collision_shape, Transform.IDENTITY)
					#scanner_collision_objects.push_back(new_collision_shape)
		#furniture_scan_result.resize(ceil(bounds_size.x) * ceil(bounds_size.y) * ceil(bounds_size.z))
		# prepare sweep scan
	var time = OS.get_ticks_msec() - _time_before
	print(time)

func _ready():
	dev_cameras = self.get_node("devCameras").get_children()
	dev_cameras[current_camera].make_current()
	camera_perspective = self.get_node("devCameras/CameraPerspective")
	if camera_perspective:
		cam_pers_offset = camera_perspective.transform.origin
	else:
		printerr("No perspective camera :(")
		cam_pers_offset = Vector3.ZERO

	current_level_container = self.get_node("CurrentLevel")
	#current_level_container.set_physics_process(false)
	scanner_probe = self.get_node("ScannerProbe")
	SpawnLevel()

	robot = get_tree().root.find_node("Robot", true, false)
	if !robot:
		printerr("No robot found :(")

func _process(delta):
	util.display(self, "fps %d" % Performance.get_monitor(Performance.TIME_FPS))

	if Input.is_action_just_pressed("level_next"):
		call_deferred("next_level")

	if Input.is_action_just_pressed("debug_switch_camera"):
		current_camera = (current_camera + 1) % (dev_cameras.size())
		dev_cameras[current_camera].make_current()

	if camera_perspective && robot:
		var displacement = robot.global_transform.origin
		var min_displacement = displacement * 0.25
		var distance_squared = displacement.length_squared()
		# t = 1 / ( 4 * dist^2 / level_dim^2 + 1) from 0 to 1
		var t = clamp(1.0 / ((4.0 * distance_squared / level_dimension_squared) + 1.0), 0.0, 1.0)
		#util.display(self, "t %f" % t)
		var camera_origin = min_displacement.linear_interpolate(displacement, t)
		# Camera follows at an offset to see player more or less in the middle of the screen
		camera_origin += cam_pers_offset
		camera_perspective.translation = camera_origin

func next_level():
	current_level = (current_level + 1) % Levels.size()
	SpawnLevel()
