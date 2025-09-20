extends RefCounted
class_name GameStats


class LevelStats extends RefCounted:
	var level_num: int
	var scores: int
	var time_elapsed: int = 0
	var hits: int = 0
	var cuts: int = 0
	var lives_collected: int = 0
	var boosts_collected: int = 0
	var slows_collected: int = 0
	
	func _init(_level_num: int) -> void:
		level_num = _level_num
	
	func to_json() -> Dictionary:
		var d: Dictionary = {}
		d["level_num"] = level_num
		d["scores"] = scores
		d["time_elapsed"] = time_elapsed
		d["hits"] = hits
		d["cuts"] = cuts
		d["lives_collected"] = lives_collected
		d["boosts_collected"] = boosts_collected
		d["slows_collected"] = slows_collected
		return d
	
	static func from_json(d: Dictionary) -> LevelStats:
		var new_stats := LevelStats.new(d.get("level_num", 0))
		new_stats.scores = d.get("scores", 0)
		new_stats.time_elapsed = d.get("time_elapsed", 0)
		new_stats.hits = d.get("hits", 0)
		new_stats.cuts = d.get("cuts", 0)
		new_stats.lives_collected = d.get("lives_collected", 0)
		new_stats.boosts_collected = d.get("boosts_collected", 0)
		new_stats.slows_collected = d.get("slows_collected", 0)
		return new_stats


var _all: Dictionary[int, LevelStats] = {}
var level_t_start: int
var game_difficulty: int = 0
var scissors_rotation_sequential: bool = false
var level_n: int
var level_stats: LevelStats:
	get: return _all[level_n]

signal score_updated


func _init(_game_difficulty: int, _scissors_rotation_sequential: bool) -> void:
	game_difficulty = _game_difficulty
	scissors_rotation_sequential = _scissors_rotation_sequential


func new_level(_level: Level) -> void:
	level_n = _level.n
	level_t_start = _level.t_start
	_all[level_n] = LevelStats.new(level_n)
	_level.scissors.cut_line_hit.connect(_increase_hits)
	_level.scissors.cut_line_success.connect(_increase_cuts)
	_level.powerups.powerup_collected.connect(_on_powerup_collected)
	_level.level_lost.connect(_on_level_end)
	_level.level_won.connect(_on_level_end)


func increase_score(partial_scores: int) -> void:
	level_stats.scores += partial_scores
	score_updated.emit()


func _increase_hits(_pencil: Pencil) -> void:
	level_stats.hits += 1
func _increase_cuts() -> void:
	level_stats.cuts += 1
func _on_powerup_collected(powerup: Powerup) -> void:
	match powerup.type:
		Powerup.Type.LIFE: level_stats.lives_collected += 1
		Powerup.Type.BOOST: level_stats.boosts_collected += 1
		Powerup.Type.SLOW: level_stats.slows_collected += 1
func _on_level_end() -> void:
	level_stats.time_elapsed = Time.get_ticks_msec() - level_t_start


func get_global_scores() -> int:
	var tot_scores: int = 0
	for l_stats: LevelStats in _all.values():
		tot_scores += l_stats.scores
	return tot_scores
func get_total_time() -> int:
	var tot_time: int = 0
	for l_stats: LevelStats in _all.values():
		tot_time += l_stats.time_elapsed
	return tot_time
func get_total_hits() -> int:
	var tot_hits: int = 0
	for l_stats: LevelStats in _all.values():
		tot_hits += l_stats.hits
	return tot_hits
func get_total_cuts() -> int:
	var tot_cuts: int = 0
	for l_stats: LevelStats in _all.values():
		tot_cuts += l_stats.cuts
	return tot_cuts
func get_total_powerups() -> int:
	var tot_powerups: int = 0
	for l_stats: LevelStats in _all.values():
		tot_powerups += l_stats.lives_collected
		tot_powerups += l_stats.boosts_collected
		tot_powerups += l_stats.slows_collected
	return tot_powerups


func to_json() -> Dictionary:
	var d: Dictionary = {}
	d["_all"] = {}
	for _level_num: int in _all.keys():
		var _level_stats: LevelStats = _all[_level_num]
		var level_dict: Dictionary = _level_stats.to_json()
		d["_all"][str(_level_num)] = level_dict
	d["game_difficulty"] = game_difficulty
	d["level_t_start"] = level_t_start
	d["level_n"] = level_n
	return d


static func from_json(d: Dictionary) -> GameStats:
	var new_game_stats := GameStats.new(
		d.get("game_difficulty", 0),
		d.get("scissors_rotation_sequential", false)
	)
	var stats_dict: Dictionary = d.get("_all", {})
	for _level_n_str: String in stats_dict.keys():
		var _level_n: int = int(_level_n_str)
		var _level_stats: LevelStats = LevelStats.from_json(stats_dict[_level_n_str])
		new_game_stats._all[_level_n] = _level_stats
	new_game_stats.level_t_start = d.get("level_t_start", 0)
	new_game_stats.level_n = d.get("level_n", 0)
	return new_game_stats


static func t_msec_to_string(msecs: int) -> String:
	@warning_ignore("integer_division")
	var usecs: int = msecs / 1000
	var fract: int = msecs % 1000
	var t_dict: Dictionary = Time.get_time_dict_from_unix_time(usecs)
	
	if t_dict["hour"] > 0:
		return "%d:%02d%02d" % [t_dict["hour"], t_dict["minute"], t_dict["second"]]
	
	return "%02d:%02d.%03d" % [t_dict["minute"], t_dict["second"], fract]
