extends AudioStreamPlayer
# Helper to randomize sounds

export var stream_pool : Array
export var pitch_min : float = 1
export var pitch_max : float = 1

# Randomize on play
func play(from:float=0.0) -> void:
	stream = stream_pool[randi()%stream_pool.size()]
	pitch_scale = rand_range(pitch_min,pitch_max)
	.play(from)
