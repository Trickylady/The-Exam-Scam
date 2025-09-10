extends Control
class_name HUD

var level: Level
func _set_level(l: Level) -> void:
	level = l
@onready var coll_poly: PackedVector2Array = %coll.polygon


func _ready() -> void:
	%pnl_debug.hide()


func setup() -> void:
	%progress.value = 0
	level.paper.available_area_updated.connect(_on_paper_available_area_updated)


func _on_paper_available_area_updated() -> void:
	%progress.value = level.paper.completed_ratio


func _input(event: InputEvent) -> void:
	if !Mng.is_debug_build: return
	if event is InputEventKey:
		if event.keycode == KEY_Q and event.is_pressed() and not event.is_echo():
			%pnl_debug.visible = !%pnl_debug.visible
