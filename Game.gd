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

var sound_time_low: AudioStreamPlayer

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

	if sound_time_low and sound_time_low.playing:
		sound_time_low.stop()

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
	
	sound_time_low = self.get_node("Sounds/AlarmSound")

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
		if !sound_time_low.playing and time_left < 11:
			sound_time_low.play()
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
	var similarity = scan_level()
	emit_signal("game_over")
	var score = int(similarity * 100)
	gameover_score_label.bbcode_text = "[center][b]%d%%[/b][/center]" % score
	if score >= 75:
		gameover_message_label.bbcode_text = "[center][b]Close enough![/b][/center]"
	elif score == 69:
		gameover_message_label.bbcode_text = "[center][b]nice[/b][/center]"
	elif score >= 40:
		gameover_message_label.bbcode_text = "[center][b]You can do better![/b][/center]"
	else:
		gameover_message_label.bbcode_text = "[center][b]Well that's a bit sad[/b][/center]"
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

func scan_level() -> float:
	final_scan = scan_aabb(level_playable_area)
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
				mean_diff += abs(point_final - point_ref)
				cell_count += 1
	mean_diff /= cell_count
	var similarity = 1.0 - ((1.0 - mean_diff) * (1.0 - mean_diff))
	return similarity

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
