extends KinematicBody2D

const ACC_INSTANT = 1000000 # If acceleration time is 0, default to this
const HALF_PI := PI/2

# Exposed movement parameters
export var move_speed : float
export var acceleration_time : float # How many seconds does it take to go from 0 to max speed?
export var air_acceleration_time : float # How many seconds does it take to go from 0 to max speed, when we're midair?
export var friction_time : float # How many seconds does it take to go from max speed to 0?
export var jump_height : float # How many pixels vertically should we jump
export var jump_apex_time : float # How many seconds should it take to reach the peak of our jump
export var falling_grav_multiplier : float # When falling, we fall this much faster
export var min_jump_speed : float # Minimum jump speed for variable jumping
export var max_air_jumps : int

export var jump_buffer_time : float # How early can we press jump
export var edge_buffer_time : float # How late can we press jump

onready var grapple := $GrapplingHook

onready var sprite := $Sprite
onready var animation := $AnimationPlayer

# Calculated parameters
var _gravity : float
var _jump_speed : float
var _acceleration : float
var _air_acceleration : float
var _friction : float

# Buffers
var jump_buffer := 0.0 # When we press jump, set this to some value - if we hit the ground while it's still positive, jump.
var edge_buffer := 0.0 # When we leave a ledge, set this to some value. if jump_buffer > 0 when this is positive, jump

# Motion variables
var motion : Vector2
var grounded : bool
var was_grounded : bool
var air_jumps : int

var standing_on

func _ready() -> void:
	_calculate_movement_params()


# DEBUGGING
func _input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == BUTTON_WHEEL_UP:
				Engine.time_scale = min(1,Engine.time_scale+0.1)
			elif event.button_index == BUTTON_WHEEL_DOWN:
				Engine.time_scale = max(0,Engine.time_scale-0.1)


func _physics_process(delta:float) -> void:
	_handle_movement(delta)


# Calculate jump vars using projectile motion and acceleration
func _calculate_movement_params() -> void:
	_gravity = 2*jump_height/(jump_apex_time*jump_apex_time)
	_jump_speed = _gravity*jump_apex_time
	
	if acceleration_time != 0:
		_acceleration = move_speed / acceleration_time
	else:
		_acceleration = ACC_INSTANT
	
	if air_acceleration_time != 0:
		_air_acceleration = move_speed / air_acceleration_time
	else:
		_air_acceleration = ACC_INSTANT
	
	if friction_time != 0:
		_friction = move_speed / friction_time
	else:
		_friction = ACC_INSTANT

# Do all movement stuff
func _handle_movement(delta:float) -> void:
	grounded = is_on_floor()
	
	# Get horizontal input
	var hor := 0.0
	if Input.is_action_pressed("right"): hor += 1
	if Input.is_action_pressed("left"): hor -= 1
	
	# Flip horizontally
	if hor != 0:
		if not grapple.extended or grounded:
			sprite.flip_h = hor < 0
	
	if hor != 0 and grounded:
		animation.play("Walk")
	else:
		if grapple.extended and not grounded:
			animation.play("Spin")
		else:
			animation.stop()
			sprite.frame = 0
	
	var target_angle := 0.0
	
	if not grounded and not was_grounded:
		if grapple.extended:
			target_angle = grapple.get_angle() + HALF_PI
	sprite.rotation = lerp_angle(sprite.rotation,target_angle,delta*10)
	
	# Determine acceleration
	var acc = _acceleration
	if grounded:
		if hor == 0:
			acc = _friction
	else:
		if hor == 0:
			acc = 0
		else:
			acc = _air_acceleration
	
	if not grounded and grapple.is_hanging():
		# If grappling, free acceleration
		motion.x += _air_acceleration * hor * delta * 0.5
	else:
		# Accelerate
		motion.x = move_toward(motion.x,hor * move_speed,acc*delta)
	
	# Gravity
	motion.y += _gravity * delta * (1 if motion.y <= 0 else falling_grav_multiplier)
	
	# Jump input
	if Input.is_action_just_pressed("jump"):
		if grounded or air_jumps < max_air_jumps:
			jump_buffer = jump_buffer_time
	# Edge buffer
	if grounded and not was_grounded:
		edge_buffer = edge_buffer_time
		air_jumps = 0
	
	if jump_buffer > 0: jump_buffer = max(jump_buffer-delta,0)
	if edge_buffer > 0: edge_buffer = max(edge_buffer-delta,0)
#
#	# Jumping	
	if jump_buffer > 0 and (grounded or edge_buffer > 0 or air_jumps < max_air_jumps):
		# Apply speed
		motion.y = -_jump_speed
		
		# Air jump
		if not grounded and edge_buffer <= 0:
			air_jumps += 1
		
		# Clear buffers
		edge_buffer = 0
		jump_buffer = 0
	
	# Cancel jump
	if Input.is_action_just_released("jump") and motion.y < 0:
		motion.y = max(motion.y,-min_jump_speed)
	
	# Actually move
	motion = move_and_slide(motion,Vector2.UP)
	
	standing_on = null
	for i in range(get_slide_count()):
		var c = get_slide_collision(i)
		if c.normal == Vector2.UP and not (standing_on != null and standing_on is KinematicBody2D):
			standing_on = c.collider
	
	was_grounded = grounded
