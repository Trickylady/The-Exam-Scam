extends PanelContainer
class_name PnlDebug

var level: Level
func _set_level(l: Level) -> void:
	level = l



func setup() -> void:
	Mng


func _on_btn_go_to_level_pressed() -> void:
	Mng.go_to_level(int(%sp_level_select.value))
