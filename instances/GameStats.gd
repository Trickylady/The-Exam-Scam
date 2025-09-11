extends RefCounted
class_name GameStats


class LevelStats extends RefCounted:
	var scores: int
	var time_elapsed: int = 0
	var hits: int = 0
	var cuts: int = 0
	var lives_collected: int = 0
	var boosts_collected: int = 0
	var slows_collected: int = 0


var _all: Dictionary[int, LevelStats] = {}
var level_t_start: int
var level_n: int


signal score_updated


func new_level(_level: Level) -> void:
	level_n = _level.n
	level_t_start = _level.t_start
	_all[level_n] = LevelStats.new()
	_level.scissors.cut_line_hit.connect(_increase_hits)
	_level.scissors.cut_line_success.connect(_increase_cuts)
	_level.powerups.powerup_collected.connect(_on_powerup_collected)
	_level.level_lost.connect(_on_level_end)
	_level.level_won.connect(_on_level_end)


func increase_score(partial_scores: int) -> void:
	var level_stat: LevelStats = _all[level_n]
	level_stat.scores += partial_scores
	score_updated.emit()


func _increase_hits(_pencil: Pencil) -> void:
	var level_stat: LevelStats = _all[level_n]
	level_stat.hits += 1
func _increase_cuts() -> void:
	var level_stat: LevelStats = _all[level_n]
	level_stat.cuts += 1
func _on_powerup_collected(powerup: Powerup) -> void:
	var level_stat: LevelStats = _all[level_n]
	match powerup.type:
		Powerup.Type.LIFE: level_stat.lives_collected += 1
		Powerup.Type.BOOST: level_stat.boosts_collected += 1
		Powerup.Type.SLOW: level_stat.slows_collected += 1
func _on_level_end() -> void:
	var level_stat: LevelStats = _all[level_n]
	level_stat.time_elapsed = Time.get_ticks_msec() - level_t_start


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


static func t_msec_to_string(msecs: int) -> String:
	@warning_ignore("integer_division")
	var usecs: int = msecs / 1000
	var fract: int = msecs % 1000
	var t_dict: Dictionary = Time.get_time_dict_from_unix_time(usecs)
	
	if t_dict["hour"] > 0:
		return "%d:%02d%02d" % [t_dict["hour"], t_dict["minute"], t_dict["second"]]
	
	return "%02d%02d.%03d" % [t_dict["minute"], t_dict["second"], fract]
