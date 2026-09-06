extends SceneTree
## Run with -- --weather-study; add --weather-captures=/absolute/path for PNGs.
const Scene = preload("res://game/camera_study.tscn")
var checks: int = 0
var failures: Array[String] = []
var _captures: String = ""

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--weather-captures="):
			_captures = argument.trim_prefix("--weather-captures=")
	_run.call_deferred()

func _run() -> void:
	var scene = Scene.instantiate()
	root.add_child(scene)
	await process_frame
	scene._set_paused(true)
	_check(scene.weather_runtime != null, "Run the scene test with -- --weather-study.")
	if scene.weather_runtime == null:
		_finish(scene)
		return
	scene._update_scene(0.0)
	_check(scene.weather_presentation.get("_panels").multimesh.instance_count == 289 and scene.weather_presentation.get("_ribbons").multimesh.instance_count == 1156, "The 2x preview subdivides lower panels while retaining 289 full-size crests.")
	_check(scene.weather_runtime.weather.get_status().simulated_cells == 1089, "The simulation includes a larger1089-cell region.")
	_check(not scene.ocean.get("_surface").visible and not scene.ocean.get("_far_surface").visible, "Both legacy continuous ocean meshes are hidden.")
	var crest_point := Vector2.ZERO
	var greatest_relief: float = 0.0
	for x in range(-4, 5):
		for z in range(-4, 5):
			var point := Vector2(x, z) * 0.5
			var sample: Dictionary = scene.water_surface.sample(point)
			if sample.crest_height > greatest_relief:
				greatest_relief = sample.crest_height
				crest_point = point
	_check(greatest_relief > 0.25, "The calm surface contains actual raised crest relief.")
	scene.bucket.position = Vector3(crest_point.x, 0.0, crest_point.y)
	scene._update_scene(0.0)
	_check(absf(scene.bucket.position.y - scene.water_surface.height_at(crest_point)) < 0.00001, "Bucket buoyancy follows the retained invisible gameplay surface.")
	scene.bucket.position = Vector3.ZERO
	scene._update_scene(0.0)
	await _capture(scene, "calm")
	_check(scene.weather_runtime.scheduler.trigger("weather.mix.raincloud.strong"), "The scene admits a triggered mixed front.")
	scene.weather_runtime.advance(20.0, Vector2.ZERO)
	scene.simulation_time = 20.0
	scene._update_scene(0.0)
	var local: Dictionary = scene.weather_runtime.weather.sample(Vector2.ZERO)
	_check(absf(scene.bucket.position.y - scene.water_surface.height_at(Vector2.ZERO)) < 0.00001, "Bucket follows the invisible shared gameplay surface.")
	_check(local.rain > 0.3, "The incoming rain front reaches the player.")
	_check(scene.weather_presentation.get("_rain").multimesh.visible_instance_count > 0, "Local rainfall generates visible nearby rain instances.")
	_check(scene._sun.light_energy < 0.72, "Cloud attenuation affects the actual scene light.")
	await _capture(scene, "rain-strong")
	for angle in [12.0, 52.0]:
		scene.camera.set_pitch(angle, true)
		scene._using_controller = true
		scene._controller_cursor = scene.camera.unproject_position(Vector3(3.0, 0.0, -6.0))
		scene._update_preview()
		_check(scene._candidate.valid, "Water targeting stays reachable at pitch%s." % angle)
		if scene._candidate.valid:
			var point: Vector3 = scene._candidate.point
			_check(absf(point.y - scene._height_at(point)) < 0.01, "Camera ray converges on the simulated two-axis water surface.")
	await _capture(scene, "rain-detail")
	var before: Dictionary = scene.weather_runtime.snapshot()
	await process_frame
	await process_frame
	_check(scene.weather_runtime.snapshot() == before, "Pausing the actual scene freezes scheduler and panel/weather simulation.")
	_finish(scene)

func _capture(scene, name: String) -> void:
	if _captures.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(_captures)
	scene._update_scene(0.0)
	await process_frame
	await RenderingServer.frame_post_draw
	var result: int = root.get_texture().get_image().save_png(_captures.path_join(name + ".png"))
	_check(result == OK, "Rendered capture succeeds: " + name)

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)

func _finish(scene) -> void:
	scene.queue_free()
	if failures.is_empty():
		print("PASS: %d weather scene integration checks." % checks)
		quit(0)
	else:
		printerr("FAIL: %s" % failures)
		quit(1)
