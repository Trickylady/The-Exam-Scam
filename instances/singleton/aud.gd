# Singleto Aud (Audio manager)
extends Node



func play_music() -> void:
	if not $mus.playing:
		$mus.play()


func play_tutorial() -> void:
	if Mng.is_family_friendly: _play_voiceline("res://sounds/h_pg.mp3")
	else: _play_voiceline("res://sounds/h.mp3")


func play_powerup_collected() -> void:
	const YOINK_PATHS := [
		"res://sounds/sfx_yoink2.mp3",
		"res://sounds/sfx_yoink3.mp3",
		"res://sounds/sfx_yoink.mp3",
	]
	$sfx_powerup.stop()
	$sfx_powerup.stream = load(YOINK_PATHS.pick_random())
	$sfx_powerup.play()


func play_hit() -> void:
	const HIT_PATHS_FF = [
		"res://sounds/sfx_ugh1.mp3",
		"res://sounds/sfx_ugh2.mp3",
		"res://sounds/sfx_boo.mp3",
	]
	const HIT_PATHS_PG = [
		"res://sounds/sfx_shite.mp3",
		"res://sounds/sfx_fuck2.mp3",
		"res://sounds/sfx_fuck.mp3",
		"res://sounds/sfx_bastard.mp3",
		"res://sounds/sfx_cunt2.mp3",
		"res://sounds/sfx_cunt.mp3",
	]
	var filepath: String = HIT_PATHS_FF.pick_random()
	if not Mng.is_family_friendly: filepath = (HIT_PATHS_FF + HIT_PATHS_PG).pick_random()
	_play_sfx(filepath)


func play_line_complete() -> void:
	pass # TODO: not implemented


func play_nice() -> void:
	const PATHS = [
		"res://sounds/sfx_blimey.mp3",
		"res://sounds/sfx_boom1.mp3",
		"res://sounds/sfx_nice.mp3",
	]
	_play_sfx(PATHS.pick_random())


func play_win_level() -> void:
	if Mng.is_family_friendly: _play_voiceline("res://sounds/win.mp3")
	else: _play_voiceline("res://sounds/win_pg.mp3")


func play_win_game() -> void:
	if Mng.is_family_friendly: _play_voiceline("res://sounds/win.mp3")
	else: _play_voiceline("res://sounds/win_pg.mp3")


func play_lose() -> void:
	if Mng.is_family_friendly: _play_voiceline("res://sounds/lose.mp3")
	else: _play_voiceline("res://sounds/lose_pg.mp3")


func _play_voiceline(filepath: String) -> void:
	$voice_line.stop()
	$voice_line.stream = load(filepath)
	$voice_line.play()

func _play_sfx(filepath: String) -> void:
	$sfx_game.stop()
	$sfx_game.stream = load(filepath)
	$sfx_game.play()
