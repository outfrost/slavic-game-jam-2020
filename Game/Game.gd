class_name Game
extends Node

signal game_over(reason, score)

export var levels: Array

export var level_container_path: NodePath
export var gameover_popup_path: NodePath
export var timer_label_path: NodePath
export var hud_message_label_path: NodePath

onready var level_container: Node = get_node(level_container_path)
onready var timer_label: RichTextLabel = get_node(timer_label_path)
onready var hud_message_label: RichTextLabel = get_node(hud_message_label_path)
onready var time_low_sound: AudioStreamPlayer = get_node(@"Sounds/AlarmSound")

var current_level = 0
var level: Level

var time_left: float
var state = GameState.STARTING
var game_state_msg = GroupMessenger.new(
	self, "game_state_changed", ["GameStateObservers"])

func _ready():
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

func on_start_game() -> void:
	spawn_level()

func spawn_level() -> void:
	level = (levels[current_level] as PackedScene).instance()
	level_container.add_child(level)

	time_left = level.time_limit

	if time_low_sound and time_low_sound.playing:
		time_low_sound.stop()

	hud_message_label.show()
	yield(get_tree().create_timer(level.freeze_time), "timeout")
	hud_message_label.hide()

	update_state(GameState.RUNNING)

func game_over(reason):
	update_state(GameState.OVER)
	var similarity = level.scan_level()
	var score = int(similarity * 100)
	emit_signal("game_over", reason, score)

func on_next_level():
	remove_level()
	current_level = (current_level + 1) % levels.size()
	update_state(GameState.STARTING)
	call_deferred("spawn_level")

func remove_level():
	for node in level_container.get_children():
		level_container.remove_child(node)
		(node as Node).queue_free()

func update_state(state: int):
	self.state = state
	game_state_msg.dispatch([state])
