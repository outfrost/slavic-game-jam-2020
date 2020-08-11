const DebugLabel = preload("DebugLabel.gd")

static func display(ref, s):
	var label = ref.get_tree().root.find_node("DebugLabel", true, false) as DebugLabel
	if label:
		label.display(s)
