extends Node2D
class_name PencilsMng


var level: Level
func _set_level(l: Level) -> void:
	level = l
var pencils: Array[Pencil] = []


func setup() -> void:
	pencils.clear()
	for node: Node in get_children():
		node.queue_free()
		#if node is Pencil:
			#pencils.append(node)
	await get_tree().process_frame
	var n_pencils: int = level.n * 2 + 3
	var pencils_radius: float = 120.0 / n_pencils
	var pencils_speed: float = 300.0 + 100 * level.n
	for i in n_pencils:
		spawn_pencil(pencils_radius, pencils_speed)


func spawn_pencil(radius: float, speed: float) -> void:
	var new_pencil: Pencil = preload("res://instances/pencil/pencil.tscn").instantiate()
	new_pencil.radius = radius
	new_pencil.speed = speed
	new_pencil.position = level.paper.get_random_point_in_paper()
	pencils.append(new_pencil)
	add_child(new_pencil)
