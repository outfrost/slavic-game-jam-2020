extends Spatial

const Level = preload("res://Levels/Level.gd")

var current_level = 0
var current_camera = 0
var dev_cameras: Array

export var Levels: Array

var current_level_container: Node

func SpawnLevel() -> void:
	var level_instance: Level = (Levels[current_level] as PackedScene).instance()
	current_level_container.add_child(level_instance)

func _ready():
	dev_cameras = self.get_node("devCameras").get_children()
	dev_cameras[current_camera].make_current()
	current_level_container = self.get_node("CurrentLevel")
	SpawnLevel()

func _process(delta):
	if Input.is_action_just_pressed("debug_switch_camera"):
		current_camera = (current_camera + 1) % (dev_cameras.size())
		dev_cameras[current_camera].make_current()
