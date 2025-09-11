extends Node2D

var cursor_reg: Texture

func _ready() -> void:
	cursor_reg = load("res://images/mouse_cursor_normal.png")
	Input.set_custom_mouse_cursor(cursor_reg)
	$ayouwin.input_event.connect(_on_ayouwin_input)

func _on_ayouwin_input(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_tree().change_scene_to_file("res://Menu.tscn")

func _exit_tree():
	Input.set_custom_mouse_cursor(null)
