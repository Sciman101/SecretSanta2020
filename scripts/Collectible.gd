extends Area2D

export var do_not_total : bool = false # Don't add this flower to the total

onready var Particle := preload("res://scenes/partial/PetalParticle.tscn")
var player
var collected := false
var particles = []
var grounded_frames := 0

func _ready() -> void:
	get_parent().connect('zone_reset',self,'reset_if_not_collected')
	# Sum flower collectibles
	if not do_not_total: Game.flowers_total += 1

# Collect thing
func _on_Collectible_body_entered(body):
	# Is it the player?
	if body.is_in_group("Player") and not collected:
		# We haven't been collected yet
		if visible:
			# Hide
			visible = false
			
			var wait = false
			if body.grounded:
				# If the player is grounded, then just collect the flower
				Game.on_collect_flower()
				collected = true
			else:
				# Otherwise, wait for the player to land before collecting
				body.connect('on_grounded',self,'_on_player_grounded')
				Game.connect('on_game_finished',self,'_force_collect')
				player = body
				wait = true
			
			# Create particles
			for i in range(8):
				var inst = Particle.instance()
				get_parent().add_child(inst)
				inst.global_position = global_position
				particles.append(inst)
				inst.wait = wait

func reset_if_not_collected() -> void:
	if not collected and player:
		if player.is_connected('on_grounded',self,'_on_player_grounded'):
			# Disconnect signal
			player.disconnect('on_grounded',self,'_on_player_grounded')
		# Remove particles
		for part in particles:
			if part: part.queue_free()
		particles.clear()
		# Re-show
		visible = true
		grounded_frames = 0

func _on_player_grounded() -> void:
	
	while grounded_frames <= player.MAX_GRACE_FRAMES and not visible:
		grounded_frames += 1
		yield(get_tree(),"idle_frame")
	
	if visible:
		grounded_frames = 0
		return
	
	_force_collect()

func _force_collect() -> void:
	if not collected:
		Game.on_collect_flower()
		Game.disconnect('on_game_finished',self,'_force_collect')
		player.disconnect('on_grounded',self,'_on_player_grounded')
		for part in particles:
			if part: part.wait = false
		collected = true
