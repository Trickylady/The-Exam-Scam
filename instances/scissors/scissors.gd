@tool
extends Node2D
class_name Scissors


@export var debug: bool = false

@export_range(3, 10) var n_angles: int = 4
@export_range(0.25, 2.0, 0.05) var scaling: float = 0.6:
	set(val):
		scaling = val
		if is_node_ready(): $sprite.scale = Vector2.ONE * scaling

@export_range(0.25, 2.0, 0.05) var cutting_line_thickness: float = 0.6

@export_subgroup("Boost")
@export_range(300.0, 2000.0, 5.0) var cutting_base_speed: float = 800 #px/s
@export_range(1.0, 5.0) var boost_mult: float = 2.5
@export var is_boosting: bool = false:
	set(val):
		if is_boosting == val: return
		is_boosting = val
		_update_shoot()

@export_subgroup("Shoot circles", "shoot_")
@export_range(0.25, 10.0, 0.25) var shoot_circles_anim_speed: float = 3.0:
	set(val):
		shoot_circles_anim_speed = val
		_update_shoot()
@export var shoot_circles_normal_speed: float = 50:
	set(val):
		shoot_circles_normal_speed = val
		_update_shoot()
@export var shoot_circles_boost_speed: float = 90:
	set(val):
		shoot_circles_boost_speed = val
		_update_shoot()
@export var shoot_col_normal: Gradient = preload("res://instances/scissors/grad_shoot_normal.tres"):
	set(val):
		shoot_col_normal = val
		_update_shoot()
@export var shoot_col_boost: Gradient = preload("res://instances/scissors/grad_shoot_boost.tres"):
	set(val):
		shoot_col_boost = val
		_update_shoot()

var level: Level
func _set_level(l: Level) -> void:
	level = l

var angles: Array[float] = []
var _angle_idx: int = 0:
	set(val):
		_angle_idx = val
		_update_scissors_rotation()

var is_cutting: bool = false

var _tw_rot: Tween
var _hit_point_forw: Vector2
var _hit_point_back: Vector2

signal cut_line_hit(pencil: Pencil)


func _ready() -> void:
	# only game logic here
	if Engine.is_editor_hint(): return


func setup() -> void:
	_update_capture_mouse()
	visibility_changed.connect(_update_capture_mouse)
	var increment: float = TAU / n_angles
	for i in n_angles:
		var angle: float = increment * i
		angles.append(angle)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint(): return
	if is_cutting: return
	position = get_global_mouse_position()
	is_boosting = Input.is_action_pressed(&"boost_speed")
	if debug:
		queue_redraw()


func _physics_process(_delta: float) -> void:
	if is_cutting: return
	if Engine.is_editor_hint(): return
	
	if %ray_forw.is_colliding():
		_hit_point_forw = %ray_forw.get_collision_point()
	else:
		_hit_point_forw = Vector2(-1,-1)
	if %ray_back.is_colliding():
		_hit_point_back = %ray_back.get_collision_point()
	else:
		_hit_point_back = Vector2(-1,-1)


func cycle_angle(is_clockwise: bool) -> void:
	if is_cutting: return
	var increment = -1 if is_clockwise else 1
	_angle_idx = wrapi(_angle_idx + increment, 0, angles.size())


func cut() -> void:
	if is_cutting: return
	if _tw_rot:
		if _tw_rot.is_running():
			await _tw_rot.finished
	
	is_cutting = true
	var cutting_line: CuttingLine = preload("res://instances/cutting_line/cutting_line.tscn").instantiate()
	cutting_line.level = level
	cutting_line.grow_speed = cutting_base_speed
	cutting_line.position = position
	cutting_line.rotation = rotation
	cutting_line.boost_mult = 1.0 if not is_boosting else boost_mult
	cutting_line.target_segment = PackedVector2Array([_hit_point_back, _hit_point_forw])
	cutting_line.finished.connect(_on_cutting_line_finished)
	cutting_line.pencil_touched.connect(_on_cutting_line_pencil_touched)
	level.add_child(cutting_line)


func _on_cutting_line_finished() -> void:
	is_cutting = false


func _on_cutting_line_pencil_touched(pencil: Pencil) -> void:
	is_cutting = false
	cut_line_hit.emit(pencil)


func _update_scissors_rotation() -> void:
	if not is_node_ready(): return
	if _tw_rot:
		_tw_rot.kill()
	
	var target: float = angles[_angle_idx]
	var delta := angle_difference(rotation, target)
	target = rotation + delta
	
	_tw_rot = create_tween()
	_tw_rot.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SPRING)
	_tw_rot.tween_property(self, ^"rotation", target, 0.15)


func _update_shoot() -> void:
	if not is_node_ready(): return
	var _boosting: bool = is_boosting
	if not Engine.is_editor_hint():
		_boosting = _boosting # TODO: check for boost in inventory
	var grad: Gradient = shoot_col_boost if _boosting else shoot_col_normal
	var shoot_speed: float = shoot_circles_boost_speed if _boosting else shoot_circles_normal_speed
	%part_forw.color_ramp = grad
	%part_back.color_ramp = grad
	%part_forw.initial_velocity_max= shoot_speed
	%part_forw.initial_velocity_min= shoot_speed
	%part_back.initial_velocity_max= shoot_speed
	%part_back.initial_velocity_min= shoot_speed
	%part_forw.speed_scale = shoot_circles_anim_speed
	%part_back.speed_scale = shoot_circles_anim_speed


func _update_capture_mouse() -> void:
	var is_mouse_hidden: bool = is_visible_in_tree() and not get_tree().paused
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if is_mouse_hidden else Input.MOUSE_MODE_VISIBLE


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"rotate_c"): cycle_angle(true)
	elif event.is_action_pressed(&"rotate_cc"): cycle_angle(false)
	if event is InputEventMouseButton:
		if not level.paper.is_point_in_paper(event.position): return
		if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
			cut()


func _draw() -> void:
	if !debug: return
	if _hit_point_forw != Vector2(-1,-1):
		var p: Vector2 = _hit_point_forw - global_position
		p = p.rotated(-rotation)
		draw_circle(p, 4, Color.RED)
	if _hit_point_back != Vector2(-1,-1):
		var p: Vector2 = _hit_point_back - global_position
		p = p.rotated(-rotation)
		draw_circle(p, 4, Color.RED)
