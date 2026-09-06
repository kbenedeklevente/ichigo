extends SceneTree
const Scene = preload("res://game/camera_study.tscn")
var checks := 0
var failures: Array[String] = []
func _initialize() -> void:
	_run.call_deferred()
func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
func _key(scene, key: Key) -> void:
	var event := InputEventKey.new()
	event.pressed = true
	event.physical_keycode = key
	scene._unhandled_input(event)
func _run() -> void:
	var scene = Scene.instantiate()
	root.add_child(scene)
	await process_frame
	scene.set_process(false)
	scene._set_paused(true)
	scene.weather_runtime.scheduler.chance_enabled = false
	_check(scene.weather_mode_select.selected == 0, "Lab override defaults off")
	var before: Dictionary = scene.weather_runtime.snapshot()
	_key(scene, KEY_4)
	_check(scene.weather_runtime.snapshot() == before, "Normal controls respect pause")
	scene.weather_mode_select.select(2)
	scene.weather_mode_select.item_selected.emit(2)
	_check(scene.weather_runtime.weather_change_mode == 2, "Toggle connects to runtime setting")
	_key(scene, KEY_4)
	_key(scene, KEY_8)
	_check(scene.weather_runtime.weather.get_status().simulation_time == before.weather.clock, "Paused keys do not advance physics")
	_check(is_equal_approx(scene.water_surface._field_image.get_pixel(16,16).b, 9.0), "GPU wind texture refreshes on paused snap")
	_check(is_equal_approx(scene.water_surface._field_image.get_pixel(16,16).a, 3.0), "GPU sky texture refreshes on paused snap")
	_check(scene.weather_presentation._rain.multimesh.visible_instance_count > 0, "Rain responds without a physics tick")
	_check(is_equal_approx(scene._sky_material.get_shader_parameter("cloud_cover"), 1.0), "Sky shader receives immediate storm")
	DirAccess.make_dir_recursive_absolute("res://work/instant-weather")
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://work/instant-weather/storm-paused.png")
	_key(scene, KEY_1)
	_key(scene, KEY_5)
	_check(is_equal_approx(scene.water_surface._field_image.get_pixel(16,16).b, 0.12), "Calm wind replaces storm texture immediately")
	_check(scene.weather_presentation._rain.multimesh.visible_instance_count == 0, "Rain disappears immediately")
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://work/instant-weather/calm-paused.png")
	_key(scene, KEY_9)
	_key(scene, KEY_0)
	_check(scene.weather_runtime.weather.get_status().sky == "tempest" and scene.weather_runtime.weather.get_status().wind == "tempest", "9/0 reach fifth sky and wind tiers while paused")
	_check(is_equal_approx(scene.water_surface._field_image.get_pixel(16,16).a, 4.0), "GPU receives independent maximum sky severity")
	_check(is_equal_approx(scene.water_surface._field_image.get_pixel(16,16).b, 12.0), "GPU receives fifth wind strength")
	_check(scene.weather_presentation._panel_material.get_shader_parameter("crest_height_range") == Vector2(0.35, 2.0), "Crest height stays bounded to calm floor and two-times maximum")
	scene.hud.visible = false
	for pitch: float in [12.0, 52.0]:
		scene.camera.set_pitch(pitch, true)
		scene._update_scene(0.0)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://work/instant-weather/tempest-%d.png" % int(pitch))
	scene.weather_mode_select.select(1)
	scene.weather_mode_select.item_selected.emit(1)
	_check(scene.weather_runtime.weather_change_mode == 1, "Selector connects queued skip mode")
	scene.weather_mode_select.select(0)
	scene.weather_mode_select.item_selected.emit(0)
	_check(scene.weather_runtime.weather_change_mode == 0, "Toggle restores normal mode")
	scene.queue_free()
	await process_frame
	await RenderingServer.frame_post_draw
	for failure in failures: printerr(failure)
	print("Instant weather scene: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
