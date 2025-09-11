extends Control


func _ready() -> void:
	Aud.play_win_level()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await get_tree().process_frame
	_populate()


func _populate() -> void:
	var text: String
	var l_stats: GameStats.LevelStats = Mng.stats.level_stats
	%lb_level.text = "Level %s completed!" % Mng.stats.level_n
	
	text = "with %s cuts!" % stat_value(l_stats.cuts)
	text += "\nLevel score %s" % stat_value(l_stats.scores)
	text += "\nTime elapsed %s" % stat_value(GameStats.t_msec_to_string(l_stats.time_elapsed))
	text += "\n1 UPs! collected %s" % stat_value(l_stats.lives_collected)
	text += "\nAdderals collected %s" % stat_value(l_stats.boosts_collected)
	text += "\nXanax collected %s" % stat_value(l_stats.slows_collected)
	text += "\nHits %s times..." % stat_value(l_stats.hits, Color.ORANGE_RED)
	%lb_score.text = text
	
	var tot_scores: int = Mng.stats.get_global_scores()
	%lb_tot_score.text = "Total scores %s" % stat_value(tot_scores, Color.GREEN, 80)


func stat_value(value: Variant, col: Color = Color.GOLD, text_size: int = 50) -> String:
	var col_hex: String = col.to_html(false)
	return "[color=%s][font_size=%s][wave]%s[/wave][/font_size][/color]" % [col_hex, text_size, value]


func _on_btn_go_to_menu_pressed() -> void:
	Mng.go_to_main_menu()


func _on_nextbutton_pressed() -> void:
	Mng.next_level()
