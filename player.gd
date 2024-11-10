extends CharacterBody2D

#todo:
#have walldash manually release movement key
#optimise logic

const JUMP_TIME=0.6
const JUMP_HEIGHT=150

const MAXSPEED = 1000

const ACCEL = 2000
const DRAG = 5000
const AIRDRAG = 500

const DASHVEL = 1000

# Get the gravity from the project settings to be synced with RigidBody nodes.
var JUMPVEL = -4*JUMP_HEIGHT/JUMP_TIME
var gravity = 8 / JUMP_TIME / JUMP_TIME * JUMP_HEIGHT#ProjectSettings.get_setting("physics/2d/default_gravity")
var wallcling=false

var prevWallcling=false

var justJumped = false

func _physics_process(delta):
	var lastCollisionExists = get_last_slide_collision() != null
	var wallDir

	if lastCollisionExists and not is_on_floor() and is_on_wall():
		wallDir = ceil(get_last_slide_collision().get_normal().x)
		wallcling= -wallDir==Input.get_axis("-x","+x")
		if wallcling:
			if !prevWallcling:
				justJumped = true
				velocity.y =0
				
	if Input.is_action_just_pressed("d"):
		if wallcling:
			velocity += Vector2(DASHVEL*1.25* -Input.get_axis("-x","+x"), JUMPVEL)
		elif not is_on_floor():
			velocity.x += DASHVEL*Input.get_axis("-x","+x")
			match Input.get_axis("-y","+y"):
				1.:
					velocity.y = DASHVEL*-1.25
				0.:
					velocity.y = 0
				-1.:
					velocity.y = DASHVEL*1.25
			justJumped = false
		else: 
			velocity.x += DASHVEL*Input.get_axis("-x","+x")

	if not is_on_floor():
		if is_on_wall() and wallcling:
			velocity.y += gravity / 5 * delta
		else:
			velocity.y += gravity * delta
	else:
		justJumped = true
	
	if not is_on_wall() or is_on_floor():
		wallcling = false

	# Handle jump.
	if Input.is_action_pressed("+y") and (is_on_floor() or wallcling):
		if wallcling and lastCollisionExists:
			velocity.x = MAXSPEED*wallDir
		velocity.y = JUMPVEL

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("-x","+x")
	if direction and abs(velocity.x)<=MAXSPEED:
		velocity.x += ACCEL * direction * delta
		if sign(direction) != sign(velocity.x):
			velocity.x = move_toward(velocity.x,0,DRAG*delta)
	elif is_on_floor():
		velocity.x = move_toward(velocity.x,0,DRAG*delta)
	else:
		velocity.x = move_toward(velocity.x,0,AIRDRAG*delta)
	print(round(velocity))
	
	prevWallcling = wallcling
	move_and_slide()
