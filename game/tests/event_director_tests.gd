extends SceneTree

const Director = preload("res://game/events/event_director.gd")
const Catalog = preload("res://game/events/event_catalog.gd")
var checks: int = 0
var failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_admission_and_lifecycle()
	_test_priority_and_queue()
	_test_ticks_and_seed()
	_test_no_chance_backlog()
	_test_competing_chance()
	_test_save_and_restore()
	_test_catalog()
	for failure: String in failures:
		printerr(failure)
	print("Event director: %d checks; %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


func _definition(id: String, activation: String = "both", group: String = "", priority: int = 0) -> Dictionary:
	return {"id": id, "domain": "fixture", "activation": activation,
		"rate_per_second": 100.0, "cooldown_seconds": 2.0, "once": false,
		"requires": [], "payload": {"nested": {"value": 2}},
		"priority": priority, "exclusive_group": group}


func _new(definitions: Array[Dictionary], seed_value: int = 55) -> RefCounted:
	var director := Director.new()
	director.configure(definitions, seed_value)
	return director


func _test_admission_and_lifecycle() -> void:
	var definition: Dictionary = _definition("story", "trigger")
	definition["requires"] = ["discovery"]
	definition["once"] = true
	var director: RefCounted = _new([definition, _definition("repeat", "trigger")])
	_check(not director.trigger("missing"), "Unknown IDs rejected")
	_check(not director.trigger("story"), "Trigger cannot bypass prerequisite")
	var context: Dictionary = {"flags": ["discovery"]}
	_check(director.trigger("story", context), "Eligible trigger admitted")
	_check(not director.trigger("story", context), "Duplicate pending trigger rejected")
	_check(director.advance(0.0).is_empty(), "Pending trigger waits if prerequisite withdrawn")
	var events: Array[Dictionary] = director.advance(0.0, context)
	_check(events.size() == 1 and events[0]["source"] == "trigger", "Trigger retains provenance")
	events[0]["payload"]["nested"]["value"] = 99
	_check(director.snapshot()["active"]["story"]["payload"]["nested"]["value"] == 2, "Dispatch payload cannot mutate internal state")
	_check(director.advance(20.0, context).is_empty(), "Active event does not auto complete")
	_check(not director.trigger("story", context), "Active trigger duplicate rejected")
	_check(director.finish("story", "declined"), "Owning system supplies outcome")
	_check(not director.finish("story"), "Already finished event cannot complete twice")
	_check(not director.trigger("story", context), "Once applies even after non-completed outcome")
	_check(director.trigger("repeat"), "Repeatable trigger admitted")
	director.advance(0.0)
	director.advance(0.25)
	director.finish("repeat")
	_check(not director.trigger("repeat"), "Cooldown starts at finish")
	director.advance(1.99)
	_check(not director.trigger("repeat"), "Fractional cooldown boundary respected")
	director.advance(0.01)
	_check(director.trigger("repeat"), "Cooldown expires at exact boundary")


func _test_priority_and_queue() -> void:
	var director: RefCounted = _new([
		_definition("first", "trigger", "weather"),
		_definition("second", "trigger", "weather"),
		_definition("story", "trigger", "weather", 10),
		_definition("independent", "trigger", "other")])
	for id: String in ["first", "second", "story", "independent"]:
		_check(director.trigger(id), "Queue admits " + id)
	var events: Array[Dictionary] = director.advance(0.0)
	_check(events.size() == 2 and events[0]["id"] == "story", "Priority wins lock; independent group proceeds")
	_check(director.snapshot()["pending"].size() == 2, "Blocked explicit triggers retained")
	director.finish("story")
	events = director.advance(0.0)
	_check(events.size() == 1 and events[0]["id"] == "first", "Equal priority explicit triggers preserve FIFO")
	director.finish("first")
	events = director.advance(0.0)
	_check(events.size() == 1 and events[0]["id"] == "second", "Next queued trigger dispatches after release")
	var many: Array[Dictionary] = []
	for i: int in range(70):
		many.append(_definition("bounded%d" % i, "trigger"))
	director = _new(many)
	for i: int in range(64):
		_check(director.trigger("bounded%d" % i), "Bounded queue retains admitted request %d" % i)
	_check(not director.trigger("bounded64"), "Queue overflow explicitly rejected")
	_check(director.advance(0.0).size() == 64, "Active budget obeyed")
	_check(director.trigger("bounded64"), "Trigger can queue behind active capacity")
	_check(director.advance(0.0).is_empty(), "Active count never exceeds budget")
	director.finish("bounded0")
	_check(director.advance(0.0).size() == 1, "Capacity release admits queued request")


func _test_ticks_and_seed() -> void:
	var definitions: Array[Dictionary] = []
	for i: int in range(12):
		var definition: Dictionary = _definition("chance%d" % i, "chance")
		definition["rate_per_second"] = 0.1
		definitions.append(definition)
	var a: RefCounted = _new(definitions, 90210)
	var b: RefCounted = _new(definitions, 90210)
	_check(not a.trigger("chance0"), "Chance-only definition rejects explicit trigger")
	var large: Array[Dictionary] = a.advance(20.25)
	var small: Array[Dictionary] = []
	for i: int in range(81):
		small.append_array(b.advance(0.25))
	_check(large == small, "Seeded dispatch sequence independent of timestep partition")
	_check(a.snapshot() == b.snapshot(), "All scheduler state independent of timestep partition")
	for event: Dictionary in large:
		_check(event["source"] == "chance", "Chance retains provenance")
	var before: Dictionary = a.snapshot()
	_check(a.advance(-1.0).is_empty() and a.advance(NAN).is_empty(), "Invalid time inputs rejected")
	_check(before == a.snapshot(), "Invalid advance does not mutate state")
	# Repeatable cooldown with a noninteger finish timestamp must not expire early
	# when a later advance batches many fixed chance ticks.
	var timed: Dictionary = _definition("timed", "both")
	var c: RefCounted = _new([timed], 81)
	var d: RefCounted = _new([timed], 81)
	for director: RefCounted in [c, d]:
		director.trigger("timed")
		director.advance(0.25)
		director.finish("timed")
	c.advance(4.0)
	for i: int in range(16):
		d.advance(0.25)
	_check(c.snapshot() == d.snapshot(), "Cooldown and RNG remain partition independent after fractional finish")
	var e: RefCounted = _new([timed])
	e.trigger("timed")
	e.advance(0.25)
	e.finish("timed")
	_check(e.advance(2.0).is_empty(), "Fixed chance ticks cannot see future cooldown expiry in a batch")
	_check(e.advance(0.75).size() == 1, "Chance resumes at first tick after actual cooldown")


func _test_no_chance_backlog() -> void:
	var director: RefCounted = _new([
		_definition("blocker", "trigger", "weather"),
		_definition("chance", "chance", "weather")])
	director.trigger("blocker")
	director.advance(0.0)
	var rng_before: String = director.snapshot()["rng_state"]
	_check(director.advance(1000.0).is_empty(), "Blocked chance creates no dispatches")
	_check(director.snapshot()["pending"].is_empty(), "Blocked chance creates no backlog")
	_check(director.snapshot()["rng_state"] == rng_before, "Blocked chance does not consume rolls")
	director.finish("blocker")
	_check(director.advance(0.0).is_empty(), "Unlock does not flush stale chance proposals")
	var events: Array[Dictionary] = director.advance(1.0)
	_check(events.size() == 1 and events[0]["source"] == "chance", "Chance gets fresh roll on next fixed tick")


func _test_competing_chance() -> void:
	var winners: Dictionary = {"a": 0, "b": 0}
	var definitions: Array[Dictionary] = [
		_definition("a", "chance", "shared"),
		_definition("b", "chance", "shared"),
		_definition("story", "trigger", "shared", 20)]
	for seed_value: int in range(40):
		var director: RefCounted = _new(definitions, seed_value)
		var events: Array[Dictionary] = director.advance(1.0)
		_check(events.size() == 1, "Exclusive chance group produces exactly one event")
		winners[events[0]["id"]] += 1
	_check(winners["a"] > 5 and winners["b"] > 5, "Equal-priority chance candidates do not always favor first ID")
	var director: RefCounted = _new(definitions)
	director.trigger("story")
	var events: Array[Dictionary] = director.advance(1.0)
	_check(events.size() == 1 and events[0]["id"] == "story", "Queued story trigger takes priority over fresh chance")


func _test_save_and_restore() -> void:
	var definitions: Array[Dictionary] = [
		_definition("active", "trigger", "group"),
		_definition("pending", "trigger", "group"),
		_definition("roll", "chance", "group")]
	var a: RefCounted = _new(definitions)
	a.trigger("active")
	a.advance(0.0)
	a.trigger("pending")
	a.advance(2.375)
	var saved: Dictionary = JSON.parse_string(JSON.stringify(a.snapshot()))
	var b: RefCounted = _new(definitions, 888)
	_check(b.restore(saved), "JSON roundtrip snapshot restored")
	_check(a.snapshot() == b.snapshot(), "Active, pending, clock and RNG restored exactly")
	for director: RefCounted in [a, b]:
		director.finish("active", "solved")
	_check(a.advance(0.0) == b.advance(0.0), "Pending dispatch replays after restore")
	for director: RefCounted in [a, b]:
		director.finish("pending", "bypassed")
	_check(a.advance(10.0) == b.advance(10.0), "Chance continuation replays after restore")
	_check(a.snapshot() == b.snapshot(), "Full continuation state matches")
	var invalid: Dictionary = saved.duplicate(true)
	invalid["catalog"] = "wrong"
	var before: Dictionary = b.snapshot()
	_check(not b.restore(invalid), "Incompatible catalog rejected")
	invalid = saved.duplicate(true)
	invalid["pending"].append(invalid["pending"][0].duplicate(true))
	_check(not b.restore(invalid), "Duplicate pending state rejected")
	invalid = saved.duplicate(true)
	invalid["remainder"] = 1.5
	_check(not b.restore(invalid), "Invalid fixed-step fraction rejected")
	_check(b.snapshot() == before, "Rejected restores are atomic")
	var detached: Dictionary = b.snapshot()
	detached["active"].clear()
	_check(not b.snapshot()["active"].is_empty(), "Snapshots cannot mutate live state")


func _test_catalog() -> void:
	var definitions: Array[Dictionary] = Catalog.default_definitions()
	_check(definitions.size() == 24, "Sixteen mixed conditions and eight single-axis debug entries")
	var mixes: Dictionary = {}
	for definition: Dictionary in definitions:
		if str(definition["id"]).begins_with("weather.mix."):
			_check(definition["payload"].size() == 2, "Mixed weather explicitly specifies both axes")
			_check(definition["activation"] == "both", "Mixed weather supports either activation source")
			_check(is_equal_approx(definition["rate_per_second"], 1.0 / 960.0), "Mixed weather uses equal provisional chance rate")
			_check(definition["cooldown_seconds"] == 120.0, "Mixed weather retains per-definition cooldown")
			mixes[definition["id"]] = definition["payload"]
		else:
			_check(definition["payload"].size() == 1, "Debug convenience changes one weather axis")
			_check(definition["activation"] == "trigger", "Single-axis debug entry never rolls automatically")
			_check(definition["rate_per_second"] == 0.0, "Single-axis debug entry has zero chance rate")
	_check(mixes.size() == 16, "All sixteen weather combinations have unique IDs")
	for sky: String in ["sunny", "cloudy", "raincloud", "storm"]:
		for wind: String in ["calm", "breeze", "strong", "storm"]:
			var id: String = "weather.mix.%s.%s" % [sky, wind]
			_check(mixes.get(id) == {"sky": sky, "wind": wind}, "Independent combination available: " + id)
	var director: RefCounted = _new(definitions)
	_check(director.trigger("weather.sky.sunny"), "Known sunny debug trigger available")
	_check(director.trigger("weather.wind.storm"), "Known storm wind trigger independent of sky")
	director = _new(definitions)
	_check(director.trigger("weather.mix.raincloud.strong"), "Mixed incoming rain and strong wind trigger available")
	var triggered: Array[Dictionary] = director.advance(0.0)
	_check(triggered.size() == 1 and triggered[0]["source"] == "trigger" and triggered[0]["payload"] == {"sky": "raincloud", "wind": "strong"}, "Mixed trigger dispatch preserves both targets and provenance")
	director = _new(definitions)
	var rolled: Array[Dictionary] = director.advance(3600.0)
	_check(rolled.size() == 1 and rolled[0]["source"] == "chance", "Catalog chance event stays active until finished")
	_check(str(rolled[0]["id"]).begins_with("weather.mix.") and rolled[0]["payload"].has_all(["sky", "wind"]), "Chance selects a complete mixed condition")


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append("FAIL: " + message)
