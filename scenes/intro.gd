extends Node2D


func _ready() -> void:
	$skipintro.pressed.connect(_on_skipintro_input)


func _on_skipintro_input():
	Mng.start_game()


func _on_timmy_slide_animation_finished(_Timmyslide: StringName) -> void:
	Mng.start_game()
