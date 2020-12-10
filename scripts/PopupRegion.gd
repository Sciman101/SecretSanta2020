extends Area2D

export(String, MULTILINE) var message : String

func _on_PopupRegion_body_entered(body):
	if body.is_in_group('Player'):
		Game.hud.show_popup(message)

func _on_PopupRegion_body_exited(body):
	if body.is_in_group('Player'):
		Game.hud.show_popup('')
