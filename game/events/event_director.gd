extends RefCounted
## Domain-independent admission and lifecycle; dispatch never means completion.
## Fixed one-second chance ticks make scheduling independent of rendering rate.
## Triggers wait by priority/FIFO; chance proposals never accumulate behind locks.

const MAX_PENDING: int = 64
const MAX_ACTIVE: int = 64
const SCHEMA_VERSION: int = 1

var _definitions: Dictionary = {}
var _ids: Array[String] = []
var _fingerprint: String = ""
var _rng := RandomNumberGenerator.new()
var _time: float = 0.0
var _remainder: float = 0.0
var _sequence: int = 0
var _pending: Array[Dictionary] = []
var _active: Dictionary = {}
var _seen: Dictionary = {}
var _ready_at: Dictionary = {}
var _last_outcome: Dictionary = {}


func configure(definitions: Array[Dictionary], seed_value: int) -> void:
	_definitions.clear()
	_ids.clear()
	_pending.clear()
	_active.clear()
	_seen.clear()
	_ready_at.clear()
	_last_outcome.clear()
	_time = 0.0
	_remainder = 0.0
	_sequence = 0
	_rng.seed = seed_value
	for source: Dictionary in definitions:
		var id: String = str(source.get("id", ""))
		var activation: String = str(source.get("activation", "chance"))
		var rate: float = float(source.get("rate_per_second", 0.0))
		var cooldown: float = float(source.get("cooldown_seconds", 0.0))
		if id.is_empty() or _definitions.has(id) or activation not in ["trigger", "chance", "both"]:
			push_error("Invalid or duplicate event definition: " + id)
			continue
		if not is_finite(rate) or rate < 0.0 or not is_finite(cooldown) or cooldown < 0.0:
			push_error("Invalid event timing: " + id)
			continue
		var definition: Dictionary = {
			"id": id, "domain": str(source.get("domain", "ambient")),
			"activation": activation, "rate_per_second": rate,
			"cooldown_seconds": cooldown, "once": bool(source.get("once", false)),
			"requires": source.get("requires", []).duplicate(),
			"payload": source.get("payload", {}).duplicate(true),
			"priority": int(source.get("priority", 0)),
			"exclusive_group": str(source.get("exclusive_group", ""))
		}
		_definitions[id] = definition
		_ids.append(id)
	_ids.sort()
	var canonical: Array[Dictionary] = []
	for id: String in _ids:
		canonical.append(_definitions[id])
	_fingerprint = JSON.stringify(canonical).sha256_text()


func trigger(event_id: String, context: Dictionary = {}) -> bool:
	if not _definitions.has(event_id) or _pending.size() >= MAX_PENDING:
		return false
	var definition: Dictionary = _definitions[event_id]
	if definition["activation"] == "chance" or not _eligible(event_id, context):
		return false
	_pending.append({"id": event_id, "sequence": _sequence})
	_sequence += 1
	return true


func advance(delta: float, context: Dictionary = {}) -> Array[Dictionary]:
	var dispatched: Array[Dictionary] = []
	if not is_finite(delta) or delta < 0.0:
		return dispatched
	_dispatch_pending(context, dispatched)
	var accumulated: float = _remainder + delta
	var ticks: int = int(floor(accumulated + 0.000000001))
	for _tick: int in range(ticks):
		_remainder = 0.0
		_time += 1.0
		_dispatch_pending(context, dispatched)
		_roll_chance(context, dispatched)
	_remainder = maxf(0.0, accumulated - float(ticks))
	return dispatched


func finish(event_id: String, outcome: String = "completed") -> bool:
	if not _active.has(event_id):
		return false
	_active.erase(event_id)
	_ready_at[event_id] = _time + _remainder + float(_definitions[event_id]["cooldown_seconds"])
	_last_outcome[event_id] = outcome
	return true


func snapshot() -> Dictionary:
	# Decimal strings preserve all 64 RNG bits through JSON save/load.
	return {
		"version": SCHEMA_VERSION, "catalog": _fingerprint,
		"rng_seed": str(_rng.seed), "rng_state": str(_rng.state),
		"time": _time, "remainder": _remainder, "sequence": _sequence,
		"pending": _pending.duplicate(true), "active": _active.duplicate(true),
		"seen": _seen.duplicate(true), "ready_at": _ready_at.duplicate(true),
		"last_outcome": _last_outcome.duplicate(true)
	}


func restore(data: Dictionary) -> bool:
	# Validate first: rejected snapshots must not mutate the live director.
	if data.get("version") != SCHEMA_VERSION or data.get("catalog") != _fingerprint:
		return false
	for key: String in ["active", "seen", "ready_at", "last_outcome"]:
		if not data.get(key) is Dictionary:
			return false
		for id: Variant in data[key]:
			if not _definitions.has(id):
				return false
	if not data.get("pending") is Array or data["pending"].size() > MAX_PENDING or data["active"].size() > MAX_ACTIVE:
		return false
	var restored_time: float = float(data.get("time", -1.0))
	var restored_remainder: float = float(data.get("remainder", -1.0))
	if not is_finite(restored_time) or restored_time < 0.0 or restored_time != floor(restored_time):
		return false
	if not is_finite(restored_remainder) or restored_remainder < 0.0 or restored_remainder >= 1.0:
		return false
	if not str(data.get("rng_state", "")).is_valid_int() or not str(data.get("rng_seed", "")).is_valid_int():
		return false
	var restored_sequence: int = int(data.get("sequence", -1))
	if restored_sequence < 0:
		return false
	var occupied: Dictionary = {}
	var reserved: Dictionary = {}
	for id: String in data["active"]:
		var record: Variant = data["active"][id]
		if not record is Dictionary or record.get("id") != id or record.get("source") not in ["trigger", "chance"]:
			return false
		if record.get("domain") != _definitions[id]["domain"]:
			return false
		if _definitions[id]["activation"] not in [record["source"], "both"] or not data["seen"].get(id, false):
			return false
		var group: String = _definitions[id]["exclusive_group"]
		if not group.is_empty() and occupied.has(group):
			return false
		occupied[group] = true
		reserved[id] = true
	for entry: Variant in data["pending"]:
		if not entry is Dictionary or not _definitions.has(entry.get("id")):
			return false
		var id: String = entry["id"]
		var sequence: int = int(entry.get("sequence", -1))
		if reserved.has(id) or sequence < 0 or sequence >= restored_sequence or _definitions[id]["activation"] == "chance":
			return false
		if _definitions[id]["once"] and data["seen"].get(id, false):
			return false
		reserved[id] = true
	for id: String in data["ready_at"]:
		var ready: float = float(data["ready_at"][id])
		if not is_finite(ready) or ready < 0.0:
			return false
	_time = restored_time
	_remainder = restored_remainder
	_sequence = restored_sequence
	_rng.seed = int(data["rng_seed"])
	_rng.state = int(data["rng_state"])
	_pending.clear()
	for entry: Dictionary in data["pending"]:
		_pending.append({"id": str(entry["id"]), "sequence": int(entry["sequence"])})
	_active.clear()
	for id: String in data["active"]:
		# Payload is immutable catalog content, not mutable encounter state. Restore
		# from the matching catalog to preserve types lost by JSON number decoding.
		_active[id] = {"id": id, "domain": _definitions[id]["domain"],
			"source": data["active"][id]["source"],
			"payload": _definitions[id]["payload"].duplicate(true)}
	_seen = data["seen"].duplicate(true)
	_ready_at = data["ready_at"].duplicate(true)
	_last_outcome = data["last_outcome"].duplicate(true)
	return true


func _has_requirements(id: String, context: Dictionary) -> bool:
	var flags: Array = context.get("flags", [])
	for required: String in _definitions[id]["requires"]:
		if not flags.has(required):
			return false
	return true


func _eligible(id: String, context: Dictionary) -> bool:
	if _active.has(id) or not _has_requirements(id, context):
		return false
	if _definitions[id]["once"] and _seen.has(id):
		return false
	if _time + _remainder + 0.000000001 < float(_ready_at.get(id, 0.0)):
		return false
	for entry: Dictionary in _pending:
		if entry["id"] == id:
			return false
	return true


func _group_available(id: String) -> bool:
	if _active.size() >= MAX_ACTIVE:
		return false
	var group: String = _definitions[id]["exclusive_group"]
	if group.is_empty():
		return true
	for active_id: String in _active:
		if _definitions[active_id]["exclusive_group"] == group:
			return false
	return true


func _dispatch_pending(context: Dictionary, dispatched: Array[Dictionary]) -> void:
	_pending.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ap: int = _definitions[a["id"]]["priority"]
		var bp: int = _definitions[b["id"]]["priority"]
		return ap > bp if ap != bp else a["sequence"] < b["sequence"]
	)
	var remaining: Array[Dictionary] = []
	for entry: Dictionary in _pending:
		var id: String = entry["id"]
		if _has_requirements(id, context) and _group_available(id):
			_dispatch(id, "trigger", dispatched)
		else:
			remaining.append(entry)
	_pending = remaining


func _roll_chance(context: Dictionary, dispatched: Array[Dictionary]) -> void:
	var candidates: Array[Dictionary] = []
	for id: String in _ids:
		var definition: Dictionary = _definitions[id]
		if definition["activation"] == "trigger" or not _eligible(id, context) or not _group_available(id):
			continue
		var probability: float = 1.0 - exp(-float(definition["rate_per_second"]))
		if probability > 0.0 and _rng.randf() < probability:
			candidates.append({"id": id, "tie": _rng.randf()})
	# Random tie ordering avoids a lexicographic preference between equal priorities.
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ap: int = _definitions[a["id"]]["priority"]
		var bp: int = _definitions[b["id"]]["priority"]
		return ap > bp if ap != bp else a["tie"] < b["tie"]
	)
	for candidate: Dictionary in candidates:
		var id: String = candidate["id"]
		if _group_available(id):
			_dispatch(id, "chance", dispatched)


func _dispatch(id: String, source: String, dispatched: Array[Dictionary]) -> void:
	var definition: Dictionary = _definitions[id]
	var event: Dictionary = {
		"id": id, "domain": definition["domain"], "source": source,
		"payload": definition["payload"].duplicate(true)
	}
	_active[id] = event.duplicate(true)
	_seen[id] = true
	dispatched.append(event)
