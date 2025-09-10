extends Node2D
class_name PencilsMng


const SLOW_MULT: float = 0.4

var level: Level
func _set_level(l: Level) -> void:
	level = l
var pencils: Array[Pencil] = []

var n_pencils: int
var pencils_radius: float
var pencils_speed: float
var is_slow_active: bool = false

var _tw_slow: Tween
var _tmr_slow: Timer


func setup() -> void:
	pencils.clear()
	for node: Node in get_children():
		node.queue_free()
		#if node is Pencil:
			#pencils.append(node)
	await get_tree().process_frame
	n_pencils = level.n * 2 + 3
	pencils_radius = 120.0 / n_pencils
	pencils_speed = 300.0 + 100 * level.n
	for i in n_pencils:
		spawn_pencil(pencils_radius, pencils_speed)
	
	if not level.is_node_ready(): await level.ready
	_tmr_slow = Timer.new()
	_tmr_slow.wait_time = 5 #seconds
	_tmr_slow.one_shot = true
	_tmr_slow.timeout.connect(_on_tmr_slow_timeout)
	add_child(_tmr_slow)


func spawn_pencil(radius: float, speed: float) -> void:
	var new_pencil: Pencil = preload("res://instances/pencil/pencil.tscn").instantiate()
	new_pencil.radius = radius
	new_pencil.speed = speed
	new_pencil.position = level.paper.get_random_point_in_paper()
	pencils.append(new_pencil)
	add_child(new_pencil)


func start_slow() -> void:
	is_slow_active = true
	_tmr_slow.start()
	var slow_speed: float = pencils_speed * SLOW_MULT
	if _tw_slow:
		_tw_slow.kill()
	_tw_slow = create_tween()
	_tw_slow.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	for pencil: Pencil in pencils:
		_tw_slow.tween_property(pencil, "speed", slow_speed, 0.25)


func end_slow() -> void:
	if _tw_slow:
		_tw_slow.kill()
	_tw_slow = create_tween()
	_tw_slow.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
	for pencil: Pencil in pencils:
		_tw_slow.parallel().tween_property(pencil, "speed", pencils_speed, 1.5)
	#is_slow_active = false
	_tw_slow.tween_property(self, "is_slow_active", false, 0.0)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"slow_down"):
		var can_slow: bool = Mng.slow_n > 0 and not is_slow_active
		if can_slow:
			Mng.slow_n -= 1
			start_slow()


func _on_tmr_slow_timeout() -> void:
	end_slow()
