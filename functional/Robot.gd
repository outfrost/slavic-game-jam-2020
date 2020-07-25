extends RigidBody

const util = preload("res://util/util.gd")

const indicator_lit = preload("res://Assets/Characters/indicator_lit.tres")
const indicator_unlit = preload("res://Assets/Characters/indicator_unlit.tres")

export var velocity_max_angular = 2
export var velocity_max_linear = 30
export var velocity_linear_acceleration = 20
export var charge: float = 0.5

var player_model: Spatial
var body_mesh: Mesh
var indicator_lookup = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	player_model = self.get_node('PlayerModel') as Spatial
	
	# Lookup table for charge indicator surface indices for materials
	body_mesh = (player_model.get_node("Char1_Body/Body2") as MeshInstance).mesh
	for i in range(0, body_mesh.get_surface_count()):
		print(body_mesh.surface_get_material(i).resource_name)
		match body_mesh.surface_get_material(i).resource_name:
			"Charge Indicator":
				indicator_lookup[0] = i
			"Charge Indicator 2":
				indicator_lookup[1] = i
			"Charge Indicator 3":
				indicator_lookup[2] = i
			"Charge Indicator 4":
				indicator_lookup[3] = i
			"Charge Indicator 5":
				indicator_lookup[4] = i
			"Charge indicator 6":
				indicator_lookup[5] = i

func _physics_process(delta):
	var velocity_abs = self.linear_velocity.length()
	if Input.is_action_pressed("turn_left") and self.angular_velocity.y < 1 * velocity_max_angular:
		player_model.rotate_y(1 * delta)
	if Input.is_action_pressed("turn_right") and self.angular_velocity.y > -1 * velocity_max_angular:
		player_model.rotate_y(-1 * delta)
	var rotataion = player_model.transform.basis.get_euler().y
	if velocity_abs < velocity_max_linear:
		if Input.is_action_pressed("move_forwards"):
			self.add_central_force(Vector3(0, 0, 1 * velocity_linear_acceleration).rotated(Vector3(0,1,0), rotataion))
		if Input.is_action_pressed("move_backwards"):
			self.add_central_force(Vector3(0, 0, -1 * velocity_linear_acceleration).rotated(Vector3(0,1,0), rotataion))
	if Input.is_action_pressed("debug_reset"):
		self.angular_velocity = Vector3(0,0,0)
		self.linear_velocity = Vector3(0,0,0)
		self.transform = Transform.IDENTITY
		self.transform.origin.y = 5.585


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	util.display(self, "charge %f" % charge)
	for i in range(0, 6):
		if (charge >= (i + 0.5) / 6.0):
			body_mesh.surface_set_material(indicator_lookup[i], indicator_lit)
		else:
			body_mesh.surface_set_material(indicator_lookup[i], indicator_unlit)

func add_charge(amount: float):
	charge += amount
	charge = clamp(charge, 0.0, 1.0)
