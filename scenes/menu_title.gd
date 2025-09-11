extends Control
class_name MenuTitle




func _on_playbutton_pressed() -> void:
	Mng.go_to_intro()
func _on_sound_pressed() -> void:
	$sound_settings.show()
func _on_exitbutton_pressed():
	Mng.quit()
