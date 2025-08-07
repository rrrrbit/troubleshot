extends RigidBody2D

var physState : PhysicsDirectBodyState2D
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _integrate_forces(state):
	physState = state
	
func get_all_collision_normals() -> PackedVector2Array:
	var arr : PackedVector2Array = []
	if physState != null:
		for i in physState.get_contact_count():
			arr.append(physState.get_contact_local_normal(i))
	return arr

func get_all_collision_points() -> PackedVector2Array:
	var arr : PackedVector2Array = []
	if physState != null:
		for i in physState.get_contact_count():
			arr.append(physState.get_contact_local_position(i))
	return arr
