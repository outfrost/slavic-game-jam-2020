extends Control

signal start_game()

export var play_button: NodePath

func _ready() -> void:
	connect("start_game", get_tree().root.find_node("Game", true, false), "on_start_game")
	get_node(play_button).connect("pressed", self, "on_play_pressed")

func on_play_pressed() -> void:
	emit_signal("start_game")
	hide()
