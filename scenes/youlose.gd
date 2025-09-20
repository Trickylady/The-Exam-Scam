extends Control


func _ready() -> void:
	Aud.play_menu_music()
	Aud.play_lose()
	Aud.start_random_lines()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if Mng.is_debug_build:
		#Mng.save_stats_to_json()
		Mng.leaderboard_mng.send_score_to_leaderboard("iRadDevLost")


func _on_btn_go_to_menu_pressed() -> void:
	Mng.go_to_main_menu()
