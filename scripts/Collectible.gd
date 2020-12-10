extends Area2D

onready var Particle := preload("res://scenes/partial/PetalParticle.tscn")

# Collect thing
func _on_Collectible_body_entered(body):
	if visible and body.is_in_group("Player"):
		visible = false
		
		# Create particles
		for i in range(8):
			var inst = Particle.instance()
			get_parent().add_child(inst)
			inst.global_position = global_position
		
		Game.on_collect_flower()
