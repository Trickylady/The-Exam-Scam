#Singleton Mng.gd
extends Node


var is_debug_build: bool = true
var is_family_friendly: bool = true


const MAX_LIVES = 4
const INIT_BOOSTS = 4
const INIT_SLOWS = 4

var score: int
var lives: int
var current_level_n: int
var boost_n: int
var slow_n: int

const LEVEL_PCK = preload("res://instances/level.tscn")
var level: Level

var start_from_level = 0
func _ready() -> void:
	reset_stats()
	if start_from_level:
		go_to_level(start_from_level)


func reset_stats() -> void:
	score = 0
	lives = MAX_LIVES
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
