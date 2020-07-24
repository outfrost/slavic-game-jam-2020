extends RigidBody

var debug_label: Label

var charge: float = 0.5

# Called when the node enters the scene tree for the first time.
func _ready():
	debug_label = get_tree().root.find_node("DebugLabel", true, false)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if debug_label:
		debug_label.text = String(charge)

func add_charge(amount: float):
	charge += amount
	charge = clamp(charge, 0.0, 1.0)
