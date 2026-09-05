extends Camera3D
## One fixed-azimuth camera. Degrees here are positive DOWN from horizontal.
## Physics and accepted cast points never derive from visual compensation.

var pitch_degrees: float = 20.0
var preferred_pitch_degrees: float = 20.0
var min_pitch: float = 12.0
var max_pitch: float = 52.0
var focus_position: Vector3 = Vector3(0.0, 0.85, 0.0)
# Slightly smaller on-screen framing, preserving child/bucket proportions.
var follow_distance: float = 10.2
var reduced_motion: bool = false
var _display_pitch: float = 20.0

func _ready() -> void:
	projection = Camera3D.PROJECTION_PERSPECTIVE
	keep_aspect = Camera3D.KEEP_HEIGHT
	fov = 60.0
	near = 0.12
	far = 5000.0
	current = true
	update_camera(0.0)

func set_pitch(value: float, immediate: bool = false) -> void:
	if not is_finite(value):
		return
	pitch_degrees = clampf(value, min_pitch, max_pitch)
	preferred_pitch_degrees = pitch_degrees
	if immediate or reduced_motion:
		_display_pitch = pitch_degrees
	update_camera(0.0)

func update_camera(delta: float) -> void:
	if reduced_motion:
		_display_pitch = pitch_degrees
	elif delta > 0.0:
		_display_pitch = lerpf(_display_pitch, pitch_degrees, 1.0 - exp(-10.0 * delta))
	var theta: float = deg_to_rad(_display_pitch)
	position = focus_position + Vector3(0.0, sin(theta), cos(theta)) * follow_distance
	rotation = Vector3(-theta, 0.0, 0.0)

static func resolve_plane_hit(ray_origin: Vector3, ray_direction: Vector3, anchor: Vector3, reach: float = 12.0) -> Dictionary:
	var invalid := {"valid": false, "point": Vector3.ZERO, "reason": "invalid ray"}
	if not ray_origin.is_finite() or not ray_direction.is_finite() or not anchor.is_finite():
		return invalid
	if not is_finite(reach) or reach < 0.0 or ray_direction.length_squared() < 0.0000001:
		return invalid
	var direction: Vector3 = ray_direction.normalized()
	if -direction.y <= 0.0001:
		invalid.reason = "sky or grazing ray"
		return invalid
	var distance: float = -ray_origin.y / direction.y
	if distance < 0.0 or distance > 200.0:
		invalid.reason = "behind camera or too distant"
		return invalid
	var hit: Vector3 = ray_origin + direction * distance
	var horizontal_distance: float = Vector2(hit.x - anchor.x, hit.z - anchor.z).length()
	if horizontal_distance > reach + 0.000001:
		invalid.reason = "beyond reach"
		return invalid
	return {"valid": true, "point": hit, "reason": "reachable water"}

static func steering_vector(input: Vector2, camera_basis: Basis) -> Vector3:
	if not input.is_finite() or input.length_squared() < 0.000001:
		return Vector3.ZERO
	var right: Vector3 = camera_basis.x
	var forward: Vector3 = -camera_basis.z
	right.y = 0.0
	forward.y = 0.0
	if right.length_squared() < 0.000001 or forward.length_squared() < 0.000001:
		return Vector3.ZERO
	var motion: Vector3 = right.normalized() * input.x + forward.normalized() * -input.y
	return motion.normalized() * minf(input.length(), 1.0)
