extends Camera2D

var screenshake : float
var screenshake_time : float

onready var tween = $Tween

# Tell the camera to go somewhere
func tween_to(pos:Vector2,time:float=0.4,delay:float=0.1) -> void:
	tween.stop(self,'position')
	tween.interpolate_property(self,'position',position,pos,time,Tween.TRANS_CUBIC,Tween.EASE_IN_OUT,delay)
	tween.start()

func add_screenshake(amt:float,time:float=0.05) -> void:
	screenshake += amt
	screenshake_time = time

func _process(delta):
	if screenshake_time > 0:
		offset = Vector2(rand_range(-screenshake,screenshake),rand_range(-screenshake,screenshake))
		screenshake_time -= delta
		if screenshake_time <= 0:
			offset = Vector2.ZERO
		
