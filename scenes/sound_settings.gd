extends Control
class_name SoundSettings


func _ready() -> void:
	%volume_master.value =  AudioServer.get_bus_volume_linear(0)
	%volume_sfx.value =  AudioServer.get_bus_volume_linear(1)
	%volume_mus.value =  AudioServer.get_bus_volume_linear(2)
	%volume_voice.value =  AudioServer.get_bus_volume_linear(3)


func _on_volume_master_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(0, value)
func _on_volume_sfx_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(1, value)
func _on_volume_mus_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(2, value)
func _on_volume_voice_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(3, value)


func _on_btn_back_pressed() -> void:
	hide()
