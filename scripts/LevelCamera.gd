extends Camera2D

onready var tween = $Tween

# Tell the camera to go somewhere
func tween_to(pos:Vector2,time:float=0.25,delay:float=0.1) -> void:
	tween.stop(self,'position')
	tween.interpolate_property(self,'position',position,pos,time,Tween.TRANS_CUBIC,Tween.EASE_IN_OUT,delay)
	tween.start()
