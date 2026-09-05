extends Node3D
## Every visible water prop is a separate curved drawing with its own pivot.
## The invisible baseline sampler remains an APPROXIMATE interaction surface.
var _cards: Array[MeshInstance3D] = []
var _materials: Array[StandardMaterial3D] = []
var _horizon: Array[MeshInstance3D] = []
var _weather_effects: Node3D

func _ready() -> void:
	_weather_effects = preload("res://game/world/weather_presentation.gd").new()
	add_child(_weather_effects)
	_weather_effects.get("_panels").visible = false
	for asset in ["whorls", "ribbons", "distance"]:
		var material := StandardMaterial3D.new()
		material.albedo_texture = load("res://game/presentation/ink/" + asset + ".svg")
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		material.alpha_scissor_threshold = 0.4
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		_materials.append(material)
	for i in range(289):
		_cards.append(_make_card(Vector2(6.6, 7.2), 0.72))
	# Distant independent paper scenery replaces the old 8000 m water plane.
	for row in range(8):
		for col in range(11):
			var card := _make_card(Vector2(27, 24), 0.22)
			card.material_override = _materials[2]
			_horizon.append(card)

func _make_card(size: Vector2, rise: float) -> MeshInstance3D:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# A shallow asymmetric hinge gives front-face relief without solid extrusion.
	var profile := [Vector2(-0.5, -0.18), Vector2(-0.26, 0.1), Vector2(-0.07, rise), Vector2(0.07, 0.2), Vector2(0.5, -0.3)]
	for row in range(4):
		for corner in [Vector2i(0,0),Vector2i(1,1),Vector2i(1,0),Vector2i(0,0),Vector2i(0,1),Vector2i(1,1)]:
			var r: int = row + corner.y
			var p: Vector2 = profile[r]
			surface.set_uv(Vector2(corner.x, float(r) / 4.0))
			surface.set_normal(Vector3.UP)
			surface.add_vertex(Vector3((corner.x - 0.5) * size.x, p.y, p.x * size.y))
	var card := MeshInstance3D.new()
	card.mesh = surface.commit()
	card.material_override = _materials[0]
	card.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	card.extra_cull_margin = 1.5
	add_child(card)
	return card

func update_weather(simulation, time: float, player: Vector3) -> void:
	_weather_effects.update_weather(simulation, time, player)
	var states: Array[Dictionary] = simulation.get_panel_states()
	for i in range(mini(states.size(), _cards.size())):
		var state: Dictionary = states[i]
		var cell: Vector2i = state.cell_id
		var seed_value := fposmod(float(cell.x * 17 + cell.y * 31), 19.0) / 19.0
		var point: Vector2 = state.position
		var card := _cards[i]
		var offset := Vector2((seed_value - 0.5) * 1.0, sin(seed_value * 19.0) * 0.55)
		var depth: float = point.y - player.z
		var kind: int = 0 if depth > 1.0 else (1 if depth > -15.0 else 2)
		card.material_override = _materials[kind]
		card.scale.x = 0.96 + seed_value * 0.16
		card.position = Vector3(point.x + offset.x, float(state.height) - 0.36, point.y + offset.y)
		card.rotation = Vector3(state.tilt.x * 0.32, (seed_value - 0.5) * 0.13, state.tilt.y * 0.32 + sin(time * 0.55 + seed_value * TAU) * 0.009)
		# Leave the bucket opening unobscured. This is an artistic clearance, not collision.
		if Vector2(card.position.x - player.x, card.position.z - player.z).length() < 3.5:
			card.position.y -= 0.55
	for i in range(_horizon.size()):
		var row := i / 11
		var col := i % 11
		_horizon[i].position = Vector3(player.x + (col - 5) * 23.0 + (row % 2) * 7.0, -0.8 - row * 0.08, player.z - 40.0 - row * 19.0)
		_horizon[i].rotation.z = sin(time * 0.12 + i) * 0.002
	var local: Dictionary = simulation.sample(Vector2(player.x, player.z))
	for material in _materials:
		material.albedo_color = Color.WHITE * lerpf(0.58, 1.0, clampf(local.light, 0, 1))
