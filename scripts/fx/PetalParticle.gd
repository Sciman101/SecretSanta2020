extends Sprite

const OFFSET := Vector2(300,150)

var motion : Vector2
var attracted : bool = false
var hover_target = null

var lifetime := 1.0

func _ready():
	motion = Vector2(rand_range(-1,1),rand_range(-1,1)).normalized() * rand_range(200,300)

func _process(delta) -> void:
	
	if attracted:
		if not hover_target:
			# Accelerate towards the corner of the screen
			if Game.game_camera:
				var target = Game.game_camera.global_position - OFFSET
				var diff = (target - global_position)
				
				# Are we close enough? Then destroy ourselves
				if diff.length_squared() < 64:
					queue_free()
				lifetime -= delta
				if lifetime <= 0: # Just in case
					queue_free()
				
				# Accelerate towards the corner of the screen
				motion += diff * 10 * delta
		else:
			# Hover around player
			var diff = (hover_target.global_position - global_position)
			motion += diff * 10 * delta
	
	else:
		# Slow down
		motion = motion.move_toward(Vector2.ZERO,delta*500)
		if motion.length_squared() <= 0:
			attracted = true
	
	position += motion * delta
