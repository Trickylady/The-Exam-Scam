extends RefCounted
class_name LeaderboardEntryData


var username: String = ""
var scores: int = 0
var game_difficulty: int = 0
var scissors_rotation_sequential: bool = false
var game_stats: GameStats = null


static func from_json(d: Dictionary) -> LeaderboardEntryData:
	var new_data: LeaderboardEntryData = LeaderboardEntryData.new()
	new_data.username = d.get("username", "")
	new_data.scores = d.get("scores", 0)
	new_data.game_difficulty = d.get("game_difficulty", 0)
	new_data.scissors_rotation_sequential = d.get("scissors_rotation_sequential", true)
	var game_stats_data: Dictionary = d.get("game_stats")
	new_data.game_stats = GameStats.from_json(game_stats_data)
	return new_data
