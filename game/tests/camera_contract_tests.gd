extends SceneTree
## Focused P1 contract checks. Run with --headless --path . --script this file.
## This does not replace the fixture's visual or interaction acceptance scenarios.

const CameraScript = preload("res://game/camera/orbit_camera.gd")
const OceanScript = preload("res://game/world/ocean_surface.gd")
const FIXTURE_PATH: String = "res://documents/work_packets/fixtures/camera_scenarios.json"
const EPSILON: float = 0.001

var failures: Array[String] = []
var checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var fixture: Variant = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE_PATH))
	_check(fixture is Dictionary, "The declarative fixture must parse as a dictionary.")
	if not fixture is Dictionary:
		_finish()
		return
	_check(fixture.get("schema_version") == 1, "The runner expects fixture schema version 1.")
	var defaults: Dictionary = fixture.get("defaults", {})
	_check(defaults.has("reach_horizontal_m"), "The fixture must declare horizontal reach.")
	if not defaults.has("reach_horizontal_m"):
		_finish()
		return
	_test_plane_hits(float(defaults["reach_horizontal_m"]))
	_test_steering()
	_test_ocean_samples()
	var camera = CameraScript.new()
	root.add_child(camera)
	await process_frame
	_test_pitch_profiles(camera, defaults)
	camera.queue_free()
	await process_frame
	_finish()


func _test_plane_hits(reach: float) -> void:
	var anchor := Vector3.ZERO
	var origin := Vector3(0.0, 3.0, 0.0)
	_expect_hit("near target", origin, Vector3(0.0, -3.0, -6.0).normalized(), anchor, reach, Vector3(0.0, 0.0, -6.0))
	_expect_hit("inclusive reach boundary", Vector3(0.0, 3.0, -reach), Vector3.DOWN, anchor, reach, Vector3(0.0, 0.0, -reach))
	_expect_rejection("beyond reach", Vector3(0.0, 3.0, -reach - 0.1), Vector3.DOWN, anchor, reach)
	_expect_hit("translated interaction anchor", Vector3(4.0, 3.0, 1.0), Vector3.DOWN, Vector3(4.0, 0.0, 7.0), reach, Vector3(4.0, 0.0, 1.0))
	_expect_rejection("skyward ray", origin, Vector3.UP, anchor, reach)
	_expect_rejection("parallel ray", origin, Vector3.FORWARD, anchor, reach)
	_expect_rejection("near-parallel ray", origin, Vector3(0.0, -0.00001, -1.0).normalized(), anchor, reach)
	_expect_rejection("zero-length ray", origin, Vector3.ZERO, anchor, reach)
	_expect_rejection("intersection behind camera", Vector3(0.0, -3.0, 0.0), Vector3.DOWN, anchor, reach)
	_expect_rejection("ray exceeds travel cap despite local hit", Vector3(0.0, 201.0, 0.0), Vector3.DOWN, anchor, reach)
	_expect_hit("inclusive ray travel cap", Vector3(0.0, 200.0, 0.0), Vector3.DOWN, anchor, reach, Vector3.ZERO)
	_expect_rejection("nonfinite ray origin", Vector3(NAN, 3.0, 0.0), Vector3.DOWN, anchor, reach)
	_expect_rejection("nonfinite ray direction", origin, Vector3(0.0, -INF, 0.0), anchor, reach)


func _expect_hit(label: String, origin: Vector3, direction: Vector3, anchor: Vector3, reach: float, expected: Vector3) -> void:
	var result: Dictionary = CameraScript.resolve_plane_hit(origin, direction, anchor, reach)
	if not _check_result_shape(result, label):
		return
	_check(result["valid"] == true, "%s should be accepted: %s" % [label, result["reason"]])
	var point: Vector3 = result["point"]
	_check(point.is_finite(), "%s must produce a finite point." % label)
	_check(point.distance_to(expected) <= EPSILON, "%s returned %s, expected %s." % [label, point, expected])


func _expect_rejection(label: String, origin: Vector3, direction: Vector3, anchor: Vector3, reach: float) -> void:
	var result: Dictionary = CameraScript.resolve_plane_hit(origin, direction, anchor, reach)
	if not _check_result_shape(result, label):
		return
	_check(result["valid"] == false, "%s must be rejected." % label)
	_check(not String(result["reason"]).is_empty(), "%s must explain rejection." % label)


func _check_result_shape(result: Dictionary, label: String) -> bool:
	var correct: bool = result.has("valid") and result.has("point") and result.has("reason")
	if correct:
		correct = result["valid"] is bool and result["point"] is Vector3 and result["reason"] is String
	_check(correct, "%s must return {valid: bool, point: Vector3, reason: String}." % label)
	return correct


func _test_steering() -> void:
	var inputs: Array[Vector2] = [Vector2.RIGHT, Vector2.UP, Vector2(1.0, -1.0)]
	for pitch: float in [12.0, 20.0, 52.0]:
		var basis := Basis(Vector3.RIGHT, deg_to_rad(-pitch))
		var idle: Vector3 = CameraScript.steering_vector(Vector2.ZERO, basis)
		_check(idle.is_equal_approx(Vector3.ZERO), "Zero input must produce no steering at pitch %s." % pitch)
		for input_value: Vector2 in inputs:
			var direction: Vector3 = CameraScript.steering_vector(input_value, basis)
			_check(direction.is_finite(), "Steering must remain finite at pitch %s." % pitch)
			_check(absf(direction.y) <= EPSILON, "Steering must stay horizontal at pitch %s." % pitch)
			_check(absf(direction.length() - 1.0) <= EPSILON, "Cardinal and diagonal steering must have unit magnitude at pitch %s." % pitch)
		var forward: Vector3 = CameraScript.steering_vector(Vector2.UP, basis)
		var right: Vector3 = CameraScript.steering_vector(Vector2.RIGHT, basis)
		_check(forward.distance_to(Vector3.FORWARD) <= EPSILON, "Up input must remain world -Z at the fixed azimuth.")
		_check(right.distance_to(Vector3.RIGHT) <= EPSILON, "Right input must remain world +X at the fixed azimuth.")
	var rotated := Basis(Vector3.UP, PI / 2.0) * Basis(Vector3.RIGHT, deg_to_rad(-52.0))
	var rotated_forward: Vector3 = CameraScript.steering_vector(Vector2.UP, rotated)
	_check(rotated_forward.distance_to(Vector3.LEFT) <= EPSILON, "Steering must use the supplied camera basis, not a hardcoded world heading.")


func _test_pitch_profiles(camera: Camera3D, defaults: Dictionary) -> void:
	_check(is_equal_approx(camera.get("pitch_degrees"), float(defaults["preferred_pitch_deg"])), "Camera starts at the fixture's preferred pitch.")
	_check(is_equal_approx(camera.get("preferred_pitch_degrees"), 20.0), "Initial preferred pitch is 20 degrees.")
	camera.call("set_pitch", -10.0, true)
	_check(is_equal_approx(camera.get("pitch_degrees"), 12.0), "Wide profile clamps below its lower limit.")
	camera.call("set_pitch", 90.0, true)
	_check(is_equal_approx(camera.get("pitch_degrees"), 52.0), "Wide profile clamps above its upper limit.")
	camera.call("set_pitch", 38.0, true)
	_check(is_equal_approx(camera.get("pitch_degrees"), 38.0), "A supported immediate pitch request is applied.")
	camera.call("set_pitch", 52.0, true)
	_check(is_equal_approx(camera.get("pitch_degrees"), 52.0), "The selected range permits its upper endpoint.")


func _test_ocean_samples() -> void:
	_check(absf(OceanScript.height_at(Vector3.ZERO, 0.0)) <= EPSILON, "Ocean begins at its documented zero phase.")
	_check(absf(OceanScript.height_at(Vector3.ZERO, 1.0) + 0.15) <= EPSILON, "At x=0, t=1 the fixture trough is -0.15 meters.")
	_check(absf(OceanScript.height_at(Vector3(2.0, 0.0, 0.0), 1.0)) <= EPSILON, "At x=2, t=1 the fixture crosses mean height.")
	_check(absf(OceanScript.height_at(Vector3(2.0, 0.0, 0.0), 0.0) - 0.15) <= EPSILON, "At x=2, t=0 the fixture crest is +0.15 meters.")
	for point: Vector3 in [Vector3.ZERO, Vector3(1.0, 4.0, 3.0), Vector3(-2.0, 0.0, -5.0)]:
		var time: float = 0.7
		var height: float = OceanScript.height_at(point, time)
		_check(absf(height - OceanScript.height_at(point, time + 4.0)) <= EPSILON, "Ocean height repeats after the fixture's four-second period.")
		_check(absf(height - OceanScript.height_at(point + Vector3(8.0, 0.0, 0.0), time)) <= EPSILON, "Ocean height repeats after the fixture's eight-meter wavelength.")
		_check(absf(height - OceanScript.height_at(point + Vector3(0.0, 9.0, 7.0), time)) <= EPSILON, "This fixture's height depends on X and simulation time, not query Y or Z.")
		var normal: Vector3 = OceanScript.normal_at(point, time)
		_check(normal.is_finite() and normal.y > 0.0, "Ocean normals must be finite and upward.")
		_check(absf(normal.length() - 1.0) <= EPSILON, "Ocean normals must have unit length.")
		var sample_step: float = 0.01
		var slope: float = (OceanScript.height_at(point + Vector3.RIGHT * sample_step, time) - OceanScript.height_at(point - Vector3.RIGHT * sample_step, time)) / (2.0 * sample_step)
		var tangent := Vector3(1.0, slope, 0.0).normalized()
		_check(absf(normal.dot(tangent)) <= EPSILON, "Ocean normal must be perpendicular to the measured height surface.")
		_check(absf(normal.z) <= EPSILON, "Single-wave fixture has no cross-wave normal component.")
		_check(OceanScript.flow_at(point, time).is_equal_approx(Vector3.ZERO), "This fixture has no advective flow.")
	_check(OceanScript.normal_at(Vector3.ZERO, 1.0).distance_to(Vector3.UP) <= EPSILON, "The wave trough has an upward vertical normal.")


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)


func _finish() -> void:
	if failures.is_empty():
		print("PASS: %d P1 camera/ocean contract checks. Visual and scene interaction acceptance remains separate." % checks)
		quit(0)
	else:
		printerr("FAIL: %d of %d P1 camera/ocean contract checks failed." % [failures.size(), checks])
		quit(1)
