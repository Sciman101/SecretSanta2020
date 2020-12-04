extends Node2D

const CREAK_ANGLE := (3.0/2)*PI

onready var rope := $RopeViz
onready var wrap_ray := $Ray
onready var player : KinematicBody2D = get_parent()

onready var sfx_creak := $"../SFX/Creak"

var particles

export var max_rope_length : float # Longest the rope can be
export var max_stretch : float # How much can the rope stretch
export var player_motion_multiplier : float

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
	
	# Setup particles
	particles = Node2D.new()
	particles.name = "LeafParticles"
	particles.set_script(load("res://scripts/LeafParticles.gd"))
	player.get_parent().call_deferred('add_child',particles)


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
		
		player.modulate = Color.white
		
		# Clamp player position to within the rope radius
		# Get the point we're dangling from
		var dangle_point = rope_points[0]
		var difference = dangle_point.world_pos() - player.global_position
		
		var slack = difference.length()
		
		# If we're holding right mouse, let the rope resize
#		var loose = Input.is_mouse_button_pressed(BUTTON_RIGHT)
#		if loose:
#			dangle_point.length_to_next = slack
		
		# Are we stretching the rope?
		if slack > dangle_point.length_to_next:
			
			# Snap the rope if it's too long
			if slack > dangle_point.length_to_next + 16:
				detach_grapple()
				return
			
			# Try and pull
			if dangle_point.relative != null and player.standing_on != dangle_point.relative:
				difference = -dangle_point.relative.pull(-difference,delta)
			
			# Move the player along the rope to the target pos
			var nudge = difference
			player.move_and_collide(nudge.normalized() * (slack - dangle_point.length_to_next))
			# Clamp the player's velocity. This means we can't stretch the rope, and it also creates the momentum effect
			player.motion = clamp_velocity_normal(player.motion,difference.normalized())
			
			# Check for creaking sfx trigger
			if abs(player.motion.x) > 100:
				if abs(get_angle()+CREAK_ANGLE-PI) < 0.25 and not sfx_creak.is_playing():
					sfx_creak.play()
			
			#player.modulate = Color.red
		
		
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
			
			# Are the two ropes even remotely aligned?
			var v1 = (rope_points[0].world_pos() - rope_points[1].world_pos()).normalized()
			var v2 = (player.global_position - rope_points[1].world_pos()).normalized()
			
			DebugDraw.line(rope_points[1].world_pos(),rope_points[1].world_pos()+v1*16,Color.red)
			DebugDraw.line(rope_points[1].world_pos(),rope_points[1].world_pos()+v2*16,Color.red)
			
			if v1.dot(v1) >= 0.5:
			
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
					
					DebugDraw.line(rope_points[1].world_pos(),player.global_position,Color.red)
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
		return dist * tang * .99 # We reduce the speed slightly so we dont swing forever
		
	return velocity


# Start the grapple
func attach_grapple(point:Vector2,relative) -> void:
	
	# If relative is null, then we undershot and missed
	if relative == null:
		create_leaf_particles(global_position,point)
		return
	
	extended = true
	
	if not relative.is_in_group("Grabbable"):
		relative = null
	
	# Create rope point
	var rp = RopePoint.new(point,relative,point.distance_to(player.global_position)-4) # Subtract a tiny bit so it's easier to swing from the ground without touching the floor
	
	# Stick and update length
	rope_points.append(rp)
	
	# Reset points and add base points
	rope.clear_points()
	rope.add_point(point)
	rope.add_point(player.global_position)


# Try and retract the rope
func try_retract(amt:float) -> void:
	if extended:
		rope_points[0].length_to_next -= amt


# Stop the grapple
func detach_grapple(show_particles:bool=true) -> void:
	extended = false
	
	# Create particles
	if show_particles:
		for i in range(-1,rope_points.size()-1):
			var pos1 = player.global_position if i == -1 else rope_points[i].world_pos()
			var pos2 = rope_points[i+1].world_pos()
			create_leaf_particles(pos1,pos2)
	
	# Drop the rope
	rope_points.clear()
	rope.clear_points()
	
	# Amplify player motion slightly
	player.motion *= player_motion_multiplier


# Create a line of leaf particles
func create_leaf_particles(from:Vector2,to:Vector2) -> void:
	var dist = floor(from.distance_to(to))* .2
	# Loop over the length of the segment
	for j in range(dist):
		particles.add_particle(lerp(from,to,float(j)/dist)+Vector2(rand_range(-4,4),rand_range(-4,4)),player.motion * 0.1 * (1-(float(j)/dist)))


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
