extends SceneTree
## Rendered comparison at identical simulation state; optional art-study UI.
const Scene = preload("res://game/camera_study.tscn")
const OUTPUT := "res://documents/experiments/crest-body-study"
var failures: Array[String] = []
var checks := 0
func _initialize() -> void:
	_run.call_deferred()
func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	var scene = Scene.instantiate()
	root.add_child(scene)
	await process_frame
	scene.set_process(false)
	scene._set_paused(true)
	scene.weather_runtime.scheduler.chance_enabled = false
	_check(scene.crest_study_select != null, "Launch with --crest-study to check the selector")
	scene.hud.visible = false
	var names := ["original", "quiet_cut", "ink_wash", "long_current"]
	for condition: String in ["calm", "storm"]:
		scene.weather_runtime.weather.set_baseline_instantly("sunny" if condition == "calm" else "storm", "calm" if condition == "calm" else "storm")
		scene._update_scene(0.0)
		var saved: Dictionary = scene.weather_runtime.snapshot()
		for pitch: float in [20.0, 52.0]:
			scene.camera.set_pitch(pitch, true)
			scene._update_scene(0.0)
			for index: int in range(4):
				_check(scene.weather_presentation.set_crest_study(index), "All three drawings load for " + names[index])
				await process_frame
				await RenderingServer.frame_post_draw
				var result: int = root.get_texture().get_image().save_png(OUTPUT.path_join("%s-%s-%d.png" % [names[index], condition, int(pitch)]))
				_check(result == OK, "Save rendered comparison")
				_check(scene.weather_runtime.snapshot() == saved, "Artwork switching leaves simulation unchanged")
	_check(not scene.weather_presentation.set_crest_study(4), "Invalid art selection is rejected")
	if scene.crest_study_select != null:
		for i in range(4):
			scene.crest_study_select.select(i)
			scene.crest_study_select.item_selected.emit(i)
			var texture: Texture2D = scene.weather_presentation._panel_material.get_shader_parameter("curl_art")
			_check(texture != null, "Study selector binds the renderer")
	# Asset previews are rendered by Godot from the editable vector sources.
	for index: int in range(4):
		var folder := "res://game/presentation/waves/"
		if index > 0: folder += "crest_studies/" + names[index] + "/"
		for shape: String in ["curl", "double", "sweep"]:
			var texture := load(folder + "theatre_" + shape + ".svg") as Texture2D
			_check(texture.get_image().save_png(OUTPUT.path_join(names[index] + "-" + shape + ".png")) == OK, "Save drawing preview")
	scene.queue_free()
	await process_frame
	await RenderingServer.frame_post_draw
	for failure in failures: printerr(failure)
	print("Crest body study: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
