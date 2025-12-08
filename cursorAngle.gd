extends Node2D

@export var tSens : float # pixelsPerDegree
# Called when the node enters the scene tree for the first time.
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	#global_position = get_parent().global_position

func _input(event: InputEvent):
	if event.is_class("InputEventMouseMotion"):
		position += event.screen_relative
		position = position.normalized( )* 180 * tSens / PI
	
	
