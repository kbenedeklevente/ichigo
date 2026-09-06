extends SceneTree
const Scheduler = preload("res://game/events/environment_scheduler.gd")
const Chance = preload("res://game/events/event_chance.gd")
const Catalog = preload("res://game/events/event_catalog.gd")
const Runtime = preload("res://game/events/environment_runtime.gd")
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	_rates()
	_prerequisites_and_cooldowns()
	_capacity_and_pairs()
	_bypass_and_fairness()
	_replay_and_chance()
	_runtime_pair()
	if failures.is_empty():
		print("PASS: %d scheduler/chance checks." % checks)
		quit(0)
	else:
		printerr("FAIL: %s" % failures)
		quit(1)

func _check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)

func _context(stage: String = "idle") -> Dictionary:
	return {"sky": "sunny", "wind_intensity": 0.0, "day_phase": 0.25, "weather_stage": stage, "encounters_enabled": true, "flags": []}

func _definition(id: String, domain: String, rate: float = 0.0) -> Dictionary:
	return {"id": id, "domain": domain, "activation": "both", "base_rate_per_second": rate,
		"wind_time_weights": Chance.uniform_table(), "sky_weights": {"sunny": 1.0, "cloudy": 1.0, "raincloud": 1.0, "storm": 1.0},
		"eligibility": {}, "payload": {"sky": "cloudy", "wind": "breeze"} if domain == "weather" else {"handler": "salvage"}}

func _scheduler():
	var scheduler = Scheduler.new()
	_check(scheduler.configure([_definition("w1", "weather"), _definition("w2", "weather"), _definition("w3", "weather"), _definition("e1", "encounter"), _definition("e2", "encounter")], 15), "Valid definitions configure atomically.")
	return scheduler

func _rates() -> void:
	var definition: Dictionary = _definition("example", "encounter", 0.001)
	definition.wind_time_weights = [[0.0, 1.0, 2.0, 3.0], [1.0, 2.0, 3.0, 4.0], [2.0, 3.0, 4.0, 5.0], [3.0, 4.0, 5.0, 6.0]]
	var context: Dictionary = _context()
	context.wind_intensity = 1.5
	context.day_phase = 0.375
	_check(is_equal_approx(Chance.evaluate(definition, context).rate, 0.003), "Wind and time interpolate across four anchors.")
	context.wind_intensity = 0.0
	context.day_phase = 0.875
	_check(is_equal_approx(Chance.evaluate(definition, context).rate, 0.0015), "Night wraps continuously back to dawn.")
	definition.eligibility = {"excluded_time_ranges": [[0.8, 0.1]]}
	_check(Chance.evaluate(definition, context).rate == 0.0, "Hard night interval overrides positive interpolated weight.")
	context.day_phase = 0.05
	_check(Chance.evaluate(definition, context).rate == 0.0, "Wrapped hard interval excludes both sides of midnight.")
	definition.eligibility = {"wind_max": 1.0, "requires": ["tool"]}
	context = _context()
	_check(Chance.evaluate(definition, context).reason == "missing:tool", "Capability prerequisites explain rejection.")
	context.flags = ["tool"]
	context.wind_intensity = 1.01
	_check(Chance.evaluate(definition, context).rate == 0.0, "Hard wind boundary stays zero despite soft table.")
	definition.eligibility = {}
	context = _context()
	definition.sky_weights.cloudy = 0.0
	context.sky_mix = {"sunny": 0.25, "cloudy": 0.75}
	_check(is_equal_approx(Chance.evaluate(definition, context).rate, 0.00025), "Local sky mix changes rate independently of wind.")
	var invalid: Dictionary = definition.duplicate(true)
	invalid.wind_time_weights[0][0] = NAN
	_check(not Chance.validate(invalid), "Nonfinite authoring values are rejected.")
	invalid = definition.duplicate(true)
	invalid.wind_time_weights.pop_back()
	_check(not Chance.validate(invalid), "Malformed matrix dimensions are rejected.")
	_check(Chance.probability(0.0, 5.0) == 0.0, "Zero hazard remains impossible.")
	_check(is_equal_approx(pow(1.0 - Chance.probability(0.003, 1.0), 5), 1.0 - Chance.probability(0.003, 5.0)), "Equivalent eligible durations preserve constant-rate probability.")
	var salvage: Dictionary = Catalog.scheduler_definitions().back()
	for sky: String in ["sunny", "cloudy", "raincloud", "storm"]:
		for wind: int in range(4):
			context = _context()
			context.sky = sky
			context.wind_intensity = wind
			var legacy: float = preload("res://game/events/encounter_runtime.gd").rate_for_environment({"sky": sky, "wind": ["calm", "breeze", "strong", "storm"][wind]})
			_check(is_equal_approx(Chance.evaluate(salvage, context).rate, legacy), "Existing salvage rate preserved at %s/%d." % [sky, wind])

func _prerequisites_and_cooldowns() -> void:
	var definition: Dictionary = _definition("gated", "encounter")
	definition.eligibility = {"requires": ["puzzle_evidence"]}
	definition.cooldown_seconds = 5.0
	var scheduler = Scheduler.new()
	_check(scheduler.configure([definition]), "Prerequisite definition validates.")
	var context: Dictionary = _context()
	_check(not scheduler.trigger("gated", context), "Explicit trigger does not bypass missing prerequisites.")
	context.flags = ["puzzle_evidence"]
	_check(scheduler.trigger("gated", context), "Explicit request accepts present prerequisite.")
	_check(scheduler.advance(1.0, _context()).is_empty(), "Queued request waits when its prerequisite is withdrawn.")
	_check(scheduler.advance(0.0, context).size() == 1, "Queued request starts when prerequisite returns.")
	scheduler.finish_encounter()
	_check(not scheduler.trigger("gated", context), "Definition cooldown starts at handler finish.")
	scheduler.advance(5.0, context)
	_check(scheduler.trigger("gated", context), "Expired cooldown permits waiting during quiet time.")
	_check(scheduler.advance(0.0, context).is_empty(), "Explicit encounter cannot bypass quiet time.")
	_check(scheduler.advance(85.0, context).size() == 1, "Pending encounter starts after quiet expires.")
	definition.once = true
	scheduler.configure([definition])
	scheduler.trigger("gated", context)
	scheduler.advance(0.0, context)
	scheduler.finish_encounter()
	scheduler.advance(100.0, context)
	_check(not scheduler.trigger("gated", context), "Once-only opportunity cannot be triggered twice.")
	var invalid: Dictionary = _definition("bad", "weather")
	invalid.payload.approach_s = 0.0
	var before: Dictionary = scheduler.snapshot()
	_check(not scheduler.configure([invalid]) and scheduler.snapshot() == before, "Invalid handler payload cannot partially replace catalog/state.")

func _capacity_and_pairs() -> void:
	var scheduler = _scheduler()
	var context: Dictionary = _context()
	_check(scheduler.submit("a", "w1") == "accepted", "First weather request accepted.")
	_check(scheduler.advance(0.0, context).size() == 1, "First weather is allocated.")
	_check(scheduler.submit("b", "w2") == "accepted", "One waiting weather accepted behind active.")
	var saved: Dictionary = scheduler.snapshot()
	_check(scheduler.submit("c", "w3") == "full", "Third weather rejected: two total includes active.")
	_check(scheduler.snapshot() == saved, "Full rejection leaves queue and sequence untouched.")
	_check(scheduler.submit_story("pair", "w3", "e1") == "full", "Linked request also obeys weather capacity.")
	_check(scheduler.encounter_owner.is_empty() and scheduler.snapshot() == saved, "Rejected pair cannot allocate an encounter half.")
	_check(scheduler.submit_story("bad", "w3", "") == "invalid", "Main story requires both payloads.")
	_check(scheduler.submit("b", "w3") == "duplicate", "Request IDs deduplicate retries.")
	_check(scheduler.finish_weather(), "Finishing releases one weather slot.")
	_check(scheduler.weather_count() == 1, "Pending weather remains counted after release.")
	_check(scheduler.cancel("b") and scheduler.weather_count() == 0, "Pending cancellation releases capacity.")
	scheduler = _scheduler()
	scheduler.submit("current", "w1", "e1")
	scheduler.advance(0.0, context)
	scheduler.advance(0.0, _context("hold"))
	_check(scheduler.submit_story("next", "w1", "e1") == "accepted", "Distinct story request may wait for the same weather/encounter definitions already active.")
	var repeated = _scheduler()
	_check(repeated.restore(scheduler.snapshot()), "Pending repeat definitions restore with distinct request identities.")
	_check(scheduler.advance(0.0, _context("hold")).is_empty(), "Repeated pair waits without partial ownership or preemption.")
	scheduler = _scheduler()
	_check(scheduler.submit_story("pair", "w1", "e1") == "accepted", "Valid pair admitted once.")
	var commands: Array = scheduler.advance(0.0, context)
	_check(commands.size() == 1 and commands[0].kind == "start_weather", "Pair starts only its weather during preparation.")
	_check(scheduler.weather_owner == "pair" and scheduler.encounter_owner == "pair", "Pair acquires both tracks atomically.")
	_check(scheduler.advance(1.0, _context("approach")).is_empty(), "Encounter waits throughout weather approach.")
	commands = scheduler.advance(0.0, _context("hold"))
	_check(commands.size() == 1 and commands[0].kind == "start_encounter", "Established weather starts the reserved encounter.")
	_check(scheduler.advance(1.0, _context("hold")).is_empty(), "No duplicate encounter activation.")
	_check(scheduler.finish_encounter("abandoned"), "Encounter reports its actual outcome.")
	_check(scheduler.encounter_owner.is_empty() and scheduler.weather_owner == "pair", "Weather retains its tail after encounter departure.")
	_check(scheduler.quiet_remaining == 90.0, "Departure starts exactly the approved quiet interval.")
	scheduler.finish_weather()
	_check(scheduler.snapshot().completed.pair.outcome == "abandoned", "Pair completion does not invent puzzle success.")

func _bypass_and_fairness() -> void:
	var scheduler = _scheduler()
	scheduler.submit("active-weather", "w1")
	scheduler.advance(0.0, _context())
	scheduler.submit("waiting-weather", "w2")
	scheduler.submit("ordinary", "", "e1")
	var commands: Array = scheduler.advance(0.0, _context("hold"))
	_check(commands.size() == 1 and commands[0].id == "e1", "Ordinary encounter safely bypasses a blocked weather request.")
	_check(scheduler.advance(1.0, _context("hold")).is_empty(), "An occupied encounter cannot be preempted.")
	scheduler = _scheduler()
	scheduler.submit("active-weather", "w1")
	scheduler.advance(0.0, _context())
	scheduler.submit_story("story", "w2", "e1")
	scheduler.submit("ordinary", "", "e2")
	_check(scheduler.advance(0.0, _context("hold")).is_empty(), "Waiting viable story pair prevents refill starvation.")
	scheduler.finish_weather()
	commands = scheduler.advance(0.0, _context())
	_check(commands.size() == 1 and commands[0].request_id == "story", "Drained tracks go to the waiting story pair.")
	_check(scheduler.cancel("story"), "Preparation can be cancelled.")
	_check(scheduler.encounter_owner.is_empty() and scheduler.weather_owner == "story", "Cancelled preparation releases only unstarted encounter; weather clears normally.")
	_check(scheduler.advance(1.0, _context("approach")).is_empty(), "Cancellation does not leak an encounter into transition.")
	var cancelled_copy = _scheduler()
	_check(cancelled_copy.restore(scheduler.snapshot()), "Cancelled preparation with a weather tail restores.")
	scheduler.finish_weather()
	_check(scheduler.snapshot().completed.story.outcome == "cancelled", "Cancelled pair never becomes completed story.")
	scheduler = _scheduler()
	scheduler.submit("weather", "w1")
	scheduler.submit("encounter", "", "e1")
	commands = scheduler.advance(0.0, _context())
	_check(commands.size() == 1 and commands[0].kind == "start_weather", "Same-tick stale idle context cannot admit an encounter after weather start.")

func _replay_and_chance() -> void:
	var scheduler = _scheduler()
	scheduler.submit_story("pair", "w1", "e1")
	scheduler.advance(0.1, _context())
	var saved: Dictionary = scheduler.snapshot()
	var other = _scheduler()
	_check(other.restore(saved), "Preparation reservation restores.")
	_check(other.advance(0.1, _context("hold")) == scheduler.advance(0.1, _context("hold")), "Restored pair emits the same single encounter command.")
	_check(other.snapshot() == scheduler.snapshot(), "Pair state replays deterministically.")
	var invalid: Dictionary = saved.duplicate(true)
	invalid.encounter_owner = ""
	var before: Dictionary = other.snapshot()
	_check(not other.restore(invalid) and other.snapshot() == before, "Partial ownership snapshot rejected atomically.")
	invalid = saved.duplicate(true)
	invalid.active.pair.phase = "weather"
	_check(not other.restore(invalid) and other.snapshot() == before, "Invalid paired phase cannot restore a permanent reservation deadlock.")
	var definitions: Array[Dictionary] = [_definition("a", "encounter", 0.01), _definition("b", "encounter", 0.03)]
	scheduler = Scheduler.new()
	scheduler.configure(definitions, 123)
	scheduler.advance(0.5, _context())
	_check(is_equal_approx(scheduler.get_status().debug.encounter.limited_total, 1.0 / 240.0), "Combined encounter hazard is capped, not per-event rolls.")
	other = Scheduler.new()
	other.configure(definitions, 123)
	_check(other.restore(scheduler.snapshot()), "Partial integrated chance tick restores.")
	_check(scheduler.advance(0.5, _context()) == other.advance(0.5, _context()), "Restored hazard/RNG reproduces choice.")
	var rng_before: String = scheduler.snapshot().rng_state
	var blocked: Dictionary = _context("approach")
	scheduler.advance(40.0, blocked)
	_check(scheduler.snapshot().rng_state == rng_before and scheduler.snapshot().pending.is_empty(), "Blocked time neither rolls nor creates backlog.")
	_check(scheduler.snapshot().clocks.encounter == 0.0 and scheduler.snapshot().hazards.encounter.is_empty(), "Blocked intervals discard stale chance accumulation.")
	# Distribution sanity check across a catalog with unequal weights. No physics
	# or quiet intervals in this isolated test of the selector itself.
	scheduler.configure(definitions, 456)
	var counts := {"a": 0, "b": 0}
	for tick: int in range(30000):
		for command: Dictionary in scheduler.advance(1.0, _context()):
			counts[command.id] += 1
			scheduler.finish_encounter()
			scheduler.quiet_remaining = 0.0
	var total: int = counts.a + counts.b
	_check(total > 80 and total < 180, "Observed frequency respects aggregate mean with seeded statistical tolerance.")
	_check(float(counts.b) / maxf(total, 1) > 0.6 and float(counts.b) / maxf(total, 1) < 0.9, "Selection favors the three-times-weight candidate without priority bias.")

func _runtime_pair() -> void:
	var runtime = Runtime.new()
	runtime.configure(15, true)
	runtime.scheduler.chance_enabled = false
	runtime.weather.render_radius = 1
	runtime.weather.simulation_radius = 3
	runtime.weather.configure(104744)
	_check(runtime.submit_story("fixture", "weather.mix.cloudy.breeze", "salvage") == "accepted", "Real handlers accept paired fixture through runtime API.")
	runtime.advance(1.0, Vector2.ZERO)
	_check(runtime.weather.get_status().stage == "approach" and not runtime.weather.get_status().transition_held, "Reserved encounter does not freeze weather approach.")
	var restored = Runtime.new()
	_check(restored.restore(runtime.snapshot()), "Real preparing weather/encounter snapshot restores consistently.")
	runtime.advance(12.0, Vector2.ZERO)
	restored.advance(12.0, Vector2.ZERO)
	_check(runtime.snapshot() == restored.snapshot(), "Pair replay across established boundary is identical.")
	_check(runtime.encounters.get_active() != null and runtime.weather.get_status().stage == "hold", "Real encounter starts after approach.")
	var live_copy = Runtime.new()
	_check(live_copy.restore(runtime.snapshot()), "Active linked encounter restores both owners and weather hold.")
	var before_modifier: Dictionary = runtime.weather.chance_context(Vector2.ZERO)
	var modifier = preload("res://game/events/local_field_modifier.gd").new()
	modifier.weight = 1.0
	modifier.origin = Vector2.ZERO
	modifier.wind_delta = Vector2(4, 0)
	runtime.weather.set_event_modifiers([modifier])
	_check(runtime.weather.chance_context(Vector2.ZERO) == before_modifier, "Local departure-like gust does not feed back into chance weather sampling.")
	runtime.weather.set_event_modifiers([])
	var elapsed: float = runtime.weather.get_status().elapsed
	runtime.advance(30.0, Vector2.ZERO)
	_check(is_equal_approx(runtime.weather.get_status().elapsed, elapsed), "Real encounter freezes macro transitions, not the approach reservation.")
	runtime.encounters.get_active().resolve("abandoned")
	runtime.encounters.report_visibility(false, false)
	runtime.advance(3.1, Vector2.ZERO)
	_check(runtime.encounters.get_active() == null and runtime.scheduler.quiet_remaining > 89.0, "Retirement releases scheduler encounter track and starts quiet time.")
	_check(not runtime.weather.get_status().transition_held, "Departure releases the weather handler hold.")
	var tail_copy = Runtime.new()
	_check(tail_copy.restore(runtime.snapshot()), "Weather tail and scheduler-owned quiet period restore together.")
	runtime.advance(32.0, Vector2.ZERO)
	_check(not runtime.weather.get_status().active and runtime.scheduler.weather_count() == 0, "Linked weather finishes clearing and falls back to calm.")
	_check(runtime.scheduler.snapshot().completed.fixture.outcome == "abandoned", "Handler outcome survives paired completion.")
