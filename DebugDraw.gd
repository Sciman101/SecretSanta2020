extends Node2D

enum {
	POINT,
	LINE,
	CIRCLE
}

var stack = []

func _ready():
	get_parent().call_deferred('move_child',self,get_parent().get_child_count()-1)

# Functions to add shapes to the stack
func point(pos:Vector2,col:Color) -> void:
	stack.append({type=POINT,p=pos,c=col})
func line(a:Vector2,b:Vector2,c:Color) -> void:
	stack.append({type=LINE,a=a,b=b,c=c})
func circle(center:Vector2,radius:float,c:Color) -> void:
	stack.append({type=CIRCLE,p=center,r=radius,c=c})

# Tell the engine to redraw us
func _process(delta):
	if not stack.empty():
		update()

# Draw all the queued stuff
func _draw():
	
	for item in stack:
		match item.type:
			POINT:
				draw_circle(item.p,2,item.c)
			LINE:
				draw_line(item.a,item.b,item.c)
			CIRCLE:
				draw_circle(item.p,item.r,item.c)
	stack.clear()
