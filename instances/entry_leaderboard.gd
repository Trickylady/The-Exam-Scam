@tool
extends HBoxContainer
class_name EntryLeaderboard


@export_tool_button("DO IT!", "Button") var _do_it_btn: Callable = _update
@export var score: int = 100:
	set(val):
		score = val
		_update()
@export var num_bg_color: Color = Color("3173a5"):
	set(val):
		num_bg_color = val
		_update()
@export var score_color: Color = Color("ccff90"):
	set(val):
		score_color = val
		_update()
@export var username: String = "Trickylady":
	set(val):
		username = val
		_update()
@export var username_highlight_key: String = "rainbow":
	set(val):
		username_highlight_key = val
		_update()
@export var is_current_player: bool = false:
	set(val):
		is_current_player = val
		_update()


const SCORE_COLS: Array[Color] = [
	Color("8cc0fd"), # 0 VERY LIGHT BLUE
	Color("3173a5"), # 1 LIGHT BLUE
	Color("091625"), # 2 DARK BLUE
	Color("ccff90"), # 3 MINT
]

var num: int = 1



func _update() -> void:
	if not is_node_ready(): await ready
	if Engine.is_editor_hint():
		num = get_index()
	
	var alt: bool = get_index() % 2 == 1
	var user_text: String = username
	var score_text: String = "%d" % [score]
	
	if is_current_player:
		var format_dict: Dictionary = {
			"key": username_highlight_key,
			"username": username,
		}
		user_text = "[{key}]{username}[/{key}]".format(format_dict)
		score_text = "[wave]" + score_text
		%lb_n.self_modulate = SCORE_COLS[2]
		%tex_n.self_modulate = SCORE_COLS[3]
		%lb_total_score.self_modulate = SCORE_COLS[3]
	else:
		%lb_n.self_modulate = Color.WHITE
		%tex_n.self_modulate = SCORE_COLS[2] if alt else SCORE_COLS[1]
		%lb_total_score.self_modulate = SCORE_COLS[0] if alt else Color.WHITE
	
	%lb_n.text = "%d" % num
	%lb_username.text = user_text
	%lb_total_score.text = score_text


func _populate() -> void:
	pass
