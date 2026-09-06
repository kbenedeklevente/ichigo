extends RefCounted
## Decorative weather lifecycles, independent of encounter admission and draw density.
const Weather = preload("res://game/world/weather_simulation.gd")
const MAX_ACTIVE := 3
const CHANCE_PER_CYCLE := 0.015
const COOLDOWN := 2.5
const RISE := 1.6
const CRASH := 0.38
const FOAM := 3.8
const LIFETIME := RISE + CRASH + FOAM
const PEAK_GAIN := 2.35
const FOOTPRINT := Vector2(8.0, 12.0)
var active: Array[Dictionary] = []
var _cycles: Dictionary = {}
var _seed: int = 15
var _clock: float = 0.0
var _next_start: float = 0.0
var starts: int = 0
var rolls: int = 0

func configure(seed_value: int) -> void:
	_seed = seed_value
	_clock = 0.0
	_next_start = 0.0
	active.clear()
	_cycles.clear()
	starts = 0
	rolls = 0

static func eligible(local: Dictionary) -> bool:
	# Exponential fronts never reach exact endpoints. Both axes must be within
	# 0.25% of maximum; named Storm (9, 3) is explicitly below this gate.
	return float(local.get("wind_strength", 0.0)) >= 11.97 and float(local.get("sky_strength", 0.0)) >= 3.99

func advance(weather, player: Vector2) -> void:
	var status: Dictionary = weather.get_status()
	var now: float = status.simulation_time
	if now <= _clock:
		return
	_clock = now
	for i in range(active.size() - 1, -1, -1):
		if _clock - float(active[i].started) >= LIFETIME:
			active.remove_at(i)
	var size: float = status.cell_size
	var radius: int = status.render_radius
	var center := Vector2i(floori(player.x / size), floori(player.y / size))
	var next_cycles: Dictionary = {}
	for z in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			var cell := Vector2i(x, z)
			var point := Vector2(cell) * size
			# One crossing of the primary traveling swell at this stable anchor.
			var cycle := floori((float(status.phase) - TAU * (point.x + point.y * 0.28) / Weather.WAVE_LENGTH) / TAU)
			next_cycles[cell] = cycle
			var previous: int = _cycles.get(cell, cycle)
			if cycle <= previous or _clock < _next_start or active.size() >= MAX_ACTIVE:
				continue
			var occupied := false
			for breaker: Dictionary in active:
				if breaker.cell == cell:
					occupied = true
			if occupied:
				continue
			var local: Dictionary = weather.sample(point)
			if not eligible(local):
				continue
			rolls += 1
			var rng := RandomNumberGenerator.new()
			rng.seed = hash("%d:%d:%d:%d" % [_seed, x, z, cycle])
			if rng.randf() >= CHANCE_PER_CYCLE:
				continue
			var direction: Vector2 = local.wind.normalized()
			if direction.length_squared() < 0.5:
				direction = Vector2.RIGHT
			active.append({"cell": cell, "anchor": point, "direction": direction,
				"started": _clock, "cell_size": size})
			_next_start = _clock + COOLDOWN
			starts += 1
	_cycles = next_cycles

func render_state() -> Dictionary:
	var crests := PackedVector4Array()
	var splashes := PackedVector4Array()
	var directions := PackedVector2Array()
	for breaker: Dictionary in active:
		var age: float = _clock - float(breaker.started)
		var gain := 1.0
		var lean := 0.0
		if age < RISE:
			gain = lerpf(1.0, PEAK_GAIN, smoothstep(0.0, RISE, age))
		elif age < RISE + CRASH:
			lean = smoothstep(RISE, RISE + CRASH, age)
			gain = lerpf(PEAK_GAIN, 0.08, lean)
		else:
			gain = lerpf(0.08, 1.0, smoothstep(RISE + CRASH + 0.3, RISE + CRASH + 1.3, age))
		var anchor: Vector2 = breaker.anchor
		var direction: Vector2 = breaker.direction
		crests.append(Vector4(anchor.x, anchor.y, gain, lean))
		# Match the card's stagger and stable seed offset before projecting impact.
		var seed_value := fposmod(float(breaker.cell.x * 17 + breaker.cell.y * 31), 13.0) / 13.0
		var center := anchor + Vector2(float(breaker.cell_size) * 0.5 if posmod(breaker.cell.y, 2) == 0 else 0.0, (seed_value - 0.5) * 0.36) + direction * 3.0
		var foam_age := age - RISE - CRASH
		var spread := lerpf(0.18, 1.0, smoothstep(0.0, 0.85, foam_age))
		var opacity := smoothstep(0.0, 0.12, foam_age) * (1.0 - smoothstep(1.0, FOAM, foam_age))
		splashes.append(Vector4(center.x, center.y, spread, opacity))
		directions.append(direction)
	var count := crests.size()
	crests.resize(MAX_ACTIVE)
	splashes.resize(MAX_ACTIVE)
	directions.resize(MAX_ACTIVE)
	return {"count": count, "crests": crests, "splashes": splashes, "directions": directions}

func snapshot() -> Dictionary:
	return {"seed": _seed, "clock": _clock, "next_start": _next_start, "active": active.duplicate(true),
		"cycles": _cycles.duplicate(), "starts": starts, "rolls": rolls}

func restore(data: Dictionary) -> bool:
	if not data.get("seed") is int or not data.get("active") is Array or not data.get("cycles") is Dictionary:
		return false
	for key in ["clock", "next_start"]:
		if not (data.get(key) is float or data.get(key) is int) or not is_finite(float(data[key])) or float(data[key]) < 0.0:
			return false
	for key in ["starts", "rolls"]:
		if not data.get(key) is int or data[key] < 0:
			return false
	if data.active.size() > MAX_ACTIVE or data.cycles.size() > 1089:
		return false
	var cells: Dictionary = {}
	for item in data.active:
		if not item is Dictionary or not item.get("cell") is Vector2i or cells.has(item.cell):
			return false
		cells[item.cell] = true
		for key in ["anchor", "direction"]:
			if not item.get(key) is Vector2 or not item[key].is_finite():
				return false
		for key in ["started", "cell_size"]:
			if not (item.get(key) is float or item.get(key) is int) or not is_finite(float(item[key])):
				return false
		if item.cell_size <= 0.0 or item.started < 0.0 or item.started > data.clock or data.clock - item.started >= LIFETIME or not is_equal_approx(item.direction.length(), 1.0):
			return false
		if not item.anchor.is_equal_approx(Vector2(item.cell) * float(item.cell_size)):
			return false
	for cell in data.cycles:
		if not cell is Vector2i or not data.cycles[cell] is int:
			return false
	_seed = data.seed
	_clock = data.clock
	_next_start = data.next_start
	active.assign(data.active.duplicate(true))
	_cycles = data.cycles.duplicate()
	starts = data.starts
	rolls = data.rolls
	return true
