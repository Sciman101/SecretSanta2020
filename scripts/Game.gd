extends Node

var game_camera # Reference to the level camera

func _ready():
	# Used so other nodes have reference to the camera
	game_camera = get_tree().get_nodes_in_group("Camera")[0]

# Key shortcuts
func _input(event):
	if event is InputEventKey and event.is_pressed():
		match event.scancode:
			KEY_F11: # Toggle fullscreen
				OS.window_fullscreen = !OS.window_fullscreen
