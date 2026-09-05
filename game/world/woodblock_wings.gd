extends Node3D
## Broad scenic flats on a fixed world lattice; simulation is consumed, never changed.
const WIDTH := 38.0
const HEIGHT := 6.4
const X_STEP := 32.0
const Z_STEP := 3.0
const ROWS := 45
const COLUMNS := 5
var _wings: Dictionary = {}
var _material := ShaderMaterial.new()
var _mesh := QuadMesh.new()
var _rain := MultiMeshInstance3D.new()

func _ready() -> void:
	_material.shader = preload("res://game/presentation/woodblock/wing.gdshader")
	_material.set_shader_parameter("illustration", preload("res://game/presentation/woodblock/wing.svg"))
	_mesh.size = Vector2(WIDTH, HEIGHT)
	var drop := QuadMesh.new()
	drop.size = Vector2(0.016, 0.26)
	_rain.multimesh = MultiMesh.new()
	_rain.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_rain.multimesh.mesh = drop
	_rain.multimesh.instance_count = 192
	_rain.multimesh.visible_instance_count = 0
	var rain_material := StandardMaterial3D.new()
	rain_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rain_material.albedo_color = Color("b9d0c9")
	rain_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_rain.material_override = rain_material
	_rain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_rain)

func update_weather(surface, time: float, player: Vector3) -> void:
	var center := Vector2i(floor(player.x / X_STEP), floor(player.z / Z_STEP))
	var wanted: Dictionary = {}
	for row in range(-ROWS + 6, 6):
		for column in range(-2, 3):
			var key := center + Vector2i(column, row)
			wanted[key] = true
	# Reuse nodes that leave the lattice window; retained cells never change roots.
	var recycled: Array[MeshInstance3D] = []
	for key in _wings.keys():
		if not wanted.has(key):
			recycled.append(_wings[key])
			_wings.erase(key)
	for key in wanted:
		if not _wings.has(key):
			var wing: MeshInstance3D
			if recycled.is_empty():
				wing = MeshInstance3D.new()
				wing.mesh = _mesh
				wing.material_override = _material
				wing.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				add_child(wing)
			else:
				wing = recycled.pop_back()
			_wings[key] = wing
	for wing in recycled:
		wing.queue_free()
	for key in _wings:
		var wing: MeshInstance3D = _wings[key]
		var seed_value := fposmod(float(key.x * 19 + key.y * 37), 31.0) / 31.0
		var point := Vector2(key.x * X_STEP + (fposmod(float(key.y), 2.0) - 0.5) * 11.0, key.y * Z_STEP)
		var weather: Dictionary = surface._simulation.sample(point)
		var amplitude: float = weather.wave_amplitude
		var phase: float = float(surface.get_status().phase) + seed_value * TAU
		wing.position = Vector3(point.x, -0.92 + float(weather.height) * 0.42 + sin(phase * 0.7) * (0.035 + amplitude * 0.10), point.y)
		wing.rotation = Vector3(deg_to_rad(-66.0) + sin(phase * 0.58) * amplitude * 0.035, (seed_value - 0.5) * 0.055, sin(phase) * (0.001 + amplitude * 0.012))
		wing.scale.x = -1.0 if posmod(key.y, 3) == 1 else 1.0
	var local: Dictionary = surface.sample(Vector2(player.x, player.z))
	_material.set_shader_parameter("player_position", Vector2(player.x, player.z))
	_material.set_shader_parameter("illumination", lerpf(0.68, 1.0, clampf(local.light, 0.0, 1.0)))
	var count: int = clampi(int(local.rain * 192.0), 0, 192)
	_rain.multimesh.visible_instance_count = count
	for index in range(count):
		var x: float = fposmod(index * 7.317, 20.0) - 10.0
		var z: float = fposmod(index * 11.713, 20.0) - 10.0
		var y: float = 0.2 + fposmod(index * 0.417 - time * 9.0, 10.0)
		var offset: Vector2 = local.wind * (10.0 - y) * 0.025
		_rain.multimesh.set_instance_transform(index, Transform3D(Basis.IDENTITY, Vector3(player.x + x + offset.x, y, player.z + z + offset.y)))
