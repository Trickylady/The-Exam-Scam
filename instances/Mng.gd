#Singleton Mng.gd
extends Node


var is_debug_build: bool = true
var is_family_friendly: bool = true


const MAX_LEVELS = 10
const MAX_LIVES = 5
const MAX_BOOSTS = 5
const MAX_SLOWS = 5
const INIT_BOOSTS = 1
const INIT_SLOWS = 1

var current_level_n: int
var score: int:
	set(val): score = val; score_updated.emit()
var lives: int:
	set(val): lives = clamp(val, 0, MAX_LIVES); lives_updated.emit()
var boost_n: int:
	set(val): boost_n = clamp(val, 0, MAX_BOOSTS); boost_n_updated.emit()
var slow_n: int:
	set(val): slow_n = clamp(val, 0, MAX_SLOWS); slow_n_updated.emit()
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


func go_to_main_menu() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://Menu.tscn")


func go_to_level(level_n: int) -> void:
	current_level_n = level_n
	await get_tree().process_frame
	get_tree().change_scene_to_packed(LEVEL_PCK)
	await get_tree().node_added
	await get_tree().current_scene.ready
	level = get_tree().current_scene
	level.n = level_n
	level.level_won.connect(_on_level_won)
	level.level_lost.connect(_on_level_lost)
	level.start()


func _on_level_won() -> void:
	if current_level_n == MAX_LEVELS:
		go_to_main_menu()
		#TODO: go to win page
	go_to_level(current_level_n + 1)
func _on_level_lost() -> void:
	go_to_main_menu() # TODO
