extends Node

const SETTINGS_FILE_NAME := 'user://settings.conf'

const CURSOR_NORMAL := 0
const CURSOR_DARK := 1
const CURSOR_LOCKED := 2
const CURSOR_DISABLED := 3

var game_camera # Reference to the level camera
var cursor # Reference to the cursor
var hud

var enable_screenshake := true
var flowers_collected := 0


func _ready() -> void:
	load_settings()
	pause_mode = Node.PAUSE_MODE_PROCESS


# Quit the game when appropriate
func _notification(what) -> void:
	if what == NOTIFICATION_WM_QUIT_REQUEST:
		save_settings()
		get_tree().quit()


# Key shortcuts
func _input(event):
	if event is InputEventKey and event.is_pressed():
		match event.scancode:
			KEY_F11: # Toggle fullscreen
				OS.window_fullscreen = !OS.window_fullscreen
			KEY_ESCAPE: # Pause the game
				toggle_pause()

func toggle_pause():
	get_tree().paused = !get_tree().paused
	PauseMenu.set_visible(get_tree().paused)

# Set the cursor based on index (defined as constants above)
func set_cursor(frame:int) -> void:
	if cursor:
		cursor.frame = frame
	else:
		print('Attempting to set cursor frame with no cursor!')


# Save and load settings
func save_settings() -> void:
	var config = {
		screenshake=enable_screenshake,
		volume=db2linear(AudioServer.get_bus_volume_db(0))
	}
	# Open settings file
	var file = File.new()
	file.open(SETTINGS_FILE_NAME, File.WRITE)
	file.store_line(to_json(config))
	file.close()
func load_settings() -> void:
	var file = File.new()
	if file.file_exists(SETTINGS_FILE_NAME):
		file.open(SETTINGS_FILE_NAME,File.READ)
		# Load from config and convert to data
		var config = parse_json(file.get_line())
		# Actually set stuff up
		AudioServer.set_bus_volume_db(0,linear2db(config.volume))
		enable_screenshake = config.screenshake


# Called when a flower is collected
func on_collect_flower() -> void:
	flowers_collected += 1
	hud.show_flower_count()
