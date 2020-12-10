extends Sprite

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	Game.cursor = self

func _process(delta):
	global_position = get_global_mouse_position()
