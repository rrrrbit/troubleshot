extends CharacterBody2D

const JUMP_TIME = 0.6
const JUMP_HEIGHT = 160
const MAX_SPEED = 1250
const ACCEL = 3000
const DRAG = 4500
const AIR_DRAG = 300
const SLIDE_DRAG = 500

const WALLCLING_VERTICAL_DRAG = 7.5

const DASH_VEL = 2500
const DASH_TIME = 0.125

var JUMP_VEL : float = -4 * JUMP_HEIGHT / JUMP_TIME # derived from the parabola given by jump time and height
var GRAVITY : float = 8 / JUMP_TIME / JUMP_TIME * JUMP_HEIGHT

var direction := Vector2.ZERO
var lastVel := Vector2.ZERO
var lastDashVel := Vector2.ZERO

var dashing := false
var hasDBounced := false

var wallcling := false
var ceilingcling := false

var jumpsLeft := 2

func _init():
	pass

func _process(delta):
	direction = Vector2(Input.get_axis("-x","+x"),-Input.get_axis("-y","+y"))
	
	
	
	%HUD/debugText.text = ("vel: " + 
	str(round(velocity.x)) + ", " +
	str(round(velocity.y))+ " normalised: " + 
	str(round(velocity.length())) + "\nfps: " + 
	str(Engine.get_frames_per_second()))


func _physics_process(delta):
	
	var lastColNormal := Vector2.ZERO
	if get_last_slide_collision() != null: lastColNormal = get_last_slide_collision().get_normal()
	
	if dashing:
		if lastColNormal.dot(lastVel) < 0:
			velocity = lastVel.bounce(lastColNormal) * (1.0 if hasDBounced else 0.7)
			hasDBounced = true and not (wallcling or ceilingcling)
				
	if Input.is_action_just_pressed("d") and not direction.is_zero_approx():
		if not is_on_floor():
			velocity.y=0
			Dash(direction.normalized() * DASH_VEL)
		else: 
			Dash(Vector2(DASH_VEL * direction.x,0))
	
	wallcling = is_on_wall_only() and lastColNormal.dot(lastVel) < 0
	ceilingcling = is_on_ceiling() and Input.is_action_pressed("+y") and not dashing
	# gravity
	if not is_on_floor() and not dashing:
		velocity.y += GRAVITY * delta

	if wallcling and velocity.y > 0:
		velocity.y -= WALLCLING_VERTICAL_DRAG * velocity.y * delta
	
	if ceilingcling:
		velocity.y = 0
	
	if is_on_floor():
		jumpsLeft = 1
		
	# jump
	
	if Input.is_action_pressed("+y"):
		if is_on_floor():
			velocity.y = JUMP_VEL + (velocity.y if dashing and lastDashVel.x == 0 else 0)
		if wallcling and not (dashing or ceilingcling or direction.x == 0):
			velocity.y = JUMP_VEL * 1.25
			velocity.x = -lastColNormal.x * JUMP_VEL

	if not is_on_floor() and jumpsLeft > 0 and Input.is_action_just_pressed("+y"):
		velocity.y = JUMP_VEL
		jumpsLeft -= 1
	#horizontal mvmt
	if not dashing:
		if direction.x and abs(velocity.x)<=MAX_SPEED:
			velocity.x += ACCEL * direction.x * delta
			if sign(direction.x) != sign(velocity.x):
				velocity.x = move_toward(velocity.x,0,DRAG*delta)
		elif is_on_floor() or ceilingcling:
			if Input.is_action_pressed("-y") and not ceilingcling:
				velocity.x = move_toward(velocity.x,0,SLIDE_DRAG*delta)
			else:
				velocity.x = move_toward(velocity.x,0,DRAG*delta)
		else:
			velocity.x = move_toward(velocity.x,0,AIR_DRAG*delta)
			
	lastVel = velocity
	move_and_slide()
	
	#queue_redraw()

func _draw():
	draw_set_transform_matrix(global_transform.affine_inverse())
	for i in get_slide_collisions():
		draw_line(i.get_position(), i.get_position()+i.get_normal()*25.0, Color.WHITE, -2)
	draw_line(position,position+direction.normalized()*50, Color.RED, -2)
	draw_line(position, position+velocity/10.0, Color.GREEN, -2)

func Dash(v: Vector2):
	var lastVel = velocity
	lastDashVel = v.normalized()
	velocity = v
	dashing = true
	hasDBounced = false
	await GLOBAL.Wait(DASH_TIME)
	
	if not hasDBounced:
		if Input.is_action_pressed("d"):
			#print("long dash")
			velocity -= (velocity - lastVel) * 0.25
		elif velocity.dot(lastVel) < 0:
			#print("short dash reverse stop")
			velocity = v * 0.1
		else:
			print("short dash")
			velocity = lastVel
	else: 
		#print("dbounce")
		pass
	
	dashing = false
	hasDBounced = false

func get_slide_collisions() -> Array[KinematicCollision2D]:
	var array : Array[KinematicCollision2D] = []
	for i in get_slide_collision_count():
		array.append(get_slide_collision(i))
	return array
