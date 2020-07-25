extends Spatial

#const RobotClass = preload("res://functional/Robot.gd")

export var playable_area_bounds: AABB = AABB(Vector3(0,0,0), Vector3(500, 500, 150))
export var time_limit: float = 90.0

#var Robot: RobotClass
#var Chargers: Array

func _ready():
	#Chargers = self.get_node("Chargers").get_children()
	#if !Robot:
	#	Robot = RobotClass.new()
	#	#TODO: spwn on random charger
	#	Robot.transform.origin = Chargers[0].transform.origin
	pass # Replace with function body.

