extends Node

const CURSOR_NORMAL := 0
const CURSOR_DARK := 1
const CURSOR_LOCKED := 2
const CURSOR_DISABLED := 3

var game_camera # Reference to the level camera
var cursor # Reference to the cursor
var hud

var flowers_collected := 0

func set_cursor(frame:int) -> void:
	if cursor:
		cursor.frame = frame
	else:
		print('Attempting to set cursor frame with no cursor!')


func on_collect_flower() -> void:
	flowers_collected += 1
	hud.show_flower_count()


# Key shortcuts
func _input(event):
	if event is InputEventKey and event.is_pressed():
		match event.scancode:
			KEY_F11: # Toggle fullscreen
				OS.window_fullscreen = !OS.window_fullscreen
