extends CanvasLayer

const TRANSPARENT := Color(1,1,1,0)

onready var label = $Counter/Label
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


func set_timer_time(time:float) -> void:
	var minutes = floor(time/60)
	var seconds = fmod(time,60)
	timer.text = "%02d:%04.1f" % [minutes,seconds]


func show_flower_count() -> void:
	if not anim.is_playing():
		anim.play('Show')

func _on_CounterAnim_animation_finished(anim_name):
	if anim_name == 'Show' and not get_tree().paused:
		anim.play("Hide")

func update_label() -> void:
	label.text = str(Game.flowers_collected)


func show_popup(text:String) -> void:
	popup_label.text = text
	# Tween
	popup_tween.stop(popup,'modulate')
	if text != "":
		popup_tween.interpolate_property(popup,'modulate',TRANSPARENT,Color.white,0.1)
	else:
		popup_tween.interpolate_property(popup,'modulate',Color.white,TRANSPARENT,0.1)
	popup_tween.start()
