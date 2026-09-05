extends Node3D
## Rendering consumes weather state; no chance rolls or physics decisions here.
## Paper Theatre: upright die-cut illustrations, independently rooted in weather springs.

var _panels := MultiMeshInstance3D.new()
var _rain := MultiMeshInstance3D.new()
var _ribbons := MultiMeshInstance3D.new()
var _ribbon_transforms: Array[Transform3D] = []
var _panel_material := ShaderMaterial.new()
var _card_transforms: Array[Transform3D] = []
var _fallback_surface
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
	var states: Array[Dictionary] = simulation.get_panel_states()
	if _panels.multimesh.instance_count != states.size():
		_panels.multimesh.instance_count = states.size()
		_ribbons.multimesh.instance_count = states.size()
	_card_transforms.resize(states.size())
	_ribbon_transforms.resize(states.size())
	for index in range(states.size()):
		var state: Dictionary = states[index]
		var point: Vector2 = state.position
		var cell: Vector2i = state.cell_id
		var seed_value := fposmod(float(cell.x * 17 + cell.y * 31), 13.0) / 13.0
		var stagger := 2.0 if posmod(cell.y, 2) == 0 else 0.0
		var tilt: Vector2 = state.tilt
		# The spring solver already supplies independently coupled height and slope.
		# The whole drawing rocks about its submerged foot; no UV travel or bending.
		var basis := Basis.from_euler(Vector3(-0.18 + tilt.x * 0.45,
			(seed_value - 0.5) * 0.12, tilt.y * 0.6))
		var size_y := lerpf(0.70, 0.85, seed_value)
		basis = basis.scaled(Vector3(1.0, size_y, 1.0))
		var position := Vector3(point.x + stagger, float(state.height) - 1.65, point.y + (seed_value - 0.5) * 0.36)
		_card_transforms[index] = Transform3D(basis, position)
		_panels.multimesh.set_instance_transform(index, _card_transforms[index])
		var variant := float(posmod(cell.x + cell.y * 3, 3)) * 0.5
		_panels.multimesh.set_instance_custom_data(index, Color(variant, seed_value, 1.0 if posmod(cell.x + cell.y, 5) == 0 else 0.0, 1.0))
		# A second independent drawing reclines between crest rows. It has real
		# depth coverage at high pitch, but never joins into a continuous sea mesh.
		var ribbon_basis := Basis.from_euler(Vector3(-1.15 + tilt.x * 0.2, 0.0, tilt.y * 0.2))
		ribbon_basis = ribbon_basis * Basis.from_scale(Vector3(1.18, 1.65, 1.0))
		var ribbon_position := Vector3(point.x + stagger - 1.0, float(state.height) - 2.25, point.y + 4.0)
		_ribbon_transforms[index] = Transform3D(ribbon_basis, ribbon_position)
		_ribbons.multimesh.set_instance_transform(index, _ribbon_transforms[index])
		_ribbons.multimesh.set_instance_custom_data(index, Color(0.0, seed_value, 0.0, 0.0))
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
