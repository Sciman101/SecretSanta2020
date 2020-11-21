extends KinematicBody2D

export var gravity : float
export var friction : float

var motion : Vector2

func _physics_process(delta:float) -> void:
	motion.y += gravity * delta
	
	if is_on_floor():
		motion.x = move_toward(motion.x,0,friction*delta)
	
	motion = move_and_slide(motion,Vector2.UP)

func get_motion() -> Vector2:
	return motion

# Pull the block along a certain direction
func pull(direction:Vector2,delta:float) -> Vector2:
	
	var pos_old = position
	motion = move_and_slide(direction,Vector2.UP)
	var move = position - pos_old
	
	return direction + move
