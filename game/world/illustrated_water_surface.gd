extends RefCounted
## Faded Tides: broad, low scalloped swells on a shared physical paper surface.
## Keep analytic_height and water_panel.gdshader vertex relief in agreement.
const SUBDIVISIONS := 24
const FACE_RISE := 0.34
const PROFILE_TRAVEL := 0.24
const NORMAL_STEP := 0.012
var _simulation
var _status: Dictionary = {}
var _snapshot: Dictionary = {}
var _heights := PackedFloat64Array()
var _amplitudes := PackedFloat64Array()
var _origin := Vector2i.ZERO
var _side := 0
var _cell_size := 4.0
var _phase := 0.0
var _texture: ImageTexture
var _field_image: Image
var _last_time := -1.0
var _panels: Array[Dictionary] = []
var _vertex_heights: Dictionary = {}

func configure(simulation) -> void:
	_simulation = simulation
	_last_time = -1.0
	update()

func update() -> void:
	if _simulation == null:
		return
	var status: Dictionary = _simulation.get_status()
	if float(status.simulation_time) == _last_time and status.origin == _origin:
		return
	_vertex_heights.clear()
	_status = status
	_last_time = status.simulation_time
	_phase = status.phase
	_origin = status.origin
	_cell_size = status.cell_size
	_side = int(status.simulation_radius) * 2 + 1
	# One small buffered snapshot per fixed tick, never a sample Dictionary per vertex.
	_snapshot = _simulation.snapshot()
	_heights = _snapshot.fields.height
	_amplitudes = _snapshot.fields.amplitude
	var pixels := PackedFloat32Array()
	pixels.resize(_side * _side * 2)
	for i in range(_side * _side):
		pixels[i * 2] = _heights[i]
		pixels[i * 2 + 1] = _amplitudes[i]
	var image := Image.create_from_data(_side, _side, false, Image.FORMAT_RGF, pixels.to_byte_array())
	_field_image = image
	if _texture == null or _texture.get_width() != _side:
		_texture = ImageTexture.create_from_image(image)
	else:
		_texture.update(image)
	_panels = _simulation.get_panel_states()

func get_status() -> Dictionary:
	return _simulation.get_status()

func get_panel_states() -> Array[Dictionary]:
	return _panels

func get_render_parameters() -> Dictionary:
	return {"field_texture": _texture, "field_origin": Vector2(_origin) * _cell_size,
		"field_side": float(_side), "cell_size": _cell_size, "crest_phase": _phase,
		"face_rise": FACE_RISE, "profile_travel": PROFILE_TRAVEL}

func sample(point: Vector2) -> Dictionary:
	if not point.is_finite():
		point = _snapshot.get("player", Vector2.ZERO)
	var value: Dictionary = _simulation.sample(point)
	value["root_height"] = value.height
	value["height"] = height_at(point)
	value["crest_height"] = float(value.height) - float(value.root_height)
	var dx := (height_at(point + Vector2(NORMAL_STEP, 0.0)) - height_at(point - Vector2(NORMAL_STEP, 0.0))) / (2.0 * NORMAL_STEP)
	var dz := (height_at(point + Vector2(0.0, NORMAL_STEP)) - height_at(point - Vector2(0.0, NORMAL_STEP))) / (2.0 * NORMAL_STEP)
	value["normal"] = Vector3(-dx, 1.0, -dz).normalized()
	return value

func _field(point: Vector2, values: PackedFloat64Array) -> float:
	var grid := point / _cell_size - Vector2(_origin)
	grid.x = clampf(grid.x, 0.0, float(_side - 1))
	grid.y = clampf(grid.y, 0.0, float(_side - 1))
	var ix := mini(int(floor(grid.x)), _side - 2)
	var iy := mini(int(floor(grid.y)), _side - 2)
	var f := grid - Vector2(ix, iy)
	var a := iy * _side + ix
	return lerpf(lerpf(values[a], values[a + 1], f.x), lerpf(values[a + _side], values[a + _side + 1], f.x), f.y)

static func _seed(cell: Vector2i) -> float:
	# Integer-sized polynomial hash also exact in shader float over the play region.
	return fposmod(float(cell.x * 17 + cell.y * 31), 13.0) / 13.0

func analytic_height(point: Vector2) -> float:
	var traveled := point - Vector2(0.0, _phase * PROFILE_TRAVEL)
	var owner := Vector2i(floor(traveled.x / _cell_size + 0.5), floor(traveled.y / _cell_size + 0.5))
	var relief := 0.0
	for y in range(-1, 2):
		for x in range(-1, 2):
			var cell := owner + Vector2i(x, y)
			var seed_value := _seed(cell)
			var center := Vector2(cell) * _cell_size + Vector2((seed_value - 0.5) * 1.2, (fposmod(seed_value * 7.0, 1.0) - 0.5) * 0.8)
			var local := (traveled - center) * (4.0 / _cell_size)
			var half_width := 2.55 + 0.35 * seed_value
			if absf(local.x) >= half_width:
				continue
			var across := local.x / half_width
			# Flat-topped rounded envelope overlaps adjacent swells; no off-centre tip.
			var taper := smoothstep(0.0, 0.70, 1.0 - absf(across))
			var scallop := 0.10 * cos(across * 9.42477796 + seed_value * 3.0)
			var along := local.y + 0.46 * across * across + scallop
			var shoulder := 1.48 + 0.22 * seed_value
			var front := 0.76 + 0.12 * seed_value
			var profile := smoothstep(-shoulder, -0.16, along) * (1.0 - smoothstep(0.08, front, along))
			relief += FACE_RISE * (0.88 + 0.18 * seed_value) * taper * profile
	var amplitude := _field(point, _amplitudes)
	return _field(point, _heights) + relief * (1.0 + 0.18 * clampf((amplitude - 0.12) / 0.66, 0.0, 1.0))

func _vertex_height(index: Vector2i) -> float:
	if not _vertex_heights.has(index):
		# Keep paused cursor exploration bounded too. Nearby queries reuse the
		# same vertices for buoyancy, normals and target-ray refinement.
		if _vertex_heights.size() >= 8192:
			_vertex_heights.clear()
		var point := Vector2(index) * (_cell_size / SUBDIVISIONS) - Vector2.ONE * _cell_size * 0.5
		_vertex_heights[index] = analytic_height(point)
	return _vertex_heights[index]

func height_at(point: Vector2) -> float:
	# Match the actual rendered triangles, including the choice of diagonal.
	# Cell edges sit at half-cell coordinates, so this lattice never moves on scroll.
	var step := _cell_size / SUBDIVISIONS
	var grid := (point + Vector2.ONE * _cell_size * 0.5) / step
	var index := Vector2i(floor(grid.x), floor(grid.y))
	var fraction := grid - Vector2(index)
	var h00 := _vertex_height(index)
	var h11 := _vertex_height(index + Vector2i.ONE)
	if fraction.x >= fraction.y:
		return h00 * (1.0 - fraction.x) + _vertex_height(index + Vector2i.RIGHT) * (fraction.x - fraction.y) + h11 * fraction.y
	return h00 * (1.0 - fraction.y) + _vertex_height(index + Vector2i.DOWN) * (fraction.y - fraction.x) + h11 * fraction.x
