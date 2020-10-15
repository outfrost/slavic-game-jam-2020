extends Popup

signal next_level

export var gameover_message_label: NodePath
export var gameover_score_label: NodePath
export var gameover_reason_label: NodePath
export var restart_button: NodePath

func _ready():
	get_node(restart_button).connect("pressed", self, "on_restart_pressed")

func on_game_state_changed(args: Array):
	if args[0] != GameState.OVER:
		hide()

func on_game_over(reason: String, score: int):
	var reason_text: String
	if reason == "battery":
		reason_text = "You ran out of battery!"
	elif reason == "time":
		reason_text = "Time's up!"

	var message_text: String
	if score >= 75:
		message_text = "Close enough!"
	elif score == 69:
		message_text = "nice"
	elif score >= 40:
		message_text = "You can do better!"
	else:
		message_text = "Well that's a bit sad"

	get_node(gameover_reason_label).bbcode_text = "[center][b]%s[/b][/center]" % reason_text
	get_node(gameover_score_label).bbcode_text = "[center][b]Score: %d%%[/b][/center]" % score
	get_node(gameover_message_label).bbcode_text = "[center][b]%s[/b][/center]" % message_text
	show()

func on_restart_pressed():
	emit_signal("next_level")
