extends Node

func _input(event):
	if event is InputEventKey and event.is_pressed():
		match event.scancode:
			KEY_F11: # Toggle fullscreen
				OS.window_fullscreen = !OS.window_fullscreen
