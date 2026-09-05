extends SceneTree
const Scene = preload("res://game/camera_study.tscn")
var checks := 0
var failures: Array[String] = []
func _initialize() -> void:
	_run.call_deferred()
func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition: failures.append(message)
func _run() -> void:
	var scene = Scene.instantiate()
	root.add_child(scene)
	await process_frame
	scene._set_paused(true)
	scene._update_scene(0.0)
	var art = scene.weather_presentation
	_check(not scene.ocean.get("_surface").visible and not scene.ocean.get("_far_surface").visible, "Both legacy ocean sheets are hidden")
	_check(art.get_script().resource_path.ends_with("woodblock_wings.gd"), "Shared near water renderer is replaced")
	_check(scene.weather_runtime.weather.get_status().simulated_cells == 1089, "Simulation remains 1089 cells")
	_check(scene.water_surface.get_panel_states().size() == 289, "Original 289 near cell states remain available")
	_check(art._wings.size() == 225, "Bounded 45 by 5 broad scenic flats")
	_check(art._mesh.size.x == 38.0, "Each wing spans more than nine cells")
	var node = art._wings[Vector2i.ZERO]
	var position_before: Vector3 = node.position
	var snapshot: Dictionary = scene.weather_runtime.snapshot()
	scene.bucket.position.x = 32.1
	scene._update_scene(0.0)
	_check(art._wings[Vector2i.ZERO] == node and node.position == position_before, "Retained wings keep their world roots when scrolling")
	_check(art._wings.size() == 225, "Recycling keeps node count bounded")
	_check(scene.weather_runtime.snapshot() == snapshot, "Art updates never mutate simulation")
	_check(scene.camera.pitch_degrees == 20.0, "Default camera remains 20 degrees")
	for pitch in [12.0, 20.0, 26.0, 38.0, 52.0]:
		scene.camera.set_pitch(pitch, true)
		_check(is_equal_approx(scene.camera.pitch_degrees, pitch), "Camera accepts capture pitch %s" % pitch)
	scene.bucket.position = Vector3.ZERO
	scene.weather_runtime.director.trigger("weather.mix.raincloud.strong")
	scene.weather_runtime.advance(20.0, Vector2.ZERO)
	scene._update_scene(0.0)
	_check(art._rain.multimesh.visible_instance_count > 0, "Weather still generates rain")
	_check(node.position != position_before, "Weather drives wing bob")
	scene.queue_free()
	if failures.is_empty():
		print("PASS: %s Woodblock Wings checks" % checks)
		quit(0)
	else:
		printerr("FAIL: %s" % failures)
		quit(1)
