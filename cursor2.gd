extends Node2D

@export var sensitivity : float = 1 # px / deg
@export var sensitivity2 : Vector2
@export var range : float = 1000
@export var locked : bool

enum AimTypes {
	cartesian,
	fixedAngular,
	distanceScaled
}

@export var aimType: AimTypes

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	#global_position = get_parent().global_position

func _input(event: InputEvent):
	if event.is_class("InputEventMouseMotion"):
		var d = event.screen_relative
		match aimType:
			AimTypes.cartesian:
				d = cartesianD(d, sensitivity)
			AimTypes.fixedAngular:
				d = fixedAngularD(position, d, sensitivity)
			AimTypes.distanceScaled:
				d = distanceScaledD(position, d, sensitivity, sensitivity2)
		
		position += d
		
		if (global_position - get_parent().global_position).length_squared() > range ** 2:
			position = (global_position - get_parent().global_position).limit_length(range) #clamp
		queue_redraw()
		
func cartesianD(rawD: Vector2, sens: float):
	return rawD * sens

func fixedAngularD(pos: Vector2, rawD: Vector2, sens: float):
	var right : Vector2 = Vector2(-pos.y, pos.x).normalized()
	var tang : Vector2 = rawD.project(right)
	var angle : float = deg_to_rad(rawD.dot(right) / sens)
	var arcLength : float = angle * pos.length()
	var adjustedTang : Vector2 = right * arcLength
	return rawD * adjustedTang.length() / tang.length()
	
func distanceScaledD(pos: Vector2, rawD: Vector2, zero: float, neutral: Vector2):
	return rawD * ((neutral.y-zero)/neutral.x * pos.length() + zero)
	
	
func _draw() -> void:
	draw_set_transform_matrix(transform.affine_inverse())
	draw_circle(Vector2.ZERO, sensitivity2.x, Color.HOT_PINK, false, 3)
	
