extends Node

const CURSOR_NORMAL := 0
const CURSOR_DARK := 1
const CURSOR_LOCKED := 2
const CURSOR_DISABLED := 3

var game_camera # Reference to the level camera
var cursor

func _ready():
	# Used so other nodes have reference to the camera
	var c = get_tree().get_nodes_in_group("Camera")
	if len(c) > 0:
		game_camera = c[0]

func set_cursor(frame:int) -> void:
	if cursor:
		cursor.frame = frame
	else:
		print('Attempting to set cursor frame with no cursor!')

# Key shortcuts
func _input(event):
	if event is InputEventKey and event.is_pressed():
		match event.scancode:
			KEY_F11: # Toggle fullscreen
				OS.window_fullscreen = !OS.window_fullscreen
