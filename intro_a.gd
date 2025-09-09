extends Node2D

var cursor_reg: Texture

func _ready() -> void:
	cursor_reg = load("res://images/mouse_cursor_normal.png")
	Input.set_custom_mouse_cursor(cursor_reg)
	$skipintro.pressed.connect(_on_skipintro_input)

func _on_skipintro_input():
		get_tree().change_scene_to_file("res://level_1.tscn")

func _exit_tree():
	Input.set_custom_mouse_cursor(null)


func _on_timmy_slide_animation_finished(_Timmyslide: StringName) -> void:
	get_tree().change_scene_to_file("res://level_1.tscn")
