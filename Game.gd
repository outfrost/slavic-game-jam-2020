extends Spatial

const util = preload("res://util/util.gd")
const Level = preload("res://Levels/Level.gd")

var current_level = 0
var current_camera = 0
var dev_cameras: Array
var camera_perspective: Camera
var cam_pers_offset: Vector3
var robot: Spatial
var level_dimension_squared: float

export var Levels: Array

var current_level_container: Node

func SpawnLevel() -> void:
	for node in current_level_container.get_children():
		current_level_container.remove_child(node)
	var level_instance = (Levels[current_level] as PackedScene).instance()
	current_level_container.add_child(level_instance)
	var level_dimension = level_instance.playable_area_bounds.get_longest_axis_size()
	level_dimension_squared = level_dimension * level_dimension

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
