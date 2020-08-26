class_name Game
extends Node

signal game_over(reason, score)

export var Levels: Array
export var scan_step: float = 0.25

export var level_container_path: NodePath
export var gameover_popup_path: NodePath
export var timer_label_path: NodePath
export var hud_message_label_path: NodePath

onready var level_container: Node = get_node(level_container_path)
onready var timer_label: RichTextLabel = get_node(timer_label_path)
onready var hud_message_label: RichTextLabel = get_node(hud_message_label_path)
onready var time_low_sound: AudioStreamPlayer = get_node(@"Sounds/AlarmSound")

var current_level = 0
var robot: Robot
var level_playable_area: AABB

var time_left: float

var state = GameState.STARTING
var game_state_msg = GroupMessenger.new(
	self, "game_state_changed", ["GameStateObservers"])

var reference_scan: Array
var final_scan: Array

func _ready():
	SpawnLevel()

	var gameover_popup = get_node(gameover_popup_path)
	connect("game_over", gameover_popup, "on_game_over")
	gameover_popup.connect("next_level", self, "on_next_level")

func _process(delta):
	DebugLabel.display(self, "fps %d" % Performance.get_monitor(Performance.TIME_FPS))

	if state == GameState.RUNNING:
		time_left = max(time_left - delta, 0.0)
		if !time_low_sound.playing and time_left < 11:
			time_low_sound.play()
		timer_label.bbcode_text = "[right][b]%02d:%02d[/b][/right]" % [int(time_left) / 60, int(time_left) % 60]
		if time_left == 0.0:
			game_over("time")

	if Input.is_action_just_pressed("level_next"):
		on_next_level()

func SpawnLevel() -> void:
	var level_instance: Level = (Levels[current_level] as PackedScene).instance()
	level_container.add_child(level_instance)
	level_playable_area = level_instance.playable_area_bounds

	var level_reference_area = level_instance.reference_area_bounds
	reference_scan = scan_aabb(level_reference_area)

	time_left = level_instance.time_limit

	if time_low_sound and time_low_sound.playing:
		time_low_sound.stop()

	robot = get_tree().root.find_node("Robot", true, false)
	if robot:
		robot.connect("battery_depleted", self, "game_over", ["battery"])
	else:
		printerr("No robot found :(")

	hud_message_label.show()
	yield(get_tree().create_timer(level_instance.freeze_time), "timeout")
	hud_message_label.hide()

	update_state(GameState.RUNNING)

func game_over(reason):
	update_state(GameState.OVER)
	var similarity = scan_level()
	var score = int(similarity * 100)
	emit_signal("game_over", reason, score)

func on_next_level():
	remove_level()
	current_level = (current_level + 1) % Levels.size()
	update_state(GameState.STARTING)
	call_deferred("SpawnLevel")
	emit_signal("game_start")

func remove_level():
	for node in level_container.get_children():
		level_container.remove_child(node)
		(node as Node).queue_free()

func update_state(state: int):
	self.state = state
	game_state_msg.dispatch([state])

func scan_level() -> float:
	final_scan = scan_aabb(level_playable_area)
	var mean_diff = 0.0
	var cell_count = 0
	for x in range(0, min(final_scan.size(), reference_scan.size())):
		var plane_final = final_scan[x]
		var plane_ref = reference_scan[x]
		for y in range(0, min(plane_final.size(), plane_ref.size())):
			var line_final = plane_final[y]
			var line_ref = plane_ref[y]
			for z in range(0, min(line_final.size(), line_ref.size())):
				var point_final = line_final[z]
				var point_ref = line_ref[z]
				#if point_final > 0.0:
					#print(point_final)
				#mean_diff += abs(point_final - point_ref)
				if point_final || point_ref:
					mean_diff += float(point_final != point_ref)
					cell_count += 1
	mean_diff /= cell_count
	var similarity = 1.0 - mean_diff * mean_diff
	return similarity

func scan_aabb(aabb: AABB) -> Array:
	var steps_x = int(ceil(aabb.size.x / scan_step))
	var steps_y = int(ceil(aabb.size.y / scan_step))
	var steps_z = int(ceil(aabb.size.z / scan_step))

	var physics_direct_state = get_tree().root.get_world().get_direct_space_state()
	var query = PhysicsShapeQueryParameters.new()
	query.collision_mask = 2 # 0b010
	query.collide_with_areas = true
	query.margin = 0.04
	var shape = BoxShape.new()
	shape.extents = Vector3.ONE * scan_step * 0.5
	query.set_shape(shape)

	var planes = []
	#var max_distance = sqrt(3 * scan_step * scan_step)

	for x in range(0, steps_x):
		var lines = []
		for y in range(0, steps_y):
			var points = []
			for z in range(0, steps_z):
				var pos: Vector3 = shape.extents + Vector3(x * scan_step, y * scan_step, z * scan_step)
				query.transform = Transform.IDENTITY.translated(
					aabb.position + pos)
				var result = physics_direct_state.collide_shape(query)
				#var cell_value = 0.0
				var cell_value: bool = result.size() > 0
#				if cell_value:
#					print("REEE")
#					for p in result:
#						print(p)
#				for point in result:
#					var distance = ((point as Vector3) - pos).length()
#					print("from %s to %s" % [pos, point])
#					#print(inverse_lerp(max_distance, 0.0, distance))
#					var value = clamp(inverse_lerp(max_distance, 0.0, distance), 0.0, 1.0)
#					cell_value = max(cell_value, value)
				points.append(cell_value)
			lines.append(points)
		planes.append(lines)

	return planes


#					var box = MeshInstance.new()
#					var cube_mesh = CubeMesh.new()
#					cube_mesh.size = Vector3.ONE * 0.1
#					box.mesh = cube_mesh
#					box.transform = Transform.IDENTITY.translated(query.transform.origin)
#					add_child(box)
