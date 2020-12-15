extends KinematicBody2D

onready var sprite = $Sprite

export var gravity : float
export var friction : float
export var stuck : float

var motion : Vector2

func _physics_process(delta:float) -> void:
	if stuck <= 0:
		motion.y += gravity * delta
		
		if is_on_floor():
			motion.x = move_toward(motion.x,0,friction*delta)
		
		motion = move_and_slide(motion,Vector2.UP)

func get_motion() -> Vector2:
	return motion

# Pull the block along a certain direction
func pull(direction:Vector2,delta:float) -> Vector2:
	if stuck > 0:
		# Shake
		stuck -= delta
		sprite.offset = Vector2(rand_range(-1,1),rand_range(-1,1))
		if stuck <= 0:
			sprite.offset = Vector2.ZERO
		
		return direction
	else:
		var pos_old = position
		motion = move_and_slide(direction,Vector2.UP)
		var move = position - pos_old
		
		return direction + move
