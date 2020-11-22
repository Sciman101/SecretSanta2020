extends Node2D

onready var rope := $Rope
onready var wrap_ray := $WrapCheck
onready var player : KinematicBody2D = get_parent()

export var max_rope_length : float # Longest the rope can be
export var max_stretch : float # How much can the rope stretch
export var shot_gravity : float

var extended : bool = false # Is the rope extended?

var shot_position : Vector2 # Position of the fired shot
var shot_motion : Vector2
var shot : bool = false

var allowed_slack : float = max_rope_length
var rope_points = [] # All rope points

func _ready() -> void:
	# Don't collide with player
	wrap_ray.add_exception(player)
	# Unparent rope so it works in world space, because the inverse transform stuff is a pain in the ass
	remove_child(rope)
	player.get_parent().call_deferred('add_child',rope)


# Draw rope
func _process(delta):
	if extended:
		if rope_points.size()+1 == rope.get_point_count():
			# Update visuals
			rope.set_point_position(0,player.global_position)
			var index = 1
			for point in rope_points:
				rope.set_point_position(index,point.world_pos())
				index += 1


# Update the rope
func _physics_process(delta:float) -> void:
	if extended:
		
		# Clamp player position to within the rope radius
		# Get the point we're dangling from
		var dangle_point = rope_points[0]
		var difference = dangle_point.world_pos() - player.global_position
		
		var slack = difference.length()
		
		if slack > allowed_slack:
			
			# Snap the rope if it's too long
			if slack > allowed_slack + max_stretch:
				detach_grapple()
				return
			
			# Try and pull
			if dangle_point.relative != null and player.standing_on != dangle_point.relative:
				difference = -dangle_point.relative.pull(-difference,delta)
			
			# Move the player along the rope to the target pos
			player.move_and_collide(difference.normalized() * (slack - allowed_slack))
			# Clamp the player's velocity. This means we can't stretch the rope, and it also creates the momentum effect
			player.motion = clamp_velocity_normal(player.motion,difference.normalized())
		
		
		# Check for wrapping
		wrap_ray.cast_to = global_transform.xform_inv(dangle_point.world_pos()) * 0.9
		wrap_ray.force_raycast_update()
		if wrap_ray.is_colliding():
			
			# Get the point and add it to the list
			var point = RopePoint.new(wrap_ray.get_collision_point(),wrap_ray.get_collider())
			rope_points.push_front(point)
			rope.add_point(point.world_pos(),1)
			
			# Change position
			allowed_slack -= point.world_pos().distance_to(rope_points[1].world_pos())
		
		# Check for unwrapping
		elif rope_points.size() > 1:
			wrap_ray.cast_to = global_transform.xform_inv(rope_points[1].world_pos()) * 0.9
			wrap_ray.force_raycast_update()
			
			# Check dot product
			var v1 = (rope_points[0].world_pos()-player.global_position).normalized()
			var v2 = (rope_points[1].world_pos()-player.global_position).normalized()
			
			if v1.dot(v2) >= 0.99 and not wrap_ray.is_colliding():
				# Unwrap
				var old_point = rope_points[0]
				rope_points.remove(0)
				allowed_slack += old_point.world_pos().distance_to(rope_points[0].world_pos())
				
				# Update visual
				rope.remove_point(1)

# Given a normal, ensure any velocity with a dot product less than 0 is removed
func clamp_velocity_normal(velocity:Vector2,norm:Vector2) -> Vector2:
	# First: do we even need to reproject motion?
	if norm.dot(velocity) < 0:
		# Ok we do
		# Create a tangent plane
		var tangent_plane = Plane(Vector3(norm.x,norm.y,0),0)
		var motion_new = tangent_plane.project(Vector3(velocity.x,velocity.y,0) * 0.99) # We decrease the velocity sliiiightly so we dont swing forever
		velocity.x = motion_new.x
		velocity.y = motion_new.y
	return velocity



# Start the grapple
func attach_grapple(point:RopePoint) -> void:
	extended = true
	
	# Raycast to find where we should stick
	wrap_ray.cast_to = get_global_mouse_position() - player.global_position
	wrap_ray.force_raycast_update()
	
	# Stick and update length
	rope_points.append(point)
	# Get slack
	allowed_slack = point.world_pos().distance_to(global_position)
	
	# Reset points and add base points
	rope.clear_points()
	rope.add_point(player.global_position)
	rope.add_point(point.world_pos())


# Stop the grapple
func detach_grapple() -> void:
	
	extended = false
	# Drop the rope
	rope_points.clear()
	rope.clear_points()


# DEBUG
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
			
			if not extended:
				
				var point = RopePoint.new(wrap_ray.get_collision_point(),wrap_ray.get_collider())
				attach_grapple(point)
				
			else:
				detach_grapple()
				# We boost the player a little
				player.motion *= 1.5


# A point on the rope
class RopePoint:
	var point : Vector2
	var relative : Node2D
	func _init(world_point,relative) -> void:
		# Assign vars
		self.point = world_point
		self.relative = relative
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
