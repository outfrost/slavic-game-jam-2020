extends Area

const Robot = preload("res://functional/Robot.gd")

export var max_charging_speed: float = 0.05

var material: SpatialMaterial;

var docked_robot: Robot;

# Called when the node enters the scene tree for the first time.
func _ready():
	material = (get_node("MeshInstance").mesh as CubeMesh).material
	if material == null:
		material = SpatialMaterial.new()
		(get_node("MeshInstance").mesh as CubeMesh).material = material
	connect("body_entered", self, "on_body_entered_dock")
	connect("body_exited", self, "on_body_exited_dock")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if docked_robot:
		docked_robot.add_charge(max_charging_speed * delta)

func on_body_entered_dock(body):
	if body is Robot:
		docked_robot = body
	material.albedo_color.g = 0.0
	material.albedo_color.b = 0.0

func on_body_exited_dock(body):
	if body == docked_robot:
		docked_robot = null
	material.albedo_color.g = 1.0
	material.albedo_color.b = 1.0
