extends SceneTree
const Weather = preload("res://game/world/weather_simulation.gd")
const Runtime = preload("res://game/events/environment_runtime.gd")
const Scheduler = preload("res://game/events/environment_scheduler.gd")
const Catalog = preload("res://game/events/event_catalog.gd")
var checks := 0
var failures: Array[String] = []
func _initialize() -> void:
	_test_event()
	_test_override()
	_test_scheduler()
	_test_queued_mode()
	for failure in failures:
		printerr(failure)
	print("Instant weather: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
func _weather():
	var w = Weather.new()
	w.render_radius = 1
	w.simulation_radius = 3
	w.configure(15)
	return w
func _runtime():
	var r = Runtime.new()
	r.configure(15, true)
	r.scheduler.chance_enabled = false
	r.weather = _weather()
	return r
func _test_event() -> void:
	var w = _weather()
	w.advance(0.5, Vector2.ZERO)
	var before: Dictionary = w.snapshot()
	_check(not w.start_event({"instant": "yes"}), "Reject malformed instant policy")
	_check(w.snapshot() == before, "Bad policy is atomic")
	var point := Vector2(-40, 24)
	_check(w.start_event({"sky": "storm", "wind": "storm", "instant": true, "hold_s": 0.5}, point), "Instant event starts")
	_check(w.get_status().stage == "hold" and w.get_status().center == point, "Instant event establishes over current player")
	_check(w.get_status().phase == before.phase and w.get_status().simulation_time == before.clock, "Snap preserves time and phase")
	var local: Dictionary = w.sample(point)
	_check(is_equal_approx(local.rain, 1.0) and is_equal_approx(local.cloud_cover, 1.0), "Sky fields snap at arrival")
	_check(is_equal_approx(local.wind_strength, 9.0) and is_equal_approx(local.amplitude, 0.78) and is_equal_approx(local.wave_speed, 2.5), "Wind, amplitude and speed snap together")
	_check(not w.start_event({"instant": true}), "Instant does not preempt active weather")
	w.set_transition_hold(true)
	w.advance(0.6, point)
	_check(w.get_status().active and w.get_status().stage == "hold", "Encounter lock holds instant weather")
	var saved: Dictionary = w.snapshot()
	var copy = _weather()
	_check(copy.restore(saved), "Instant event restores")
	w.set_transition_hold(false)
	copy.set_transition_hold(false)
	w.advance(0.5, point)
	copy.advance(0.5, point)
	_check(w.snapshot() == copy.snapshot(), "Instant hold/exit replays deterministically")
	_check(not w.get_status().active and is_equal_approx(w.sample(point).rain, 0.0), "Instant exit skips clear and snaps baseline")
	_check(is_equal_approx(w.sample(point).amplitude, 0.12), "Instant exit removes residual storm amplitude")
	var normal = _weather()
	_check(normal.start_event({"wind": "storm"}) and normal.get_status().stage == "approach", "Normal events still approach")
	_check(is_equal_approx(normal.sample(Vector2.ZERO).wind_strength, 0.12), "Normal wind response remains gradual")
	var old: Dictionary = normal.snapshot()
	old.erase("instant")
	_check(_weather().restore(old), "Earlier snapshots default to gradual")
func _test_override() -> void:
	var r = _runtime()
	r.trigger_weather("sky", "storm")
	r.advance(1.0/30, Vector2.ZERO)
	r.trigger_weather("wind", "strong")
	_check(r.scheduler.weather_count() == 2, "Fixture has active plus waiting weather")
	r.weather_change_mode = Runtime.WeatherChangeMode.REPLACE_NOW
	var before: Dictionary = r.weather.snapshot()
	_check(r.trigger_weather("wind", "calm"), "Lab replaces current weather")
	_check(r.scheduler.weather_count() == 0 and r.active_weather_id.is_empty(), "Lab clears current and pending weather ownership")
	_check(r.weather.get_status().stage == "idle", "Lab sets established baseline without a lifecycle")
	_check(r.weather.snapshot().clock == before.clock and r.weather.snapshot().phase == before.phase, "Paused lab replacement consumes no simulation time")
	_check(is_equal_approx(r.weather.sample(Vector2.ZERO).rain, 1.0) and is_equal_approx(r.weather.sample(Vector2.ZERO).wind_strength, 0.12), "Independent sky and wind survive replacement")
	_check(r.weather.get_status().field_revision > 0, "Snap invalidates renderer cache without advancing time")
	_check(r.trigger_weather("sky", "sunny") and r.trigger_weather("sky", "sunny"), "Repeated lab selections bypass cooldown")
	var snapshot: Dictionary = r.snapshot()
	_check(_runtime().restore(snapshot), "Lab override leaves restorable scheduler state")
	_check(not r.trigger_weather("wind", "invalid") and r.snapshot() == snapshot, "Bad lab selection leaves state unchanged")
	r.weather_change_mode = Runtime.WeatherChangeMode.TRANSITIONS
	_check(r.trigger_weather("wind", "breeze"), "Turning off restores queued requests")
	r.advance(1.0/30, Vector2.ZERO)
	_check(r.weather.get_status().stage == "approach", "Queued weather remains gradual after toggle off")
	# An actual encounter stays alive through the explicit lab bypass.
	var live = _runtime()
	live.scheduler.quiet_remaining = 0.0
	live.trigger_encounter()
	live.advance(1.0/30, Vector2.ZERO)
	_check(live.encounters.get_active() != null, "Encounter fixture is active")
	live.weather_change_mode = Runtime.WeatherChangeMode.REPLACE_NOW
	_check(live.trigger_weather("wind", "storm"), "Lab can override during an encounter")
	_check(live.encounters.get_active() != null and _runtime().restore(live.snapshot()), "Override preserves live actor and valid ownership")
	var paired = _runtime()
	paired.scheduler.quiet_remaining = 0.0
	paired.submit_story("pair", "weather.mix.sunny.calm", "salvage")
	paired.advance(12.1, Vector2.ZERO)
	_check(paired.encounters.get_active() != null, "Linked encounter fixture is active")
	paired.weather_change_mode = Runtime.WeatherChangeMode.REPLACE_NOW
	paired.trigger_weather("sky", "storm")
	_check(paired.encounters.get_active() != null and _runtime().restore(paired.snapshot()), "Replacing linked weather preserves actor and restorable cancelled pair")
	_check(paired.scheduler.get_status().active.pair.cancelled, "Debug interruption cannot count as story completion")
func _test_scheduler() -> void:
	var definitions: Array[Dictionary] = Catalog.scheduler_definitions()
	for definition: Dictionary in definitions:
		if definition.id == "weather.mix.storm.storm":
			definition.payload.instant = true
	var scheduler = Scheduler.new()
	_check(scheduler.configure(definitions), "Catalog accepts instant weather option")
	scheduler.chance_enabled = false
	scheduler.trigger("weather.mix.storm.storm")
	var context := {"weather_stage": "hold", "wind_intensity": 0.0, "sky": "sunny", "sky_mix": {"sunny": 1.0}, "day_phase": 0.25, "encounters_enabled": true, "flags": []}
	# Use managed encounter ownership, not a fake simulator hold flag.
	scheduler.quiet_remaining = 0.0
	var encounter_only = Scheduler.new()
	encounter_only.configure(definitions)
	encounter_only.chance_enabled = false
	encounter_only.quiet_remaining = 0.0
	encounter_only.trigger("salvage")
	encounter_only.advance(1.0/30, context)
	encounter_only.trigger("weather.mix.storm.storm")
	_check(encounter_only.advance(1.0/30, context).is_empty(), "Authored instant event respects encounter lock")
	var commands: Array[Dictionary] = scheduler.advance(1.0/30, context)
	_check(commands.size() == 1 and commands[0].payload.instant, "Scheduler passes execution policy unchanged")
	for definition: Dictionary in definitions:
		if definition.id == "weather.mix.storm.storm": definition.payload.instant = "invalid"
	_check(not Scheduler.new().configure(definitions), "Catalog rejects malformed execution policy")

func _test_queued_mode() -> void:
	var r = _runtime()
	r.weather_change_mode = Runtime.WeatherChangeMode.SKIP_TRANSITIONS
	_check(r.trigger_weather("wind", "storm"), "Skip mode accepts a queued weather request")
	_check(not r.weather.get_status().active, "Skip mode does not replace at submission")
	r.advance(1.0/30, Vector2.ZERO)
	_check(r.weather.get_status().stage == "hold" and r.weather.get_status().instant, "Skip mode snaps when scheduler allocates")
	_check(r.trigger_weather("sky", "raincloud") and r.scheduler.weather_count() == 2, "Skip mode retains active plus pending capacity")
	r.advance(0.2, Vector2.ZERO)
	_check(r.weather.get_status().sky == "sunny", "Pending request cannot preempt active instant hold")
	_check(_runtime().restore(r.snapshot()), "Skip-mode active front restores with its execution policy")
	r.advance(18.0, Vector2.ZERO)
	_check(r.weather.get_status().sky == "raincloud" and r.weather.get_status().stage == "hold", "Waiting weather starts after prior hold ends")
	var blocked = _runtime()
	blocked.scheduler.quiet_remaining = 0.0
	blocked.trigger_encounter()
	blocked.advance(1.0/30, Vector2.ZERO)
	blocked.weather_change_mode = Runtime.WeatherChangeMode.SKIP_TRANSITIONS
	blocked.trigger_weather("sky", "storm")
	blocked.advance(0.1, Vector2.ZERO)
	_check(not blocked.weather.get_status().active and blocked.scheduler.weather_count() == 1, "Skip mode waits for active encounter")
