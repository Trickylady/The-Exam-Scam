extends Area2D
class_name CuttingLine


@onready var coll_forw: CollisionShape2D = %coll_forw
@onready var coll_back: CollisionShape2D = %coll_back


var level: Level
var is_boosting: bool
var target_segment: PackedVector2Array

var _grow_delta: float
var _length_forw: float
var _length_back: float
@onready var _shape_forw: SegmentShape2D = %coll_forw.shape
@onready var _shape_back: SegmentShape2D = %coll_back.shape
var has_reached_forw: bool = false
var has_reached_back: bool = false


signal finished
signal pencil_touched(pencil: Pencil)


func _ready() -> void:
	%line_back.width = Mng.cut_thickness
	%line_forw.width = Mng.cut_thickness
	if not is_boosting:
		%line_back.gradient = preload("res://instances/scissors/grad_shoot_normal.tres")
		%line_forw.gradient = preload("res://instances/scissors/grad_shoot_normal.tres")
	else:
		%line_back.gradient = preload("res://instances/scissors/grad_shoot_boost.tres")
		%line_forw.gradient = preload("res://instances/scissors/grad_shoot_boost.tres")
	
	_grow_delta = Mng.cutting_grow_speed_base
	if is_boosting:
		_grow_delta *= Mng.cutting_grow_speed_mult
	
	_length_back = (target_segment[0] - position).length()
	_length_forw = (target_segment[1] - position).length()
	_shape_back.b.x = 0
	_shape_forw.b.x = 0
	set_capture_mouse(true)


func _physics_process(delta: float) -> void:
	if not has_reached_forw:
		_shape_forw.b.x += _grow_delta * delta
	if not has_reached_back:
		_shape_back.b.x -= _grow_delta * delta
	has_reached_forw = abs(_shape_forw.b.x) > _length_forw
	has_reached_back = abs(_shape_back.b.x) > _length_back
	
	if has_reached_forw and has_reached_back:
		complete()


func _process(_delta: float) -> void:
	%line_back.points = [
		Vector2.ZERO,
		Vector2(_shape_back.b.x, 0),
	]
	%line_forw.points = [
		Vector2.ZERO,
		Vector2(_shape_forw.b.x, 0),
	]


func set_capture_mouse(val: bool) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if val else Input.MOUSE_MODE_HIDDEN


func _on_body_entered(body: Node2D) -> void:
	if body is Pencil:
		hit()
		pencil_touched.emit(body)


func hit() -> void:
	Aud.play_hit()
	set_capture_mouse(false)
	queue_free()


func complete() -> void:
	Aud.play_nice()
	finished.emit()
	level.paper.cut_along_segment(target_segment, position)
	set_capture_mouse(false)
	queue_free()
