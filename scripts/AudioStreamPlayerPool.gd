extends AudioStreamPlayer
# Helper to randomize sounds

export var stream_pool : Array
export var pitch_min : float = 1
export var pitch_max : float = 1
export var trigger_children : bool

var last_index := -1

# Randomize on play
func play(from:float=0.0,randomize_pitch:bool=true) -> void:
	
	var index = last_index
	if stream_pool.size() > 1:
		while index == last_index:
			index = randi()%stream_pool.size()
	last_index = index
	
	stream = stream_pool[index]
	if randomize_pitch: pitch_scale = rand_range(pitch_min,pitch_max)
	.play(from)
	
	if trigger_children:
		for child in get_children():
			if child.has_method('play'):
				child.play(from,randomize_pitch)
