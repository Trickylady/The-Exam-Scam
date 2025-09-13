extends Control
class_name MenuTitle



func _ready() -> void:
	Aud.play_menu_music()
	Aud.stop_random_lines()
	$sound_settings.hide()
	$credits.hide()
	$difficulty_selector.hide()


func _on_btn_play_pressed() -> void:
	#Mng.go_to_intro()
	$difficulty_selector.show()
func _on_btn_exit_pressed() -> void:
	Mng.quit()
func _on_btn_sound_pressed() -> void:
	$sound_settings.show()
func _on_btn_credits_pressed() -> void:
	$credits.show()
