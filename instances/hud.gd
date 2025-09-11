extends Control
class_name HUD


@onready var coll_poly: PackedVector2Array = %coll.polygon


var level: Level
func _set_level(l: Level) -> void:
	level = l


func _ready() -> void:
	%pnl_debug.hide()
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
	_clear_container(%hb_lives)
	for i in Mng.lives:
		_add_icon_to_container(Powerup.IMGS.Lives, %hb_lives)
func update_boosts() -> void:
	_clear_container(%hb_boosts)
	for i in Mng.boost_n:
		_add_icon_to_container(Powerup.IMGS.Boosts, %hb_boosts)
func update_slows() -> void:
	_clear_container(%hb_slows)
	for i in Mng.slow_n:
		_add_icon_to_container(Powerup.IMGS.Slows, %hb_slows)


func _on_paper_available_area_updated() -> void:
	%progress.value = level.paper.completed_ratio


func _add_icon_to_container(tex: Texture2D, cont: Container, dim: float = 32) -> void:
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
	if !Mng.is_debug_build: return
	if event is InputEventKey:
		if event.keycode == KEY_Q and event.is_pressed() and not event.is_echo():
			%pnl_debug.visible = !%pnl_debug.visible


func _on_gomenubutton_pressed() -> void:
	Mng.go_to_main_menu()
