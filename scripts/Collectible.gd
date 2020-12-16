extends Area2D

onready var Particle := preload("res://scenes/partial/PetalParticle.tscn")
var player
var collected := false
var particles = []

func _ready() -> void:
	get_parent().connect('zone_reset',self,'reset_if_not_collected')

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
				player = body
				wait = true
			
			# Create particles
			for i in range(8):
				var inst = Particle.instance()
				get_parent().add_child(inst)
				inst.global_position = global_position
				particles.append(inst)
				if wait:
					inst.hover_target = player

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

func _on_player_grounded() -> void:
	Game.on_collect_flower()
	player.disconnect('on_grounded',self,'_on_player_grounded')
	for part in particles:
		if part: part.hover_target = null
	collected = true
