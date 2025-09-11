extends Control


func _ready() -> void:
	Aud.play_menu_music()
	Aud.play_lose()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_btn_go_to_menu_pressed() -> void:
	Mng.go_to_main_menu()
