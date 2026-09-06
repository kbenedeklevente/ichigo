extends Node3D
## Rendering consumes weather state; no chance rolls or physics decisions here.
## Paper Theatre: upright die-cut illustrations, independently rooted in weather springs.

var _panels := MultiMeshInstance3D.new()
var _rain := MultiMeshInstance3D.new()
var _ribbons := MultiMeshInstance3D.new()
var _panel_material := ShaderMaterial.new()
var _fallback_surface
# Amplify signed spring displacement equally above/below the existing art roots.
const VERTICAL_MOTION_SCALE := 2.0
const CALM_HEIGHT_SCALE := 0.5
const MAX_HEIGHT_SCALE := 2.0
const CALM_CREST_HEIGHT_SCALE := 0.35
const CREST_CURVE_SHAPE := 9.0
const MIN_VISUAL_DENSITY := 1
const MAX_VISUAL_DENSITY := 8
var visual_density: int = 1
var _layout_key: Array = []
var _layout_rebuilds: int = 0
var _crest_layout_key: Array = []
var _crest_layout_rebuilds: int = 0
var _visual_side: int = 17
var _visual_spacing: float = 4.0
var _visual_origin := Vector2.ZERO
var _layout_ms: float = 0.0
var _update_ms: float = 0.0
var _field_side: int = 33
const SurfaceSampler = preload("res://game/world/illustrated_water_surface.gd")

static func build_surface_mesh(cell_size: float = 4.0) -> ArrayMesh:
	# A standing card with its pivot at the submerged lower edge. Its silhouette
	# comes solely from the original transparent SVG, never a displaced sea mesh.
	var width := cell_size * 1.70
	var height := cell_size * 0.95
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([
		Vector3(-width / 2.0, 0.0, 0.0), Vector3(width / 2.0, 0.0, 0.0),
		Vector3(width / 2.0, height, 0.0), Vector3(-width / 2.0, height, 0.0)])
	arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array([Vector3.BACK, Vector3.BACK, Vector3.BACK, Vector3.BACK])
	arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array([Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 0, 2, 3])
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _ready() -> void:
	var mesh := build_surface_mesh()
	_panel_material.shader = preload("res://game/world/water_panel.gdshader")
	_panel_material.set_shader_parameter("curl_art", preload("res://game/presentation/waves/theatre_curl.svg"))
	_panel_material.set_shader_parameter("double_art", preload("res://game/presentation/waves/theatre_double.svg"))
	_panel_material.set_shader_parameter("sweep_art", preload("res://game/presentation/waves/theatre_sweep.svg"))
	_panel_material.set_shader_parameter("ribbon_art", preload("res://game/presentation/waves/theatre_ribbon.svg"))
	_panels.multimesh = MultiMesh.new()
	_panels.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_panels.multimesh.use_custom_data = true
	_panels.multimesh.mesh = mesh
	_panels.material_override = _panel_material
	_panels.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_panels.extra_cull_margin = 2.0
	add_child(_panels)
	_ribbons.multimesh = MultiMesh.new()
	_ribbons.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_ribbons.multimesh.use_custom_data = true
	_ribbons.multimesh.mesh = mesh
	_ribbons.material_override = _panel_material
	_ribbons.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ribbons.extra_cull_margin = 3.0
	add_child(_ribbons)
	var drop := QuadMesh.new()
	drop.size = Vector2(0.016, 0.26)
	_rain.multimesh = MultiMesh.new()
	_rain.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_rain.multimesh.mesh = drop
	_rain.multimesh.instance_count = 192
	_rain.multimesh.visible_instance_count = 0
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color("b5c8c4")
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_rain.material_override = material
	_rain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_rain)

func update_weather(simulation, time: float, player: Vector3) -> void:
	if not simulation.has_method("get_render_parameters"):
		if _fallback_surface == null:
			_fallback_surface = SurfaceSampler.new()
			_fallback_surface.configure(simulation)
		_fallback_surface.update()
		simulation = _fallback_surface
	var update_started := Time.get_ticks_usec()
	var status: Dictionary = simulation.get_status()
	var parameters: Dictionary = simulation.get_render_parameters()
	var cell_size: float = status.cell_size
	var center := Vector2i(floori(player.x / cell_size), floori(player.z / cell_size))
	var key: Array = [visual_density, center, status.render_radius, cell_size]
	if key != _layout_key:
		_rebuild_layout(center, int(status.render_radius), cell_size)
		_layout_key = key
	_field_side = int(parameters.field_side)
	_panel_material.set_shader_parameter("weather_fields", parameters.field_texture)
	_panel_material.set_shader_parameter("field_origin", parameters.field_origin)
	_panel_material.set_shader_parameter("field_side", parameters.field_side)
	_panel_material.set_shader_parameter("logical_cell_size", cell_size)
	_panel_material.set_shader_parameter("visual_spacing", _visual_spacing)
	_panel_material.set_shader_parameter("visual_center_offset", (_visual_spacing - cell_size) * 0.5)
	_panel_material.set_shader_parameter("vertical_motion_scale", VERTICAL_MOTION_SCALE)
	_panel_material.set_shader_parameter("height_range", Vector2(CALM_HEIGHT_SCALE, MAX_HEIGHT_SCALE))
	_panel_material.set_shader_parameter("crest_height_range", Vector2(CALM_CREST_HEIGHT_SCALE, MAX_HEIGHT_SCALE))
	_panel_material.set_shader_parameter("crest_curve_shape", CREST_CURVE_SHAPE)
	# Shader motion is absent from static MultiMesh transforms: include actual
	# field extrema and the largest artwork in explicit conservative bounds.
	var y_min: float = float(parameters.minimum_height) * VERTICAL_MOTION_SCALE - 12.0
	var y_max: float = float(parameters.maximum_height) * VERTICAL_MOTION_SCALE + 12.0
	var span: float = (_visual_side - 1) * _visual_spacing + 16.0
	var bounds := AABB(Vector3(_visual_origin.x - 8.0, y_min, _visual_origin.y - 8.0), Vector3(span, y_max - y_min, span))
	_panels.multimesh.custom_aabb = bounds
	_ribbons.multimesh.custom_aabb = bounds
	var local: Dictionary = simulation.sample(Vector2(player.x, player.z))
	_panel_material.set_shader_parameter("bucket_center", Vector2(player.x, player.z))
	_panel_material.set_shader_parameter("illumination", lerpf(0.50, 1.0, clampf(local.light, 0.0, 1.0)))
	var count: int = clampi(int(local.rain * 192.0), 0, 192)
	_rain.multimesh.visible_instance_count = count
	for index in range(count):
		var x: float = fposmod(index * 7.317, 20.0) - 10.0
		var z: float = fposmod(index * 11.713, 20.0) - 10.0
		var y: float = 0.2 + fposmod(index * 0.417 - time * 9.0, 10.0)
		var offset: Vector2 = local.wind * (10.0 - y) * 0.025
		var basis := Basis.from_euler(Vector3(local.wind.y * 0.018, 0, -local.wind.x * 0.018))
		_rain.multimesh.set_instance_transform(index, Transform3D(basis, Vector3(player.x+x+offset.x, y, player.z+z+offset.y)))

	_update_ms = float(Time.get_ticks_usec() - update_started) / 1000.0

func set_visual_density(value: int) -> void:
	visual_density = clampi(value, MIN_VISUAL_DENSITY, MAX_VISUAL_DENSITY)

func get_density_status() -> Dictionary:
	return {"density": visual_density, "spacing": _visual_spacing,
		"tiles": _visual_side * _visual_side, "crest_drawings": _panels.multimesh.instance_count,
		"drawings": _panels.multimesh.instance_count + _ribbons.multimesh.instance_count,
		"crest_layout_rebuilds": _crest_layout_rebuilds,
		"field_samples": _field_side * _field_side, "layout_rebuilds": _layout_rebuilds,
		"layout_ms": _layout_ms, "update_ms": _update_ms}

func _rebuild_layout(center: Vector2i, radius: int, cell_size: float) -> void:
	var started := Time.get_ticks_usec()
	_visual_spacing = cell_size / float(visual_density)
	_visual_side = (radius * 2 + 1) * visual_density
	var first_cell := (center - Vector2i.ONE * radius) * visual_density
	var offset := Vector2.ONE * (_visual_spacing - cell_size) * 0.5
	_visual_origin = Vector2(first_cell) * _visual_spacing + offset
	# Large curling crests retain their original logical-cell anchors and size.
	# Slider changes rebuild only the denser lower-water drawings.
	var crest_key: Array = [center, radius, cell_size]
	if crest_key != _crest_layout_key:
		_fill_grid(_panels.multimesh, center - Vector2i.ONE * radius, radius * 2 + 1, cell_size, Vector2.ZERO, true)
		_crest_layout_key = crest_key
		_crest_layout_rebuilds += 1
	_fill_grid(_ribbons.multimesh, first_cell, _visual_side, _visual_spacing, offset, false)
	_layout_rebuilds += 1
	_layout_ms = float(Time.get_ticks_usec() - started) / 1000.0

func _fill_grid(mm: MultiMesh, first_cell: Vector2i, side: int, spacing: float, offset: Vector2, crest: bool) -> void:
	mm.instance_count = side * side
	for y in range(side):
		for x in range(side):
			var index := y * side + x
			var cell := first_cell + Vector2i(x, y)
			var point := Vector2(cell) * spacing + offset
			var transform := Transform3D(Basis.IDENTITY, Vector3(point.x, 0.0, point.y))
			var seed_value := fposmod(float(cell.x * 17 + cell.y * 31), 13.0) / 13.0
			var variant := float(posmod(cell.x + cell.y * 3, 3)) * 0.5
			mm.set_instance_transform(index, transform)
			mm.set_instance_custom_data(index, Color(variant, seed_value, 1.0 if posmod(cell.x + cell.y, 5) == 0 else 0.0, 1.0) if crest else Color(0.0, seed_value, 0.0, 0.0))
