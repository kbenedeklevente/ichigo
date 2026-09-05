extends RefCounted
## One live salvage opportunity. Retirement and outcome are independent.

const Modifier = preload("res://game/events/local_field_modifier.gd")
const MAX_AGE: float = 180.0
const GUST_RAMP: float = 20.0
const VISIBILITY_GRACE: float = 3.0
var id: String = ""
var definition_id: String = "salvage"
var source: String = "trigger"
var center: Vector2 = Vector2.ZERO
var bounds_radius: float = 1.5
var phase: String = "arriving"
var outcome: String = "unresolved"
var velocity: Vector2 = Vector2.ZERO
var age: float = 0.0
var departure_age: float = 0.0
var outside_age: float = 0.0
var departure_direction: Vector2 = Vector2.RIGHT
var visible: bool = true
var in_interaction_range: bool = false
var modifier = Modifier.new()

func resolve(result: String) -> bool:
	if outcome != "unresolved" or phase == "retired" or not result in ["completed", "failed", "abandoned"]:
		return false
	outcome = result
	return true

func advance(delta: float, player: Vector2) -> void:
	if phase == "retired":
		return
	age += delta
	if phase == "arriving" and age >= 2.0:
		phase = "present"
	if phase != "departing" and (age + 0.000001 >= MAX_AGE or outcome != "unresolved"):
		phase = "departing"
		departure_direction = (center - player).normalized()
		if departure_direction.is_zero_approx():
			departure_direction = Vector2.RIGHT
	if phase == "departing":
		departure_age += delta
	if not visible and not in_interaction_range:
		outside_age += delta
	else:
		outside_age = 0.0
	_refresh_modifier()
	# Salvage's greater drag response separates it from a following bucket.
	velocity = departure_direction * 0.12
	if phase == "departing":
		velocity = departure_direction * 0.25 + modifier.sample(center).current_delta * 2.0
	center += velocity * delta
	modifier.origin = center
	if outside_age + 0.000001 >= VISIBILITY_GRACE:
		phase = "retired"
		if outcome == "unresolved":
			outcome = "abandoned"
		modifier.weight = 0.0

func _refresh_modifier() -> void:
	modifier.origin = center
	modifier.wind_delta = departure_direction * 7.0
	modifier.current_delta = departure_direction * 3.0
	modifier.amplitude_delta = 0.12
	var arrival: float = smoothstep(0.0, GUST_RAMP, departure_age) if phase == "departing" else 0.0
	# Grace-period fade prevents an abrupt modifier removal at retirement.
	var departure: float = 1.0 - smoothstep(0.0, VISIBILITY_GRACE, outside_age)
	modifier.weight = arrival * departure

func snapshot() -> Dictionary:
	return {"id": id, "definition_id": definition_id, "source": source,
		"center": center, "bounds_radius": bounds_radius, "phase": phase, "outcome": outcome,
		"velocity": velocity, "age": age, "departure_age": departure_age,
		"outside_age": outside_age, "departure_direction": departure_direction,
		"visible": visible, "in_interaction_range": in_interaction_range}

func restore(data: Dictionary) -> bool:
	if not data.has_all(["id", "definition_id", "source", "center", "bounds_radius", "phase", "outcome", "velocity", "age", "departure_age", "outside_age", "departure_direction", "visible", "in_interaction_range"]):
		return false
	if not data.id is String or data.id.is_empty() or data.definition_id != "salvage" or not data.source in ["trigger", "chance"]:
		return false
	if not data.phase in ["arriving", "present", "departing"] or not data.outcome in ["unresolved", "completed", "failed", "abandoned"]:
		return false
	for key: String in ["center", "velocity", "departure_direction"]:
		if not data[key] is Vector2 or not data[key].is_finite():
			return false
	for key: String in ["age", "departure_age", "outside_age", "bounds_radius"]:
		if not (data[key] is float or data[key] is int) or not is_finite(float(data[key])) or float(data[key]) < 0.0:
			return false
	if data.bounds_radius != 1.5 or data.outside_age >= VISIBILITY_GRACE or data.departure_age > data.age or not is_equal_approx(data.departure_direction.length(), 1.0):
		return false
	if (data.phase == "arriving" and data.age >= 2.0) or (data.phase != "departing" and (data.age >= MAX_AGE or data.departure_age != 0.0)):
		return false
	if not data.visible is bool or not data.in_interaction_range is bool:
		return false
	for key: String in data:
		if key in ["id", "definition_id", "source", "center", "bounds_radius", "phase", "outcome", "velocity", "age", "departure_age", "outside_age", "departure_direction", "visible", "in_interaction_range"]:
			set(key, data[key])
	_refresh_modifier()
	return true
