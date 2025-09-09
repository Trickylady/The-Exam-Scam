extends Control
class_name Level

@onready var hud: HUD = %HUD
@onready var paper: Paper = %paper
@onready var pencils_mng: PencilsMng = %pencils_mng
@onready var scissors: Scissors = %scissors


var pencils: Array[Pencil]:
	get: return pencils_mng.pencils


#region Init
func _ready() -> void:
	propagate_call("setup", [], true)


func setup() -> void:
	_assign_references()
	_connect_signals()
	_update_world_boundaries()


func _assign_references() -> void:
	propagate_call("_set_level", [self], true)
	#paper.level = self
	#scissors.level = self
	#hud.level = self


func _connect_signals() -> void:
	item_rect_changed.connect(_update_world_boundaries)


func _update_world_boundaries() -> void:
	await get_tree().process_frame
	%coll_bot.position.y = size.y
	%coll_right.position.x = size.x
#endregion
