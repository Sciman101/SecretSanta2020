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
var wrap_points = [] # Positions where the rope has wrapped around something

func _ready() -> void:
	# Don't collide with player
	wrap_ray.add_exception(player)
	# Unparent rope so it works in world space, because the inverse transform stuff is a pain in the ass
	remove_child(rope)
	player.get_parent().call_deferred('add_child',rope)


func _process(delta):
	if extended:
		# Update rope visual
		rope.set_point_position(1,get_world_point()) # 1 is the stuck position
		rope.set_point_position(0,player.global_position) # 0 is the player


# Update the rope
func _physics_process(delta:float) -> void:
	if extended:
		
		# Clamp player position to within the rope radius
		var point = get_world_point()
		var difference = point - player.global_position
		
		var ropelen = difference.length()
		if ropelen > rope_length:
			
			# Try and pull
			if stuck_parent != null:
				difference = -stuck_parent.pull(-difference)
			
			# Move the player along the rope to the target pos
			player.move_and_collide(difference.normalized() * (ropelen - rope_length))
			# Clamp the player's velocity. This means we can't stretch the rope, and it also creates the momentum effect
			player.clamp_velocity_normal(difference.normalized())
		
		# Wrapping code
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
				
				extended = true
				
				# Raycast to find where we should stick
				wrap_ray.cast_to = get_global_mouse_position() - player.global_position
				wrap_ray.force_raycast_update()
				
				# Stick and update length
				stuck_position = wrap_ray.get_collision_point()
				rope_length = stuck_position.distance_to(global_position)
				
				# Did we hit something to parent to?
				stuck_parent = null
				if wrap_ray.get_collider().is_in_group('Grabbable'):
					stuck_parent = wrap_ray.get_collider()
					stuck_position = stuck_parent.transform.xform_inv(stuck_position)
				
				# Reset points and add base points
				rope.clear_points()
				rope.add_point(player.global_position)
				rope.add_point(stuck_position)
				
			else:
				extended = false
				
				# Drop the rope
				rope.clear_points()
				wrap_points.clear()
				
				stuck_parent = null
				stuck_position = Vector2.ZERO
				# We boost the player a little
				player.motion *= 1.5
