extends RefCounted
## Buffered square weather field. X/Y here map to world X/Z.
## Dynamics are stylized, connected paper springs, not an ocean forecasting model.

const SKY_PROFILES := {
	"sunny": {"cloud_cover": 0.12, "rain": 0.0, "light": 1.0},
	"cloudy": {"cloud_cover": 0.65, "rain": 0.0, "light": 0.73},
	"raincloud": {"cloud_cover": 0.88, "rain": 0.58, "light": 0.49},
	"storm": {"cloud_cover": 1.0, "rain": 1.0, "light": 0.26},
}
const WIND_PROFILES := {
	"calm": {"strength": 0.12, "wave_amplitude": 0.12, "wave_speed": 0.65},
	"breeze": {"strength": 1.8, "wave_amplitude": 0.24, "wave_speed": 1.0},
	"strong": {"strength": 5.0, "wave_amplitude": 0.48, "wave_speed": 1.7},
	"storm": {"strength": 9.0, "wave_amplitude": 0.78, "wave_speed": 2.5},
}
const FIXED_STEP := 1.0 / 30.0
const WAVE_LENGTH := 24.0
const SPRING_STIFFNESS := 12.0
const SPRING_DAMPING := 6.0
const NEIGHBOR_STIFFNESS := 1.2
const FIELD_NAMES := ["height", "velocity", "amplitude", "wind_strength", "wind_x", "wind_z", "cloud_cover", "rain", "light"]

var cell_size: float = 4.0
var render_radius: int = 8
var simulation_radius: int = 16
var baseline_sky: String = "sunny"
var baseline_wind: String = "calm"
## Zero holds daylight for visual review; nonzero is a full day in seconds.
var day_period_s: float = 0.0
var day_phase: float = 0.25

var _rng := RandomNumberGenerator.new()
var _seed: int = 15
var _origin := Vector2i.ZERO
var _side: int = 33
var _fields: Dictionary = {}
var _player := Vector2.ZERO
var _clock: float = 0.0
var _remainder: float = 0.0
var _phase: float = 0.0
var _wave_speed: float = 0.65
var _active: bool = false
var _complete: bool = false
var _elapsed: float = 0.0
var _approach_s: float = 12.0
var _hold_s: float = 18.0
var _clearing_s: float = 12.0
var _sky: String = "sunny"
var _wind: String = "calm"
var _direction := Vector2.RIGHT
var _center := Vector2.ZERO
var _transition_held: bool = false
var _event_modifiers: Array = []

func set_transition_hold(enabled: bool) -> void:
	_transition_held = enabled

func set_event_modifiers(modifiers: Array) -> void:
	# Ephemeral sources are owned/saved by encounters, never baked into base fields.
	_event_modifiers = modifiers.duplicate()

func _modifier_at(point: Vector2) -> Dictionary:
	var wind := Vector2.ZERO
	var current := Vector2.ZERO
	var amplitude := 0.0
	for modifier in _event_modifiers:
		var value: Dictionary = modifier.sample(point)
		wind += value.get("wind_delta", Vector2.ZERO)
		current += value.get("current_delta", Vector2.ZERO)
		amplitude += float(value.get("amplitude_delta", 0.0))
	return {"wind": wind.limit_length(12.0), "current": current.limit_length(3.0), "amplitude": clampf(amplitude, -0.5, 0.5)}

func configure(seed_value: int = 15) -> void:
	cell_size = maxf(cell_size, 0.25)
	render_radius = maxi(render_radius, 1)
	simulation_radius = maxi(simulation_radius, render_radius + 2)
	if not SKY_PROFILES.has(baseline_sky):
		baseline_sky = "sunny"
	if not WIND_PROFILES.has(baseline_wind):
		baseline_wind = "calm"
	_seed = seed_value
	_rng.seed = seed_value
	_side = simulation_radius * 2 + 1
	_origin = Vector2i(-simulation_radius, -simulation_radius)
	_player = Vector2.ZERO
	_clock = 0.0
	_remainder = 0.0
	_phase = 0.0
	_wave_speed = float(WIND_PROFILES[baseline_wind].wave_speed)
	_active = false
	_complete = false
	_elapsed = 0.0
	_sky = baseline_sky
	_wind = baseline_wind
	_direction = Vector2.RIGHT
	_center = Vector2.ZERO
	_transition_held = false
	_event_modifiers.clear()
	_fields.clear()
	for field_name in FIELD_NAMES:
		var values := PackedFloat64Array()
		values.resize(_side * _side)
		_fields[field_name] = values
	for y in _side:
		for x in _side:
			_initialize_cell(y * _side + x, _origin + Vector2i(x, y))

func start_event(payload: Dictionary) -> bool:
	if _fields.is_empty():
		configure(_seed)
	if _active or _transition_held:
		return false
	var sky_name := str(payload.get("sky", baseline_sky))
	var wind_name := str(payload.get("wind", baseline_wind))
	if not SKY_PROFILES.has(sky_name) or not WIND_PROFILES.has(wind_name):
		return false
	for key in ["approach_s", "hold_s", "clearing_s"]:
		if payload.has(key) and (not (payload[key] is float or payload[key] is int) or not is_finite(float(payload[key])) or float(payload[key]) <= 0.0):
			return false
	_approach_s = float(payload.get("approach_s", 12.0))
	_hold_s = float(payload.get("hold_s", 18.0))
	_clearing_s = float(payload.get("clearing_s", 12.0))
	_sky = sky_name
	_wind = wind_name
	_direction = Vector2.from_angle(_rng.randf_range(0.0, TAU))
	_elapsed = 0.0
	_active = true
	_complete = false
	_update_center()
	return true

func advance(delta: float, player_position: Vector2) -> void:
	if not is_finite(delta) or delta <= 0.0 or not player_position.is_finite():
		return
	if _fields.is_empty():
		configure(_seed)
	_player = player_position
	_scroll_grid()
	_remainder += delta
	while _remainder + 0.000000001 >= FIXED_STEP:
		_remainder = maxf(0.0, _remainder - FIXED_STEP)
		_step(FIXED_STEP)
	_update_center()

func sample(point: Vector2) -> Dictionary:
	if _fields.is_empty():
		configure(_seed)
	if not point.is_finite():
		point = _player
	var grid := point / cell_size - Vector2(_origin)
	grid.x = clampf(grid.x, 0.0, float(_side - 1))
	grid.y = clampf(grid.y, 0.0, float(_side - 1))
	var ix := mini(int(floor(grid.x)), _side - 2)
	var iy := mini(int(floor(grid.y)), _side - 2)
	var fraction := grid - Vector2(ix, iy)
	var a := iy * _side + ix
	var b := a + 1
	var c := a + _side
	var d := c + 1
	var result: Dictionary = {}
	for field_name in FIELD_NAMES:
		var field: PackedFloat64Array = _fields[field_name]
		result[field_name] = lerpf(lerpf(field[a], field[b], fraction.x), lerpf(field[c], field[d], fraction.x), fraction.y)
	var heights: PackedFloat64Array = _fields.height
	var dx := lerpf(heights[b] - heights[a], heights[d] - heights[c], fraction.y) / cell_size
	var dz := lerpf(heights[c] - heights[a], heights[d] - heights[b], fraction.x) / cell_size
	result["normal"] = Vector3(-dx, 1.0, -dz).normalized()
	result["wind"] = Vector2(float(result.wind_x), float(result.wind_z))
	result["wave_amplitude"] = result.amplitude
	result["wave_speed"] = _wave_speed
	result["light"] = float(result.light) * _daylight()
	result["current"] = Vector2.ZERO
	if not _event_modifiers.is_empty():
		var modifier := _modifier_at(point)
		result["wind"] += modifier.wind
		result["current"] = modifier.current
		result["wave_amplitude"] = maxf(0.0, float(result.wave_amplitude) + modifier.amplitude)
	return result

func get_status() -> Dictionary:
	return {"active": _active, "event_complete": _complete, "stage": _stage(), "transition_held": _transition_held, "incoming_direction": _direction, "center": _center,
		"sky": _sky if _active else baseline_sky, "wind": _wind if _active else baseline_wind, "elapsed": _elapsed,
		"progress": _stage_progress(), "simulation_time": _clock, "phase": _phase, "wave_speed": _wave_speed, "cell_size": cell_size,
		"render_radius": render_radius, "simulation_radius": simulation_radius, "origin": _origin,
		"simulated_cells": _side * _side, "rendered_cells": (2 * render_radius + 1) ** 2}

func get_panel_states() -> Array[Dictionary]:
	if _fields.is_empty():
		configure(_seed)
	var result: Array[Dictionary] = []
	var anchor := _player_cell()
	for y in range(-render_radius, render_radius + 1):
		for x in range(-render_radius, render_radius + 1):
			var cell := anchor + Vector2i(x, y)
			var point := Vector2(cell) * cell_size
			var value := sample(point)
			var normal: Vector3 = value.normal
			result.append({"cell_id": cell, "position": point, "height": value.height, "tilt": Vector2(atan2(normal.z, normal.y), -atan2(normal.x, normal.y)),
				"normal": normal, "size": cell_size, "rain": value.rain, "cloud_cover": value.cloud_cover, "light": value.light})
	return result

func snapshot() -> Dictionary:
	return {"version": 1, "seed": str(_seed), "rng_state": str(_rng.state), "cell_size": cell_size, "render_radius": render_radius,
		"simulation_radius": simulation_radius, "baseline_sky": baseline_sky, "baseline_wind": baseline_wind,
		"day_period_s": day_period_s, "day_phase": day_phase, "origin": _origin, "player": _player,
		"clock": _clock, "remainder": _remainder, "phase": _phase, "wave_speed": _wave_speed,
		"active": _active, "complete": _complete, "transition_held": _transition_held, "elapsed": _elapsed, "approach_s": _approach_s,
		"hold_s": _hold_s, "clearing_s": _clearing_s, "sky": _sky, "wind": _wind,
		"direction": _direction, "center": _center, "fields": _fields.duplicate(true)}

## Native Godot Variant snapshot (store_var/get_var); invalid snapshots do not mutate state.
func restore(data: Dictionary) -> bool:
	var required := ["seed", "rng_state", "cell_size", "render_radius", "simulation_radius", "baseline_sky", "baseline_wind", "day_period_s", "day_phase", "origin", "player", "clock", "remainder", "phase", "wave_speed", "active", "complete", "elapsed", "approach_s", "hold_s", "clearing_s", "sky", "wind", "direction", "center", "fields"]
	if data.get("version", 0) != 1:
		return false
	for key in required:
		if not data.has(key):
			return false
	if not SKY_PROFILES.has(data.sky) or not SKY_PROFILES.has(data.baseline_sky) or not WIND_PROFILES.has(data.wind) or not WIND_PROFILES.has(data.baseline_wind):
		return false
	if not data.origin is Vector2i or not data.player is Vector2 or not data.direction is Vector2 or not data.center is Vector2 or not data.fields is Dictionary:
		return false
	if not data.player.is_finite() or not data.direction.is_finite() or not data.center.is_finite():
		return false
	for key in ["cell_size", "day_period_s", "day_phase", "clock", "remainder", "phase", "wave_speed", "elapsed", "approach_s", "hold_s", "clearing_s"]:
		if not (data[key] is int or data[key] is float) or not is_finite(float(data[key])):
			return false
	if not data.render_radius is int or not data.simulation_radius is int or data.cell_size < 0.25 or data.render_radius < 1 or data.simulation_radius < data.render_radius + 2 or data.simulation_radius > 256:
		return false
	if data.approach_s <= 0.0 or data.hold_s <= 0.0 or data.clearing_s <= 0.0 or data.clock < 0.0 or data.remainder < 0.0 or data.remainder >= FIXED_STEP + 0.000001:
		return false
	var side: int = data.simulation_radius * 2 + 1
	for name in FIELD_NAMES:
		if not data.fields.has(name) or not data.fields[name] is PackedFloat64Array or data.fields[name].size() != side * side:
			return false
		for value in data.fields[name]:
			if not is_finite(value):
				return false
	if not str(data.seed).is_valid_int() or not str(data.rng_state).is_valid_int():
		return false
	cell_size = data.cell_size
	render_radius = data.render_radius
	simulation_radius = data.simulation_radius
	baseline_sky = data.baseline_sky
	baseline_wind = data.baseline_wind
	day_period_s = data.day_period_s
	day_phase = data.day_phase
	_seed = int(data.seed)
	_rng.seed = _seed
	_rng.state = int(data.rng_state)
	_origin = data.origin
	_side = side
	_player = data.player
	_clock = data.clock
	_remainder = data.remainder
	_phase = data.phase
	_wave_speed = data.wave_speed
	_active = data.active
	_complete = data.complete
	_elapsed = data.elapsed
	_approach_s = data.approach_s
	_hold_s = data.hold_s
	_clearing_s = data.clearing_s
	_sky = data.sky
	_wind = data.wind
	_direction = data.direction
	_center = data.center
	_fields = data.fields.duplicate(true)
	_transition_held = bool(data.get("transition_held", false))
	_event_modifiers.clear()
	return true

func _step(dt: float) -> void:
	_clock += dt
	if _active and not _transition_held:
		_elapsed += dt
		if _elapsed >= _approach_s + _hold_s + _clearing_s:
			_active = false
			_complete = true
	_update_center()
	var local_strength := _influence(_player)
	var speed_target := lerpf(float(WIND_PROFILES[baseline_wind].wave_speed), float(WIND_PROFILES[_wind].wave_speed), local_strength)
	_wave_speed = lerpf(_wave_speed, speed_target, 1.0 - exp(-dt / 2.0))
	_phase += TAU / WAVE_LENGTH * _wave_speed * dt
	var wind_mix := 1.0 - exp(-dt / 2.0)
	var amplitude_mix := 1.0 - exp(-dt / 10.0)
	var sky_mix := 1.0 - exp(-dt / 3.0)
	var targets := PackedFloat64Array()
	targets.resize(_side * _side)
	for y in _side:
		for x in _side:
			var index := y * _side + x
			var point := Vector2(_origin + Vector2i(x, y)) * cell_size
			var influence := _influence(point)
			for name in ["cloud_cover", "rain", "light"]:
				var target := lerpf(float(SKY_PROFILES[baseline_sky][name]), float(SKY_PROFILES[_sky][name]), influence)
				_fields[name][index] = lerpf(_fields[name][index], target, sky_mix)
			var wind_target := lerpf(float(WIND_PROFILES[baseline_wind].strength), float(WIND_PROFILES[_wind].strength), influence)
			_fields.wind_strength[index] = lerpf(_fields.wind_strength[index], wind_target, wind_mix)
			var target_vector := _wind_target(influence)
			_fields.wind_x[index] = lerpf(_fields.wind_x[index], target_vector.x, wind_mix)
			_fields.wind_z[index] = lerpf(_fields.wind_z[index], target_vector.y, wind_mix)
			var amplitude_target := lerpf(float(WIND_PROFILES[baseline_wind].wave_amplitude), float(WIND_PROFILES[_wind].wave_amplitude), influence)
			_fields.amplitude[index] = lerpf(_fields.amplitude[index], amplitude_target, amplitude_mix)
			var effective_amplitude: float = _fields.amplitude[index]
			if not _event_modifiers.is_empty():
				effective_amplitude = maxf(0.0, effective_amplitude + _modifier_at(point).amplitude)
			targets[index] = _wave(point, effective_amplitude)
	# Read only last-step heights; commit together so neighbor order cannot bias motion.
	var next_height: PackedFloat64Array = _fields.height.duplicate()
	var next_velocity: PackedFloat64Array = _fields.velocity.duplicate()
	for y in _side:
		for x in _side:
			var index := y * _side + x
			var displacement: float = _fields.height[index] - targets[index]
			var neighbor_displacement := 0.0
			var count := 0
			for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var nx: int = x + offset.x
				var ny: int = y + offset.y
				if nx >= 0 and nx < _side and ny >= 0 and ny < _side:
					var neighbor: int = ny * _side + nx
					neighbor_displacement += _fields.height[neighbor] - targets[neighbor]
					count += 1
			var acceleration: float = -SPRING_STIFFNESS * displacement - SPRING_DAMPING * _fields.velocity[index] + NEIGHBOR_STIFFNESS * (neighbor_displacement / float(count) - displacement)
			next_velocity[index] += acceleration * dt
			next_height[index] += next_velocity[index] * dt
	_fields.height = next_height
	_fields.velocity = next_velocity

func _wind_target(influence: float) -> Vector2:
	var baseline := Vector2.RIGHT * float(WIND_PROFILES[baseline_wind].strength)
	return baseline.lerp(_direction * float(WIND_PROFILES[_wind].strength), influence)

func _wave(point: Vector2, amplitude: float) -> float:
	# Fixed world basis avoids an instantaneous wave rotation when a new front arrives.
	return amplitude * (0.78 * sin(TAU * (point.x + point.y * 0.28) / WAVE_LENGTH - _phase) + 0.22 * sin(TAU * (point.y - point.x * 0.17) / (WAVE_LENGTH * 0.71) - _phase * 1.19))

func _influence(point: Vector2) -> float:
	if not _active:
		return 0.0
	var radius := float(simulation_radius) * cell_size * 0.9
	var normalized_distance := point.distance_to(_center) / radius
	var spatial := 1.0 - smoothstep(0.0, 1.0, normalized_distance)
	var envelope := 1.0
	if _elapsed < _approach_s:
		envelope = smoothstep(0.0, 1.0, _elapsed / _approach_s)
	elif _elapsed > _approach_s + _hold_s:
		envelope = 1.0 - smoothstep(0.0, 1.0, (_elapsed - _approach_s - _hold_s) / _clearing_s)
	return spatial * envelope

func _update_center() -> void:
	var progress := clampf(_elapsed / _approach_s, 0.0, 1.0) if _active else 1.0
	var distance := float(simulation_radius) * cell_size * 1.7
	_center = _player + _direction * distance * (1.0 - smoothstep(0.0, 1.0, progress))

func _stage() -> String:
	if not _active:
		return "idle"
	if _elapsed + 0.0000001 < _approach_s:
		return "approach"
	if _elapsed + 0.0000001 < _approach_s + _hold_s:
		return "hold"
	return "clear"

func _stage_progress() -> float:
	match _stage():
		"approach": return clampf(_elapsed / _approach_s, 0.0, 1.0)
		"hold": return clampf((_elapsed - _approach_s) / _hold_s, 0.0, 1.0)
		"clear": return clampf((_elapsed - _approach_s - _hold_s) / _clearing_s, 0.0, 1.0)
	return 1.0 if _complete else 0.0

func _daylight() -> float:
	var phase := day_phase + (_clock / day_period_s if day_period_s > 0.0 else 0.0)
	return lerpf(0.18, 1.0, smoothstep(-0.12, 0.25, sin(phase * TAU)))

func _player_cell() -> Vector2i:
	return Vector2i(floori(_player.x / cell_size), floori(_player.y / cell_size))

func _scroll_grid() -> void:
	var new_origin := _player_cell() - Vector2i(simulation_radius, simulation_radius)
	if new_origin == _origin:
		return
	var previous_origin := _origin
	var old_fields: Dictionary = _fields
	_fields = {}
	_origin = new_origin
	for name in FIELD_NAMES:
		var values := PackedFloat64Array()
		values.resize(_side * _side)
		_fields[name] = values
	for y in _side:
		for x in _side:
			var index := y * _side + x
			var cell := _origin + Vector2i(x, y)
			var previous := cell - previous_origin
			if previous.x >= 0 and previous.y >= 0 and previous.x < _side and previous.y < _side:
				var old_index := previous.y * _side + previous.x
				for name in FIELD_NAMES:
					_fields[name][index] = old_fields[name][old_index]
			else:
				_initialize_cell(index, cell)

func _initialize_cell(index: int, cell: Vector2i) -> void:
	var point := Vector2(cell) * cell_size
	var influence := _influence(point)
	var amplitude := lerpf(float(WIND_PROFILES[baseline_wind].wave_amplitude), float(WIND_PROFILES[_wind].wave_amplitude), influence)
	_fields.amplitude[index] = amplitude
	_fields.height[index] = _wave(point, amplitude)
	_fields.velocity[index] = 0.0
	_fields.wind_strength[index] = lerpf(float(WIND_PROFILES[baseline_wind].strength), float(WIND_PROFILES[_wind].strength), influence)
	var target_vector := _wind_target(influence)
	_fields.wind_x[index] = target_vector.x
	_fields.wind_z[index] = target_vector.y
	for name in ["cloud_cover", "rain", "light"]:
		_fields[name][index] = lerpf(float(SKY_PROFILES[baseline_sky][name]), float(SKY_PROFILES[_sky][name]), influence)
