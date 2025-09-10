extends Area2D
class_name CuttingLine


var grow_speed: float = 800 #px/s


@onready var coll_forw: CollisionShape2D = %coll_forw
@onready var coll_back: CollisionShape2D = %coll_back
@onready var line: Line2D = %line


var level: Level
var boost_mult: float = 1.0
var thickness: float = 10.0
var target_segment: PackedVector2Array

var _length_forw: float
var _length_back: float
@onready var _shape_forw: SegmentShape2D = %coll_forw.shape
@onready var _shape_back: SegmentShape2D = %coll_back.shape
var has_reached_forw: bool = false
var has_reached_back: bool = false


signal finished
signal pencil_touched(pencil: Pencil)


func _ready() -> void:
	%line.width = thickness
	_length_back = (target_segment[0] - position).length()
	_length_forw = (target_segment[1] - position).length()
	_shape_back.b.x = 0
	_shape_forw.b.x = 0
	set_capture_mouse(true)


func _physics_process(delta: float) -> void:
	if not has_reached_forw:
		_shape_forw.b.x += grow_speed * boost_mult * delta
	if not has_reached_back:
		_shape_back.b.x -= grow_speed * boost_mult * delta
	has_reached_forw = abs(_shape_forw.b.x) > _length_forw
	has_reached_back = abs(_shape_back.b.x) > _length_back
	
	if has_reached_forw and has_reached_back:
		finished.emit()
		level.paper.cut_along_segment(target_segment, position)
		set_capture_mouse(false)
		queue_free()


func _process(_delta: float) -> void:
	%line.points = [
		Vector2(_shape_back.b.x, 0),
		Vector2(_shape_forw.b.x, 0)
	]


func set_capture_mouse(val: bool) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if val else Input.MOUSE_MODE_HIDDEN


func _on_body_entered(body: Node2D) -> void:
	if body is Pencil:
		set_capture_mouse(false)
		pencil_touched.emit(body)
		queue_free()
