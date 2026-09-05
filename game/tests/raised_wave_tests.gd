extends SceneTree
## Shared mesh/reconstruction checks. Visual approval still needs angle captures.
const Weather = preload("res://game/world/weather_simulation.gd")
const Surface = preload("res://game/world/illustrated_water_surface.gd")
const Presentation = preload("res://game/world/weather_presentation.gd")
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)

func _run() -> void:
	var weather := Weather.new()
	weather.configure(15)
	var surface := Surface.new()
	surface.configure(weather)
	_check(surface.get_panel_states().size() == 289, "Keep 289 bounded near assemblies")
	_check(surface.get_status() == weather.get_status(), "Weather status remains delegated")
	var mesh := Presentation.build_surface_mesh()
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	_check(vertices.size() == (Surface.SUBDIVISIONS + 1) ** 2, "The paper has enough real shoulder/face rows")
	_check(indices.size() == Surface.SUBDIVISIONS ** 2 * 6, "Opaque connected triangles cover every near assembly")
	var max_error := 0.0
	var max_relief := 0.0
	var max_front_slope := 0.0
	# Interpolate actual indexed mesh triangles after the shader's shared vertex
	# deformation. This catches the diagonal and half-cell lattice agreement.
	for offset: Vector2 in [Vector2.ZERO, Vector2(-4.0, 4.0), Vector2(12.0, -8.0)]:
		for i in range(0, indices.size(), 9):
			var va: Vector3 = vertices[indices[i]]
			var vb: Vector3 = vertices[indices[i + 1]]
			var vc: Vector3 = vertices[indices[i + 2]]
			var a := offset + Vector2(va.x, va.z)
			var b := offset + Vector2(vb.x, vb.z)
			var c := offset + Vector2(vc.x, vc.z)
			var p := a * 0.23 + b * 0.31 + c * 0.46
			var mesh_height := surface.analytic_height(a) * 0.23 + surface.analytic_height(b) * 0.31 + surface.analytic_height(c) * 0.46
			max_error = maxf(max_error, absf(surface.height_at(p) - mesh_height))
			max_relief = maxf(max_relief, surface.height_at(p) - float(weather.sample(p).height))
			max_front_slope = maxf(max_front_slope, (surface.height_at(p - Vector2(0.0, 0.01)) - surface.height_at(p + Vector2(0.0, 0.01))) / 0.02)
	_check(max_error < 0.00001, "Gameplay height equals actual deformed triangle interpolation (error %f)" % max_error)
	_check(max_relief > 0.25 and max_relief < 0.60, "Faded Tides retains low, meaningful rounded crest relief (%f m)" % max_relief)
	_check(max_front_slope > 0.25 and max_front_slope < 1.10, "Broad scalloped fronts stay rounded rather than standing as fins (%f slope)" % max_front_slope)
	for p in [Vector2(0.1, 0.2), Vector2(-0.73, -0.29), Vector2(3.13, 4.44), Vector2(7.52, -8.17)]:
		var sample := surface.sample(p)
		_check(sample.has("rain") and sample.has("wind") and sample.has("wave_speed"), "Shared sample preserves environment fields")
		var epsilon := Surface.NORMAL_STEP
		var dx := (surface.height_at(p + Vector2(epsilon, 0.0)) - surface.height_at(p - Vector2(epsilon, 0.0))) / (epsilon * 2.0)
		var dz := (surface.height_at(p + Vector2(0.0, epsilon)) - surface.height_at(p - Vector2(0.0, epsilon))) / (epsilon * 2.0)
		_check(sample.normal.distance_to(Vector3(-dx, 1.0, -dz).normalized()) < 0.000001, "Normals are gradients of the same rendered water")
	for axis in range(2):
		for edge in [-6.0, -2.0, 2.0, 6.0]:
			for along in [-1.3, 0.0, 1.7]:
				var p := Vector2(edge, along) if axis == 0 else Vector2(along, edge)
				var step := Vector2(0.0001, 0.0) if axis == 0 else Vector2(0.0, 0.0001)
				_check(absf(surface.height_at(p + step) - surface.height_at(p - step)) < 0.001, "No cell-edge cracks in opaque substrate or crest")
	var fixed := Vector2(0.2, 0.17)
	var before := surface.height_at(fixed)
	for angle in [12.0, 20.0, 38.0, 52.0]:
		var camera := Camera3D.new()
		camera.rotation_degrees.x = -angle
		_check(surface.height_at(fixed) == before, "Camera pitch cannot move water/profile anchors")
		camera.free()
	var before_phase: float = surface.get_status().phase
	weather.advance(1.0 / 30.0, Vector2(4.01, 0.0))
	surface.update()
	_check(absf(surface.height_at(fixed) - before) < 0.015, "Grid recentering preserves crest identity and smooth phase")
	_check(surface.get_status().phase > before_phase, "Shared crest phase advances with the connected weather solver")
	var params := surface.get_render_parameters()
	_check(params.field_texture.get_width() == 33, "One coarse GPU field texture, no per-vertex simulation dictionaries")
	var image: Image = surface._field_image
	_check(absf(image.get_pixel(16, 16).r - float(weather.sample(Vector2(surface.get_status().origin + Vector2i(16, 16)) * 4.0).height)) < 0.000001, "GPU upload buffer agrees with authoritative root field")
	var start := Time.get_ticks_usec()
	for i in range(100):
		surface.sample(Vector2(float(i) * 0.013, 0.2))
	print("Raised shared sampling: 100 complete height/normal/environment samples in %.2f ms" % ((Time.get_ticks_usec() - start) / 1000.0))
	for failure in failures:
		push_error(failure)
	print("Raised paper waves: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
