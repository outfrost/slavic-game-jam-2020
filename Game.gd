extends Spatial

const util = preload("res://util/util.gd")
const Level = preload("res://Levels/Level.gd")
const Robot = preload("res://functional/Robot.gd")

signal game_over()

export var Levels: Array
export var scan_step: float = 0.25

var current_level = 0
var current_camera = 0
var dev_cameras: Array
var camera_perspective: Camera
var cam_pers_offset: Vector3
var robot: Robot
var level_playable_area: AABB
var level_dimension_squared: float

var current_level_container: Node

var timer_label: RichTextLabel

var gameover_popup: Popup
var gameover_message_label: RichTextLabel
var gameover_score_label: RichTextLabel

var time_left: float

var reference_scan: Array
var final_scan: Array

func SpawnLevel() -> void:
	var level_instance: Level = (Levels[current_level] as PackedScene).instance()
	current_level_container.add_child(level_instance)
	level_playable_area = level_instance.playable_area_bounds
	var level_dimension = level_playable_area.get_longest_axis_size()
	level_dimension_squared = level_dimension * level_dimension

	var level_reference_area = level_instance.reference_area_bounds
	reference_scan = scan_aabb(level_reference_area)

	time_left = level_instance.time_limit

	robot = get_tree().root.find_node("Robot", true, false)
	if robot:
		robot.connect("battery_depleted", self, "game_over")
		connect("game_over", robot, "on_game_over")
	else:
		printerr("No robot found :(")

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
	SpawnLevel()
	
	timer_label = find_node("TimerLabel")

	gameover_popup = find_node("GameoverPopup")
	gameover_message_label = gameover_popup.get_node("Panel/MessageLabel")
	gameover_score_label = gameover_popup.get_node("Panel/ScoreLabel")
	gameover_popup.get_node("Panel/RestartButton").connect("pressed", self, "next_level")

func _process(delta):
	util.display(self, "fps %d" % Performance.get_monitor(Performance.TIME_FPS))
	if Input.is_action_just_pressed("level_next"):
		#call_deferred("next_level")
		next_level()

	if !gameover_popup.visible:
		time_left = max(time_left - delta, 0.0)
		timer_label.bbcode_text = "[right][b]%02d:%02d[/b][/right]" % [int(time_left) / 60, int(time_left) % 60]
		if time_left == 0.0:
			game_over()

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

func game_over():
	scan_level()
	emit_signal("game_over")
	gameover_popup.show()

func next_level():
	gameover_popup.hide()
	remove_level()
	current_level = (current_level + 1) % Levels.size()
	call_deferred("SpawnLevel")

func remove_level():
	for node in current_level_container.get_children():
		current_level_container.remove_child(node)
		(node as Node).queue_free()

func scan_level():
	final_scan = scan_aabb(level_playable_area)

func scan_aabb(aabb: AABB) -> Array:
	var steps_x = int(ceil(aabb.size.x / scan_step))
	var steps_y = int(ceil(aabb.size.y / scan_step))
	var steps_z = int(ceil(aabb.size.z / scan_step))

	var physics_direct_state = get_world().get_direct_space_state()
	var query = PhysicsShapeQueryParameters.new()
	query.collision_mask = 2 # 0b010
	query.collide_with_areas = true
	query.margin = 0.04
	var shape = BoxShape.new()
	shape.extents = Vector3.ONE * scan_step * 0.5
	query.set_shape(shape)

	var planes = []
	var max_distance = sqrt(3 * scan_step * scan_step)

	for x in range(0, steps_x):
		var lines = []
		for y in range(0, steps_y):
			var points = []
			for z in range(0, steps_z):
				var pos: Vector3 = shape.extents + Vector3(x * scan_step, y * scan_step, z * scan_step)
				query.transform = Transform.IDENTITY.translated(
					aabb.position + pos)
				var result = physics_direct_state.collide_shape(query)
				var cell_value = 0.0
				for point in result:
					var distance = (point as Vector3 - pos).length()
					var value = clamp(inverse_lerp(max_distance, 0.0, distance), 0.0, 1.0)
					cell_value = max(cell_value, value)
				points.append(cell_value)
			lines.append(points)
		planes.append(lines)
	
	return planes


#					var box = MeshInstance.new()
#					var cube_mesh = CubeMesh.new()
#					cube_mesh.size = Vector3.ONE * 0.1
#					box.mesh = cube_mesh
#					box.transform = Transform.IDENTITY.translated(query.transform.origin)
#					add_child(box)
