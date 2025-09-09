extends Node2D
class_name PencilsMng


var level: Level
func _set_level(l: Level) -> void:
	level = l
var pencils: Array[Pencil] = []


func setup() -> void:
	pencils.clear()
	for node: Node in get_children():
		if node is Pencil:
			pencils.append(node)
