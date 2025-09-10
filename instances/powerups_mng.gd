extends Node2D
class_name PowerupsMng


# TODO
const PROBABILITIES = {
	Powerup.Type.LIFE: 0.0,
	Powerup.Type.BOOST: 0.0,
	Powerup.Type.SLOW: 0.0,
}

const SPAWN_NEW_TIME = 5 #s

var level: Level
func _set_level(l: Level) -> void:
	level = l
var tmr_spawn_new: Timer


func _ready() -> void:
	tmr_spawn_new = Timer.new()
	tmr_spawn_new.wait_time = SPAWN_NEW_TIME
	tmr_spawn_new.one_shot = false
	tmr_spawn_new.timeout.connect(_on_tmr_spawn_new_timeout)
	add_child(tmr_spawn_new)
	tmr_spawn_new.start()


func spawn_new_powerup() -> void:
	var new_powerup: Powerup = preload("res://instances/powerup.tscn").instantiate()
	new_powerup.level = level
	new_powerup.type = PROBABILITIES.keys().pick_random() # TODO
	new_powerup.position = level.paper.get_random_point_in_paper()
	add_child(new_powerup)


func _on_tmr_spawn_new_timeout() -> void:
	spawn_new_powerup()
