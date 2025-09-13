#Singleton Mng.gd
extends Node

var is_debug_build: bool = false # TODO: REMEMBER TO CHANGE THAT FOR THE FINAL BUILD

# Game modifiers
var is_family_friendly: bool = true
var max_levels: int = 3 # when the game ends
var max_lives: int = 20 # can't collect more than this
var max_boosts: int = 20
var max_slows: int = 20
var init_lives: int = 4 # the game starts with
var init_boosts: int = 1
var init_slows: int = 1
var goal_completion: float = 0.75 # 0 to 1 (percentage to win the level)
var compliment_ratio: float = 0.18 # 0 to 1 (percentage to get a "blimey" compliment from Fin)
var game_difficulty: int = 1: set = set_game_difficulty

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
var powerup_spaw_probabilities = { # TODO:
	Powerup.Type.LIFE: 0.0,
	Powerup.Type.BOOST: 0.0,
	Powerup.Type.SLOW: 0.0,
}
var powerup_spawn_new_time: float = 5.0 # sec
var powerup_despawn_time: float = 5.0 # sec
var pencils_slow_duration: float = 10.0 # sec
var slow_pencils_mult: float = 0.25


# Game status
var current_level_n: int
var stats: GameStats
var lives: int:
	set(val): lives = clamp(val, 0, max_lives); lives_updated.emit()
var boost_n: int:
	set(val): boost_n = clamp(val, 0, max_boosts); boost_n_updated.emit()
var slow_n: int:
	set(val): slow_n = clamp(val, 0, max_slows); slow_n_updated.emit()
signal lives_updated
signal boost_n_updated
signal slow_n_updated


const LEVEL_PCK = preload("res://instances/level.tscn")
var level: Level


func _ready() -> void:
	Input.set_custom_mouse_cursor(preload("res://images/ui/mouse_cursor_normal.png"))
	reset_stats()


func start_game() -> void:
	reset_stats()
	Aud.play_game_music()
	Aud.start_random_lines()
	Mng.go_to_level(1)


func reset_stats() -> void:
	stats = GameStats.new()
	lives = init_lives
	current_level_n = 1
	boost_n = init_boosts
	slow_n = init_slows


func go_to_intro() -> void:
	if is_family_friendly:
		get_tree().call_deferred("change_scene_to_file", "res://scenes/intro_family.tscn")
	else:
		get_tree().call_deferred("change_scene_to_file", "res://scenes/intro_pg.tscn")


func go_to_main_menu() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().call_deferred("change_scene_to_file", "res://scenes/menu_title.tscn")


func go_to_level(level_n: int) -> void:
	if level_n == 1:
		Aud.play_tutorial()
	
	current_level_n = level_n
	await get_tree().process_frame
	get_tree().change_scene_to_packed(LEVEL_PCK)
	await get_tree().node_added
	await get_tree().current_scene.ready
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	level = get_tree().current_scene
	level.n = level_n
	level.level_won.connect(_on_level_won)
	level.level_lost.connect(go_to_youlose)
	level.start()
	stats.new_level(level)


func go_to_level_score() -> void:
	get_tree().call_deferred("change_scene_to_file", "res://scenes/level_score.tscn")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func next_level() -> void:
	go_to_level(current_level_n + 1)


func go_to_youlose() -> void:
	get_tree().call_deferred("change_scene_to_file", "res://scenes/youlose.tscn")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
func go_to_youwin() -> void:
	get_tree().call_deferred("change_scene_to_file", "res://scenes/youwin.tscn")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func quit() -> void:
	get_tree().quit()


func _on_level_won() -> void:
	if current_level_n >= max_levels:
		go_to_youwin()
		return
	go_to_level_score()


func set_game_difficulty(val: int) -> void:
	game_difficulty = clampi(val, 1, 3)
	match game_difficulty:
		1:
			max_levels = 3
			init_lives = 5
			init_boosts = 3
			init_slows = 2
			goal_completion = 0.75
		2:
			max_levels = 5
			init_lives = 4
			init_boosts = 2
			init_slows = 1
			goal_completion = 0.80
		3:
			max_levels = 7
			init_lives = 3
			init_boosts = 0
			init_slows = 0
			goal_completion = 0.85


func get_spawn_number_pencils() -> int:
	match game_difficulty:
		1:
			return level.n + 3
		2:
			return level.n + 4
		3:
			return level.n + 5
	return level.n + 1
