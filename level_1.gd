extends Node2D

func _ready() -> void:
	%gomenubutton.pressed.connect(_on_gomenubutton_input)

func _on_gomenubutton_input():
		get_tree().change_scene_to_file("res://Menu.tscn")
