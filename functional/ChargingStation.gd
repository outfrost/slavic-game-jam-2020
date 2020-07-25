extends Area

const Robot = preload("res://functional/Robot.gd")

export var max_charging_speed: float = 0.05

var material: SpatialMaterial; # debug shit

var robot: Robot
var docked: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	material = (get_node("MeshInstance").mesh as CubeMesh).material
	if material == null:
		material = SpatialMaterial.new()
		(get_node("MeshInstance").mesh as CubeMesh).material = material
	robot = get_tree().root.find_node("Robot", true, false)
	connect("body_entered", self, "on_body_entered_dock")
	connect("body_exited", self, "on_body_exited_dock")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if docked:
		robot.add_charge(max_charging_speed * delta)

func on_body_entered_dock(body):
	if body == robot:
		docked = true
	material.albedo_color.g = 0.0
	material.albedo_color.b = 0.0

func on_body_exited_dock(body):
	if body == robot:
		docked = false
	material.albedo_color.g = 1.0
	material.albedo_color.b = 1.0
