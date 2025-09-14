extends Control


func _ready() -> void:
	%btn_toggle_rot.title_text = "" if Mng.scissors_rotation_sequential else "x"
	%btn_play_intro.title_text = "x" if Mng.play_intro else ""


func _on_btn_toggle_rot_pressed() -> void:
	Mng.scissors_rotation_sequential = !Mng.scissors_rotation_sequential
	%btn_toggle_rot.title_text = "" if Mng.scissors_rotation_sequential else "x"
func _on_btn_play_intro_pressed() -> void:
	Mng.play_intro = !Mng.play_intro
	%btn_play_intro.title_text = "x" if Mng.play_intro else ""


func _on_btn_easy_pressed() -> void:
	Mng.game_difficulty = 1
	if Mng.play_intro: Mng.go_to_intro()
	else: Mng.start_game()
func _on_btn_medium_pressed() -> void:
	Mng.game_difficulty = 2
	if Mng.play_intro: Mng.go_to_intro()
	else: Mng.start_game()
func _on_btn_hard_pressed() -> void:
	Mng.game_difficulty = 3
	if Mng.play_intro: Mng.go_to_intro()
	else: Mng.start_game()


func _on_btn_go_to_menu_pressed() -> void:
	hide()
