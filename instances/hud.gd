extends Control
class_name HUD

var level: Level
func _set_level(l: Level) -> void:
	level = l
@onready var coll_poly: PackedVector2Array = %coll.polygon


func setup() -> void:
	%progress.value = 0
	level.paper.available_area_updated.connect(_on_paper_available_area_updated)


func _on_paper_available_area_updated() -> void:
	%progress.value = level.paper.completed_ratio
