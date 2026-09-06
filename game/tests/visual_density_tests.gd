extends SceneTree
## Renderer-density contracts; physics and scheduler snapshots must stay unchanged.
const Scene = preload("res://game/camera_study.tscn")
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("Run this rendered MultiMesh study without --headless.")
		quit(2)
		return
	_run.call_deferred()

func _check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)

func _run() -> void:
	var scene = Scene.instantiate()
	root.add_child(scene)
	await process_frame
	scene._set_paused(true)
	var renderer = scene.weather_presentation
	var runtime = scene.weather_runtime
	var surface = scene.water_surface
	var saved: Dictionary = runtime.snapshot()
	var height: float = surface.height_at(Vector2(0.4, -0.3))
	var field_bytes: int = surface._field_image.get_data().size()
	var original_bounds: Rect2
	for density: int in range(1, 9):
		scene.density_slider.value = density
		scene._update_scene(0.0)
		var status: Dictionary = renderer.get_density_status()
		_check(status.density == density and status.tiles == 289 * density * density, "Slider controls density %d and bounded draw count." % density)
		_check(status.spacing == 4.0 / density, "Visual cell side shrinks at density %d." % density)
		_check(runtime.snapshot() == saved, "Density %d does not mutate simulation, scheduler, clock or RNG." % density)
		_check(surface.height_at(Vector2(0.4, -0.3)) == height, "Density %d cannot change gameplay height." % density)
		_check(status.field_samples == 1089 and surface._field_image.get_data().size() == field_bytes, "Density %d does not add field particles or texture samples." % density)
		var mm: MultiMesh = renderer._panels.multimesh
		_check(mm.instance_count == status.tiles and renderer._ribbons.multimesh.instance_count == status.tiles, "Crests/ribbons remain paired at density %d." % density)
		var first: Vector3 = mm.get_instance_transform(0).origin
		var last: Vector3 = mm.get_instance_transform(mm.instance_count - 1).origin
		var bounds := Rect2(Vector2(first.x, first.z) - Vector2.ONE * status.spacing * 0.5, Vector2(last.x-first.x, last.z-first.z) + Vector2.ONE * status.spacing)
		if density == 1:
			original_bounds = bounds
		_check(bounds.is_equal_approx(original_bounds), "Rendered physical extent stays fixed at density %d." % density)
		_check(mm.custom_aabb.has_point(first) and mm.custom_aabb.has_point(last), "Shader-displaced tiles have conservative CPU culling bounds.")
		var rebuilt: int = status.layout_rebuilds
		scene._update_scene(0.0)
		_check(renderer.get_density_status().layout_rebuilds == rebuilt, "Paused/frame updates do not rebuild density %d layout." % density)
	# Verify field texture interpolation against the logical sampler, including
	# non-grid coordinates. The shader uses these four texels and derivatives.
	for point: Vector2 in [Vector2(0.5, -0.75), Vector2(-3.75, -4.25), Vector2(16.3, -18.6)]:
		var actual: Dictionary = runtime.weather.sample(point)
		var packed: Vector4 = _sample_texture(surface, point)
		_check(absf(actual.height - packed.x) < 0.000001 and absf(actual.wind_strength - packed.z) < 0.000001 and absf(actual.cloud_cover - packed.w) < 0.000001, "GPU source interpolation matches base fields at %s." % point)
	# Rebase into negative logical coordinates; shared world anchors must retain
	# their artwork instead of shuffling when the visible window scrolls.
	scene.density_slider.value = 4
	scene._update_scene(0.0)
	var before: Dictionary = _anchors(renderer._panels.multimesh)
	var rebuilt: int = renderer.get_density_status().layout_rebuilds
	scene.bucket.position.x = -4.1
	scene.bucket.position.z = -4.1
	scene._update_scene(0.0)
	_check(renderer.get_density_status().layout_rebuilds == rebuilt + 1, "Logical boundary travel rebuilds the static window once.")
	var after: Dictionary = _anchors(renderer._panels.multimesh)
	var shared: int = 0
	var stable: bool = true
	for key: Vector3 in before:
		if after.has(key):
			shared += 1
			stable = stable and before[key] == after[key]
	_check(shared > 2000 and stable, "Overlapping negative-coordinate tiles keep stable world identity and artwork.")
	_check(runtime.snapshot() == saved, "Rendering a scrolled window still cannot advance logical state.")
	renderer.set_visual_density(1000)
	_check(renderer.visual_density == 8, "Upper bound prevents accidental unbounded allocations.")
	renderer.set_visual_density(-3)
	_check(renderer.visual_density == 1, "Lower bound prevents zero-sized units.")
	# The new texture is transient presentation data and is rebuilt after restore.
	var restored = preload("res://game/events/environment_runtime.gd").new()
	_check(restored.restore(saved), "Existing native runtime save still restores without density in its schema.")
	for failure: String in failures:
		push_error(failure)
	print("Visual density: %d checks, %d failures" % [checks, failures.size()])
	scene.queue_free()
	await process_frame
	await RenderingServer.frame_post_draw
	await process_frame
	quit(0 if failures.is_empty() else 1)

func _anchors(mm: MultiMesh) -> Dictionary:
	var result: Dictionary = {}
	for index: int in range(mm.instance_count):
		result[mm.get_instance_transform(index).origin] = mm.get_instance_custom_data(index)
	return result

func _sample_texture(surface, point: Vector2) -> Vector4:
	var parameters: Dictionary = surface.get_render_parameters()
	var grid: Vector2 = (point - parameters.field_origin) / parameters.cell_size
	grid = grid.clamp(Vector2.ZERO, Vector2.ONE * (parameters.field_side - 1.0))
	var cell := Vector2i(mini(floori(grid.x), int(parameters.field_side)-2), mini(floori(grid.y), int(parameters.field_side)-2))
	var fraction := grid - Vector2(cell)
	var texture: Image = surface._field_image
	var a := texture.get_pixel(cell.x, cell.y)
	var b := texture.get_pixel(cell.x+1, cell.y)
	var c := texture.get_pixel(cell.x, cell.y+1)
	var d := texture.get_pixel(cell.x+1, cell.y+1)
	var result := a.lerp(b, fraction.x).lerp(c.lerp(d, fraction.x), fraction.y)
	return Vector4(result.r, result.g, result.b, result.a)
