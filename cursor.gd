extends Node2D

@export var sensitivity : float = 1
@export var range : float = 1000
# Called when the node enters the scene tree for the first time.
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	global_position = get_parent().global_position

func _unhandled_input(event):
	if event.is_class("InputEventMouseMotion"):
		position += event.screen_relative * sensitivity
		if (global_position - get_parent().global_position).length_squared() > range ** 2:
			position = (global_position - get_parent().global_position).limit_length(range)
