extends Control


func _ready() -> void:
	Aud.play_lose()
	_populate()


func _populate() -> void:
	%lb_score.text =  "[wave]%s[/wave]" % Mng.score


func _on_btn_go_to_menu_pressed() -> void:
	Mng.go_to_main_menu()


func _on_nextbutton_pressed() -> void:
	Mng.next_level()
