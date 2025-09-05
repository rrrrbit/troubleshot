extends CharacterBody2D
@export var renderGizmos : bool
@export var cursor : Node2D
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
var JUMP_VEL : float = -4 * JUMP_HEIGHT / JUMP_TIME
var GRAVITY : float = 8 / JUMP_TIME / JUMP_TIME * JUMP_HEIGHT
var direction := Vector2.ZERO
var lastVel := Vector2.ZERO
var lastDashVel := Vector2.ZERO
var dashing := false
var hasDBounced := false
var wallcling := false
var jumpsLeft := 2
var surfaceNormal := Vector2.ZERO
var on_floor := false
var dragType := "normal"
var wall := 0

var shader : ShaderMaterial
@export var squishOverVelocity : Curve
@export var skewOverVelocityX : Curve
@export var skewOverVelocityY : Curve

var currentSkew := Vector2.ZERO
var currentSkewAxes := Vector2.ZERO

var currentSquish := 0.0
var currentSquishDir := Vector2.ZERO

var snapSquishDirThisFrame := false

@export var holePosOverCursorPos : Curve
func _ready():
	shader = $Sprite2D.material
	shader.set_shader_parameter("holeSize", 3.0)
	Engine.time_scale = 1

func touching(dir: Vector2):
	return move_and_collide(dir, true) != null

func _process(delta):
	
	direction = Vector2(
		Input.get_axis("-x","+x"),
		-Input.get_axis("-y","+y")
		)

	%HUD/debugText.text = ("vel: " + 
		str(round(velocity.x)) + ", " +
		str(round(velocity.y))+ 
		" speed: " + str(round(velocity.length())) + 
		"\nfloor: " + str(on_floor) + 
		"\nwall: " + str(wall) + 
		"\ndrag type: " + str(dragType) + 
		"\n\nwallcling: " + str(wallcling) + 
		"\n\nfps: " + str(Engine.get_frames_per_second())
		)
	
	
	queue_redraw()

func update_shader(delta):
	
	var cursorD = (cursor.global_position) - (global_position)
	var hole = (cursorD/25).limit_length(0.25)
	shader.set_shader_parameter("holePos", hole)
	
	var squishDir := Vector2.ZERO
	if on_floor:
		shader.set_shader_parameter("squishPivot", Vector2.DOWN)
		squishDir = Vector2.RIGHT
		snapSquishDirThisFrame = true
		
	elif wall:
		shader.set_shader_parameter("squishPivot", Vector2(wall,0.0))
		squishDir = Vector2.UP
		snapSquishDirThisFrame = true
	else:
		shader.set_shader_parameter("squishPivot", Vector2.ZERO)
		squishDir = velocity
	
	var squishRatio = 1.0
	if not on_floor and not wall:
		squishRatio = squishOverVelocity.sample(velocity.length())
	
	if snapSquishDirThisFrame:
		currentSquishDir = squishDir
		snapSquishDirThisFrame = false
	else:
		currentSquishDir = GLOBAL.lerpd(currentSquishDir, squishDir, 0.5, 0.05, delta)
	
	currentSquish = GLOBAL.lerpd(currentSquish, squishRatio, 0.3, 0.05, delta)
	shader.set_shader_parameter("squishRatio", currentSquish)
	shader.set_shader_parameter("squishDir", currentSquishDir)
	
	var skewAxes := Vector2.ZERO
	var skewAmt := Vector2.ZERO
	if on_floor:
		skewAxes = Vector2.DOWN
		skewAmt.x = skewOverVelocityX.sample(velocity.x)
	elif wall:
		skewAxes.x = direction.x
		skewAmt.y = skewOverVelocityY.sample(velocity.y)*direction.x if direction.x else 0
	
	currentSkew = GLOBAL.lerpd(currentSkew, skewAmt, 0.5, 0.03, delta)
	currentSkewAxes = GLOBAL.lerpd(currentSkewAxes, skewAxes, 0.5, 0.03, delta)
	
	shader.set_shader_parameter("shearPivot", currentSkewAxes)
	shader.set_shader_parameter("shearAmts", currentSkew)

func normal_calcs():
	wall = int(touching(Vector2.RIGHT)) - int(touching(Vector2.LEFT))
	on_floor = touching(Vector2.DOWN)

func _physics_process(delta):
	normal_calcs()
	var normalsPacked = $rb.get_all_collision_normals()
	var normals = Array(normalsPacked)
	
	#region input-independent logic
	var lastColNormal := Vector2.ZERO
	if get_last_slide_collision() != null: lastColNormal = get_last_slide_collision().get_normal().normalized()
	wallcling = wall and not (on_floor) and normals.any(func(x): return x.dot(lastVel) < 0)
	
	#region 	gravity
	if not on_floor and not dashing:
		velocity.y += GRAVITY * delta
	if wallcling and velocity.y > 0:
		velocity.y -= WALLCLING_VERTICAL_DRAG * velocity.y * delta
	#endregion
	#region 	dash bounce
	if dashing:
		if lastColNormal.dot(lastVel) < 0:
			velocity = lastVel.bounce(lastColNormal) * (1.0 if hasDBounced else 0.7)
			hasDBounced = true
	if on_floor:
		jumpsLeft = 1
	#endregion	
	#endregion
	
	#region input-dependent logic
	#region 	dash logic
	if Input.is_action_just_pressed("d") and not direction.is_zero_approx():
		velocity.y=0
		Dash(get_dash_vec() * DASH_VEL)
	#endregion
	#region 	jump
	if Input.is_action_pressed("+y"):
		if wall and normals.any(func(x): sign(x.x) == sign(direction.x)):
			print("bounce")
		if on_floor:
			#print("floor jump")
			velocity.y = JUMP_VEL + (velocity.y if dashing and !lastDashVel.x else 0)
		
		elif wallcling and not dashing and direction.x:
			#print("wall jump")
			velocity.y = JUMP_VEL * 1.25
			velocity.x = wall * JUMP_VEL
			
	if not on_floor and jumpsLeft > 0 and Input.is_action_just_pressed("+y"):
		#print("air jump")
		velocity.y = JUMP_VEL
		jumpsLeft -= 1
	#endregion
	#region 	horizontal mvmt
	if not dashing:
		if direction.x and abs(velocity.x) <= MAX_SPEED:
			velocity.x += ACCEL * direction.x * delta
			if sign(direction.x) != sign(velocity.x):
				velocity.x = move_toward(velocity.x,0,DRAG*delta)
				dragType = "pivot"
		elif on_floor:
			if Input.is_action_pressed("-y"):
				velocity.x = move_toward(velocity.x,0,SLIDE_DRAG*delta)
				dragType = "sliding"
			else:
				velocity.x = move_toward(velocity.x,0,DRAG*delta)
				dragType = "normal"
		else:
			velocity.x = move_toward(velocity.x,0,AIR_DRAG*delta)
			dragType = "air"
	#endregion
	#endregion
	lastVel = velocity
	move_and_slide()
	update_shader(delta)

func get_dash_vec() -> Vector2:
	var dir = direction.normalized()
	if wallcling:
		#print("wall dash")
		return dir * Vector2(-1,1)
	elif on_floor:
		#print("ground dash")
		return Vector2(direction.x,0)
	else:
		#print("air dash")
		return dir
		
		

func _draw():
	if not renderGizmos: return
	
	draw_set_transform_matrix(global_transform.affine_inverse())
	var pos : PackedVector2Array = $rb.get_all_collision_points()
	var norm : PackedVector2Array = $rb.get_all_collision_normals()
	
	for i in pos.size():
		draw_line(pos[i], pos[i]+norm[i]*50.0, Color.WHITE, -2)
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
			print("long dash")
			velocity -= (velocity - lastVel) * 0.25
		elif velocity.dot(lastVel) < 0:
			print("short dash reverse stop")
			velocity = v * 0.1
		else:
			print("short dash")
			velocity = lastVel
	else: 
		print("dbounce")
		pass
	
	dashing = false
	hasDBounced = false
