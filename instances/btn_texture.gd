@tool
extends Control
class_name ButtonPentagon


@export var title_text: String = "Easy":
	set(val):
		title_text = val
		_editor_update()
@export var subtitle_text: String = "3 Levels":
	set(val):
		subtitle_text = val
		_editor_update()
@export var bg_color: Color = Color("8cc0fd"):
	set(val):
		bg_color = val
		_editor_update()
@export var text_color: Color = Color.WHITE:
	set(val):
		text_color = val
		_editor_update()
@export_range(-180.0, 180.0, 0.1) var base_rot: float = 0.0:
	set(val):
		base_rot = val
		_rad_rot = deg_to_rad(base_rot)
		_editor_update()
@export_range(-180.0, 180.0, 0.1) var anim_rot: float = 0.0:
	set(val):
		anim_rot = val
		_anim_rad_rot = deg_to_rad(anim_rot)
		_anim_loop()
@export_range(-180.0, 180.0, 0.1) var text_rot: float = 12.5:
	set(val):
		text_rot = val
		_text_rad_rot = deg_to_rad(text_rot)
		_editor_update()
@export var anim_trans: Tween.TransitionType = Tween.TRANS_SINE:
	set(val):
		anim_trans = val
		_anim_loop()
@export var anim_speed: float = 1.0:
	set(val):
		anim_speed = val
		_anim_loop()
@export var levitate_min: float = 15: #px
	set(val):
		levitate_min = val
		_anim_loop()
@export var levitate_max: float = 30: #px
	set(val):
		levitate_max = val
		_anim_loop()


var _rad_rot: float
var _anim_rad_rot: float
var _text_rad_rot: float
var _tw_anim: Tween

signal pressed



func _ready() -> void:
	_editor_update()
	#await get_tree().create_timer(randf_range(0.0, anim_speed*2.0)).timeout
	_anim_loop()


func _reset() -> void:
	if _tw_anim: _tw_anim.kill()
	var dur: float = 0.06
	_tw_anim = create_tween()
	_tw_anim.set_ease(Tween.EASE_IN_OUT)
	_tw_anim.set_trans(anim_trans)
	_tw_anim.tween_property(%tex_rect_shadow, "scale", 1.025 * Vector2.ONE, dur)
	_tw_anim.parallel().tween_property(%tex_rect_shadow, "rotation", _rad_rot, dur)
	_tw_anim.parallel().tween_property(%tex_rect, "rotation", _rad_rot, dur)
	_tw_anim.parallel().tween_property(%tex_rect, "position:y", -levitate_min, dur)
	await _tw_anim.finished


func _anim_loop() -> void:
	if not is_node_ready(): await ready
	_reset()
	if _tw_anim:
		if _tw_anim.is_running():
			await _tw_anim.finished
		_tw_anim.kill()
	var duration: float = 2.0/anim_speed
	_tw_anim = create_tween()
	_tw_anim.set_ease(Tween.EASE_IN_OUT)
	_tw_anim.set_trans(anim_trans)
	_tw_anim.set_loops()
	_tw_anim.tween_property(%tex_rect_shadow, "scale", Vector2.ONE * 1.1, duration)
	_tw_anim.parallel().tween_property(%tex_rect, "position:y", -levitate_max, duration)
	_tw_anim.parallel().tween_property(%tex_rect, "rotation", _rad_rot - _anim_rad_rot, duration)
	_tw_anim.parallel().tween_property(%tex_rect_shadow, "rotation", _rad_rot - _anim_rad_rot, duration)
	_tw_anim.tween_property(%tex_rect_shadow, "scale", Vector2.ONE * 1.025, duration)
	_tw_anim.parallel().tween_property(%tex_rect, "position:y", -levitate_min, duration)
	_tw_anim.parallel().tween_property(%tex_rect, "rotation", _rad_rot + _anim_rad_rot, duration)
	_tw_anim.parallel().tween_property(%tex_rect_shadow, "rotation", _rad_rot + _anim_rad_rot, duration)


func _anim_hovered() -> void:
	if _tw_anim: _tw_anim.kill()
	var duration: float = 0.06
	_tw_anim = create_tween()
	_tw_anim.set_ease(Tween.EASE_OUT)
	_tw_anim.set_trans(anim_trans)
	_tw_anim.set_parallel()
	_tw_anim.tween_property(%tex_rect_shadow, "rotation", _rad_rot, duration)
	_tw_anim.tween_property(%tex_rect_shadow, "scale", Vector2.ONE, duration)
	_tw_anim.tween_property(%tex_rect, "rotation", _rad_rot, duration)
	_tw_anim.tween_property(%tex_rect, "position:y", -levitate_min/2.0, duration)


func _anim_pressed_down() -> void:
	if _tw_anim: _tw_anim.kill()
	var duration: float = 0.06
	_tw_anim = create_tween()
	_tw_anim.set_ease(Tween.EASE_OUT)
	_tw_anim.set_trans(anim_trans)
	_tw_anim.set_parallel()
	_tw_anim.tween_property(%tex_rect_shadow, "rotation", _rad_rot, duration)
	_tw_anim.tween_property(%tex_rect_shadow, "scale", Vector2.ONE, duration)
	_tw_anim.tween_property(%tex_rect, "rotation", _rad_rot, duration)
	_tw_anim.tween_property(%tex_rect, "position:y", 0, duration)


func _editor_update() -> void:
	if not is_node_ready(): return
	#if not Engine.is_editor_hint(): return
	_reset()
	%tex_rect.self_modulate = bg_color
	#%tex_rect.rotation = _rad_rot
	#%tex_rect_shadow.rotation = _rad_rot
	%vb.rotation = _text_rad_rot
	%vb.modulate = text_color
	%lb_title.visible = not title_text.is_empty()
	%lb_title.text = title_text
	%lb_sub.visible = not subtitle_text.is_empty()
	%lb_sub.text = subtitle_text



func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_released():
				_anim_loop()
				pressed.emit()
			else:
				_anim_pressed_down()
		


func _on_mouse_entered() -> void: _anim_hovered()
func _on_mouse_exited() -> void: _anim_loop()
