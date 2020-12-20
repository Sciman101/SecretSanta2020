extends KinematicBody2D

onready var sprite = $Sprite

export var gravity : float
export var friction : float
export var stuck : float

var motion : Vector2
var starting_pos : Vector2
var starting_stuck : float
var was_on_floor : bool

func _ready():
	starting_pos = position
	starting_stuck = stuck
	get_parent().connect('zone_reset',self,'reset_pos')

func _physics_process(delta:float) -> void:
	if stuck <= 0:
		motion.y += gravity * delta
		
		var grounded = is_on_floor()
		if grounded:
			motion.x = move_toward(motion.x,0,friction*delta)
			if not was_on_floor and motion.y > 50:
				Game.game_camera.add_screenshake(4,0.1)
		was_on_floor = grounded
		
		motion = move_and_slide(motion,Vector2.UP)

func get_motion() -> Vector2:
	return motion

# Reset to original positon and whatnot
func reset_pos() -> void:
	position = starting_pos
	stuck = starting_stuck
	motion = Vector2.ZERO

# Pull the block along a certain direction
func pull(direction:Vector2,delta:float) -> Vector2:
	if stuck > 0:
		# Shake
		stuck -= delta
		sprite.offset = Vector2(rand_range(-1,1),rand_range(-1,1))
		if stuck <= 0:
			sprite.offset = Vector2.ZERO
			Game.game_camera.add_screenshake(4,0.1)
		
		return direction
	else:
		var pos_old = position
		motion = move_and_slide(direction,Vector2.UP)
		var move = position - pos_old
		
		return direction + move
