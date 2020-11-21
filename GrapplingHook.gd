extends Node2D

onready var rope := $Rope
onready var wrap_ray := $WrapCheck
onready var player : KinematicBody2D = get_parent()

export var max_rope_length : float # Longest the rope can be
export var shot_gravity : float

var extended : bool = false # Is the rope extended?

var rope_length : float = max_rope_length
var stuck_parent : KinematicBody2D # What is the hook stuck in?
var stuck_position : Vector2 # Where is the grappling hook stuck, relative to it's parent
							# If parent is null, this is relative to the world
var wrap_points = []

func _ready() -> void:
	# Don't collide with player
	wrap_ray.add_exception(player)
	# Unparent rope so it works in world space
	remove_child(rope)
	player.get_parent().call_deferred('add_child',rope)


func _process(delta):
	if extended:
		# Update rope visual
		rope.set_point_position(1,get_world_point())
		rope.set_point_position(0,player.global_position)


func _physics_process(delta:float) -> void:
	if extended:
		# Clamp player position
		var point = get_world_point()
		var difference = point - player.global_position
		
		var ropelen = difference.length()
		if ropelen > rope_length:
			
			# Pull
			if stuck_parent != null:
				if player.edge_buffer > 0: # We can only drag when we're grounded
					difference = -stuck_parent.pull(-difference)
					if difference.length() <= rope_length:
						return
			
			# Move the player along the rope to the target pos
			player.move_and_collide(difference.normalized() * (ropelen - rope_length))
			player.clamp_velocity_normal(difference.normalized())
		
		if stuck_parent == null:
			# Check for wrapping
			wrap_ray.cast_to = global_transform.xform_inv(point) * 0.9
			wrap_ray.force_raycast_update()
			if wrap_ray.is_colliding():
				
				# Add current point to line renderer and to the wrap point list
				rope.add_point(stuck_position,rope.get_point_count()-2)
				wrap_points.append(stuck_position)
				
				# Change position
				stuck_position = wrap_ray.get_collision_point()
				rope_length = stuck_position.distance_to(global_position)
			
			# Check for unwrapping
			if not wrap_points.empty():
				wrap_ray.cast_to = global_transform.xform_inv(wrap_points[-1]) * 0.9
				wrap_ray.force_raycast_update()
				if not wrap_ray.is_colliding():
					# Unwrap
					var old_stuck_pos = stuck_position
					stuck_position = wrap_points.pop_back()
					rope_length += old_stuck_pos.distance_to(stuck_position)
					if rope.get_point_count() > 1:
						rope.remove_point(1)


# Get where the hook is stuck
func get_world_point() -> Vector2:
	var pos = stuck_position
	if stuck_parent != null:
		pos = stuck_parent.transform.xform(stuck_position)
	return pos


# DEBUG
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
			
			if not extended:
				
				wrap_ray.cast_to = get_global_mouse_position() - player.global_position
				wrap_ray.force_raycast_update()
				
				stuck_position = wrap_ray.get_collision_point()
				rope_length = stuck_position.distance_to(global_position)
				
				# Reset points
				rope.clear_points()
				rope.add_point(player.global_position)
				rope.add_point(stuck_position)
				
				# Find parent
				if wrap_ray.get_collider() is KinematicBody2D:
					stuck_parent = wrap_ray.get_collider()
					stuck_position = stuck_parent.transform.xform_inv(stuck_position)
					wrap_ray.add_exception(stuck_parent)
				else:
					stuck_parent = null
				
				extended = true
			else:
				extended = false
				
				rope.clear_points()
				wrap_points.clear()
				
				stuck_parent = null
				stuck_position = Vector2.ZERO
				# We boost the player a little
				player.motion *= 1.5
