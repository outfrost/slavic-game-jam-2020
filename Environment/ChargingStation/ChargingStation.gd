class_name ChargingStation
extends Area

export var max_charging_speed: float = 0.05
export var charging_falloff_distance: float = 10.0

onready var robot: Robot = get_tree().root.find_node("Robot", true, false)
onready var sound_nearby_charging: AudioStreamPlayer3D = get_node("Sounds/NearbyCharging")
onready var sound_station_charging: AudioStreamPlayer3D = get_node("Sounds/StationCharging")
onready var sound_station_docking: AudioStreamPlayer3D =get_node("Sounds/StationDocking")

var docked: bool = false
var working: bool = false

func _ready():
	connect("body_entered", self, "on_body_entered")
	connect("body_exited", self, "on_body_exited")

func _process(delta):
	if !working:
		return
	var charging_eff = 0.0
	if docked:
		charging_eff = 1.0
	else:
		var distance = global_transform.origin.distance_to(robot.global_transform.origin)
		charging_eff = clamp(inverse_lerp(charging_falloff_distance, 0.0, distance), 0.0, 1.0)
	DebugLabel.display(self, "charging_eff %f" % charging_eff)
	robot.add_charge(max_charging_speed * charging_eff * delta)

func on_body_entered(body):
	if body == robot:
		docked = true
		if !sound_station_docking.playing:
			sound_station_docking.play()
		if !sound_station_charging.playing:
			yield(get_tree().create_timer(0.5), "timeout")
			sound_station_charging.play()

func on_body_exited(body):
	if body == robot:
		docked = false
		sound_station_charging.stop()

func on_game_state_changed(args: Array):
	working = (args[0] == GameState.RUNNING)
