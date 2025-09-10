#Singleton Mng.gd
extends Node

var is_debug_build: bool = true

# Game modifiers
var is_family_friendly: bool = true
var max_levels: int = 10 # when the game ends
var max_lives: int = 5 # can't collect more than this
var max_boosts: int = 5
var max_slows: int = 5
var init_boosts: int = 1 # the game starts with
var init_slows: int = 1
var goal_completion: float = 0.75 # 0 to 1 (percentage to win the level)

# Scissors
var scissors_angles_num: int = 5
var scissors_rotation_sequential: bool = true
var scissors_scaling: float = 0.6:
	set(val): scissors_scaling = val; if level: level.scissors.update_scale()
var cutting_grow_speed_base = 800 # px/s
var cutting_grow_speed_mult = 2.5 # multiplier
var cut_thickness: float = 10.0

# Pencils

# Power-ups
var powerup_spaw_probabilities = {
	Powerup.Type.LIFE: 0.0,
	Powerup.Type.BOOST: 0.0,
	Powerup.Type.SLOW: 0.0,
}
var powerup_spawn_new_time: float = 5.0 # sec
var powerup_despawn_time: float = 5.0 # sec
var pencils_slow_duration: float = 10.0 # sec
var slow_pencils_mult: float = 0.25


var current_level_n: int
var scores: Dictionary = {}
var score: int:
	set(val): score = val; score_updated.emit()
var lives: int:
	set(val): lives = clamp(val, 0, max_lives); lives_updated.emit()
var boost_n: int:
	set(val): boost_n = clamp(val, 0, max_boosts); boost_n_updated.emit()
var slow_n: int:
	set(val): slow_n = clamp(val, 0, max_slows); slow_n_updated.emit()
signal score_updated
signal lives_updated
signal boost_n_updated
signal slow_n_updated

const LEVEL_PCK = preload("res://instances/level.tscn")
var level: Level



func _ready() -> void:
	reset_stats()


func start_game() -> void:
	reset_stats()
	Mng.go_to_level(1)


func reset_stats() -> void:
	scores = {}
	score = 0
	lives = 4
	current_level_n = 1
	boost_n = init_boosts
	slow_n = init_slows


func go_to_main_menu() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().call_deferred("change_scene_to_file", "res://Menu.tscn")


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
	if current_level_n == max_levels:
		go_to_main_menu()
		#TODO: go to win page
	go_to_level(current_level_n + 1)
func _on_level_lost() -> void:
	go_to_main_menu() # TODO
