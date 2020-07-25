extends Area

const util = preload("res://util/util.gd")
const Robot = preload("res://functional/Robot.gd")

export var max_charging_speed: float = 0.05
export var charging_falloff_distance: float = 10.0

var robot: Robot
var docked: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	robot = get_tree().root.find_node("Robot", true, false)
	if !robot:
		printerr("Charging station lost connection to robot :(")
	connect("body_entered", self, "on_body_entered_dock")
	connect("body_exited", self, "on_body_exited_dock")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
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

func on_body_exited_dock(body):
	if body == robot:
		docked = false
