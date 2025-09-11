extends TextureRect
class_name VolumeSlider


var value: float: set = _set_value

signal value_changed(value: float)


func _set_value(_value: float) -> void:
	value = clamp(_value, 0, 1)
	$bar.size.x = size.x * value
	value_changed.emit(value)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			value = event.position.x / size.x
	
	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			value = event.position.x / size.x
