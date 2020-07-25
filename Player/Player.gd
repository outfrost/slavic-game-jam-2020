extends RigidBody


var current_camera = 0
const cameras = ['../CameraPerspective', '../CameraDebugTop', '../CameraDebugSide']
export var velocity_max_angular = 2
export var velocity_max_linear = 30
export var velocity_linear_acceleration = 20
var PlayerModel: Spatial

func _ready():
	self.get_node(cameras[current_camera]).make_current()
	PlayerModel = self.get_node('PlayerModel') as Spatial

func _physics_process(delta):
	var velocity_abs = self.linear_velocity.length()
	print(velocity_abs)
	if Input.is_action_pressed("turn_left") and self.angular_velocity.y < 1 * velocity_max_angular:
		PlayerModel.rotate_y(1 * delta)
	if Input.is_action_pressed("turn_right") and self.angular_velocity.y > -1 * velocity_max_angular:
		PlayerModel.rotate_y(-1 * delta)
	var rotataion = PlayerModel.transform.basis.get_euler().y
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
	if Input.is_action_just_pressed("debug_switch_camera"):
		current_camera = (current_camera + 1) % (cameras.size())
		self.get_node(cameras[current_camera]).make_current()


