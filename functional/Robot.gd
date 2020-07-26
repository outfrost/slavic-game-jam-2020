extends RigidBody

const util = preload("res://util/util.gd")

const indicator_lit = preload("res://Assets/Characters/indicator_lit.tres")
const indicator_unlit = preload("res://Assets/Characters/indicator_unlit.tres")

const grab_radius = 1.5
const debug_visualize_item_selection = true
const debug_visualize_grab_point_selection = true
var pinjoint: PinJoint

var grab_target_body: RigidBody
var grabbed_item
var is_carrying_item: bool

signal battery_depleted()

export var velocity_max_angular = 2
export var velocity_max_linear = 30
export var velocity_linear_acceleration = 20
export var charge: float = 0.5
export var discharge_rate: float = -0.025

var player_model: Spatial
var body_mesh: Mesh
var indicator_lookup = {}

var grab_point: Position3D

var working: bool = true

func paint_object(object, color):
	var model = object.find_node("*Model")
	for model_part in model.get_children():
		if model_part is MeshInstance and model_part.mesh:
			var material
			if material == null:
				material = SpatialMaterial.new()
				model_part.set_surface_material(0, material)
			material.albedo_color = color
	pass

# Called when the node enters the scene tree for the first time.
func _ready():
	player_model = self.get_node('PlayerModel') as Spatial
	grab_point = player_model.find_node("GrabPoint") as Position3D
	pinjoint = self.get_parent().find_node("PinJoint") as PinJoint
	pinjoint.set_param(PinJoint.PARAM_BIAS, 1)
	pinjoint.set_param(PinJoint.PARAM_DAMPING, 1.5)
	pinjoint.set_param(PinJoint.PARAM_IMPULSE_CLAMP, 0)
	# TODO: spawn it or move to Game scene to make sure it appears on every level
	grab_target_body = self.get_parent().get_node("GrabTarget")
	if !grab_target_body:
		print("!!!!")
	
	# Lookup table for charge indicator surface indices for materials
	var mesh_instance = player_model.get_node("Char1_Body/Body2") as MeshInstance
	body_mesh = mesh_instance.mesh.duplicate()
	mesh_instance.mesh = body_mesh
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

func _physics_process(delta):
	if !working:
		return
	var acceleration = velocity_linear_acceleration
	if(is_carrying_item):
		acceleration = acceleration * 5
	var velocity_abs = self.linear_velocity.length()
	var rotation_angle = 0
	if Input.is_action_pressed("turn_left") and self.angular_velocity.y < 1 * velocity_max_angular:
		rotation_angle += 1 * delta
	if Input.is_action_pressed("turn_right") and self.angular_velocity.y > -1 * velocity_max_angular:
		rotation_angle -= 1 * delta
	player_model.rotate_y(rotation_angle)
	#if is_carrying_item:
	#	(grabbed_item.item as RigidBody).rotate_y(rotation_angle)
	var rotataion = player_model.transform.basis.get_euler().y
	if velocity_abs < velocity_max_linear or is_carrying_item:
		var central_force = Vector3(0,0,0)
		if Input.is_action_pressed("move_forwards"):
			central_force += Vector3(0, 0, 1 * velocity_linear_acceleration).rotated(Vector3(0,1,0), rotataion)
		if Input.is_action_pressed("move_backwards"):
			central_force += Vector3(0, 0, -1 * velocity_linear_acceleration).rotated(Vector3(0,1,0), rotataion)
		self.add_central_force(central_force)
		#if is_carrying_item:
		#	grabbed_item.item.add_central_force(central_force)
	if Input.is_action_pressed("debug_reset"):
		self.angular_velocity = Vector3(0,0,0)
		self.linear_velocity = Vector3(0,0,0)
		self.transform = Transform.IDENTITY
		charge = 0.5
		player_model.rotation.y = 0
	
	var test_visual_thing = self.get_parent().find_node("TestThing") as Spatial
	var grab_point_pos = grab_point.global_transform.origin
	if(debug_visualize_grab_point_selection):
		test_visual_thing.transform = Transform.IDENTITY
		test_visual_thing.translate(grab_point_pos)
	grab_target_body.transform = Transform.IDENTITY
	grab_target_body.translate(grab_point_pos)
	
	# TODO: teleport item up/down when robot moves arm up/down
	var level_items = self.get_parent().get_node("Items").get_children()
	
	var items_matched = []
	var distance_min = grab_radius
	for item in level_items:
		var grab_points_container = item.get_node("GrabPoints")
		if(!grab_points_container or !grab_points_container.get_child_count()):
			continue
		var item_grab_points = grab_points_container.get_children()
		for item_grab_point in item_grab_points:
			var dist = (item_grab_point.global_transform.origin - grab_point_pos).length()
			if(dist < grab_radius):
				items_matched.push_back({"distance": dist, "item": item, "gp": item_grab_point})
				distance_min = min(distance_min, dist)
	var item_data = null
	for item_canditate in items_matched:
		if(item_canditate.distance == distance_min):
			item_data = item_canditate
			if(debug_visualize_grab_point_selection):
				test_visual_thing.transform = Transform.IDENTITY
				test_visual_thing.translate(item_canditate.gp.global_transform.origin)
			break
	if !is_carrying_item:
		if item_data:
			grabbed_item = item_data
		if debug_visualize_item_selection:
			for item in level_items:
				paint_object(item, Color(1,1,1,0))
			if item_data:
				paint_object(item_data.item, Color(0,0,1,0.5))
	
	pinjoint.transform = Transform.IDENTITY
	pinjoint.translate(grab_point.global_transform.origin)
	
	if is_carrying_item and Input.is_action_pressed("jump_button"):
		(grabbed_item.item as RigidBody).add_central_force(Vector3(0, 15, 0))
	if Input.is_action_just_pressed("arm_grab_toggle"):
		is_carrying_item = grabbed_item and !is_carrying_item
		if(is_carrying_item):
			grabbed_item.item.set_sleeping(false)
			if Input.is_action_pressed("jump_button"):
				(grabbed_item.item as RigidBody).add_central_force(Vector3(0, 5, 0))
			paint_object(grabbed_item.item, Color(0,1,0,0.5))
			pinjoint.set_node_a(grabbed_item.item.get_path())
			pinjoint.set_node_b(grab_target_body.get_path())
		else:
			pinjoint.set_node_a("")
			pinjoint.set_node_b("")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !working:
		return
	add_charge(discharge_rate * delta)
	util.display(self, "charge %f" % charge)
	if charge == 0.0:
		emit_signal("battery_depleted")

	if indicator_lookup.empty():
		return
	for i in range(0, 6):
		if (charge >= (i + 0.5) / 6.0):
			body_mesh.surface_set_material(indicator_lookup[i], indicator_lit)
		else:
			body_mesh.surface_set_material(indicator_lookup[i], indicator_unlit)

func add_charge(amount: float):
	charge += amount
	charge = clamp(charge, 0.0, 1.0)

func on_game_over():
	working = false
