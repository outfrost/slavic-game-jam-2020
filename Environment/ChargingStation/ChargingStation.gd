extends Area

const util = preload("res://Game/UI/util.gd")
const Game = preload("res://Game/Game.gd")
const Robot = preload("res://Characters/Robot.gd")

export var max_charging_speed: float = 0.05
export var charging_falloff_distance: float = 10.0

var robot: Robot
var docked: bool = false

var working: bool = true

var sound_nearby_charging: AudioStreamPlayer3D
var sound_station_charging: AudioStreamPlayer3D
var sound_station_docking: AudioStreamPlayer3D

# Called when the node enters the scene tree for the first time.
func _ready():
	robot = get_tree().root.find_node("Robot", true, false)
	if !robot:
		printerr("Charging station lost connection to robot :(")
	connect("body_entered", self, "on_body_entered_dock")
	connect("body_exited", self, "on_body_exited_dock")
	(get_tree().root.find_node("Game", true, false) as Game).connect("game_over", self, "on_game_over")
	
	sound_nearby_charging = self.get_node("Sounds/NearbyCharging")
	sound_station_charging = self.get_node("Sounds/StationCharging")
	sound_station_docking = self.get_node("Sounds/StationDocking")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !working:
		return
	var charging_eff = 0.0
	if docked:
		charging_eff = 1.0
	else:
		var distance = global_transform.origin.distance_to(robot.global_transform.origin)
		charging_eff = clamp(inverse_lerp(charging_falloff_distance, 0.0, distance), 0.0, 1.0)
	util.display(self, "charging_eff %f" % charging_eff)
	robot.add_charge(max_charging_speed * charging_eff * delta)

func on_body_entered_dock(body):
	if body == robot:
		docked = true
		if !sound_station_docking.playing:
			sound_station_docking.play()
		if !sound_station_charging.playing:
			sound_station_charging.play()
		

func on_body_exited_dock(body):
	if body == robot:
		docked = false
		sound_station_charging.stop()

func on_game_over():
	working = false
