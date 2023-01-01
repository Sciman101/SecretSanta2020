extends Sprite

const OFFSET := Vector2(300,150)

var motion : Vector2
var attracted : bool = false
var wait := false

var speed := 0.0

func _ready():
	motion = Vector2(rand_range(-1,1),rand_range(-1,1)).normalized() * rand_range(200,300)

func _process(delta) -> void:
	
	if attracted:
		if not wait:
			# Accelerate towards the corner of the screen
			if Game.game_camera:
				var target = Game.game_camera.global_position - OFFSET
				var diff = (target - global_position)
				
				# Are we close enough? Then destroy ourselves
				if diff.length_squared() < 64:
					queue_free()
				
				speed += delta * 1000
				
				# Accelerate towards the corner of the screen
				#motion += diff * 10 * delta
				global_position = global_position.move_toward(target,delta*speed)
	
	else:
		# Slow down
		motion = motion.move_toward(Vector2.ZERO,delta*500)
		if motion.length_squared() <= 0:
			attracted = true
	
	position += motion * delta
