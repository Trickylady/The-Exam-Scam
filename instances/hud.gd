extends Control
class_name HUD


@onready var coll_poly: PackedVector2Array = %coll.polygon


var level: Level
func _set_level(l: Level) -> void:
	level = l


func _ready() -> void:
	%pnl_debug.hide()
	$sound_settings.hide()
	%progress.visible = Mng.is_debug_build


func setup() -> void:
	%progress.value = 0
	level.paper.available_area_updated.connect(_on_paper_available_area_updated)
	update_gui()
	_connect_signals()


func _connect_signals() -> void:
	Mng.stats.score_updated.connect(update_scores)
	Mng.lives_updated.connect(update_lives)
	Mng.boost_n_updated.connect(update_boosts)
	Mng.slow_n_updated.connect(update_slows)


func update_gui() -> void:
	%lb_level_n.text = str(level.n)
	update_scores()
	update_lives()
	update_boosts()
	update_slows()


func update_scores() -> void:
	var zero_pad := true
	var v: int = clamp(Mng.stats.get_global_scores(), 0, 9999)
	@warning_ignore("integer_division")
	var digits := [ (v / 1000) % 10, (v / 100) % 10, (v / 10) % 10, v % 10 ]

	var nonzero_seen := false
	for i in range(4):
		var d: int = digits[i]
		nonzero_seen = nonzero_seen or d != 0
		var lbl := %hb_scores.get_child(i) as Label
		# show blanks for leading zeros unless zero_pad is true; ones place always shown
		lbl.text = str(d) if (zero_pad or nonzero_seen or i == 3) else ""
func update_lives() -> void:
	_add_icons(Powerup.IMGS.Lives, Powerup.IMGS.StackLives, Mng.lives, %hb_lives)
func update_boosts() -> void:
	_add_icons(Powerup.IMGS.Boosts, Powerup.IMGS.StackBoosts, Mng.boost_n, %hb_boosts)
func update_slows() -> void:
	_add_icons(Powerup.IMGS.Slows, Powerup.IMGS.StackSlows, Mng.slow_n, %hb_slows)

func _add_icons(img: Texture2D, img_stack: Texture2D, qt: int, cont: Container) -> void:
	_clear_container(cont)
	if qt <= 5:
		#single
		for i in qt:
			_add_icon_to_container(img, cont)
	else:
		#stack
		_add_icon_to_container(img_stack, cont)
		var lb := Label.new()
		lb.text = str(qt)
		lb.add_theme_font_size_override("font_size", 36)
		cont.add_child(lb)

func _on_paper_available_area_updated() -> void:
	%progress.value = level.paper.completed_ratio


func _add_icon_to_container(tex: Texture2D, cont: Container, dim: float = 42) -> void:
	var new_tex := TextureRect.new()
	new_tex.texture = tex
	new_tex.custom_minimum_size = Vector2.ONE * dim
	new_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	new_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cont.add_child(new_tex)


func _clear_container(cont: Container) -> void:
	for child in cont.get_children():
		child.free()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		$sound_settings.visible = !$sound_settings.visible
	if !Mng.is_debug_build: return
	if event is InputEventKey:
		if event.keycode == KEY_Q and event.is_pressed() and not event.is_echo():
			%pnl_debug.visible = !%pnl_debug.visible


func _process(_delta: float) -> void:
	var on_overlay: bool = Geometry2D.is_point_in_polygon(get_local_mouse_position(), %coll.polygon)
	if on_overlay and Input.mouse_mode == Input.MOUSE_MODE_HIDDEN:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif not on_overlay and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN


func _on_gomenubutton_pressed() -> void:
	$sound_settings.show()
func _on_btn_override_go_to_menu_pressed() -> void:
	get_tree().paused = false
	Mng.go_to_main_menu()
func _on_btn_close_menu_pressed() -> void:
	$sound_settings.hide()
func _on_sound_settings_visibility_changed() -> void:
	get_tree().paused = $sound_settings.visible
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if $sound_settings.visible else Input.MOUSE_MODE_HIDDEN
