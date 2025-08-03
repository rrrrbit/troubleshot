extends Camera2D

@export var target : Node2D
@export var cursor : Node2D

@export var fixedOffset : Vector2

@export var smoothingTime : float
@export var smoothingFactor : float

@export var velocityOffset : Vector2
@export var velSmoothingTime : float
@export var velSmoothingFactor : float

@export var cursorOffset : Vector2
@export var cursorSmoothingTime : float
@export var cursorSmoothingFactor : float

@export var velocityZoom : Curve
@export var velocityZoomMult : Vector2
@export var zoomSmoothTime : float
@export var zoomSmoothOffset : float

var targetPositionFinal := Vector2.ZERO
var cursorOffs := Vector2.ZERO
var velOffs := Vector2.ZERO

var zoomScalar := 0.75
# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	cursorOffs = GLOBAL.lerpd(
		cursorOffs, 
		(cursor.global_position - target.position) * cursorOffset, 
		cursorSmoothingFactor, 
		cursorSmoothingTime, 
		delta
		)
	
	velOffs = GLOBAL.lerpd(
		velOffs, 
		target.velocity * velocityOffset, 
		velSmoothingFactor, 
		velSmoothingTime, 
		delta
		)
	
	targetPositionFinal = GLOBAL.lerpd(
		targetPositionFinal, 
		target.position + fixedOffset, 
		smoothingFactor, 
		smoothingTime, 
		delta
		)
	
	position = targetPositionFinal + cursorOffs + velOffs
	
	zoomScalar = GLOBAL.lerpd(
		zoomScalar, 
		velocityZoom.sample(clamp(target.velocity.length(), velocityZoom.min_domain, velocityZoom.max_domain)), 
		zoomSmoothTime, 
		zoomSmoothOffset, 
		delta
		)
		
	zoom = Vector2.ONE * zoomScalar
	
	$cameratarget.global_position = targetPositionFinal
	$cameratarget2.global_position = targetPositionFinal + velOffs
