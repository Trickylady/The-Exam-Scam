extends TextureRect
class_name Paper


@export_range(1.0, 16.0, 0.5) var slit_thickness = 10.0 #px

@onready var cut_polygons: Node2D = %cut_polygons
@onready var mask_polys: Node2D = %mask_polys

# references
var level: Level
func _set_level(l: Level) -> void:
	level = l
var pencils: Array[Pencil]:
	get: return level.pencils


var paper_regions: Array[PackedVector2Array] = []
var removed_regions: Array[PackedVector2Array] = []
var cut_segments: Array[PackedVector2Array] = []  # each: [p0, p1]

var initial_available_area: float
var ui_polygon: PackedVector2Array

var available_area: float:
	set(val):
		available_area = val
		available_area_updated.emit()
		if debug: queue_redraw()
var completed_ratio: float:
	get: return (initial_available_area - available_area) / initial_available_area


signal paper_removed(polygon: PackedVector2Array)
signal available_area_updated


func setup() -> void:
	available_area_updated.connect(_on_available_area_updated)
	
	# mask
	clear_cut_visuals()
	%sub.size = size
	material.set_shader_parameter("mask_tex", %sub.get_texture())
	
	paper_regions.clear()
	removed_regions.clear()
	cut_segments.clear()

	var paper := rect_to_poly(Rect2(Vector2.ZERO, size))  # TextureRect local space
	paper_regions = [paper]

	if ui_polygon.size() >= 3:
		# paper = paper - ui_polygon
		paper_regions = diff_many(paper_regions, [ui_polygon])

	initial_available_area = calculate_polygons_area(paper_regions)
	available_area = initial_available_area


func _on_available_area_updated() -> void:
	pass


func cut_out_ui_polygon_from_field(_poly: PackedVector2Array) -> void:
	ui_polygon = _poly
	


func cut_along_segment(seg: PackedVector2Array, at_point: Vector2) -> void:
	assert(seg.size() == 2)
	# 1) Find the target region under the point
	var target_idx := _paper_region_index_at(at_point)
	if target_idx == -1:
		return  # nothing to cut under the point

	var p0 := seg[0]
	var p1 := seg[1]
	var d := (p1 - p0).normalized()
	var n_left := Vector2(d.y, -d.x)  # left normal in y-down

	var hp_left  := half_plane_for_segment(p0, p1, true)
	var hp_right := half_plane_for_segment(p0, p1, false)

	# We'll rebuild paper_regions: all others unchanged, only target replaced
	var new_regions: Array[PackedVector2Array] = []
	var just_removed: Array[PackedVector2Array] = []

	# 2) Copy all non-target regions as-is
	for i in range(paper_regions.size()):
		if i != target_idx:
			new_regions.append(paper_regions[i])

	# 3) Process only the target polygon
	var target := paper_regions[target_idx]

	# Partition by the cut
	var left_raw  : Array = Geometry2D.intersect_polygons(target, hp_left)
	var right_raw : Array = Geometry2D.intersect_polygons(target, hp_right)

	# If the cut does not touch this target, keep it and finish
	if left_raw.is_empty() and right_raw.is_empty():
		new_regions.append(target)
		paper_regions = new_regions
		available_area = calculate_polygons_area(paper_regions)
		return

	# If you still keep segment barriers, clip candidates by them (else leave as-is)
	var left_pieces := _clip_pieces_by_segments(left_raw)
	var right_pieces := _clip_pieces_by_segments(right_raw)

	# Only pencils that are inside the target region should influence keep/throw logic
	var pens_here := _pencils_in_region(target)

	var keep_left := _any_piece_have_pencils(left_pieces, pens_here)
	var keep_right := _any_piece_have_pencils(right_pieces, pens_here)

	# 4) Apply the decision to the target only
	if keep_left and keep_right:
		# carve a thin slit ONLY in this region, and count its area as removed
		var slit := segment_to_strip(seg, slit_thickness, slit_thickness * 0.5)
		var kept := Geometry2D.clip_polygons(target, slit)           # target - slit
		var slit_removed_now: Array[PackedVector2Array] = Geometry2D.intersect_polygons(target, slit)

		new_regions.append_array(kept)
		if slit_removed_now.size() > 0:
			just_removed.append_array(slit_removed_now)
		add_solid_collision_polygon_to_segments(slit)
		paper_removed.emit(slit)

	elif keep_left or (not keep_right and calculate_polygons_area(left_pieces) >= calculate_polygons_area(right_pieces)):
		new_regions.append_array(left_pieces)
		just_removed.append_array(right_pieces)
		paper_removed.emit(right_pieces.front())
	else:
		new_regions.append_array(right_pieces)
		just_removed.append_array(left_pieces)
		paper_removed.emit(left_pieces.front())

	# 5) Commit changes
	paper_regions = new_regions

	if just_removed.size() > 0:
		add_collision_polygons(just_removed)
		removed_regions.append_array(just_removed)

	available_area = calculate_polygons_area(paper_regions)
	if debug: queue_redraw()



#region Collisions update
func add_collision_polygons(polys: Array[PackedVector2Array]) -> void:
	for poly in polys:
		add_collision_polygon(poly)


func clear_cut_visuals() -> void:
	for c in cut_polygons.get_children() + mask_polys.get_children():
		c.queue_free()


func add_collision_polygon(poly: PackedVector2Array) -> void:
	if poly.size() < 3:
		return
	
	# Normalize winding for consistency
	if Geometry2D.is_polygon_clockwise(poly):
		poly = poly.duplicate()
		poly.reverse()
	
	var vis := Polygon2D.new()
	vis.polygon = poly
	mask_polys.add_child(vis)
	
	# Parent node for this piece
	var body := StaticBody2D.new()
	var cp := CollisionPolygon2D.new()
	cp.polygon = poly
	#cp.build_mode = CollisionPolygon2D.BUILD_SEGMENTS
	body.add_child(cp)
	
	cut_polygons.add_child(body)


func add_solid_collision_polygon_to_segments(poly: PackedVector2Array) -> void:
	if poly.size() < 3: return
	var body := StaticBody2D.new()
	var cp := CollisionPolygon2D.new()
	cp.polygon = poly
	cp.build_mode = CollisionPolygon2D.BUILD_SOLIDS
	body.add_child(cp)
	cut_polygons.add_child(body)
	
	var vis := Polygon2D.new()
	vis.polygon = poly
	mask_polys.add_child(vis)


#func add_collision_segment(seg: PackedVector2Array) -> void:
	#cut_segments.append(seg)
	#var wall := StaticBody2D.new()
	#var cs := CollisionShape2D.new()
	#var ss := SegmentShape2D.new()
	#ss.a = seg[0]
	#ss.b = seg[1]
	#cs.shape = ss
	#wall.add_child(cs)
	#
	#var line := Line2D.new()
	#line.points = seg
	#line.width = 3.0
	#line.default_color = Color.WHITE
	#wall.add_child(line)
	#
	#segments.add_child(wall)
#endregion


#region Game Utilities
func are_pencils_in_polygon(poly: PackedVector2Array) -> bool:
	for pencil: Pencil in pencils:
		if Geometry2D.is_point_in_polygon(pencil.global_position, poly):
			return true
	return false


func _any_piece_has_pencil(pieces: Array) -> bool:
	for poly: PackedVector2Array in pieces:
		if are_pencils_in_polygon(poly):
			return true
	return false


func _any_piece_have_pencils(pieces: Array, _local_pencils: Array[Pencil]) -> bool:
	for poly: PackedVector2Array in pieces:
		for pencil: Pencil in _local_pencils:
			if Geometry2D.is_point_in_polygon(pencil.global_position, poly):
				return true
	return false


func is_point_in_paper(point: Vector2) -> bool:
	var inside_any := false
	for poly: PackedVector2Array in paper_regions:
		if Geometry2D.is_point_in_polygon(point, poly):
			return true
	return false


func _paper_region_index_at(point: Vector2) -> int:
	var p := point  # use to_local(point) later if Field can move/scale
	for i in range(paper_regions.size()):
		if Geometry2D.is_point_in_polygon(p, paper_regions[i]):
			return i
	return -1


func _pencils_in_region(region: PackedVector2Array) -> Array[Pencil]:
	var out: Array[Pencil] = []
	for pen: Pencil in pencils:
		if Geometry2D.is_point_in_polygon(pen.global_position, region):
			out.append(pen)
	return out
#endregion


#region Static Utilities
static func rect_to_poly(rect: Rect2) -> PackedVector2Array:
	var p := rect.position
	var s := rect.size
	return PackedVector2Array([
		p,
		p + Vector2(0.0, s.y),
		p + s,
		p + Vector2(s.x, 0.0),
	])


static func segment_to_strip(seg: PackedVector2Array, thickness: float = 1.0, end_expand: float = 1.0) -> PackedVector2Array:
	assert(seg.size() == 2)
	var p0 := seg[0]
	var p1 := seg[1]

	var dir := p1 - p0
	var L := dir.length()
	if L <= 1e-6:
		return PackedVector2Array()

	dir /= L
	var n := Vector2(dir.y, -dir.x)
	var h := thickness * 0.5
	var e: float = max(end_expand, 0.0)

	# CCW rectangle in y-down coords
	var a := p0 - dir * e + n * h
	var b := p1 + dir * e + n * h
	var c := p1 + dir * e - n * h
	var d := p0 - dir * e - n * h
	return PackedVector2Array([a, b, c, d])


static func triangle_area(triangle: PackedVector2Array) -> float:
	if triangle.size() != 3: return 0.0
	var a := triangle[0]
	var b := triangle[1]
	var c := triangle[2]
	var ab := b - a
	var ac := c - a
	var cross := ab.x * ac.y - ab.y * ac.x
	return 0.5 * abs(cross)


static func polygon_area_shoelace(poly: PackedVector2Array, signed := false) -> float:
	assert(poly.size() >= 3)
	var s := 0.0
	for i in range(poly.size()):
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		s += a.x * b.y - a.y * b.x
	var area := 0.5 * s
	return area if signed else abs(area)


static func polygon_area_triangulated(poly: PackedVector2Array) -> float:
	assert(poly.size() >= 3)
	var idx := Geometry2D.triangulate_polygon(poly) # PackedInt32Array of indices
	var area := 0.0
	for i in range(0, idx.size(), 3):
		var a := poly[idx[i]]
		var b := poly[idx[i + 1]]
		var c := poly[idx[i + 2]]
		var ab := b - a
		var ac := c - a
		area += 0.5 * abs(ab.x * ac.y - ab.y * ac.x)
	return area


static func calculate_polygons_area(polygons: Array[PackedVector2Array]) -> float:
	var area: float = 0.0
	for poly: PackedVector2Array in polygons:
		area += polygon_area_shoelace(poly)
	return area


static func half_plane_for_segment(p0: Vector2, p1: Vector2, take_left_side: bool) -> PackedVector2Array:
	var d := (p1 - p0).normalized()
	var n_left := Vector2(d.y, -d.x) # left normal in y-down coords
	var n := n_left if take_left_side else -n_left
	
	var L := 100000.0 # far along the line
	var W := 100000.0 # far to one side
	
	var a := p0 - d * L
	var b := p1 + d * L
	
	# Rectangle that lies entirely on the chosen side of the infinite line
	return PackedVector2Array([
		a,
		b,
		b + n * W,
		a + n * W,
	])


static func diff_many(subjects: Array[PackedVector2Array], cutters: Array[PackedVector2Array]) -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	for s in subjects:
		var cur: Array[PackedVector2Array] = [s]
		for c in cutters:
			var next: Array[PackedVector2Array] = []
			for piece in cur:
				next.append_array(Geometry2D.clip_polygons(piece, c)) # A - B
			cur = next
		out.append_array(cur)
	return out


func _clip_pieces_by_segments(pieces: Array[PackedVector2Array]) -> Array[PackedVector2Array]:
	if cut_segments.is_empty():
		return pieces
	var strips: Array[PackedVector2Array] = []
	for seg in cut_segments:
		strips.append(segment_strip(seg, 0.5))
	# subtract all strips from each piece
	var out: Array[PackedVector2Array] = []
	for poly in pieces:
		var cur: Array[PackedVector2Array] = [poly]
		for s in strips:
			var next: Array[PackedVector2Array] = []
			for p in cur:
				next.append_array(Geometry2D.clip_polygons(p, s))
			cur = next
		out.append_array(cur)
	return out


# A very thin rectangle centered on seg (p0->p1), thickness in pixels
static func segment_strip(seg: PackedVector2Array, thickness: float) -> PackedVector2Array:
	var p0 := seg[0]
	var p1 := seg[1]
	var d := (p1 - p0).normalized()
	var n := Vector2(d.y, -d.x) # left normal in y-down
	var h := thickness * 0.5
	return PackedVector2Array([
		p0 + n * h,
		p1 + n * h,
		p1 - n * h,
		p0 - n * h,
	])

func split_regions_by_segment(seg: PackedVector2Array, thickness: float = 0.5) -> void:
	var slit := segment_strip(seg, thickness)
	paper_regions = diff_many(paper_regions, [slit])
#endregion


#region Debug
@export var debug: bool = false:
	set(val):
		debug = val
		queue_redraw()
@export var debug_line_width: float = 2.0

const COL_PAPER_FILL    := Color(0.2, 0.8, 1.0, 0.10)
const COL_PAPER_OUTLINE := Color(0.2, 0.8, 1.0, 0.85)

const COL_CUT_FILL      := Color(1.0, 0.3, 0.3, 0.15)
const COL_CUT_OUTLINE   := Color(1.0, 0.3, 0.3, 1.00)

const COL_UI_FILL       := Color(1.0, 1.0, 0.0, 0.12)
const COL_UI_OUTLINE    := Color(1.0, 1.0, 0.0, 0.85)

const COL_SEGMENT       := Color(1.0, 1.0, 1.0, 0.9)


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_E and event.is_pressed() and not event.is_echo():
			debug = !debug


func _draw() -> void:
	if not debug:
		return

	# Paper that remains
	for poly: PackedVector2Array in paper_regions:
		_draw_region(poly, COL_PAPER_FILL, COL_PAPER_OUTLINE)
	
	for poly: PackedVector2Array in removed_regions:
		_draw_region(poly, COL_CUT_FILL, COL_CUT_OUTLINE)
	
	if ui_polygon.size() >= 3:
		_draw_region(ui_polygon, COL_UI_FILL, COL_UI_OUTLINE)
	
	
	for seg: PackedVector2Array in cut_segments:
		if seg.size() == 2:
			draw_line(seg[0], seg[1], COL_SEGMENT, debug_line_width, true)


func _draw_region(poly: PackedVector2Array, fill: Color, outline: Color) -> void:
	if poly.size() < 3:
		return
	draw_colored_polygon(poly, fill)
	var loop := poly.duplicate()
	loop.append(poly[0])
	draw_polyline(loop, outline, debug_line_width, true)
#endregion
