extends CharacterBody2D
class_name Pencil

@export_range(300, 2000, 0.5) var speed: float = 600.0
@export_range(2, 40, 0.5) var radius: float = 10.0:
	set(val):
		if is_equal_approx(radius, val): return
		radius = val
		if is_node_ready():
			resize(radius)

@onready var coll_shape: CollisionShape2D = $coll
@onready var sprite: Node2D = $sprite

const TEX_SIZE := 47.0
const SKIN := 0.5
const SAFE_MARGIN := 0.001
const MAX_BOUNCES_PER_FRAME := 8
const EPS := 1e-6


func _ready() -> void:
	if Engine.is_editor_hint(): return
	# Random initial direction and velocity
	var dir := Vector2.RIGHT.rotated(randf_range(0.0, TAU)).normalized()
	velocity = dir * speed
	resize(radius)


func resize(r: float) -> void:
	sprite.scale = Vector2.ONE * (r / (TEX_SIZE * 0.5))
	var circle := coll_shape.shape as CircleShape2D
	if circle:
		circle.radius = r


func _physics_process(delta: float) -> void:
	# keep magnitude locked to 'speed'
	if velocity.length() > 0.0:
		velocity = velocity.normalized() * speed
	else:
		velocity = Vector2.RIGHT * speed

	var remaining := speed * delta
	var tries := MAX_BOUNCES_PER_FRAME

	while remaining > 0.0 and tries > 0:
		tries -= 1
		
		var motion := velocity.normalized() * remaining
		var hit := move_and_collide(motion, false, SAFE_MARGIN, true)
		
		if hit:
			var leftover := hit.get_remainder().length()
			var n := hit.get_normal()
			var other := hit.get_collider()

			if other is Pencil:
				# Resolve once: only the owner handles the pair
				if _owns_pair(self, other):
					_bounce_pair_fixed_speed(self, other)
				# No manual translate() here for pair hits (handled in helper)
				remaining = leftover
			else:
				# Static bounce
				velocity = velocity.bounce(n).normalized() * speed
				translate(n * SKIN)  # tiny step only for statics
				remaining = leftover
		else:
			remaining = 0.0


static func _bounce_pair_fixed_speed(a: Pencil, b: Pencil) -> void:
	var n := (b.global_position - a.global_position).normalized()
	if n.length_squared() < EPS:
		n = Vector2.RIGHT

	var v1 := a.velocity
	var v2 := b.velocity
	var rel := v1 - v2
	var j := rel.dot(n)

	# swap normal components
	v1 -= j * n
	v2 += j * n

	# keep magnitudes
	a.velocity = v1.normalized() * a.speed
	b.velocity = v2.normalized() * b.speed

	# tiny separation so they don't instantly collide again
	a.translate(-n * SKIN)
	b.translate( n * SKIN)


static func _owns_pair(a: Pencil, b: Pencil) -> bool:
	return a.get_instance_id() < b.get_instance_id()
