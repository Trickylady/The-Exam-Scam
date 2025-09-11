extends Control


func _ready() -> void:
	Aud.play_menu_music()
	Aud.play_win_game()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$credits.hide()


func _on_btn_go_to_menu_pressed() -> void:
	Mng.go_to_main_menu()


func _on_btn_credits_pressed() -> void:
	$credits.show()
