extends Control

signal start_game()

export var play_button: NodePath
export var quit_button: NodePath

func _ready() -> void:
	connect("start_game", get_tree().root.find_node("Game", true, false), "on_start_game")
	get_node(play_button).connect("pressed", self, "on_play_pressed")
	get_node(quit_button).connect("pressed", self, "on_quit_pressed")

func on_play_pressed() -> void:
	emit_signal("start_game")
	hide()

func on_quit_pressed() -> void:
	get_tree().quit()
