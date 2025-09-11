extends Control


func _ready() -> void:
	Aud.play_win_game()


func _on_btn_go_to_menu_pressed() -> void:
	Mng.go_to_main_menu()
