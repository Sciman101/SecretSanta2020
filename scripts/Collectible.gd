extends Area2D

# Collect thing
func _on_Collectible_body_entered(body):
	if visible and body.is_in_group("Player"):
		visible = false
