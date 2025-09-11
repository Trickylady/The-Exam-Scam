extends Control
class_name SoundSettings


func _ready() -> void:
	%volume_master.value =  AudioServer.get_bus_volume_linear(0)
	%volume_sfx.value =  AudioServer.get_bus_volume_linear(1)
	%volume_mus.value =  AudioServer.get_bus_volume_linear(2)
	%volume_voice.value =  AudioServer.get_bus_volume_linear(3)


func _toggle_mute(bus: int) -> void:
	var is_mute: bool = AudioServer.is_bus_mute(bus)
	AudioServer.set_bus_mute(bus, !is_mute)
	match bus:
		0: %lb_master.text = "Master" if is_mute else "[color=black][s]Master"
		1: %lb_sfx.text = "Sfx" if is_mute else "[color=black][s]Sfx"
		2: %lb_music.text = "Music" if is_mute else "[color=black][s]Music"
		3: %lb_voice.text = "voice" if is_mute else "[color=black][s]voice"


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") and visible:
		hide()


func _on_btn_back_pressed() -> void:
	hide()

func _on_volume_master_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(0, value)
func _on_volume_sfx_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(1, value)
func _on_volume_mus_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(2, value)
func _on_volume_voice_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(3, value)


func _on_lb_master_gui_input(event: InputEvent) -> void: if event.is_pressed(): _toggle_mute(0)
func _on_lb_sfx_gui_input(event: InputEvent) -> void: if event.is_pressed(): _toggle_mute(1)
func _on_lb_music_gui_input(event: InputEvent) -> void: if event.is_pressed(): _toggle_mute(2)
func _on_lb_voice_gui_input(event: InputEvent) -> void: if event.is_pressed(): _toggle_mute(3)
