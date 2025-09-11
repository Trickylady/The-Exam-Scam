extends PanelContainer
class_name PnlDebug

var level: Level
func _set_level(l: Level) -> void:
	level = l



func setup() -> void:
	update_from_mng()


func _process(delta: float) -> void:
	if !is_visible_in_tree(): return
	var is_mouse_in: bool = get_global_rect().has_point(get_global_mouse_position())
	if Input.mouse_mode == Input.MOUSE_MODE_HIDDEN and is_mouse_in:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		level.scissors.set_process(false)
	if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE and not is_mouse_in:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
		level.scissors.set_process(true)


func update_from_mng() -> void:
	%sp_level_select.value = Mng.current_level_n
	# Game modifiers
	%ck_is_family_friendly.button_pressed = Mng.is_family_friendly
	#Mng.max_levels
	#Mng.max_lives
	#Mng.max_boosts
	#Mng.max_slows
	#Mng.init_boosts
	#Mng.init_slows
	%sp_lives.value = Mng.lives
	%sp_boost_n.value = Mng.boost_n
	%sp_slow_n.value = Mng.slow_n
	
	%sl_goal.value = Mng.goal_completion
	%lb_goal.text = "%d%%" % (Mng.goal_completion * 100)

	# Scissors
	%sp_angles.value = Mng.scissors_angles_num
	%ck_sequential.button_pressed = Mng.scissors_rotation_sequential
	#Mng.scissors_scaling
	%sl_cut_speed.value = Mng.cutting_grow_speed_base
	%lb_cut_speed.text = "%d px/s" % Mng.cutting_grow_speed_base
	%sl_cut_mult.value = Mng.cutting_grow_speed_mult
	%lb_cut_mult.text = "x %.1f" % Mng.cutting_grow_speed_mult
	#Mng.cut_thickness
	
	%sl_spawn.value = Mng.powerup_spawn_new_time
	%lb_spawn.text = "%.1f s" % Mng.powerup_spawn_new_time
	%sl_despawn.value = Mng.powerup_despawn_time
	%lb_despawn.text = "%.1f s" % Mng.powerup_despawn_time
	%sl_slow_dur.value = Mng.pencils_slow_duration
	%lb_slow_dur.text = "%.1f s" % Mng.pencils_slow_duration
	%sl_slow_mult.value = Mng.slow_pencils_mult
	%lb_slow_mult.text = "x %.2f" % Mng.slow_pencils_mult


func _on_btn_close_pressed() -> void: hide()
func _on_btn_go_to_level_pressed() -> void: Mng.go_to_level(int(%sp_level_select.value))

# game
func _on_ck_is_family_friendly_toggled(toggled_on: bool) -> void: Mng.is_family_friendly = toggled_on
func _on_sp_lives_value_changed(value: float) -> void: Mng.lives = int(value)
func _on_sp_boost_n_value_changed(value: float) -> void: Mng.boost_n = int(value)
func _on_sp_slow_n_value_changed(value: float) -> void: Mng.slow_n = int(value)
func _on_sl_goal_value_changed(value: float) -> void: Mng.goal_completion = value; %lb_goal.text = "%d%%" % (value * 100)

func _on_sp_angles_value_changed(value: float) -> void: Mng.scissors_angles_num = int(value); level.scissors.cycle_angle(true)
func _on_ck_sequential_toggled(toggled_on: bool) -> void: Mng.scissors_rotation_sequential = toggled_on
func _on_sl_cut_speed_value_changed(value: float) -> void: Mng.cutting_grow_speed_base = value; %lb_cut_speed.text = "%d px/s" % value
func _on_sl_cut_mult_value_changed(value: float) -> void: Mng.cutting_grow_speed_mult = value; %lb_cut_mult.text = "x %.1f" % value

func _on_sl_spawn_value_changed(value: float) -> void: Mng.powerup_spawn_new_time = value; %lb_spawn.text = "%.1f s" % value
func _on_sl_despawn_value_changed(value: float) -> void: Mng.powerup_despawn_time = value; %lb_despawn.text = "%.1f s" % value
func _on_sl_slow_dur_value_changed(value: float) -> void: Mng.pencils_slow_duration = value; %lb_slow_dur.text = "%.1f s" % value
func _on_sl_slow_mult_value_changed(value: float) -> void: Mng.slow_pencils_mult = value; %lb_slow_mult.text = "x %.2f" % value
