extends Area2D

func _on_Finish_body_entered(body):
	if not Game.complete:
		if body.is_in_group('Player'):
			# We done boys
			Game.complete_game()
