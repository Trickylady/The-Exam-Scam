extends Node2D

var cursor_reg: Texture


func _ready() -> void:
	cursor_reg = load("res://images/mouse_cursor_normal.png")
	Input.set_custom_mouse_cursor(cursor_reg)
	$exitbutton.pressed.connect(_on_exitbutton_pressed)
	$sound.pressed.connect(_on_sound_input)


func _on_sound_input():
		get_tree().change_scene_to_file("res://Sound.tscn")


func _on_exitbutton_pressed():
	get_tree().quit()


func _exit_tree():
	Input.set_custom_mouse_cursor(null)


func _on_playbutton_pressed() -> void:
	Mng.start_game()
