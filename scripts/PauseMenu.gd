extends CanvasLayer

onready var screenshake_btn := $Background/VBoxContainer/Screenshake
onready var fullscreen_btn := $Background/VBoxContainer/Fullscreen
onready var timer_btn := $Background/VBoxContainer/ShowTimer
onready var bg := $Background

func _ready() -> void:
	# Load settings into menu
	_update_btn()
	$Background/VBoxContainer/VolumeSlider.value = db2linear(AudioServer.get_bus_volume_db(0))
	bg.visible = false

func set_visible(visible:bool) -> void:
	bg.visible = visible
	if visible:
		Game.hud.show_flower_count()
	else:
		Game.hud._on_CounterAnim_animation_finished('Show')

# Specific menu button operations
func quit():
	Game._notification(NOTIFICATION_WM_QUIT_REQUEST)
func restart():
	get_tree().reload_current_scene()
	Game.toggle_pause()
	Game.restart_timer()
func resume():
	Game.toggle_pause()

func _on_ShowTimer_pressed():
	Game.timer_enabled = !Game.timer_enabled
	_update_btn()

func _on_Screenshake_pressed():
	Game.enable_screenshake = !Game.enable_screenshake
	_update_btn()

func _on_Fullscreen_pressed():
	OS.window_fullscreen = !OS.window_fullscreen
	_update_btn()

# Set game volume
func _on_VolumeSlider_value_changed(value):
	AudioServer.set_bus_volume_db(0,linear2db(value))

func _update_btn():
	screenshake_btn.text = "Screenshake: " + ("On" if Game.enable_screenshake else "Off")
	fullscreen_btn.text = ("Windowed" if OS.window_fullscreen else "Fullscreen")
	timer_btn.text = "Timer: " + ("On" if Game.timer_enabled else "Off")
