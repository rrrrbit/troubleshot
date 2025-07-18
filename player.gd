extends CharacterBody2D

#todo:
#optimise logic
#complete implementation of short dash 

const JUMP_TIME=0.6
const JUMP_HEIGHT=150

const MAXSPEED = 1250

const ACCEL = 3000
const DRAG = 4500
const AIRDRAG = 300

const DASHVEL = 2500

const DASHTIME = 0.1
#git test
# Get the gravity from the project settings to be synced with RigidBody nodes.
var JUMPVEL = -4*JUMP_HEIGHT/JUMP_TIME

var gravity = 8 / JUMP_TIME / JUMP_TIME * JUMP_HEIGHT#ProjectSettings.get_setting("physics/2d/default_gravity")

var direction = Vector2(0,0)

var dashing = false
var hasDBounced=false

var lastVel = Vector2.ZERO

func Dash(v):
	var lastVel  =velocity
	velocity = v
	dashing = true
	hasDBounced = false
	await GLOBAL.Wait(DASHTIME)
	if not hasDBounced:
		velocity = lastVel
	dashing = false
	hasDBounced = false

func _init():
	pass

func _process(delta):
	direction = Vector2(Input.get_axis("-x","+x"),-Input.get_axis("-y","+y"))
	
	$Trail.global_position = Vector2(0,0)
	$Trail.add_point(position,0)
	$Trail.remove_point(100)
	
	$Camera2D/debugText.text = ("vel: " + 
	str(round(velocity.x)) + ", " +
	str(round(velocity.y))+ " normalised: " + 
	str(round(velocity.length())))

func _physics_process(delta):
	
	
	var lastCollisionExists = get_last_slide_collision() != null
				
	if dashing:
		if lastCollisionExists:
			velocity = lastVel.bounce(get_last_slide_collision().get_normal())*0.7
			print("has dbounced")
			hasDBounced = true
				
	if Input.is_action_just_pressed("d") and not direction.is_zero_approx():
		if not is_on_floor():
			velocity.y=0
			Dash(direction.normalized()*DASHVEL)
		else: 
			Dash(Vector2(DASHVEL* direction.x,0))
	# gravity
	if not is_on_floor() and not dashing:
		velocity.y += gravity * delta

	# jump
	if Input.is_action_pressed("+y") and is_on_floor():
		velocity.y = JUMPVEL

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	if not dashing:
		if direction.x and abs(velocity.x)<=MAXSPEED:
			velocity.x += ACCEL * direction.x * delta
			if sign(direction.x) != sign(velocity.x):
				velocity.x = move_toward(velocity.x,0,DRAG*delta)
		elif is_on_floor():
			velocity.x = move_toward(velocity.x,0,DRAG*delta)
		else:
			velocity.x = move_toward(velocity.x,0,AIRDRAG*delta)
	
	lastVel = velocity
	move_and_slide()
