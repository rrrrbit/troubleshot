extends Node2D

@export var rSens : float
@export var range : float = 1000

@export var angle : Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	#global_position = get_parent().global_position

func _input(event: InputEvent):
	if event.is_class("InputEventMouseMotion"):
		position += event.screen_relative * rSens
		position = position.rotated(position.angle_to(angle.position))
		position = position.limit_length(range)
	
	
