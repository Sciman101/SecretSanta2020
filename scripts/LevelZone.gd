extends Area2D

export var track_h : bool # Should the player be tracked horizontally in this zone?
export var track_v : bool # Should the player be tracked vertically in this zone?
export var secret : bool

onready var level_shape = $LevelShape.shape # Used to constrain the camera if track_h or track_v is enabled
onready var camera_start_pos = $CameraStart # Used to constrain the camera if track_h or track_v is enabled
onready var spawn_pos = $SpawnPoint

var found := false


# Detect the player entering the area
func _on_LevelZone_body_entered(body):
	if body.is_in_group("Player"):
		# Tween the camera
		body.current_zone = self
		if secret and not found:
			body.sfx_secret.play()
		
		Game.game_camera.tween_to(camera_start_pos.global_position)
		
		found = true


func _on_LevelZone_body_exited(body):
	pass # Replace with function body.
