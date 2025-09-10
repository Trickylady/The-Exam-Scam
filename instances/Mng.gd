#Singleton Mng.gd
extends Node


var is_debug_build: bool = true
var is_family_friendly: bool = true


const MAX_LIVES = 4
const INIT_BOOSTS = 4
const INIT_SLOWS = 4

var current_level_n: int
var score: int:
	set(val): score = val; score_updated.emit()
var lives: int:
	set(val): lives = val; lives_updated.emit()
var boost_n: int:
	set(val): boost_n = val; boost_n_updated.emit()
var slow_n: int:
	set(val): slow_n = val; slow_n_updated.emit()
signal score_updated
signal lives_updated
signal boost_n_updated
signal slow_n_updated

const LEVEL_PCK = preload("res://instances/level.tscn")
var level: Level

var start_from_level = 0
func _ready() -> void:
	reset_stats()
	if start_from_level:
		go_to_level(start_from_level)


func start_game() -> void:
	reset_stats()
	Mng.go_to_level(1)


func reset_stats() -> void:
	score = 0
	lives = 4
	current_level_n = 1
	boost_n = INIT_BOOSTS
	slow_n = INIT_SLOWS


func go_to_level(level_n: int) -> void:
	current_level_n = level_n
	await get_tree().process_frame
	get_tree().change_scene_to_packed(LEVEL_PCK)
	await get_tree().node_added
	await get_tree().current_scene.ready
	level = get_tree().current_scene
	level.n = level_n
	level.start()
