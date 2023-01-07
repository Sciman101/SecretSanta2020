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
var timer_enabled := false setget _set_enable_timer
var flowers_collected := 0
var flowers_total := 0
var restarts := 0

var game_time := 0.0
var complete := false # Set to true once we beat the game

var cheats := false

signal on_game_finished
signal toggle_cheats

func _ready() -> void:
	load_settings()
	pause_mode = Node.PAUSE_MODE_PROCESS
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)


# Quit the game when appropriate
func _notification(what) -> void:
	if what == NOTIFICATION_WM_QUIT_REQUEST:
		save_settings()
		get_tree().quit()

func _process(delta) -> void:
	if not get_tree().paused and not complete:
		game_time += delta
		if timer_enabled and not cheats:
			hud.set_timer_time(game_time)

# Key shortcuts
func _input(event):
	if event is InputEventKey and event.is_pressed():
		
		if Input.is_action_just_pressed("restart_game"):
			restart_game()
		
		match event.scancode:
			KEY_F11: # Toggle fullscreen
				OS.window_fullscreen = !OS.window_fullscreen
				PauseMenu._update_btn()
			KEY_ESCAPE: # Pause the game
				toggle_pause()
			KEY_F1:
				if get_tree().is_paused():
					cheats = !cheats
					emit_signal('toggle_cheats')
			
			KEY_F10:
				if hud:
					hud.speedometer.visible = !hud.speedometer.visible


func complete_game() -> void:
	complete = true
	emit_signal("on_game_finished")
	if get_tree().paused:
		toggle_pause()
	hud.show_results()
	PauseMenu.layer = 12


func restart_game():
	get_tree().reload_current_scene()
	if get_tree().paused:
		toggle_pause()
	
	game_time = 0.0
	restarts = 0
	complete = false
	flowers_collected = 0
	flowers_total = 0
	PauseMenu.layer = 9

func toggle_pause():
	get_tree().paused = !get_tree().paused
	PauseMenu.set_visible(get_tree().paused)
	if complete:
		# Show cursor on end screen, since the pause menu now obstructs the HUD
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN if not get_tree().paused else Input.MOUSE_MODE_VISIBLE)

# Set the cursor based on index (defined as constants above)
func set_cursor(frame:int) -> void:
	if cursor:
		cursor.frame = frame
	else:
		print('Attempting to set cursor frame with no cursor!')


func _set_enable_timer(val) -> void:
	timer_enabled = val
	if hud:
		hud.timer.visible = val
		hud.set_timer_time(game_time)


# Save and load settings
func save_settings() -> void:
	var config = {
		screenshake=enable_screenshake,
		volume=db2linear(AudioServer.get_bus_volume_db(0)),
		fullscreen=OS.window_fullscreen,
		timer=timer_enabled
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
		OS.window_fullscreen = config.fullscreen
		self.timer_enabled = config.timer


# Called when a flower is collected
func on_collect_flower() -> void:
	flowers_collected += 1
	hud.show_flower_count()
