extends Control
class_name Level

@onready var hud: HUD = %HUD
@onready var paper: Paper = %paper
@onready var pencils_mng: PencilsMng = %pencils_mng
@onready var scissors: Scissors = %scissors

@export var n: int = 1

var goal_completion: float = 0.75 # 0 to 1

signal level_won
signal level_lost


var pencils: Array[Pencil]:
	get: return pencils_mng.pencils


#region Init
func start() -> void:
	propagate_call("setup", [], true)


func setup() -> void:
	_assign_references()
	_connect_signals()
	_update_world_boundaries()


func _assign_references() -> void:
	propagate_call("_set_level", [self], true)


func _connect_signals() -> void:
	item_rect_changed.connect(_update_world_boundaries)
	scissors.cut_line_hit.connect(_on_scissors_line_hit)
	paper.available_area_updated.connect(_on_paper_area_updated)


func _update_world_boundaries() -> void:
	await get_tree().process_frame
	%coll_bot.position.y = size.y
	%coll_right.position.x = size.x
#endregion


func _on_scissors_line_hit(_pencil: Pencil) -> void:
	Mng.lives -= 1
	if Mng.lives <= 0:
		level_lost.emit()


func _on_paper_area_updated() -> void:
	if paper.completed_ratio > goal_completion:
		level_won.emit()
