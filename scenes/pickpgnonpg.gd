extends Control


func _on_btn_family_pressed() -> void:
	Mng.is_family_friendly = true
	Mng.go_to_main_menu()
	Aud.play_music()


func _on_btn_pg_pressed() -> void:
	Mng.is_family_friendly = false
	Mng.go_to_main_menu()
	Aud.play_music()
