extends Node2D
class_name PowerupsMng


var level: Level
func _set_level(l: Level) -> void:
	level = l
var tmr_spawn_new: Timer

signal powerup_collected(powerup: Powerup)


func _ready() -> void:
	tmr_spawn_new = Timer.new()
	tmr_spawn_new.wait_time = Mng.powerup_spawn_new_time
	tmr_spawn_new.one_shot = false
	tmr_spawn_new.timeout.connect(_on_tmr_spawn_new_timeout)
	add_child(tmr_spawn_new)
	tmr_spawn_new.start()


func spawn_new_powerup() -> void:
	var new_powerup: Powerup = preload("res://instances/powerups/powerup.tscn").instantiate()
	new_powerup.level = level
	new_powerup.type = Mng.powerup_spaw_probabilities.keys().pick_random() # TODO
	new_powerup.position = level.paper.get_random_point_in_paper()
	new_powerup.collected.connect(_on_powerup_collected)
	add_child(new_powerup)


func _on_powerup_collected(powerup: Powerup) -> void:
	powerup_collected.emit(powerup)


func _on_tmr_spawn_new_timeout() -> void:
	spawn_new_powerup()
