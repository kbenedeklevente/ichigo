extends SceneTree
## Actual rendered stress study; no synthetic FPS estimates from headless timing.
const Scene = preload("res://game/camera_study.tscn")
var output_dir := "res://work/visual-density-benchmark"
var measurements: Array[Dictionary] = []

func _initialize() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("Run this rendered MultiMesh study without --headless.")
		quit(2)
		return
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--density-output="):
			output_dir = argument.trim_prefix("--density-output=")
	_run.call_deferred()

func _run() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	DirAccess.make_dir_recursive_absolute(output_dir)
	var scene = Scene.instantiate()
	root.add_child(scene)
	await process_frame
	scene.set_process(false)
	scene._set_paused(true)
	scene.weather_runtime.scheduler.chance_enabled = false
	for condition: String in ["calm", "storm"]:
		var weather = scene.weather_runtime.weather
		weather.baseline_sky = "sunny" if condition == "calm" else "storm"
		weather.baseline_wind = condition
		weather.configure(104744)
		scene.water_surface.configure(weather)
		for pitch: float in [20.0, 52.0]:
			scene.camera.set_pitch(pitch, true)
			for density: int in [1, 2, 4, 8]:
				scene.density_slider.value = density
				# Same warm-up scene path as live play, excluding chance content.
				for frame: int in range(20):
					_step_scene(scene)
					await process_frame
					await RenderingServer.frame_post_draw
				var frames_ms: Array[float] = []
				var cpu_ms: Array[float] = []
				var presentation_ms: Array[float] = []
				for frame: int in range(60):
					var start := Time.get_ticks_usec()
					_step_scene(scene)
					cpu_ms.append(float(Time.get_ticks_usec() - start) / 1000.0)
					presentation_ms.append(scene.weather_presentation.get_density_status().update_ms)
					await process_frame
					await RenderingServer.frame_post_draw
					frames_ms.append(float(Time.get_ticks_usec() - start) / 1000.0)
				var info: Dictionary = scene.weather_presentation.get_density_status()
				var mean: float = _mean(frames_ms)
				frames_ms.sort()
				var record := {"condition": condition, "pitch": pitch, "density": density,
					"tiles": info.tiles, "drawings": info.drawings, "spacing_m": info.spacing,
					"field_samples": info.field_samples, "field_texture_bytes": scene.water_surface._field_image.get_data().size(),
					"frame_mean_ms": mean, "frame_p95_ms": frames_ms[56], "measured_fps": 1000.0 / mean,
					"scene_cpu_mean_ms": _mean(cpu_ms), "presentation_cpu_mean_ms": _mean(presentation_ms), "layout_ms": info.layout_ms}
				measurements.append(record)
				print("DENSITY_BENCH ", JSON.stringify(record))
				scene.hud.visible = false
				await process_frame
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(output_dir.path_join("%s-%02d-density-%d.png" % [condition, int(pitch), density]))
				scene.hud.visible = true
	var result := {"engine": Engine.get_version_info().string, "gpu": RenderingServer.get_video_adapter_name(),
		"window": str(DisplayServer.window_get_size()), "viewport": str(root.get_texture().get_size()),
		"vsync": "disabled", "measurement_frames": 60, "warmup_frames": 20, "results": measurements}
	var file := FileAccess.open(output_dir.path_join("results.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	scene.queue_free()
	await process_frame
	await RenderingServer.frame_post_draw
	await process_frame
	quit(0)

func _step_scene(scene) -> void:
	# One 1/60-second game frame; the runtime retains its independent 30Hz step.
	scene.simulation_time += 1.0 / 60.0
	scene.weather_runtime.advance(1.0 / 60.0, Vector2.ZERO)
	scene._update_scene(1.0 / 60.0)
	scene._update_hud()

func _mean(values: Array[float]) -> float:
	var sum := 0.0
	for value: float in values:
		sum += value
	return sum / values.size()
