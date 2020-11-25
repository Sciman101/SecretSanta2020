extends Node2D

const LeafTex = preload("res://textures/Leaves.png")
const SIZE = Vector2.ONE * 8

const MIN_LIFETIME = 0.5
const MAX_LIFETIME = 1

const GRAVITY := 25

var particles = []

func add_particle(position:Vector2,velocity:Vector2=Vector2.ZERO) -> void:
	particles.append({
		p=position,
		v=velocity+Vector2(rand_range(-16,16),rand_range(-16,16)),
		l=rand_range(MIN_LIFETIME,MAX_LIFETIME),
		f=randi()%3,
		c=lerp(Color.white,Color.darkgreen,rand_range(0,0.5))
	})

# Animate particles
func _process(delta:float) -> void:
	if not particles.empty():
		var expired = []
		for part in particles:
			part.v.y += GRAVITY * delta
			part.p += part.v * delta
			part.l -= delta
			
			if part.l <= 0:
				expired.append(part)
		
		# Remove expired particles
		if not expired.empty():
			for i in expired:
				particles.erase(i)
		update()

# Draw particles
func _draw():
	if not particles.empty():
		for part in particles:
			var c = part.c
			# Fade alpha over lifetime
			c.a = min(part.l*2,1)
			draw_texture_rect_region(LeafTex,Rect2(part.p,SIZE),Rect2(Vector2.RIGHT*part.f*SIZE.x,SIZE),c)
