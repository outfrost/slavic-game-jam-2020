extends RigidBody

export var velocity_max_angular = 2
export var velocity_max_linear = 30
export var velocity_linear_acceleration = 20
var player_model: Spatial
var debug_label: Label

var charge: float = 0.5

# Called when the node enters the scene tree for the first time.
func _ready():
	debug_label = get_tree().root.find_node("DebugLabel", true, false)
	player_model = self.get_node('PlayerModel') as Spatial

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
	if debug_label:
		debug_label.text = String(charge)

func add_charge(amount: float):
	charge += amount
	charge = clamp(charge, 0.0, 1.0)
