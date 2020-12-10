extends CanvasLayer

onready var label = $Counter/Label
onready var anim = $Counter/CounterAnim

# Called when the node enters the scene tree for the first time.
func _ready():
	Game.hud = self

func show_flower_count() -> void:
	if not anim.is_playing():
		anim.play('Pop')

func update_label() -> void:
	label.text = str(Game.flowers_collected)
