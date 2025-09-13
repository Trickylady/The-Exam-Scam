extends Control


func _ready() -> void:
	%btn_toggle_rot.title_text = "" if Mng.scissors_rotation_sequential else "x"


func _on_btn_toggle_rot_pressed() -> void:
	Mng.scissors_rotation_sequential = !Mng.scissors_rotation_sequential
	%btn_toggle_rot.title_text = "" if Mng.scissors_rotation_sequential else "x"


func _on_btn_easy_pressed() -> void:
	Mng.game_difficulty = 1
	Mng.start_game()
func _on_btn_medium_pressed() -> void:
	Mng.game_difficulty = 2
	Mng.start_game()
func _on_btn_hard_pressed() -> void:
	Mng.game_difficulty = 3
	Mng.start_game()
