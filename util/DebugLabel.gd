extends Label

var buffer: String = ""

func _ready():
	text = ""

func _process(_delta):
	text = buffer
	buffer = ""

func display(s: String):
	buffer += s + "\n"
