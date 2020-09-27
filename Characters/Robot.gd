class_name Robot
extends RigidBody

signal battery_depleted()

export var velocity_max_angular: float = 2
export var velocity_max_linear: float = 30
export var velocity_linear_acceleration: float = 20
export var charge: float = 0.5
export var discharge_rate: float = -0.025
export var grab_radius: float = 2.0
export var max_engine_sound_db: float = 30
export var min_engine_sound_db: float = 0
export var visualize_item_selection = true

export var indicator_lit: Material
export var indicator_unlit: Material

export var player_model_path: NodePath
export var grab_anchor_path: NodePath
export var grab_joint_path: NodePath
export var sound_battery_low_path: NodePath
export var sound_grab_path: NodePath
export var sound_engine_path: NodePath
export var sound_pull_path: NodePath
export var sound_push_path: NodePath
export var sound_turning_on_path: NodePath
export var sound_turning_off_path: NodePath

onready var player_model: Spatial = get_node(player_model_path)
onready var grab_anchor: RigidBody = get_node(grab_anchor_path)
onready var grab_joint: Joint = get_node(grab_joint_path)
onready var sound_battery_low: AudioStreamPlayer3D = get_node(sound_battery_low_path)
onready var sound_grab: AudioStreamPlayer3D = get_node(sound_grab_path)
onready var sound_engine: AudioStreamPlayer3D = get_node(sound_engine_path)
onready var sound_pull: AudioStreamPlayer3D = get_node(sound_pull_path)
onready var sound_push: AudioStreamPlayer3D = get_node(sound_push_path)
onready var sound_turning_on: AudioStreamPlayer3D = get_node(sound_turning_on_path)
onready var sound_turning_off: AudioStreamPlayer3D = get_node(sound_turning_off_path)

onready var items_container = get_tree().root.find_node("Items", true, false)

var body_mesh: Mesh
var indicator_lookup = {}

var working: bool = false
var level_items: Array
var item_to_grab: RigidBody
var grabbed_item: RigidBody = null

func _ready():
	connect("battery_depleted", get_tree().root.find_node("Game", true, false), "game_over", ["battery"])

	sound_turning_on.play()
	sound_engine.play()

	# Clone the body mesh, because otherwise we end up modifying
	# the actual mesh asset in memory
	var mesh_instance: MeshInstance = player_model.get_node("Char1_Body/Body2")
	body_mesh = mesh_instance.mesh.duplicate()
	mesh_instance.mesh = body_mesh
	# Generate lookup table for charge indicator surface indices for materials
	for i in range(0, body_mesh.get_surface_count()):
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

	if items_container:
		level_items = items_container.get_children()
	else:
		printerr("No Items container found in level")

func _physics_process(delta):
	if !working:
		return
	var acceleration = velocity_linear_acceleration
	if grabbed_item:
		acceleration = acceleration * 5
	var velocity_abs = self.linear_velocity.length()
	var rotation_angle = 0
	if Input.is_action_pressed("turn_left") and self.angular_velocity.y < 1 * velocity_max_angular:
		rotation_angle += 1 * delta
	if Input.is_action_pressed("turn_right") and self.angular_velocity.y > -1 * velocity_max_angular:
		rotation_angle -= 1 * delta
	player_model.rotate_y(rotation_angle)
	var rotataion = player_model.transform.basis.get_euler().y
	if velocity_abs < velocity_max_linear || grabbed_item:
		var central_force = Vector3(0,0,0)
		if Input.is_action_pressed("move_forwards"):
			central_force += Vector3(0, 0, 1 * velocity_linear_acceleration).rotated(Vector3(0,1,0), rotataion)
		if Input.is_action_pressed("move_backwards"):
			central_force += Vector3(0, 0, -1 * velocity_linear_acceleration).rotated(Vector3(0,1,0), rotataion)
		self.add_central_force(central_force)
		if grabbed_item:
			grabbed_item.add_central_force(central_force)
	if Input.is_action_pressed("debug_reset"):
		self.angular_velocity = Vector3(0,0,0)
		self.linear_velocity = Vector3(0,0,0)
		self.transform = Transform.IDENTITY
		charge = 0.5
		player_model.rotation.y = 0

	sound_engine.unit_db = lerp(min_engine_sound_db, max_engine_sound_db, velocity_abs/velocity_max_linear)

	# Scan for potential items to grab
	if !grabbed_item:
		if visualize_item_selection && item_to_grab:
			paint_object(item_to_grab, Color(1,1,1,0))
		item_to_grab = null

		var min_distance: float = grab_radius
		var grab_joint_pos = grab_joint.global_transform.origin

		for item in level_items:
			var grab_points_container = item.get_node("GrabPoints")
			if !grab_points_container or !grab_points_container.get_child_count():
				continue
			var item_grab_points = grab_points_container.get_children()
			for item_grab_point in item_grab_points:
				var dist = grab_joint_pos.distance_to(item_grab_point.global_transform.origin)
				if dist < min_distance:
					item_to_grab = item
					min_distance = dist

		if visualize_item_selection && item_to_grab:
			paint_object(item_to_grab, Color(0,0,1,0.5))

	# Lifting the carried item
	# TODO actually lift, because it's locked by the joint now
	# TODO teleport item up/down when robot moves arm up/down
	if grabbed_item && Input.is_action_pressed("jump_button"):
		grabbed_item.add_central_force(Vector3(0, 15, 0))

	if Input.is_action_just_pressed("arm_grab_toggle"):
		if grabbed_item:
			grab_joint.set_node_a(@"")
			grab_joint.set_node_b(@"")
			grabbed_item.gravity_scale = 1.0
			if visualize_item_selection:
				paint_object(grabbed_item, Color(1,1,1,0))
			grabbed_item = null
		elif item_to_grab:
			grabbed_item = item_to_grab
			item_to_grab = null
			grabbed_item.set_sleeping(false)
			grab_joint.set_node_a(grab_anchor.get_path())
			grab_joint.set_node_b(grabbed_item.get_path())
			grabbed_item.gravity_scale = 0.0
			if visualize_item_selection:
				paint_object(grabbed_item, Color(0,1,0,0.5))
			sound_grab.play()

func _process(delta):
	if !working:
		return
	add_charge(discharge_rate * delta)
	DebugLabel.display(self, "charge %f" % charge)
	if charge < 0.2:
		if !sound_battery_low.playing:
			sound_battery_low.play()
	if charge == 0.0:
		emit_signal("battery_depleted")
		if !sound_turning_off.playing:
			sound_turning_off.play()

	if indicator_lookup.empty():
		return
	for i in range(0, 6):
		if (charge >= (i + 0.5) / 6.0):
			body_mesh.surface_set_material(indicator_lookup[i], indicator_lit)
		else:
			body_mesh.surface_set_material(indicator_lookup[i], indicator_unlit)

func paint_object(object, color):
	var model = object.find_node("*Model")
	if !model:
		return
	for model_part in model.get_children():
		if model_part is MeshInstance and model_part.mesh:
			var material = model_part.get_surface_material(0)
			if material == null:
				material = SpatialMaterial.new()
				model_part.set_surface_material(0, material)
			material.albedo_color = color

func add_charge(amount: float):
	charge += amount
	charge = clamp(charge, 0.0, 1.0)

func on_game_state_changed(args: Array):
	working = (args[0] == GameState.RUNNING)
