extends RefCounted
## Exclusive side-encounter gate. Ordinary fishing is deliberately not a gate.
## Native Variant snapshots preserve vectors and the seeded scheduling stream.

const EventInstance = preload("res://game/events/event_instance.gd")
const SpatialIndex = preload("res://game/events/event_spatial_index.gd")
const STEP: float = 1.0 / 30.0
const QUIET_SECONDS: float = 90.0
const MAX_TOTAL_RATE: float = 1.0 / 240.0
const MAX_PENDING: int = 64
const SKY_P60: Dictionary = {"sunny": 0.05, "cloudy": 0.07, "raincloud": 0.09, "storm": 0.04}
const WIND_MULTIPLIER: Dictionary = {"calm": 0.6, "breeze": 1.0, "strong": 1.3, "storm": 0.5}

var spatial_index = SpatialIndex.new()
var _active = null
var _rng := RandomNumberGenerator.new()
var _accumulator: float = 0.0
var _chance_steps: int = 0
var _quiet_remaining: float = 0.0
var _next_ordinal: int = 1
var _pending: Array[String] = []
var _outcomes: Dictionary = {}
var _last_source: String = ""
var _last_id: String = ""

func configure(seed_value: int = 15) -> void:
	_rng.seed = seed_value
	_active = null
	spatial_index = SpatialIndex.new()
	_accumulator = 0.0
	_chance_steps = 0
	_quiet_remaining = 0.0
	_next_ordinal = 1
	_pending.clear()
	_outcomes.clear()
	_last_source = ""
	_last_id = ""

func trigger(id: String = "salvage") -> bool:
	# Only this authored fixture is enabled. No placeholder wildlife/story handlers.
	if id != "salvage" or _pending.has(id) or _pending.size() >= MAX_PENDING:
		return false
	if _active != null and _active.definition_id == id:
		return false
	_pending.append(id)
	return true

func advance(delta: float, player: Vector2, environment: Dictionary, can_start: bool) -> void:
	if not is_finite(delta) or delta < 0.0 or not player.is_finite():
		return
	_dispatch_pending(player, can_start)
	_accumulator += delta
	var steps: int = floori((_accumulator + 0.0000001) / STEP)
	_accumulator = snappedf(maxf(0.0, _accumulator - steps * STEP), 0.000000001)
	for step: int in range(steps):
		_step(player, environment, can_start)

func _step(player: Vector2, environment: Dictionary, can_start: bool) -> void:
	if _active != null:
		_active.advance(STEP, player)
		if _active.phase == "retired":
			_outcomes[_active.id] = {"definition_id": _active.definition_id,
				"outcome": _active.outcome, "source": _active.source}
			spatial_index.remove(_active.id)
			_active = null
			_quiet_remaining = QUIET_SECONDS
			_chance_steps = 0
		else:
			_update_index()
		return
	if _quiet_remaining > 0.000001:
		_quiet_remaining = maxf(0.0, _quiet_remaining - STEP)
		if _quiet_remaining < 0.000001:
			_quiet_remaining = 0.0
		# The last quiet step still belongs to quiet time, not eligible random time.
		_dispatch_pending(player, can_start)
		return
	if not can_start:
		return
	_dispatch_pending(player, can_start)
	if _active != null:
		return
	_chance_steps += 1
	if _chance_steps >= 30:
		_chance_steps = 0
		var rate: float = rate_for_environment(environment)
		if rate > 0.0 and _rng.randf() < probability_for_rate(rate, 1.0):
			_activate(player, "chance")

func _dispatch_pending(player: Vector2, can_start: bool) -> void:
	# Explicit salvage requests obey quiet time too. Future story bypass requires policy.
	if can_start and _active == null and _quiet_remaining <= 0.000001 and not _pending.is_empty():
		_pending.pop_front()
		_activate(player, "trigger")

func _activate(player: Vector2, source: String) -> void:
	_active = EventInstance.new()
	_active.id = "salvage:%d" % _next_ordinal
	_next_ordinal += 1
	_active.source = source
	_active.center = player + Vector2(5.0, -7.0)
	_active.departure_direction = Vector2(5.0, -7.0).normalized()
	_active.modifier.origin = _active.center
	_last_id = _active.id
	_last_source = source
	_chance_steps = 0
	_update_index()

func _update_index() -> void:
	spatial_index.index(_active.id, _active.center, maxf(_active.bounds_radius, _active.modifier.radius))

static func probability_for_rate(rate: float, duration: float) -> float:
	if not is_finite(rate) or not is_finite(duration) or rate <= 0.0 or duration <= 0.0:
		return 0.0
	return 1.0 - exp(-rate * duration)

static func rate_for_environment(environment: Dictionary) -> float:
	var sky: String = str(environment.get("sky", ""))
	var wind: String = str(environment.get("wind", ""))
	if not SKY_P60.has(sky) or not WIND_MULTIPLIER.has(wind):
		return 0.0
	var rate: float = -log(1.0 - float(SKY_P60[sky])) / 60.0 * float(WIND_MULTIPLIER[wind])
	return minf(rate, MAX_TOTAL_RATE)

func get_active():
	return _active

func get_modifiers() -> Array:
	return [_active.modifier] if _active != null and _active.modifier.weight > 0.0 else []

func report_visibility(visible: bool, in_interaction_range: bool) -> void:
	# Renderer supplies full actor bounds against its padded viewport for next step.
	if _active != null:
		_active.visible = visible
		_active.in_interaction_range = in_interaction_range

func get_status() -> Dictionary:
	return {"active": _active != null, "phase": _active.phase if _active != null else "idle",
		"active_id": _active.id if _active != null else "", "quiet_remaining": _quiet_remaining,
		"last_id": _last_id, "last_source": _last_source, "pending": _pending.size(),
		"outcomes": _outcomes.duplicate(true)}

func snapshot() -> Dictionary:
	return {"version": 1, "rng_seed": str(_rng.seed), "rng_state": str(_rng.state),
		"accumulator": _accumulator, "chance_steps": _chance_steps,
		"quiet_remaining": _quiet_remaining, "next_ordinal": _next_ordinal,
		"active": _active.snapshot() if _active != null else {},
		"pending": _pending.duplicate(), "outcomes": _outcomes.duplicate(true),
		"last_id": _last_id, "last_source": _last_source}

func restore(data: Dictionary) -> bool:
	if data.get("version", 0) != 1 or not data.has_all(["rng_seed", "rng_state", "accumulator", "chance_steps", "quiet_remaining", "next_ordinal", "active", "pending", "outcomes", "last_id", "last_source"]):
		return false
	for key: String in ["rng_seed", "rng_state"]:
		if not data[key] is String or not data[key].is_valid_int() or str(int(data[key])) != data[key]:
			return false
	for key: String in ["accumulator", "quiet_remaining"]:
		if not (data[key] is float or data[key] is int) or not is_finite(float(data[key])):
			return false
	if data.accumulator < 0.0 or data.accumulator >= STEP or data.quiet_remaining < 0.0 or data.quiet_remaining > QUIET_SECONDS:
		return false
	if not data.chance_steps is int or data.chance_steps < 0 or data.chance_steps >= 30 or not data.next_ordinal is int or data.next_ordinal < 1:
		return false
	if not data.active is Dictionary or not data.pending is Array or not data.outcomes is Dictionary or not data.last_id is String or not data.last_source is String:
		return false
	if data.pending.size() > 1 or (not data.pending.is_empty() and data.pending[0] != "salvage"):
		return false
	if not data.last_source in ["", "trigger", "chance"]:
		return false
	var restored_active = null
	if not data.active.is_empty():
		restored_active = EventInstance.new()
		if not restored_active.restore(data.active) or data.quiet_remaining > 0.0 or data.chance_steps != 0 or not data.pending.is_empty():
			return false
		if restored_active.id != "salvage:%d" % (data.next_ordinal - 1) or data.last_id != restored_active.id or data.last_source != restored_active.source:
			return false
	# Every issued instance is either live or permanently represented in the ledger.
	var retired_count: int = data.next_ordinal - 1 - (1 if restored_active != null else 0)
	if data.outcomes.size() != retired_count:
		return false
	for ordinal: int in range(1, retired_count + 1):
		var id: String = "salvage:%d" % ordinal
		if not data.outcomes.get(id) is Dictionary:
			return false
		var record: Dictionary = data.outcomes[id]
		if record.get("definition_id") != "salvage" or not record.get("outcome") in ["completed", "failed", "abandoned"] or not record.get("source") in ["trigger", "chance"]:
			return false
	if data.next_ordinal == 1:
		if data.last_id != "" or data.last_source != "":
			return false
	elif data.last_id != "salvage:%d" % (data.next_ordinal - 1) or data.last_source.is_empty():
		return false
	elif restored_active == null and data.last_source != data.outcomes[data.last_id].source:
		return false
	_rng.seed = int(data.rng_seed)
	_rng.state = int(data.rng_state)
	_accumulator = float(data.accumulator)
	_chance_steps = data.chance_steps
	_quiet_remaining = float(data.quiet_remaining)
	_next_ordinal = data.next_ordinal
	_active = restored_active
	_pending.assign(data.pending)
	_outcomes = data.outcomes.duplicate(true)
	_last_id = data.last_id
	_last_source = data.last_source
	spatial_index = SpatialIndex.new()
	if _active != null:
		_update_index()
	return true
