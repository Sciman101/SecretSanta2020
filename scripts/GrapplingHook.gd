extends Node2D

onready var rope := $Rope
onready var wrap_ray := $Ray
onready var player : KinematicBody2D = get_parent()

export var max_rope_length : float # Longest the rope can be
export var max_stretch : float # How much can the rope stretch
export var shot_gravity : float

var extended : bool = false # Is the rope extended?

var shot_position : Vector2 # Position of the fired shot
var shot_motion : Vector2
var shot : bool = false

var rope_points = [] # All rope points

func _ready() -> void:
	# Don't collide with player
	wrap_ray.add_exception(player)
	# Unparent rope so it works in world space, because the inverse transform stuff is a pain in the ass
	remove_child(rope)
	player.get_parent().call_deferred('add_child',rope)
	player.get_parent().call_deferred('move_child',rope,player.get_index())


# Draw rope
func _process(delta):
	if extended:
		var n = rope.get_point_count()
		# We reverse points so the vine extends from the pot
		if rope_points.size()+1 == n:
			# Update visuals
			rope.set_point_position(n-1,player.global_position)
			var index = n-2
			for point in rope_points:
				rope.set_point_position(index,point.world_pos())
				index -= 1


# Update the rope
func _physics_process(delta:float) -> void:
	if extended:
		
		var loose = Input.is_mouse_button_pressed(BUTTON_RIGHT)
		
		# Clamp player position to within the rope radius
		# Get the point we're dangling from
		var dangle_point = rope_points[0]
		var difference = dangle_point.world_pos() - player.global_position
		
		var slack = difference.length()
		
		# If we're holding right mouse, let the rope resize
		if loose:
			dangle_point.length_to_next = slack
		
		# Are we stretching the rope?
		if slack > dangle_point.length_to_next:
			
			# Snap the rope if it's too long
			if slack > dangle_point.length_to_next * 1.1:
				detach_grapple()
				return
			
			# Try and pull
			if dangle_point.relative != null and player.standing_on != dangle_point.relative:
				difference = -dangle_point.relative.pull(-difference,delta)
			
			# Move the player along the rope to the target pos
			player.move_and_collide(difference.normalized() * (slack - dangle_point.length_to_next))
			# Clamp the player's velocity. This means we can't stretch the rope, and it also creates the momentum effect
			player.motion = clamp_velocity_normal(player.motion,difference.normalized())
		
		
		# Check for wrapping
		wrap_ray.cast_to = global_transform.xform_inv(dangle_point.world_pos()) * 0.9
		wrap_ray.force_raycast_update()
		if wrap_ray.is_colliding():
			
			# Get the point and add it to the list
			var pos = wrap_ray.get_collision_point()
			var next_pos = player.global_position
			var point = RopePoint.new(pos,wrap_ray.get_collider(),next_pos.distance_to(pos))
			
			# Change length of rope
			rope_points[0].length_to_next -= point.length_to_next
			
			rope_points.push_front(point)
			rope.add_point(point.world_pos(),1)
		
		# Check for unwrapping
		elif rope_points.size() > 1:
		
			wrap_ray.cast_to = global_transform.xform_inv(rope_points[1].world_pos()) * 0.9
			wrap_ray.force_raycast_update()
			
			if not wrap_ray.is_colliding():
				
				# Check against projected ray
				var origin = rope_points[0].world_pos()
				
				var n = (player.global_position - rope_points[1].world_pos()).normalized()
				var end = rope_points[1].world_pos() + (n.dot(rope_points[0].world_pos() - rope_points[1].world_pos()) * n)
				
				# We nudge the position out a tad bit so we don't intersect stuff
				wrap_ray.global_position = origin + (end - origin) * 0.5
				wrap_ray.cast_to = (end - origin) * 0.9
				wrap_ray.force_raycast_update()
				wrap_ray.position = Vector2.ZERO
				
				DebugDraw.line(origin,end,Color.red)
				
				if not wrap_ray.is_colliding():
					# Unwrap
					var old_point = rope_points[0]
					rope_points.remove(0)
					rope_points[0].length_to_next += old_point.length_to_next
					
					# Update visual
					rope.remove_point(1)

# Given a normal, ensure any velocity with a dot product less than 0 is removed
func clamp_velocity_normal(velocity:Vector2,norm:Vector2) -> Vector2:
	# First: do we even need to reproject motion?
	if norm.dot(velocity) < 0:
		# Ok we do
		# Vector projection time!
		# https://demoman.net/?a=circle-vs-line (11/13)
		
		# Get the tangent vector
		var tang = norm.tangent().normalized()
		# Calculate distance along it
		var dist = velocity.dot(tang)
		return dist * tang # We reduce the speed slightly so we dont swing forever
		
	return velocity


# Start the grapple
func attach_grapple(point:RopePoint) -> void:
	extended = true
	
	# Stick and update length
	rope_points.append(point)
	
	# Reset points and add base points
	rope.clear_points()
	rope.add_point(point.world_pos())
	rope.add_point(player.global_position)


# Stop the grapple
func detach_grapple() -> void:
	extended = false
	# Drop the rope
	rope_points.clear()
	rope.clear_points()


# Are we hanging?
func is_hanging() -> bool:
	if extended:
		return (rope_points[0].world_pos() - player.global_position).dot(Vector2.UP) > 0
	return false


func get_angle() -> float:
	if extended:
		return (rope_points[0].world_pos() - player.global_position).angle()
	else:
		return 0.0


# DEBUG
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
			
			if not extended:
				
				wrap_ray.cast_to = (get_global_mouse_position() - player.global_position).normalized() * 512
				wrap_ray.force_raycast_update()
				
				var point = RopePoint.new(wrap_ray.get_collision_point(),wrap_ray.get_collider(),wrap_ray.get_collision_point().distance_to(player.global_position))
				attach_grapple(point)
				
			else:
				detach_grapple()
				# We boost the player a little
				player.motion *= 1.5


# A point on the rope
class RopePoint:
	
	var point : Vector2 # Where is this point anchored to?
	var relative : Node2D # What is the point relative to? null means world space
	var length_to_next : float # How far is it to the next point?
	
	func _init(world_point,relative,length) -> void:
		# Assign vars
		self.point = world_point
		self.relative = relative
		self.length_to_next = length
		# Check for relative
		if relative and relative.is_in_group('Grabbable'):
			self.point = relative.transform.xform_inv(point)
		else:
			self.relative = null
	
	# Get this rope point's position in world space
	func world_pos() -> Vector2:
		if relative:
			return relative.transform.xform(point)
		else:
			return point
