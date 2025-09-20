extends Node
class_name LeaderboardMng


var leaderboard_data_main: Array[LeaderboardEntryData] = []
var leaderboard_data_easy: Array[LeaderboardEntryData] = []
var leaderboard_data_medium: Array[LeaderboardEntryData] = []
var leaderboard_data_hard: Array[LeaderboardEntryData] = []
var scores: SWScores


func _ready() -> void:
	if not SilentWolf.is_setup: await SilentWolf.setup_complete
	var f: FileAccess = FileAccess.open("res://silent_wolf_api.json", FileAccess.READ)
	var silent_wolf_config: Dictionary = JSON.parse_string(f.get_as_text())
	SilentWolf.configure(silent_wolf_config)


func get_score_from_leaderboard(difficulty: int = 0, maximum: int = 1000) -> void:
	if not SilentWolf.is_config: await SilentWolf.config_complete
	
	var ldboard_name: String = get_difficulty_table_name(difficulty)
	scores = SilentWolf.Scores.get_scores(maximum, ldboard_name)
	
	if not scores.sw_get_scores_complete.is_connected(_on_get_scores_complete):
		scores.sw_get_scores_complete.connect(_on_get_scores_complete)


func _on_get_scores_complete(sw_result: Dictionary) -> void:
	if not sw_result.get("success", false):
		print("SilentWolf: Error retrieving the scores. Error: %s" % sw_result.error)
		return
	var difficulty: int = 0
	for score_data: Dictionary in sw_result.scores:
		var username: String = score_data.player_name
		var scores: int = int(score_data.score)
		var game_stats: GameStats = GameStats.from_json(score_data.metadata)
		difficulty = game_stats.game_difficulty
		
		var entry_data := LeaderboardEntryData.new()
		entry_data.username = username
		entry_data.scores = scores
		entry_data.game_difficulty = difficulty
		entry_data.scissors_rotation_sequential = game_stats.scissors_rotation_sequential
		entry_data.game_stats = game_stats
		
		



func send_score_to_leaderboard(username: String) -> void:
	var table: String = ""
	match Mng.game_difficulty:
		1: table = "easy"
		2: table = "medium"
		3: table = "hard"
	
	var global_scores: int = Mng.stats.get_global_scores()
	var metadata: Dictionary = Mng.stats.to_json()
	SilentWolf.Scores.save_score(
		username,
		global_scores,
		table,
		metadata
	)
	SilentWolf.Scores.save_score(
		username,
		global_scores,
		"main",
		metadata
	)


func update_leaderboard_data() -> void:
	pass


static func get_difficulty_table_name(difficulty: int) -> String:
	match difficulty:
		0: return "main"
		1: return "easy"
		2: return "medium"
		3: return "hard"
	return "main"
