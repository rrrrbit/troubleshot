extends CharacterBody2D

#todo:
#add wallcling release coyote time.
#add dash.
#optimise logic

const JUMP_TIME=0.6
const JUMP_HEIGHT=150

const SPEED = 1000
const X_ACCEL_LERP=10.**-3
const X_DECEL_LERP=10.**-5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var JUMP_VELOCITY = -4*JUMP_HEIGHT/JUMP_TIME
var gravity = 8 / JUMP_TIME / JUMP_TIME * JUMP_HEIGHT#ProjectSettings.get_setting("physics/2d/default_gravity")
var wallcling=false

var prevWallcling=false

func _physics_process(delta):
	var lastCollisionExists = get_last_slide_collision() != null
	var wallDir
	if lastCollisionExists:
		wallDir = ceil(get_last_slide_collision().get_normal().x)
	if not is_on_floor():
		if lastCollisionExists:
			wallcling= -wallDir==Input.get_axis("-x","+x")
			if wallcling and !prevWallcling and is_on_wall():
				velocity.y =0
		if is_on_wall() and wallcling:
			velocity.y += gravity / 5 * delta
		else:
			velocity.y += gravity * delta
	
	if not is_on_wall() or is_on_floor():
		wallcling = false

	# Handle jump.
	if Input.is_action_pressed("+y") and (is_on_floor() or wallcling):
		if wallcling and lastCollisionExists:
			velocity.x = SPEED*2*wallDir
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("-x","+x")
	if direction:
		velocity.x = lerp(velocity.x, direction*SPEED, 1 - X_ACCEL_LERP**delta)
	else:
		velocity.x = lerp(velocity.x, 0., 1 - X_DECEL_LERP**delta)
	prevWallcling = wallcling
	move_and_slide()
