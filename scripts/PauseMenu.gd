extends CanvasLayer

onready var screenshake_btn := $Background/VBoxContainer/Screenshake
onready var bg := $Background

func _ready() -> void:
	# Load settings into menu
	_update_screenshake_btn()
	$Background/VBoxContainer/VolumeSlider.value = db2linear(AudioServer.get_bus_volume_db(0))
	bg.visible = false

func set_visible(visible:bool) -> void:
	bg.visible = visible

# Specific menu button operations
func quit():
	Game._notification(NOTIFICATION_WM_QUIT_REQUEST)
func restart():
	get_tree().reload_current_scene()
	Game.toggle_pause()
func resume():
	Game.toggle_pause()

func _on_Screenshake_pressed():
	Game.enable_screenshake = !Game.enable_screenshake
	_update_screenshake_btn()

# Set game volume
func _on_VolumeSlider_value_changed(value):
	AudioServer.set_bus_volume_db(0,linear2db(value))

func _update_screenshake_btn():
	screenshake_btn.text = "Screenshake: " + ("On" if Game.enable_screenshake else "Off")
