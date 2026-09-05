extends SceneTree
## Actual-scene P1 checks; no rendered appearance or hardware-input claims.

const StudyScene = preload("res://game/camera_study.tscn")
const OceanScript = preload("res://game/world/ocean_surface.gd")
const POSITION_TOLERANCE: float = 0.001
const WATERLINE_TOLERANCE: float = 0.01

var failures: Array[String] = []
var checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1280, 800)
	root.content_scale_size = Vector2i(1280, 800)
	var scene = StudyScene.instantiate()
	root.add_child(scene)
	await physics_frame
	await process_frame
	await process_frame
	_check(scene.get_viewport().get_camera_3d() == scene.camera, "The study's camera must be the viewport's actual active camera.")
	_check(not scene.has_committed_point, "The scene must start without a committed point.")
	_check_waterline(scene, "initial scene")

	# Unproject a known mean-water point, then exercise the actual scene ray solver
	# and commit handler. Wave refinement may legitimately move the resulting hit.
	scene._using_controller = true
	scene._controller_cursor = scene.camera.unproject_position(Vector3(3.0, 0.0, -6.0))
	scene._suppress_commit = false
	var ray_origin: Vector3 = scene.camera.project_ray_origin(scene._controller_cursor)
	var ray_direction: Vector3 = scene.camera.project_ray_normal(scene._controller_cursor)
	scene._unhandled_input(_pressed("commit_target"))
	_check(scene.has_committed_point, "Projected reachable water must commit through the scene input handler; candidate=%s." % scene._candidate)
	if not scene.has_committed_point:
		await _cleanup(scene)
		return
	var initial_point: Vector3 = scene.committed_point
	_check(initial_point.is_finite(), "Scene commit must produce a finite world point.")
	_check((initial_point - ray_origin).cross(ray_direction).length() <= POSITION_TOLERANCE, "The committed wave hit must lie on the active camera's ray.")
	_check(absf(initial_point.y - OceanScript.height_at(initial_point, scene.simulation_time)) <= WATERLINE_TOLERANCE, "The committed hit must lie on the sampled moving water surface.")
	_check(scene.committed.visible, "Committing water must expose the committed marker.")
	await process_frame
	await process_frame
	_check(scene.fishing_line.mesh != null, "The committed point must produce an actual line mesh.")
	if scene.fishing_line.mesh != null:
		_check(scene.fishing_line.mesh.get_surface_count() > 0, "The committed line mesh must contain geometry.")

	for pitch: float in [12.0, 52.0]:
		scene.camera.set_pitch(pitch, true)
		await process_frame
		_check(scene.committed_point.distance_to(initial_point) <= POSITION_TOLERANCE, "Immediate pitch %s must preserve the committed world point." % pitch)
	var before_resize: Vector2 = scene.get_viewport().get_visible_rect().size
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	await process_frame
	await process_frame
	var after_resize: Vector2 = scene.get_viewport().get_visible_rect().size
	_check(after_resize != before_resize, "The integration fixture must actually change viewport dimensions.")
	_check(scene.committed_point.distance_to(initial_point) <= POSITION_TOLERANCE, "Viewport resizing must preserve the committed world point.")
	_check_waterline(scene, "after pitch and resize")

	# Input.action_press supplies held state; direct handler calls exercise the
	# real scene logic without depending on a physical controller or GUI focus.
	Input.action_press("commit_target")
	scene._set_paused(true)
	var frozen_time: float = scene.simulation_time
	var frozen_root: Transform3D = scene.bucket.transform
	var ocean_material: ShaderMaterial = scene.ocean.get("_material")
	_check(ocean_material != null, "The scene must expose its actual ocean shader material.")
	var frozen_shader_time: float = float(ocean_material.get_shader_parameter("simulation_time")) if ocean_material != null else NAN
	_check(absf(frozen_shader_time - frozen_time) <= POSITION_TOLERANCE, "Ocean shader phase must use the simulation time at pause.")
	scene._unhandled_input(_pressed("commit_target"))
	for frame in range(4):
		await process_frame
	_check(is_equal_approx(scene.simulation_time, frozen_time), "Pause must freeze simulation time across actual scene frames.")
	_check(scene.bucket.transform.is_equal_approx(frozen_root), "Pause must freeze the bucket simulation root.")
	if ocean_material != null:
		_check(is_equal_approx(float(ocean_material.get_shader_parameter("simulation_time")), frozen_shader_time), "Pause must freeze the ocean shader's phase parameter.")
	_check(scene.has_committed_point and scene.committed_point.distance_to(initial_point) <= POSITION_TOLERANCE, "Paused commit input must preserve the legitimate existing selection.")
	_check(scene._suppress_commit, "Held commit must remain suppressed throughout pause.")

	# Move the cursor to a distinct reachable spot so an accidental recommit
	# would be observable without discarding the legitimate current point.
	scene._controller_cursor = scene.camera.unproject_position(Vector3(-3.0, 0.0, -5.0))
	scene._set_paused(false)
	scene._unhandled_input(_pressed("commit_target"))
	_check(scene.committed_point.distance_to(initial_point) <= POSITION_TOLERANCE, "Immediate resume input must not recommit the held action.")
	await process_frame
	await process_frame
	scene._unhandled_input(_pressed("commit_target"))
	_check(scene._suppress_commit, "Suppression must remain while commit is still held after resume.")
	_check(scene.committed_point.distance_to(initial_point) <= POSITION_TOLERANCE, "Held action over resumed frames must preserve the committed point.")
	_check(scene.simulation_time > frozen_time, "Resume must restart simulation time.")
	_check_waterline(scene, "resumed scene")
	if ocean_material != null:
		_check(absf(float(ocean_material.get_shader_parameter("simulation_time")) - scene.simulation_time) <= POSITION_TOLERANCE, "Resumed shader phase must still match the simulation clock.")
	Input.action_release("commit_target")
	await process_frame
	await process_frame
	_check(not scene._suppress_commit, "Releasing commit must clear suppression on a following frame.")
	scene._controller_cursor = scene.camera.unproject_position(Vector3(-3.0, 0.0, -5.0))
	scene._unhandled_input(_pressed("commit_target"))
	_check(scene.has_committed_point, "A fresh commit after release must leave a valid committed point.")
	_check(scene.committed_point.distance_to(initial_point) > 1.0, "A fresh commit after release must reach the distinct new water target; candidate=%s." % scene._candidate)
	scene._unhandled_input(_pressed("cancel_target"))
	_check(not scene.has_committed_point, "Cancel must clear the actual scene's committed-point state.")
	_check(not scene.committed.visible, "Cancel must hide the committed marker.")
	await process_frame
	await process_frame
	_check(scene.fishing_line.mesh == null, "The scene must remove line geometry after cancel.")
	await _cleanup(scene)


func _check_waterline(scene: Node3D, label: String) -> void:
	var bucket_node: Node3D = scene.get("bucket")
	var time: float = scene.get("simulation_time")
	_check(absf(bucket_node.position.y - OceanScript.height_at(bucket_node.position, time)) <= WATERLINE_TOLERANCE, "%s: direct-follow bucket waterline must match the shared sample." % label)


func _pressed(action: StringName) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	return event


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)


func _cleanup(scene: Node3D) -> void:
	Input.action_release("commit_target")
	scene.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: %d actual-scene P1 integration checks. Rendered appearance and hardware-input routing remain separate." % checks)
		quit(0)
	else:
		printerr("FAIL: %d of %d actual-scene P1 integration checks failed." % [failures.size(), checks])
		quit(1)
