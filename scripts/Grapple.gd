extends Line2D
# The actual 'hook' part of the grapple
const NUM_LINE_POINTS := 50

onready var hook := $GrapppleCheck

# Used for visuals
export var wobble_curve : Curve
export var wobble_intensity : float

var motion : Vector2
var thrown : bool = false # Has the hook been thrown?
var shot_time : float

# Emitted when we hit something
signal grapple_hit(position,thing)

func _ready() -> void:
	# Setup line renderer
	visible = false
	for i in range(NUM_LINE_POINTS):
		add_point(Vector2.ZERO)
	# Exclude parent
	hook.add_exception(get_parent())


# Move the hook and actually embed it in stuff
func _physics_process(delta:float) -> void:
	if thrown:
		hook.position += motion * delta
		hook.cast_to = motion * delta
		
		shot_time += delta
		recalculate_visuals()
		
		hook.force_raycast_update()
		if hook.is_colliding():
			# We must have hit something
			emit_signal("grapple_hit",hook.get_collision_point(),hook.get_collider())
			end_throw()


# Recalculate the viuals for the hook
func recalculate_visuals() -> void:
	set_point_position(NUM_LINE_POINTS-1,Vector2.ZERO)
	
	var tangent = hook.position.normalized().tangent()
	
	# Set point visuals
	for i in range(1,NUM_LINE_POINTS-1):
		var prog = 1-(float(i)/(NUM_LINE_POINTS-2))
		
		var pos = hook.position * prog
		
		pos += tangent * cos(pos.length()*0.1+shot_time) * wobble_intensity * wobble_curve.interpolate(prog)
		
		set_point_position(i,pos)
	
	set_point_position(0,hook.position)


func throw(mot:Vector2) -> void:
	motion = mot
	thrown = true
	shot_time = 0
	
	hook.position = Vector2.ZERO
	hook.cast_to = motion.normalized() * 16
	visible = true

func end_throw() -> void:
	thrown = false
	visible = false
