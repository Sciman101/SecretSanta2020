extends Area2D

export var secret : bool

onready var level_shape = $LevelShape.shape # Used to constrain the camera if track_h or track_v is enabled
onready var camera_start_pos = $CameraStart # Used to constrain the camera if track_h or track_v is enabled
onready var spawn_pos = $SpawnPoint

var found := false

signal zone_reset # Called when the player dies

# Detect the player entering the area
func _on_LevelZone_body_entered(body):
	if body.is_in_group("Player"):
		
		# Tween the camera
		body.current_zone = self
		if secret and not found:
			body.sfx_secret.play()
		
		# Tween the camera
		if Game.game_camera.global_position != camera_start_pos.global_position:
			Game.game_camera.tween_to(camera_start_pos.global_position)
			body.frozen = true
		
		found = true


func _on_LevelZone_body_exited(body):
	pass
		
