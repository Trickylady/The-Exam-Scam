extends VBoxContainer


func _ready() -> void:
	_populate()


func _populate() -> void:
	var text: String
	text = "Total score %s" % stat_value(Mng.stats.get_global_scores(), Color.GREEN)
	text += "\nCuts %s" % stat_value(Mng.stats.get_total_cuts())
	text += "\nHits %s" % stat_value(Mng.stats.get_total_hits(), Color.ORANGE_RED)
	text += "\nPowerups %s" % stat_value(Mng.stats.get_total_powerups())
	text += "\nTotal time %s" % stat_value(GameStats.t_msec_to_string(Mng.stats.get_total_time()))
	$lb_score.text = text


func stat_value(value: Variant, col: Color = Color.GOLD, text_size: int = 30) -> String:
	var col_hex: String = col.to_html(false)
	return "[color=%s][font_size=%s][wave]%s[/wave][/font_size][/color]" % [col_hex, text_size, value]
