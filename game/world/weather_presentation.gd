extends Node3D
## Rendering consumes weather state; no chance rolls or physics decisions here.
## The single near batch is a measured-study baseline, not a final LOD layout.

var _panels := MultiMeshInstance3D.new()
var _rain := MultiMeshInstance3D.new()
var _panel_material := ShaderMaterial.new()

func _ready() -> void:
	var mesh := QuadMesh.new()
	mesh.size = Vector2(4.55, 4.75)
	_panel_material.shader = preload("res://game/world/water_panel.gdshader")
	_panel_material.set_shader_parameter("illustration", preload("res://game/presentation/water_panel.svg"))
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
	var states: Array[Dictionary] = simulation.get_panel_states()
	if _panels.multimesh.instance_count != states.size():
		_panels.multimesh.instance_count = states.size()
	for index in range(states.size()):
		var state: Dictionary = states[index]
		var point: Vector2 = state.position
		var tilt: Vector2 = state.get("tilt", Vector2.ZERO)
		# The drawing lies on a paper plane with bounded physical tilt.
		var basis := Basis.from_euler(Vector3(-PI * 0.5 + clampf(tilt.x, -0.15, 0.15), 0.0, clampf(tilt.y, -0.15, 0.15)))
		_panels.multimesh.set_instance_transform(index, Transform3D(basis, Vector3(point.x, state.height + 0.035, point.y)))
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
