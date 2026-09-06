extends SceneTree
const Scene = preload("res://game/camera_study.tscn")
const Breakers = preload("res://game/world/storm_breakers.gd")
const OUTPUT := "res://documents/experiments/extended-storm-sprite"
var failures: Array[String] = []
var checks := 0
func _initialize() -> void:
	_run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	var scene = Scene.instantiate()
	root.add_child(scene)
	await process_frame
	scene.set_process(false)
	scene._set_paused(true)
	scene.hud.visible = false
	scene.weather_runtime.scheduler.chance_enabled = false
	check(scene.weather_presentation.visual_density == 4, "Default sea panels are twice as fine per side")
	check(scene.density_slider.max_value == 16, "Slider exposes the extended fine-detail limit")
	var storm: Texture2D = scene.weather_presentation._panel_material.get_shader_parameter("storm_curl_art")
	check(storm != null and storm.resource_path.ends_with("storm_sprite_a_extended.png"), "Selected storm sprite with extended base loads")
	scene.weather_runtime.weather.set_baseline_instantly("sunny", "calm")
	scene._update_scene(0.0)
	await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(OUTPUT.path_join("quiet-calm-default.png")) == OK, "Small crests retain Quiet Cut")
	scene.weather_runtime.weather.set_baseline_instantly("tempest", "tempest")
	var breaker = scene.weather_runtime.breakers
	# Fixed art fixture: a real logical crest in front of the bucket.
	breaker.active.assign([{"cell":Vector2i(0,-2), "anchor":Vector2(0,-8), "direction":Vector2.RIGHT, "started":0.0, "cell_size":4.0}])
	var ages := {"normal":0.0, "peak":Breakers.RISE, "crash":Breakers.RISE + Breakers.CRASH * 0.65, "foam":Breakers.RISE + Breakers.CRASH + 0.85}
	for pitch: float in [12.0, 20.0, 52.0]:
		scene.camera.set_pitch(pitch, true)
		for density: int in [1, 4, 16]:
			scene.weather_presentation.set_visual_density(density)
			for phase: String in ages:
				breaker._clock = ages[phase]
				scene._update_scene(0.0)
				var before: Dictionary = breaker.snapshot()
				await process_frame
				await RenderingServer.frame_post_draw
				check(breaker.snapshot() == before, "Rendering cannot change breaker state")
				check(scene.weather_presentation._panels.multimesh.instance_count == 289, "Density preserves crest anchors")
				if density == 4 or phase == "foam":
					check(root.get_texture().get_image().save_png(OUTPUT.path_join("%s-%d-density%d.png" % [phase, int(pitch), density])) == OK, "Capture effect study")
				check(scene.weather_presentation._panel_material.get_shader_parameter("breaker_count") == 1, "Lifecycle reaches GPU")
				check(scene.water_surface._field_image.get_width() == 33, "No finer physics grid")
	# Matched steady frame-time sample, not a moving-game performance guarantee.
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	for density: int in [4, 16]:
		scene.weather_presentation.set_visual_density(density)
		for enabled: bool in [false, true]:
			var values: Array[float] = []
			for frame in range(50):
				var start := Time.get_ticks_usec()
				scene._update_scene(0.0)
				if not enabled: scene.weather_presentation._panel_material.set_shader_parameter("breaker_count", 0)
				await process_frame
				await RenderingServer.frame_post_draw
				if frame >= 10: values.append(float(Time.get_ticks_usec() - start) / 1000.0)
			values.sort()
			print("Breaker paused frame sample: density=%d effect=%s median=%.2fms p95=%.2fms" % [density, enabled, values[20], values[38]])
	for failure in failures: printerr(failure)
	print("Storm visual study: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
