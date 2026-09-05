extends Node3D
## Rendering consumes weather state; no chance rolls or physics decisions here.
## The single near batch is a measured-study baseline, not a final LOD layout.

var _panels := MultiMeshInstance3D.new()
var _rain := MultiMeshInstance3D.new()
var _panel_material := ShaderMaterial.new()
var _fallback_surface
const SurfaceSampler = preload("res://game/world/illustrated_water_surface.gd")

static func build_surface_mesh(cell_size: float = 4.0) -> ArrayMesh:
	# Each assembly is a thin, connected shoulder/crest/face surface. World-space
	# displacement joins its boundary vertices exactly to the adjoining assembly.
	var n: int = SurfaceSampler.SUBDIVISIONS
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for z in range(n + 1):
		for x in range(n + 1):
			vertices.append(Vector3((float(x) / n - 0.5) * cell_size, 0.0, (float(z) / n - 0.5) * cell_size))
			normals.append(Vector3.UP)
			uvs.append(Vector2(float(x) / n, float(z) / n))
	for z in range(n):
		for x in range(n):
			var a: int = z * (n + 1) + x
			var b: int = a + 1
			var c: int = a + n + 1
			var d: int = c + 1
			indices.append_array(PackedInt32Array([a, d, b, a, c, d]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.custom_aabb = AABB(Vector3(-cell_size * 0.5, -3.0, -cell_size * 0.5), Vector3(cell_size, 6.0, cell_size))
	return mesh

func _ready() -> void:
	var mesh := build_surface_mesh()
	_panel_material.shader = preload("res://game/world/water_panel.gdshader")
	_panel_material.set_shader_parameter("illustration", preload("res://game/presentation/waves/raised_crest.svg"))
	_panels.multimesh = MultiMesh.new()
	_panels.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_panels.multimesh.mesh = mesh
	_panels.material_override = _panel_material
	_panels.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_panels.extra_cull_margin = 2.0
	add_child(_panels)
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
	for index in range(states.size()):
		var state: Dictionary = states[index]
		var point: Vector2 = state.position
		# Root height and meaningful relief are both applied by the shared field.
		_panels.multimesh.set_instance_transform(index, Transform3D(Basis.IDENTITY, Vector3(point.x, 0.0, point.y)))
	var parameters: Dictionary = simulation.get_render_parameters()
	for key in parameters:
		_panel_material.set_shader_parameter(key, parameters[key])
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
