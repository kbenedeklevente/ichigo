extends SceneTree

const Runtime = preload("res://game/events/encounter_runtime.gd")
const Instance = preload("res://game/events/event_instance.gd")
const Spatial = preload("res://game/events/event_spatial_index.gd")
const Modifier = preload("res://game/events/local_field_modifier.gd")
const ENV: Dictionary = {"sky": "sunny", "wind": "breeze"}
var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	_test_rates()
	_test_gate_and_quiet()
	_test_lifecycle()
	_test_fields_and_index()
	_test_local_grid()
	_test_replay()
	for failure: String in failures:
		printerr(failure)
	print("Encounter runtime: %d checks; %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

func _new(seed_value: int = 15):
	var runtime = Runtime.new()
	runtime.configure(seed_value)
	return runtime

func _start(runtime) -> void:
	_check(runtime.trigger(), "Salvage trigger accepted")
	runtime.advance(0.0, Vector2.ZERO, ENV, true)

func _test_rates() -> void:
	var expected: float = -log(0.95) / 60.0
	_check(is_equal_approx(Runtime.rate_for_environment(ENV), expected), "P60 converts to hazard")
	_check(is_equal_approx(Runtime.probability_for_rate(expected, 60.0), 0.05), "Hazard converts back to standalone P60")
	_check(Runtime.probability_for_rate(0.0, 1000.0) == 0.0, "Zero hazard stays exactly zero")
	_check(Runtime.rate_for_environment({}) == 0.0, "Unknown weather is excluded")
	for sky: String in ["sunny", "cloudy", "raincloud", "storm"]:
		for wind: String in ["calm", "breeze", "strong", "storm"]:
			_check(Runtime.rate_for_environment({"sky": sky, "wind": wind}) <= 1.0 / 240.0, "Total rate bound for " + sky + "/" + wind)
	var p1: float = Runtime.probability_for_rate(1.0 / 240.0, 1.0)
	_check(is_equal_approx(1.0 - pow(1.0 - p1, 10.0), Runtime.probability_for_rate(1.0 / 240.0, 10.0)), "Equivalent hazard across scheduling intervals")
	var runtime = _new()
	var before: String = runtime.snapshot().rng_state
	runtime.advance(100.0, Vector2.ZERO, {}, true)
	_check(runtime.snapshot().rng_state == before and runtime.get_active() == null, "Zero eligibility consumes no RNG and activates nothing")

func _test_gate_and_quiet() -> void:
	var runtime = _new()
	_check(not runtime.trigger("fish_shoal"), "Unauthored handlers excluded")
	_check(runtime.trigger(), "Trigger queues once")
	_check(not runtime.trigger(), "Duplicate queued trigger rejected")
	var before: String = runtime.snapshot().rng_state
	runtime.advance(1000.0, Vector2.ZERO, ENV, false)
	_check(runtime.get_active() == null and runtime.get_status().pending == 1, "Weather gate retains trigger")
	_check(runtime.snapshot().rng_state == before, "Blocked scheduler consumes no rolls")
	var fishing_env: Dictionary = ENV.duplicate()
	fishing_env.fishing_active = true
	runtime.advance(0.0, Vector2.ZERO, fishing_env, true)
	_check(runtime.get_active() != null and runtime.get_active().source == "trigger", "Ordinary hooked fishing is not an encounter gate")
	_check(not runtime.trigger(), "No second salvage while active")
	runtime.report_visibility(false, false)
	runtime.advance(3.0, Vector2.ZERO, ENV, false)
	_check(runtime.get_active() == null, "Active cleanup advances while admission blocked")
	_check(is_equal_approx(runtime.get_status().quiet_remaining, 90.0), "Retirement begins exact guaranteed quiet")
	_check(runtime.get_status().outcomes["salvage:1"].outcome == "abandoned", "Unresolved offscreen cleanup records abandonment, not completion")
	_check(runtime.trigger(), "Explicit trigger can wait through quiet")
	runtime.advance(89.0, Vector2.ZERO, ENV, true)
	_check(runtime.get_active() == null, "Quiet holds trigger for full duration")
	runtime.advance(1.0, Vector2.ZERO, ENV, true)
	_check(runtime.get_active() != null and runtime.get_active().id == "salvage:2", "Quiet boundary dispatches next unique instance")
	_check(runtime.get_active().source == "trigger", "Queued provenance retained")
	runtime.report_visibility(false, false)
	runtime.advance(3.0, Vector2.ZERO, ENV, true)
	before = runtime.snapshot().rng_state
	runtime.advance(90.0, Vector2.ZERO, ENV, false)
	_check(runtime.snapshot().rng_state == before and runtime.snapshot().chance_steps == 0, "Quiet advances while blocked without chance backlog")
	runtime.advance(0.5, Vector2.ZERO, ENV, true)
	_check(runtime.snapshot().rng_state == before, "First chance roll needs a full eligible second after quiet")
	runtime.advance(100.0, Vector2.ZERO, ENV, false)
	_check(runtime.snapshot().rng_state == before, "Ineligible wait consumes no partial pending roll")
	runtime.advance(0.5, Vector2.ZERO, ENV, true)
	_check(runtime.snapshot().rng_state != before, "Eligible partial seconds combine across weather holds")

func _test_lifecycle() -> void:
	var runtime = _new()
	_start(runtime)
	runtime.report_visibility(false, false)
	runtime.advance(2.9, Vector2.ZERO, ENV, true)
	_check(runtime.get_active() != null, "Looking away does not instantly retire")
	runtime.report_visibility(true, false)
	runtime.advance(0.1, Vector2.ZERO, ENV, true)
	_check(runtime.get_active().outside_age == 0.0, "Returning camera clears grace timer")
	runtime.report_visibility(false, true)
	runtime.advance(10.0, Vector2.ZERO, ENV, true)
	_check(runtime.get_active() != null, "Interaction prevents offscreen retirement")
	runtime.report_visibility(true, true)
	runtime.advance(167.0, Vector2.ZERO, ENV, true)
	_check(runtime.get_active().phase == "departing", "Departure begins at 180 seconds even during interaction")
	runtime.advance(20.0, Vector2.ZERO, ENV, true)
	_check(runtime.get_active().velocity.length() > 5.0, "Full gust salvage exceeds 2 m/s follower plus 3 m/s current")
	var active = runtime.get_active()
	var player: Vector2 = active.center - active.departure_direction * 2.0
	for i: int in range(900):
		var current: Vector2 = active.modifier.sample(player).current_delta
		player += (active.departure_direction * 2.0 + current) / 30.0
		runtime.advance(1.0 / 30.0, player, ENV, true)
	_check(active.center.distance_to(player) > active.modifier.radius, "Follower escapes finite current footprint rather than locking to encounter")
	_check(active.resolve("completed") and not active.resolve("completed"), "Outcome resolves at most once")
	_check(active.phase == "departing", "Completion does not imply retirement")
	runtime.report_visibility(false, false)
	runtime.advance(3.0, player, ENV, true)
	_check(runtime.get_status().outcomes["salvage:1"].outcome == "completed", "Retirement preserves actual completion outcome")
	_check(runtime.get_modifiers().is_empty(), "Retirement removes all local influences")

func _test_fields_and_index() -> void:
	var modifier = Modifier.new()
	modifier.origin = Vector2(3.0, -4.0)
	modifier.weight = 1.0
	modifier.wind_delta = Vector2(7.0, 0.0)
	modifier.current_delta = Vector2(3.0, 0.0)
	modifier.amplitude_delta = 0.12
	var base: Dictionary = {"wind": Vector2(2.0, 1.0)}
	var before: Dictionary = base.duplicate(true)
	for i: int in range(100):
		var effective: Vector2 = base.wind + modifier.sample(modifier.origin).wind_delta
		_check(effective == Vector2(9.0, 1.0), "Repeated composition does not accumulate")
	_check(base == before, "Sampling leaves base field intact")
	_check(modifier.sample(modifier.origin + Vector2(15.0, 0.0)).current_delta == Vector2.ZERO, "No effect outside finite local footprint")
	modifier.weight = 0.5
	_check(modifier.sample(modifier.origin).current_delta == Vector2(1.5, 0.0), "Envelope blends field linearly")
	modifier.weight = 0.0
	_check(modifier.sample(modifier.origin).wind_delta == Vector2.ZERO, "Fade to zero exactly restores base")
	var index = Spatial.new()
	index.index("large", Vector2(-1.0, -1.0), 35.0)
	_check(index.query_point(Vector2(30.0, -1.0)).has("large"), "Large bounds indexed across all covered cells")
	_check(index.query_rect(Rect2(32.0, -2.0, 4.0, 4.0)).has("large"), "Rectangle intersects bounds while center lies outside")
	_check(index.query_rect(Rect2(36.0, 2.0, -4.0, -4.0)).has("large"), "Negative rectangle extents normalize before bounds query")
	_check(index.query_point(Vector2(34.0, 34.0)).is_empty(), "Broad-phase corner false positives filtered")
	index.index("large", Vector2(200.0, 200.0), 2.0)
	_check(index.query_point(Vector2.ZERO).is_empty(), "Moving event removes old cells")
	_check(index.query_point(Vector2(200.0, 200.0)).has("large"), "Moving event inserts new cells")
	index.remove("large")
	_check(index.query_rect(Rect2(180.0, 180.0, 40.0, 40.0)).is_empty(), "Retirement clears sparse entries")

func _test_local_grid() -> void:
	var modifier = Modifier.new()
	modifier.origin = Vector2(100.0, -50.0)
	modifier.weight = 1.0
	var values: Dictionary = {"wind_x": PackedFloat64Array([0.0, 2.0, 4.0, 6.0]),
		"wind_y": PackedFloat32Array([-2.0, -2.0, -2.0, -2.0]),
		"current_x": PackedFloat64Array([2.0, 4.0, 6.0, 8.0]),
		"amplitude": PackedFloat64Array([-0.2, -0.2, -0.2, -0.2])}
	_check(modifier.configure_grid(2, 2, 2.0, Vector2(-2.0, -2.0), values), "Packed local grid accepted")
	var middle: Vector2 = Vector2(99.0, -51.0)
	var sampled: Dictionary = modifier.sample(middle)
	_check(sampled.wind_delta == Vector2(3.0, -2.0), "Local world transform and bilinear wind interpolation")
	_check(sampled.current_delta == Vector2(5.0, 0.0), "Missing grid channels default to zero")
	_check(is_equal_approx(sampled.amplitude_delta, -0.2), "Signed scalar allows subtractive amplitude composition")
	values.wind_x[0] = 1000.0
	_check(modifier.sample(middle) == sampled, "Grid copies incoming arrays")
	_check(modifier.sample(Vector2(96.9, -51.0)).wind_delta == Vector2.ZERO, "Grid has no influence outside finite cell footprint")
	_check(modifier.get_bounds() == Rect2(97.0, -53.0, 4.0, 4.0), "Grid bounds include full outer cells")
	_check(not modifier.configure_grid(2, 2, 0.0, Vector2.ZERO, values), "Zero grid cell size rejected")
	_check(not modifier.configure_grid(2, 2, 2.0, Vector2.ZERO, {"wind_x": PackedFloat64Array([1.0])}), "Wrong grid channel length rejected")
	_check(modifier.sample(middle) == sampled, "Rejected grid configurations leave source intact")
	modifier.weight = 0.5
	_check(modifier.sample(middle).wind_delta == Vector2(1.5, -1.0), "Grid uses shared fade envelope")
	modifier.origin += Vector2(8.0, 12.0)
	_check(modifier.sample(middle + Vector2(8.0, 12.0)).wind_delta == Vector2(1.5, -1.0), "Grid travels with logical event origin")
	modifier.clear_grid()
	modifier.wind_delta = Vector2(4.0, 0.0)
	_check(modifier.sample(modifier.origin).wind_delta == Vector2(2.0, 0.0), "Clearing grid restores analytic sampler")

func _test_replay() -> void:
	var a = _new(99)
	var b = _new(99)
	a.advance(10000.25, Vector2.ZERO, ENV, true)
	for i: int in range(40001):
		b.advance(0.25, Vector2.ZERO, ENV, true)
	_check(a.snapshot() == b.snapshot(), "Fixed seeded rolls and physics independent of frame partition")
	_check(a.get_active() != null and a.get_active().source == "chance", "Seeded long run exercises chance activation")
	a.report_visibility(false, true)
	a.advance(0.1, Vector2.ZERO, ENV, false)
	var saved: Dictionary = a.snapshot()
	b = _new(888)
	_check(b.restore(saved), "Active native snapshot restores")
	_check(a.snapshot() == b.snapshot(), "All active fields and RNG replay exactly")
	_check(a.get_modifiers()[0].sample(a.get_active().center) == b.get_modifiers()[0].sample(b.get_active().center), "Derived modifiers restore consistently")
	a.report_visibility(false, false)
	a.advance(1.0, Vector2.ZERO, ENV, true)
	_check(b.restore(a.snapshot()), "Snapshot preserves partially faded modifier")
	_check(a.get_modifiers()[0].sample(a.get_active().center) == b.get_modifiers()[0].sample(b.get_active().center), "Fade envelope restored at same physics instant")
	for runtime in [a, b]:
		runtime.report_visibility(false, false)
		runtime.advance(3.0, Vector2.ZERO, ENV, true)
		runtime.advance(90.0, Vector2.ZERO, ENV, true)
		runtime.advance(1500.0, Vector2.ZERO, ENV, true)
	_check(a.snapshot() == b.snapshot(), "Retirement ledger and later random encounter replay")
	var before: Dictionary = b.snapshot()
	for field: String in ["accumulator", "quiet_remaining", "next_ordinal", "active", "pending", "rng_state"]:
		var bad: Dictionary = saved.duplicate(true)
		bad[field] = null
		_check(not b.restore(bad), "Malformed snapshot rejects " + field)
		_check(before == b.snapshot(), "Rejected restore is atomic for " + field)
	var bad: Dictionary = saved.duplicate(true)
	bad.active.outside_age = 3.0
	_check(not b.restore(bad), "Already retired active state rejected")
	a.advance(-1.0, Vector2.ZERO, ENV, true)
	a.advance(NAN, Vector2.ZERO, ENV, true)
	_check(a.snapshot() == before, "Invalid time leaves state unchanged")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append("FAIL: " + message)
