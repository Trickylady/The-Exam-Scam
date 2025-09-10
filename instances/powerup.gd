extends Node2D
class_name Powerup


const IMGS = {
	"Lives": preload("res://images/1up.png"),
	"Boosts": preload("res://images/adderall.png"),
	"Slows": preload("res://images/xanax.png"),
}

enum Type {
	LIFE,
	BOOST,
	SLOW
}

var type: Type
var level: Level
var _tw_anim: Tween

signal collected(powerup: Powerup)


func _ready() -> void:
	$tmr_despawn.wait_time = Mng.powerup_despawn_time
	$tmr_despawn.timeout.connect(_on_tmr_despawn_timeout)
	assign_image()
	if not level: return
	level.paper.paper_removed.connect(_on_paper_removed)
	spawn_in()
	$tmr_despawn.start()


func _on_paper_removed(polygon: PackedVector2Array) -> void:
	var is_collected: bool = Geometry2D.is_point_in_polygon(position, polygon)
	if not is_collected: return
	collect()


func assign_image() -> void:
	match type:
		Type.LIFE: $sprite.texture = IMGS.Lives
		Type.BOOST: $sprite.texture = IMGS.Boosts
		Type.SLOW: $sprite.texture = IMGS.Slows


func spawn_in() -> void:
	const SPAWN_DURATION = 0.6
	var _orig_sprite_scale: Vector2 = $sprite.scale
	var _orig_shadow_scale: Vector2 = $shadow.scale
	var _orig_sprite_pos: Vector2 = $sprite.position
	
	$sprite.position.y -= 600
	$sprite.scale *= 1.5
	$sprite.modulate.a = 0
	$shadow.scale = Vector2.ONE * 0.05
	
	if _tw_anim:
		_tw_anim.kill()
	_tw_anim = create_tween()
	_tw_anim.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	_tw_anim.parallel().tween_property($sprite, ^"scale", _orig_sprite_scale, SPAWN_DURATION)
	_tw_anim.parallel().tween_property($sprite, ^"position:y", _orig_sprite_pos.y, SPAWN_DURATION)
	_tw_anim.parallel().tween_property($sprite, ^"modulate:a", 1, SPAWN_DURATION)
	_tw_anim.parallel().tween_property($shadow, ^"scale", _orig_shadow_scale, SPAWN_DURATION)


func despawn() -> void:
	const DESPAWN_DURATION = 0.3
	if _tw_anim:
		_tw_anim.kill()
	_tw_anim = create_tween()
	_tw_anim.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	_tw_anim.parallel().tween_property($sprite, ^"scale", Vector2.ONE * 1.5, DESPAWN_DURATION)
	_tw_anim.parallel().tween_property($sprite, ^"position:y", $sprite.position.y - 24, DESPAWN_DURATION)
	_tw_anim.parallel().tween_property($sprite, ^"modulate:a", 0, DESPAWN_DURATION)
	_tw_anim.parallel().tween_property($shadow, ^"scale", Vector2.ZERO, DESPAWN_DURATION)
	_tw_anim.parallel().tween_property($shadow, ^"modulate:a", 0, DESPAWN_DURATION)
	_tw_anim.tween_callback(queue_free)


func collect() -> void:
	collected.emit(self)
	match type:
		Type.LIFE: Mng.lives += 1
		Type.BOOST: Mng.boost_n += 1
		Type.SLOW: Mng.slow_n += 1
	# TODO: animate
	if $sfx_collect.stream:
		$sfx_collect.play()
		#await $sfx_collect.finished
	despawn()


func _on_tmr_despawn_timeout() -> void:
	despawn()
