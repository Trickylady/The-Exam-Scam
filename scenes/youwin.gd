extends Control


func _ready() -> void:
	Aud.play_menu_music()
	Aud.play_win_game()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$credits.hide()


func _on_btn_go_to_menu_pressed() -> void:
	Mng.go_to_main_menu()

var _next_interval: float = 1.0
var _interval: float = 0.0 
func _process(delta: float) -> void:
	_interval += delta
	if _interval > _next_interval:
		_interval = 0
		_next_interval = randf_range(0.1, 1.5)
		var new_pos: Vector2 = Vector2.ZERO
		new_pos.x = randf_range(size.x/8.0, size.x - size.x/8.0)
		new_pos.y = randf_range(0, 1.5 * size.y/8.0)
		_add_firework_at_pos(new_pos)


func _add_firework_at_pos(pos: Vector2) -> void:
	var new_firework: CPUParticles2D = preload("res://instances/fireworks.tscn").instantiate()
	new_firework.position = pos
	new_firework.finished.connect(new_firework.queue_free)
	add_child(new_firework)
	new_firework.emitting = true


func _on_btn_credits_pressed() -> void:
	$credits.show()
