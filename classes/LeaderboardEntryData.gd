extends RefCounted
class_name LeaderboardEntryData


var username: String
var game_difficulty: int
var scissors_rotation_sequential: bool
var game_stats: GameStats


static func from_game(mng: Node, _username: String) -> LeaderboardEntryData:
	var new_data: LeaderboardEntryData = LeaderboardEntryData.new()
	new_data.game_difficulty = Mng.game_difficulty
	return new_data


static func from_json(dict: Dictionary) -> LeaderboardEntryData:
	var new_data: LeaderboardEntryData = LeaderboardEntryData.new()
	return new_data
