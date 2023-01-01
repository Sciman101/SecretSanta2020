extends CanvasLayer

const TRANSPARENT := Color(1,1,1,0)

onready var label = $Counter/Label
onready var cheats_label = $CheatsLabel
onready var speedometer = $Speedometer
onready var anim = $Counter/CounterAnim
onready var popup = $Popup
onready var popup_label = $Popup/Label
onready var popup_tween = $Popup/Tween
onready var timer = $Timer

# Called when the node enters the scene tree for the first time.
func _ready():
	Game.hud = self
	# Hacky way to make this work
	Game._set_enable_timer(Game.timer_enabled)
	Game.connect("toggle_cheats",self,'_on_cheats_toggled')
	_on_cheats_toggled()
	$Results.visible = false


# Display final results
func show_results() -> void:
	var results = $Results
	var lbl = $Results/Label
	
	# Show results
	var time = Game.game_time
	var minutes = floor(time/60)
	var seconds = fmod(time,60)
	lbl.text = lbl.text % [minutes,seconds,Game.flowers_collected,Game.flowers_total,Game.restarts]
	
	# Unhide
	results.visible = true
	popup_tween.stop_all()
	popup_tween.interpolate_property(results,'modulate',TRANSPARENT,Color.white,0.25)
	popup_tween.start()


func set_timer_time(time:float) -> void:
	var minutes = floor(time/60)
	var seconds = fmod(time,60)
	timer.text = "%02d:%04.1f" % [minutes,seconds]

func set_speedometer_value(speed:float) -> void:
	speedometer.text = "Speed: %1.f" % speed

func show_flower_count() -> void:
	if not anim.is_playing():
		anim.play('Show')

func _on_CounterAnim_animation_finished(anim_name):
	if anim_name == 'Show' and not get_tree().paused:
		anim.play("Hide")

func update_label() -> void:
	label.text = str(Game.flowers_collected)

func _on_cheats_toggled():
	cheats_label.visible = Game.cheats

func show_popup(text:String) -> void:
	popup_label.text = text
	# Tween
	popup_tween.stop(popup,'modulate')
	if text != "":
		popup_tween.interpolate_property(popup,'modulate',TRANSPARENT,Color.white,0.1)
	else:
		popup_tween.interpolate_property(popup,'modulate',Color.white,TRANSPARENT,0.1)
	popup_tween.start()
