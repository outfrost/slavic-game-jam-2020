extends RigidBody

func _integrate_forces(_state: PhysicsDirectBodyState) -> void:
	transform = Transform.IDENTITY
