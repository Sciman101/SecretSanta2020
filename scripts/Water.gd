extends Area2D



func _on_Water_body_entered(body):
	if body.is_in_group('Player'):
		if body.water_area == null and body.motion.y > 120:
			if not body.sfx_splash.is_playing():
				body.sfx_splash.play()
		body.water_area = self


func _on_Water_body_exited(body):
	if body.is_in_group('Player'):
		if body.water_area == self:
			body.water_area = null
