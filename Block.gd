extends KinematicBody2D

export var gravity : float

var motion : Vector2

func _physics_process(delta:float) -> void:
	motion.y += gravity * delta
	
	motion = move_and_slide(motion,Vector2.UP)

# Pull the block along a certain direction
func pull(direction:Vector2) -> Vector2:
	
	var pos_old = position
	move_and_slide(direction)
	var delta = position - pos_old
	
	return direction + delta
