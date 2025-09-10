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
		if debug: %debug_renderer.queue_redraw()
var completed_ratio: float:
	get: return (initial_available_area - available_area) / initial_available_area


signal setup_done
signal paper_removed(polygon: PackedVector2Array)
signal available_area_updated


func setup() -> void:
	available_area_updated.connect(_on_available_area_updated)
	paper_removed.connect(_on_paper_removed)
	
	# mask
	clear_cut_visuals()
	%sub.size = size
	material.set_shader_parameter("mask_tex", %sub.get_texture())
	
	paper_regions.clear()
	removed_regions.clear()
	cut_segments.clear()

	var paper := rect_to_poly(Rect2(Vector2.ZERO, size))  # TextureRect local space
	paper_regions = [paper]
	
	ui_polygon = level.hud.coll_poly
	if Geometry2D.is_polygon_clockwise(ui_polygon):
		ui_polygon = ui_polygon.duplicate()
		ui_polygon.reverse()
	if ui_polygon.size() >= 3:
		var hud_removed: Array[PackedVector2Array] = Geometry2D.intersect_polygons(paper, ui_polygon)
		# Subtract HUD from the paper geometry
		paper_regions = diff_many(paper_regions, [ui_polygon])
		# Spawn colliders/visuals for the removed area so pencils collide with it
		if hud_removed.size() > 0:
			add_collision_polygons(hud_removed)
			#_add_removed_region_colliders(hud_removed)
			removed_regions.append_array(hud_removed)

	initial_available_area = calculate_polygons_area(paper_regions)
	available_area = initial_available_area
	setup_done.emit()


func _on_available_area_updated() -> void:
	pass


func _on_paper_removed(poly_removed: PackedVector2Array) -> void:
	@warning_ignore("integer_division")
	var removed_area: float = polygon_area_shoelace(poly_removed)
	var removed_area_ratio: float = removed_area/initial_available_area
	var delta_score: int = int(floor(1000 * removed_area_ratio))
	Mng.score += delta_score


func cut_out_ui_polygon_from_field(_poly: PackedVector2Array) -> void:
	ui_polygon = _poly
	


func cut_along_segment(seg: PackedVector2Array, at_point: Vector2) -> void:
	assert(seg.size() == 2)
	if not is_point_in_paper(at_point):
		return

	# 1) Find the region under the point and copy others as-is
	var target_idx := _paper_region_index_at(at_point)
	if target_idx == -1:
		return

	var new_regions: Array[PackedVector2Array] = []
	for i in range(paper_regions.size()):
		if i != target_idx:
			new_regions.append(paper_regions[i])

	var target := paper_regions[target_idx]

	# 2) Build a finite slit along the actual cut segment and apply it only to the target
	var slit := segment_to_strip(seg, slit_thickness, slit_thickness * 0.5)

	# Pieces actually removed by the slit (for area/signal/visuals)
	var slit_removed_now: Array[PackedVector2Array] = Geometry2D.intersect_polygons(target, slit)
	# Target after subtracting the slit (this returns the disconnected components you need)
	var kept_components: Array[PackedVector2Array] = Geometry2D.clip_polygons(target, slit)

	# If slit doesn't touch the target, keep target unchanged and bail
	if slit_removed_now.is_empty() and kept_components.is_empty():
		new_regions.append(target)
		paper_regions = new_regions
		available_area = calculate_polygons_area(paper_regions)
		if debug: %debug_renderer.queue_redraw()
		return

	# 3) Decide which components to keep/remove
	#    - prefer the component containing the at_point
	#    - consider pencils only inside the original target
	var pens_here := _pencils_in_region(target)

	var chosen_idx := _index_of_component_with_point(kept_components, at_point)
	var comps_with_pencils := _flags_components_have_pencils(kept_components, pens_here)

	# Both sides active? (any component other than chosen has a pencil)
	var both_sides := false
	if chosen_idx != -1:
		for i in range(kept_components.size()):
			if i != chosen_idx and comps_with_pencils[i]:
				both_sides = true
				break
	else:
		# If the cut went exactly through a vertex/edge and at_point sits on the slit,
		# fall back: if multiple comps have pencils, treat as both_sides
		var pencil_count := 0
		for f in comps_with_pencils:
			if f: pencil_count += 1
		both_sides = pencil_count >= 2

	var just_removed: Array[PackedVector2Array] = []

	if both_sides:
		# Keep all components; only the slit is removed
		new_regions.append_array(_filter_nontrivial(kept_components))
		just_removed.append_array(_filter_nontrivial(slit_removed_now))
		# Optional: solid collider for the slit so pencils bounce on it
		add_solid_collision_polygon_to_segments(slit)
		# Emit per slit piece (not the whole rectangle)
		for poly in slit_removed_now:
			paper_removed.emit(poly)
	else:
		# Keep one side, remove the other components (+ the slit)
		if chosen_idx == -1:
			# If at_point is ambiguous, pick the component with pencils; else the largest
			chosen_idx = _first_component_with_pencils(comps_with_pencils)
			if chosen_idx == -1:
				chosen_idx = _index_of_largest_component(kept_components)
		# Keep chosen
		if chosen_idx != -1:
			new_regions.append(kept_components[chosen_idx])
		# Remove others
		for i in range(kept_components.size()):
			if i == chosen_idx: continue
			just_removed.append(kept_components[i])
			paper_removed.emit(kept_components[i])
		# Slit pieces are also removed (count area + visuals/colliders)
		for poly in slit_removed_now:
			just_removed.append(poly)
			paper_removed.emit(poly)

	# 4) Commit and spawn visuals/colliders for removed bits
	paper_regions = new_regions

	if just_removed.size() > 0:
		add_collision_polygons(just_removed)
		removed_regions.append_array(just_removed)

	available_area = calculate_polygons_area(paper_regions)
	if debug: %debug_renderer.queue_redraw()




#region Collisions update
func clear_cut_visuals() -> void:
	for c in cut_polygons.get_children() + mask_polys.get_children():
		c.queue_free()


func add_collision_polygons(polys: Array[PackedVector2Array]) -> void:
	for poly in polys:
		add_collision_polygon(poly)


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


func _index_of_component_with_point(comps: Array[PackedVector2Array], p: Vector2) -> int:
	for i in range(comps.size()):
		if Geometry2D.is_point_in_polygon(p, comps[i]):
			return i
	return -1


func _flags_components_have_pencils(comps: Array[PackedVector2Array], pens: Array[Pencil]) -> PackedByteArray:
	var flags := PackedByteArray()
	flags.resize(comps.size())
	for i in range(comps.size()):
		var has := false
		for pen in pens:
			if Geometry2D.is_point_in_polygon(pen.global_position, comps[i]):
				has = true
				break
		flags[i] = 1 if has else 0
	return flags


func _first_component_with_pencils(flags: PackedByteArray) -> int:
	for i in range(flags.size()):
		if flags[i] == 1: return i
	return -1


func _index_of_largest_component(comps: Array[PackedVector2Array]) -> int:
	var best := -1
	var best_area := -INF
	for i in range(comps.size()):
		var a := polygon_area_shoelace(comps[i])
		if a > best_area:
			best_area = a; best = i
	return best


func _filter_nontrivial(pieces: Array[PackedVector2Array], area_eps := 1e-3) -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	for poly in pieces:
		if poly.size() >= 3 and abs(polygon_area_shoelace(poly, true)) > area_eps:
			out.append(poly)
	return out


func get_random_point_in_paper() -> Vector2:
	@warning_ignore_start("confusable_local_declaration")
	if paper_regions.is_empty():
		return Vector2.ZERO
	
	# --- 1) Pick a region weighted by area ---
	var eps := 1e-6
	var areas := PackedFloat32Array()
	areas.resize(paper_regions.size())
	var total_area := 0.0
	
	for i in range(paper_regions.size()):
		var poly := paper_regions[i]
		var a: float = abs(polygon_area_shoelace(poly, true))
		areas[i] = a
		total_area += a
	
	if total_area <= eps:
		return Vector2.ZERO
	
	var r := randf() * total_area
	var acc := 0.0
	var region_idx := 0
	for i in range(areas.size()):
		acc += areas[i]
		if r <= acc:
			region_idx = i
			break

	var poly: PackedVector2Array = paper_regions[region_idx]

	# --- 2) Triangulate & pick a triangle weighted by area ---
	var idx := Geometry2D.triangulate_polygon(poly)  # PackedInt32Array
	if idx.size() < 3:
		return _random_point_in_polygon_rejection(poly)  # fallback

	var tri_areas := PackedFloat32Array()
	@warning_ignore("integer_division")
	tri_areas.resize(idx.size() / 3)
	var tri_total := 0.0
	var t := 0
	for i in range(0, idx.size(), 3):
		var A := poly[idx[i]]
		var B := poly[idx[i + 1]]
		var C := poly[idx[i + 2]]
		var area2: float = abs((B - A).cross(C - A))  # 2 * area
		var area: float = 0.5 * area2
		tri_areas[t] = area
		tri_total += area
		t += 1

	if tri_total <= eps:
		return _random_point_in_polygon_rejection(poly)  # fallback

	var rr := randf() * tri_total
	acc = 0.0
	var k := 0
	for j in range(tri_areas.size()):
		acc += tri_areas[j]
		if rr <= acc:
			k = j
			break

	var A := poly[idx[3 * k + 0]]
	var B := poly[idx[3 * k + 1]]
	var C := poly[idx[3 * k + 2]]

	# --- 3) Uniform point in triangle via barycentric reflection trick ---
	var u := randf()
	var v := randf()
	if u + v > 1.0:
		u = 1.0 - u
		v = 1.0 - v
	@warning_ignore_restore("confusable_local_declaration")
	return A + (B - A) * u + (C - A) * v


# Fallback: rejection sample in the polygon's AABB (fast for reasonably shaped polys).
func _random_point_in_polygon_rejection(poly: PackedVector2Array, max_tries := 64) -> Vector2:
	var rect := _poly_aabb(poly)
	for _i in range(max_tries):
		var p := Vector2(
			randf_range(rect.position.x, rect.position.x + rect.size.x),
			randf_range(rect.position.y, rect.position.y + rect.size.y)
		)
		if Geometry2D.is_point_in_polygon(p, poly):
			return p
	# If we somehow fail repeatedly, return a simple centroid-ish fallback.
	return _poly_vertex_centroid(poly)
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


static func _poly_aabb(poly: PackedVector2Array) -> Rect2:
	var minp := poly[0]
	var maxp := poly[0]
	for i in range(1, poly.size()):
		var p := poly[i]
		minp.x = min(minp.x, p.x)
		minp.y = min(minp.y, p.y)
		maxp.x = max(maxp.x, p.x)
		maxp.y = max(maxp.y, p.y)
	return Rect2(minp, maxp - minp)


static func _poly_vertex_centroid(poly: PackedVector2Array) -> Vector2:
	var c := Vector2.ZERO
	for p in poly:
		c += p
	return c / float(max(1, poly.size()))
#endregion


#region Debug
@export var debug: bool = false:
	set(val):
		debug = val
		%debug_renderer.queue_redraw()
@export var debug_line_width: float = 2.0

const COL_PAPER := Color.GREEN
const COL_CUT := Color.RED
const COL_UI := Color.BLUE
const COL_SEGMENT := Color.BLUE_VIOLET


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_E and event.is_pressed() and not event.is_echo():
			debug = !debug


func _draw_on_renderer() -> void:
	if not debug:
		return
	for poly: PackedVector2Array in paper_regions:
		_draw_region(poly, COL_PAPER)
	for poly: PackedVector2Array in removed_regions:
		_draw_region(poly, COL_CUT)
	#if ui_polygon.size() >= 3:
		#_draw_region(ui_polygon, COL_UI)
	for seg: PackedVector2Array in cut_segments:
		if seg.size() == 2:
			%debug_renderer.draw_line(seg[0], seg[1], COL_SEGMENT, debug_line_width, true)


func _draw_region(poly: PackedVector2Array, outline: Color) -> void:
	var fill: Color = outline
	fill.a *= 0.3
	if poly.size() < 3:
		return
	%debug_renderer.draw_colored_polygon(poly, fill)
	var loop := poly.duplicate()
	loop.append(poly[0])
	%debug_renderer.draw_polyline(loop, outline, debug_line_width, true)
#endregion
