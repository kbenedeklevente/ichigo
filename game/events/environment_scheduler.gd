extends RefCounted
## Sole runtime admission owner: two tracks, one pending collection, atomic pairs.
## Handlers report completion; this class never advances weather or actor physics.
const Chance = preload("res://game/events/event_chance.gd")
const WEATHER_CAPACITY := 2 # Includes active weather, as chosen by the user.
const MAX_PENDING := 64
const QUIET_SECONDS := 90.0
const ENCOUNTER_RATE_CAP := 1.0 / 240.0
const WEATHER_RATE_CAP := 1.0 / 60.0 # Preserve the sixteen-profile study ceiling.

var weather_owner: String = ""
var encounter_owner: String = ""
var quiet_remaining: float = 0.0
var chance_enabled: bool = true
var _definitions: Dictionary = {}
var _fingerprint: String = ""
var _pending: Array[Dictionary] = []
var _active: Dictionary = {}
var _completed: Dictionary = {}
var _ready_at: Dictionary = {}
var _seen: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _time: float = 0.0
var _sequence: int = 0
var _clocks: Dictionary = {"weather": 0.0, "encounter": 0.0}
var _hazards: Dictionary = {"weather": {}, "encounter": {}}
var _debug: Dictionary = {}

func configure(definitions: Array[Dictionary], seed_value: int = 15) -> bool:
	var validated: Dictionary = {}
	for definition: Dictionary in definitions:
		var id: Variant = definition.get("id")
		if not id is String or id.is_empty() or validated.has(id) or not Chance.validate(definition):
			return false
		if definition.get("domain") not in ["weather", "encounter"] or definition.get("activation") not in ["trigger", "chance", "both"]:
			return false
		if not Chance.valid_number(definition.get("cooldown_seconds", 0.0)) or not definition.get("payload", {}) is Dictionary:
			return false
		if not definition.get("priority", 0) is int or not definition.get("once", false) is bool:
			return false
		var payload: Dictionary = definition.get("payload", {})
		if definition.domain == "weather":
			if not payload.get("instant", false) is bool:
				return false
			if payload.get("sky", "sunny") not in Chance.SKIES or payload.get("wind", "calm") not in Chance.WINDS:
				return false
			for key: String in ["approach_s", "hold_s", "clearing_s"]:
				if payload.has(key) and (not Chance.valid_number(payload[key]) or payload[key] <= 0):
					return false
		elif payload.get("handler") != "salvage":
			return false
		validated[id] = definition.duplicate(true)
	_definitions = validated
	_fingerprint = JSON.stringify(_definitions, "", true).sha256_text()
	_pending.clear()
	_active.clear()
	_completed.clear()
	_ready_at.clear()
	_seen.clear()
	weather_owner = ""
	encounter_owner = ""
	quiet_remaining = 0.0
	chance_enabled = true
	_time = 0.0
	_sequence = 0
	_rng.seed = seed_value
	_clocks = {"weather": 0.0, "encounter": 0.0}
	_hazards = {"weather": {}, "encounter": {}}
	_debug.clear()
	return true

func submit(request_id: String, weather_id: String = "", encounter_id: String = "", story: bool = false, context: Dictionary = {}) -> String:
	if request_id.is_empty() or (weather_id.is_empty() and encounter_id.is_empty()) or (story and (weather_id.is_empty() or encounter_id.is_empty())):
		return "invalid"
	if _active.has(request_id) or _completed.has(request_id):
		return "duplicate"
	for record: Dictionary in _pending:
		if record.id == request_id:
			return "duplicate"
	for pair: Array in [[weather_id, "weather"], [encounter_id, "encounter"]]:
		var id: String = pair[0]
		if id.is_empty():
			continue
		if not _definitions.has(id) or _definitions[id].domain != pair[1] or _definitions[id].activation == "chance":
			return "invalid"
		if _definitions[id].get("once", false) and _definition_busy(id):
			return "duplicate"
		if not _available(id):
			return "ineligible"
		# Queue requests whose environment is not ready, but never waive authored
		# story/capability prerequisites at submission or dispatch.
		if not _prerequisites(id, context):
			return "ineligible"
	if _pending.size() >= MAX_PENDING or (not weather_id.is_empty() and weather_count() >= WEATHER_CAPACITY):
		return "full"
	var priority: int = 100 if story else 0
	for id: String in [weather_id, encounter_id]:
		if not id.is_empty():
			priority = maxi(priority, int(_definitions[id].get("priority", 0)))
	_pending.append({"id": request_id, "weather": weather_id, "encounter": encounter_id,
		"story": story, "priority": priority, "sequence": _sequence, "source": "trigger"})
	_sequence += 1
	return "accepted"

func trigger(definition_id: String, context: Dictionary = {}) -> bool:
	if not _definitions.has(definition_id) or _definition_busy(definition_id):
		return false
	var domain: String = _definitions[definition_id].domain
	return submit("trigger:%d" % _sequence, definition_id if domain == "weather" else "", definition_id if domain == "encounter" else "", false, context) == "accepted"

func submit_story(request_id: String, weather_id: String, encounter_id: String, context: Dictionary = {}) -> String:
	return submit(request_id, weather_id, encounter_id, true, context)

func weather_count() -> int:
	var count: int = 0 if weather_owner.is_empty() else 1
	for record: Dictionary in _pending:
		if not record.weather.is_empty():
			count += 1
	return count

func _prerequisites(id: String, context: Dictionary) -> bool:
	var rules: Dictionary = _definitions[id].get("eligibility", {})
	for flag: String in rules.get("requires", []):
		if flag not in context.get("flags", []):
			return false
	for flag: String in rules.get("excludes", []):
		if flag in context.get("flags", []):
			return false
	return true

func _available(id: String) -> bool:
	return _time + 0.0000001 >= float(_ready_at.get(id, 0.0)) and not (_definitions[id].get("once", false) and _seen.has(id))

func _definition_busy(id: String) -> bool:
	for record: Dictionary in _pending:
		if id in [record.weather, record.encounter]:
			return true
	for record: Dictionary in _active.values():
		if id == record.weather and not record.weather_done or id == record.encounter and not record.encounter_done:
			return true
	return false

func _eligible(id: String, context: Dictionary) -> bool:
	return _available(id) and Chance.exclusion(_definitions[id], context).is_empty()

func _can_start(record: Dictionary, context: Dictionary) -> bool:
	if not record.weather.is_empty():
		if not weather_owner.is_empty() or not encounter_owner.is_empty() or not _eligible(record.weather, context):
			return false
	if not record.encounter.is_empty():
		if not encounter_owner.is_empty() or quiet_remaining > 0.0000001 or not context.get("encounters_enabled", false):
			return false
		if record.weather.is_empty():
			return context.get("weather_stage", "idle") in ["idle", "hold"] and _eligible(record.encounter, context)
		# A linked encounter needs its requested destination, not current weather.
		# Recheck against actual local fields when that front is established.
		var destination: Dictionary = context.duplicate(true)
		var payload: Dictionary = _definitions[record.weather].payload
		destination.sky = payload.get("sky", "sunny")
		destination.wind_intensity = float(Chance.WINDS.find(payload.get("wind", "calm")))
		if not _eligible(record.encounter, destination):
			return false
	return true

func _story_barrier(context: Dictionary) -> bool:
	for record: Dictionary in _pending:
		if record.story and context.get("encounters_enabled", false) and _prerequisites(record.weather, context) and _prerequisites(record.encounter, context):
			# Only viable pairs drain tracks. A hard-ineligible destination cannot
			# starve ordinary work indefinitely.
			var hypothetical: Dictionary = context.duplicate(true)
			hypothetical.sky = _definitions[record.weather].payload.get("sky", "sunny")
			hypothetical.wind_intensity = float(Chance.WINDS.find(_definitions[record.weather].payload.get("wind", "calm")))
			if _eligible(record.weather, context) and _eligible(record.encounter, hypothetical):
				return true
	return false

func advance(delta: float, context: Dictionary) -> Array[Dictionary]:
	var commands: Array[Dictionary] = []
	if not is_finite(delta) or delta < 0.0:
		return commands
	context = context.duplicate(true)
	_time += delta
	context["encounter_was_quiet"] = quiet_remaining > 0.0000001
	quiet_remaining = maxf(0.0, quiet_remaining - delta)
	# Reserved is not active: approaching weather must keep advancing.
	if not encounter_owner.is_empty():
		var linked: Dictionary = _active[encounter_owner]
		if linked.phase == "preparing" and context.get("weather_stage") == "hold":
			if _prerequisites(linked.encounter, context) and Chance.exclusion(_definitions[linked.encounter], context).is_empty():
				linked.phase = "encounter"
				_seen[linked.encounter] = true
				commands.append(_command("start_encounter", linked, linked.encounter))
			elif not _prerequisites(linked.encounter, context):
				cancel(linked.id)
			# Local physical fields can lag the front phase. Keep checking during
			# its finite hold; if it clears before becoming eligible, cancel the
			# unstarted encounter instead of starting in incompatible weather.
		elif linked.phase == "preparing" and context.get("weather_stage") == "clear":
			cancel(linked.id)
	_pending.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.priority > b.priority if a.priority != b.priority else a.sequence < b.sequence)
	var barrier: bool = _story_barrier(context)
	for record: Dictionary in _pending.duplicate():
		if barrier and not record.story:
			continue
		if _can_start(record, context):
			_pending.erase(record)
			_allocate(record, commands)
			if not record.weather.is_empty():
				context.weather_stage = "approach"
	for domain: String in ["weather", "encounter"]:
		_roll(domain, delta, context, barrier, commands)
	return commands

func _allocate(request: Dictionary, commands: Array[Dictionary]) -> void:
	var record: Dictionary = request.duplicate(true)
	record.weather_done = record.weather.is_empty()
	record.encounter_done = record.encounter.is_empty()
	record.cancelled = false
	record.phase = "preparing" if not record.weather.is_empty() and not record.encounter.is_empty() else "weather" if not record.weather.is_empty() else "encounter"
	_active[record.id] = record
	if not record.weather.is_empty():
		weather_owner = record.id
		_seen[record.weather] = true
		commands.append(_command("start_weather", record, record.weather))
	if not record.encounter.is_empty():
		encounter_owner = record.id
		if record.weather.is_empty():
			_seen[record.encounter] = true
			commands.append(_command("start_encounter", record, record.encounter))

func _command(kind: String, record: Dictionary, id: String) -> Dictionary:
	return {"kind": kind, "request_id": record.id, "id": id, "source": record.source, "payload": _definitions[id].payload.duplicate(true)}

func _roll(domain: String, delta: float, context: Dictionary, barrier: bool, commands: Array[Dictionary]) -> void:
	var blocked: bool = not chance_enabled or barrier
	if domain == "weather":
		blocked = blocked or not weather_owner.is_empty() or not encounter_owner.is_empty() or weather_count() >= WEATHER_CAPACITY
	else:
		blocked = blocked or context.get("encounter_was_quiet", false) or not encounter_owner.is_empty() or quiet_remaining > 0.0000001 or not context.get("encounters_enabled", false) or context.get("weather_stage", "idle") not in ["idle", "hold"]
		# A weather command has reserved the track this tick; context still refers
		# to the prior frame. Do not start an encounter alongside that approach.
		for command: Dictionary in commands:
			blocked = blocked or command.kind == "start_weather"
	if blocked:
		_debug[domain] = {"blocked": true, "limited_total": 0.0}
		_clocks[domain] = 0.0
		_hazards[domain] = {}
		return
	var rates: Dictionary = {}
	var total: float = 0.0
	var ids: Array = _definitions.keys()
	ids.sort()
	for id: String in ids:
		var definition: Dictionary = _definitions[id]
		if definition.domain != domain:
			continue
		var evaluation: Dictionary = Chance.evaluate(definition, context)
		if definition.activation == "trigger" or not _available(id) or _definition_busy(id):
			evaluation = {"rate": 0.0, "reason": "trigger_only_or_busy_or_cooldown"}
		_debug[id] = evaluation
		if evaluation.rate > 0:
			rates[id] = evaluation.rate
			total += float(evaluation.rate)
	if total <= 0.0:
		_debug[domain] = {"blocked": false, "raw_total": 0.0, "limited_total": 0.0}
		_clocks[domain] = 0.0
		_hazards[domain] = {}
		return
	var cap: float = WEATHER_RATE_CAP if domain == "weather" else ENCOUNTER_RATE_CAP
	var scale: float = minf(1.0, cap / total)
	_debug[domain] = {"raw_total": total, "limited_total": total * scale}
	# Fixed-step integration accounts for local field changes within a chance tick.
	# Drop opportunities whose hard eligibility disappeared before the roll.
	for id: String in _hazards[domain].keys():
		if not rates.has(id):
			_hazards[domain].erase(id)
	for id: String in rates:
		_hazards[domain][id] = float(_hazards[domain].get(id, 0.0)) + float(rates[id]) * scale * delta
	_clocks[domain] += delta
	if _clocks[domain] + 0.0000001 < 1.0:
		return
	var hazard: float = 0.0
	for amount: float in _hazards[domain].values():
		hazard += amount
	if _rng.randf() < Chance.probability(hazard, 1.0):
		var ticket: float = _rng.randf() * hazard
		for id: String in _hazards[domain]:
			ticket -= float(_hazards[domain][id])
			if ticket <= 0.0:
				var record := {"id": "chance:%d" % _sequence, "weather": id if domain == "weather" else "", "encounter": id if domain == "encounter" else "", "story": false, "priority": 0, "sequence": _sequence, "source": "chance"}
				if _can_start(record, context):
					_sequence += 1
					_debug[domain]["selected"] = id
					_allocate(record, commands)
				break
	_clocks[domain] = 0.0
	_hazards[domain] = {}

## Explicit laboratory replacement, never used by authored event admission.
func interrupt_weather_for_testing() -> void:
	for record: Dictionary in _pending.duplicate():
		if not record.weather.is_empty():
			cancel(record.id)
	if not weather_owner.is_empty():
		finish_weather("cancelled")
	_clocks.weather = 0.0
	_hazards.weather = {}

func finish_weather(outcome: String = "completed") -> bool:
	if weather_owner.is_empty():
		return false
	var record: Dictionary = _active[weather_owner]
	record.weather_done = true
	_ready_at[record.weather] = _time + float(_definitions[record.weather].get("cooldown_seconds", 0.0))
	weather_owner = ""
	if record.phase == "preparing":
		record.encounter_done = true
		encounter_owner = ""
		record.cancelled = true
	if outcome != "completed":
		record.cancelled = true
	_close_if_done(record)
	return true

func finish_encounter(outcome: String = "abandoned") -> bool:
	if encounter_owner.is_empty():
		return false
	var record: Dictionary = _active[encounter_owner]
	if record.phase != "encounter":
		return false
	record.encounter_done = true
	record.encounter_outcome = outcome
	record.phase = "weather_tail"
	_ready_at[record.encounter] = _time + float(_definitions[record.encounter].get("cooldown_seconds", 0.0))
	encounter_owner = ""
	quiet_remaining = QUIET_SECONDS
	_close_if_done(record)
	return true

func cancel(request_id: String) -> bool:
	for record: Dictionary in _pending:
		if record.id == request_id:
			_pending.erase(record)
			_completed[request_id] = {"outcome": "cancelled"}
			return true
	if not _active.has(request_id):
		return false
	var record: Dictionary = _active[request_id]
	if record.phase == "encounter":
		return false # Live actors must resolve/depart through their handler.
	record.cancelled = true
	if record.phase == "preparing":
		record.encounter_done = true
		encounter_owner = ""
		record.phase = "weather_tail"
	# Let an already approaching front finish its ordinary clear, without jumping
	# its center/field envelope. Cancellation never teleports weather to calm.
	_close_if_done(record)
	return true

func _close_if_done(record: Dictionary) -> void:
	if record.weather_done and record.encounter_done:
		_completed[record.id] = {"outcome": "cancelled" if record.cancelled else record.get("encounter_outcome", "completed"), "weather": record.weather, "encounter": record.encounter}
		_active.erase(record.id)

func definition(id: String) -> Dictionary:
	return _definitions.get(id, {}).duplicate(true)

func get_status() -> Dictionary:
	return {"weather_owner": weather_owner, "encounter_owner": encounter_owner, "weather_count": weather_count(), "quiet_remaining": quiet_remaining, "pending": _pending.duplicate(true), "active": _active.duplicate(true), "debug": _debug.duplicate(true)}

func snapshot() -> Dictionary:
	return {"version": 1, "catalog": _fingerprint, "rng_seed": str(_rng.seed), "rng_state": str(_rng.state),
		"time": _time, "sequence": _sequence, "pending": _pending.duplicate(true), "active": _active.duplicate(true),
		"completed": _completed.duplicate(true), "ready_at": _ready_at.duplicate(true), "seen": _seen.duplicate(true),
		"weather_owner": weather_owner, "encounter_owner": encounter_owner, "quiet_remaining": quiet_remaining,
		"clocks": _clocks.duplicate(true), "hazards": _hazards.duplicate(true), "chance_enabled": chance_enabled}

func restore(data: Dictionary) -> bool:
	if data.get("version") != 1 or data.get("catalog") != _fingerprint:
		return false
	for key: String in ["active", "completed", "ready_at", "seen", "clocks", "hazards"]:
		if not data.get(key) is Dictionary:
			return false
	if not data.get("pending") is Array or data.pending.size() > MAX_PENDING or data.active.size() > 2:
		return false
	if not Chance.valid_number(data.get("time")) or not Chance.valid_number(data.get("quiet_remaining")) or data.quiet_remaining > QUIET_SECONDS:
		return false
	if not data.get("sequence") is int or data.sequence < 0 or not data.get("chance_enabled") is bool:
		return false
	for key: String in ["rng_seed", "rng_state"]:
		if not data.get(key) is String or not data[key].is_valid_int() or str(int(data[key])) != data[key]:
			return false
	for key: String in ["weather_owner", "encounter_owner"]:
		if not data.get(key) is String or (not data[key].is_empty() and not data.active.has(data[key])):
			return false
	var ids: Dictionary = {}
	var definitions_in_use: Dictionary = {}
	var sequences: Dictionary = {}
	var weather_slots: int = 0
	var expected_weather: String = ""
	var expected_encounter: String = ""
	for entry: Variant in data.pending + data.active.values():
		if not entry is Dictionary or not entry.get("id") is String or entry.id.is_empty() or ids.has(entry.id) or data.completed.has(entry.id):
			return false
		if not entry.get("sequence") is int or entry.sequence < 0 or entry.sequence >= data.sequence or not entry.get("priority") is int or not entry.get("story") is bool or entry.get("source") not in ["trigger", "chance"]:
			return false
		if sequences.has(entry.sequence):
			return false
		sequences[entry.sequence] = true
		ids[entry.id] = true
		var live: bool = data.active.has(entry.id)
		if live:
			if data.active[entry.id] != entry or entry.get("phase") not in ["preparing", "weather", "encounter", "weather_tail"]:
				return false
			for key: String in ["weather_done", "encounter_done", "cancelled"]:
				if not entry.get(key) is bool:
					return false
			if entry.weather_done and entry.encounter_done:
				return false
		elif entry.source != "trigger":
			return false
		for domain: String in ["weather", "encounter"]:
			if not entry.get(domain) is String:
				return false
			var id: String = entry[domain]
			if id.is_empty():
				if live and not entry[domain + "_done"]:
					return false
				continue
			if not _definitions.has(id) or _definitions[id].domain != domain or _definitions[id].activation not in [entry.source, "both"]:
				return false
			if live and entry[domain + "_done"]:
				continue
			if definitions_in_use.has(id) and _definitions[id].get("once", false):
				return false
			definitions_in_use[id] = true
			if domain == "weather":
				weather_slots += 1
			if live:
				if domain == "weather":
					if not expected_weather.is_empty():
						return false
					expected_weather = entry.id
				else:
					if not expected_encounter.is_empty():
						return false
					expected_encounter = entry.id
		if entry.weather.is_empty() and entry.encounter.is_empty() or entry.story and (entry.weather.is_empty() or entry.encounter.is_empty()):
			return false
		if live:
			match entry.phase:
				"preparing":
					if entry.weather_done or entry.encounter_done or entry.cancelled:
						return false
				"weather":
					if entry.weather_done or not entry.encounter.is_empty():
						return false
				"encounter":
					if entry.encounter_done or (not entry.weather.is_empty() and entry.weather_done and not entry.cancelled):
						return false
				"weather_tail":
					if entry.weather_done or not entry.encounter_done:
						return false
			if not entry.weather_done and not data.seen.get(entry.weather, false):
				return false
			if entry.phase == "encounter" and not data.seen.get(entry.encounter, false):
				return false
		else:
			for id: String in [entry.weather, entry.encounter]:
				if not id.is_empty() and _definitions[id].get("once", false) and data.seen.get(id, false):
					return false
	for id: Variant in data.completed:
		if not id is String or id.is_empty() or not data.completed[id] is Dictionary or data.completed[id].get("outcome") not in ["cancelled", "completed", "failed", "abandoned"]:
			return false
	if weather_slots > WEATHER_CAPACITY or expected_weather != data.weather_owner or expected_encounter != data.encounter_owner:
		return false
	if not expected_encounter.is_empty() and data.quiet_remaining > 0.0000001:
		return false
	for key: String in ["ready_at", "seen"]:
		for id: Variant in data[key]:
			if not _definitions.has(id) or (key == "ready_at" and not Chance.valid_number(data[key][id])) or (key == "seen" and data[key][id] != true):
				return false
	for domain: String in ["weather", "encounter"]:
		if not Chance.valid_number(data.clocks.get(domain)) or data.clocks[domain] >= 1.0 or not data.hazards.get(domain) is Dictionary:
			return false
		var sum: float = 0.0
		for id: Variant in data.hazards[domain]:
			if not _definitions.has(id) or _definitions[id].domain != domain or not Chance.valid_number(data.hazards[domain][id]):
				return false
			sum += float(data.hazards[domain][id])
		var cap: float = WEATHER_RATE_CAP if domain == "weather" else ENCOUNTER_RATE_CAP
		if sum > cap * float(data.clocks[domain]) + 0.0000001:
			return false
	_time = data.time
	_sequence = data.sequence
	_pending.assign(data.pending.duplicate(true))
	_active = data.active.duplicate(true)
	_completed = data.completed.duplicate(true)
	_ready_at = data.ready_at.duplicate(true)
	_seen = data.seen.duplicate(true)
	weather_owner = data.weather_owner
	encounter_owner = data.encounter_owner
	quiet_remaining = data.quiet_remaining
	_clocks = data.clocks.duplicate(true)
	_hazards = data.hazards.duplicate(true)
	chance_enabled = data.chance_enabled
	_rng.seed = int(data.rng_seed)
	_rng.state = int(data.rng_state)
	_debug.clear()
	return true
