extends Node

export var level_path: NodePath
export var main_camera_path: NodePath
export var clean_room_camera_path: NodePath
export var robot_path: NodePath

onready var cameras: Array = get_children()
onready var main_camera: Camera = get_node(main_camera_path)
onready var robot: Spatial = get_node(robot_path)
onready var main_camera_offset: Vector3 = main_camera.transform.origin

var current_camera: int = 0
var level_dimension_squared: float

func _ready() -> void:
	set_camera(get_node(clean_room_camera_path).get_position_in_parent())

	var level: Level = get_node(level_path)
	var level_dimension = level.playable_area_bounds.get_longest_axis_size()
	level_dimension_squared = level_dimension * level_dimension

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("debug_switch_camera"):
		set_camera((current_camera + 1) % cameras.size())

	var displacement = robot.global_transform.origin
	var min_displacement = displacement * 0.25
	var distance_squared = displacement.length_squared()
	# t = 1 / ( 4 * dist^2 / level_dim^2 + 1) from 0 to 1
	var t = clamp(1.0 / ((4.0 * distance_squared / level_dimension_squared) + 1.0), 0.0, 1.0)
	var camera_origin = min_displacement.linear_interpolate(displacement, t)
	# Camera follows at an offset to see player more or less in the middle of the screen
	camera_origin += main_camera_offset
	main_camera.translation = camera_origin

func set_camera(index) -> void:
	current_camera = index
	cameras[current_camera].make_current()

func on_game_state_changed(args: Array):
	if args[0] == GameState.RUNNING:
		set_camera(main_camera.get_position_in_parent())
