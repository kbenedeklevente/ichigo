extends SceneTree
const Weather = preload("res://game/world/weather_simulation.gd")
const Chance = preload("res://game/events/event_chance.gd")
const Catalog = preload("res://game/events/event_catalog.gd")
const Runtime = preload("res://game/events/environment_runtime.gd")
var checks := 0
var failures: Array[String] = []
func _initialize() -> void:
	var weather = Weather.new()
	weather.render_radius = 1
	weather.simulation_radius = 3
	weather.configure(15)
	_check(Weather.SKY_NAMES.size() == 5 and Weather.WIND_NAMES.size() == 5, "Five levels per axis, ten total")
	for sky: String in Weather.SKY_NAMES:
		for wind: String in Weather.WIND_NAMES:
			_check(weather.set_baseline_instantly(sky, wind), "All pairs can be selected: %s/%s" % [sky, wind])
			var context: Dictionary = weather.chance_context(Vector2.ZERO)
			_check(context.sky == sky and is_equal_approx(context.wind_intensity, float(Weather.WIND_NAMES.find(wind))), "Physical profiles reach correct authoring coordinates")
	var definitions: Array[Dictionary] = Catalog.scheduler_definitions()
	var random_weather := 0
	var test_weather := 0
	var mix_count := 0
	for definition: Dictionary in definitions:
		_check(Chance.validate(definition), "Five-row/five-sky catalog validates: " + definition.id)
		if definition.id.begins_with("weather.mix."):
			mix_count += 1
			if definition.activation == "both":
				random_weather += 1
				_check(is_equal_approx(definition.base_rate_per_second, 1.0/960.0), "Existing weather base rate unchanged")
			else:
				test_weather += 1
				_check(definition.base_rate_per_second == 0.0, "New tier combinations have no unapproved chance rate")
	_check(mix_count == 25 and random_weather == 16 and test_weather == 9, "25 combinations with original stochastic pool intact")
	weather.set_baseline_instantly("storm", "storm")
	weather.start_event({"sky": "tempest", "wind": "tempest", "approach_s": 0.1, "hold_s": 30.0})
	weather.advance(5.0, Vector2.ZERO)
	var local: Dictionary = weather.sample(Vector2.ZERO)
	_check(local.cloud_cover == 1.0 and local.sky_strength > 3.0 and local.sky_strength < 4.0, "Sky severity can transition beyond storm without cloud cover exceeding one")
	var definition: Dictionary = definitions[0].duplicate(true)
	definition.wind_time_weights[4] = [3.0,3.0,3.0,3.0]
	definition.sky_weights.tempest = 2.0
	var context := {"wind_intensity":3.5, "sky":"tempest", "sky_mix":{"storm":0.5,"tempest":0.5}, "day_phase":0.25}
	var evaluation: Dictionary = Chance.evaluate(definition, context)
	_check(is_equal_approx(evaluation.wind_time_weight, 2.0) and is_equal_approx(evaluation.sky_weight, 1.5), "Chance interpolation spans fourth to fifth level")
	definition.eligibility = {"excluded_skies":["tempest"]}
	_check(Chance.evaluate(definition, context).rate == 0.0, "New sky tier supports hard exclusions")
	weather.advance(25.0, Vector2(-2, 1))
	var finite := true
	for values: PackedFloat64Array in weather.snapshot().fields.values():
		for value: float in values: finite = finite and is_finite(value)
	_check(finite, "New maximum remains numerically finite through a long hold")
	var saved: Dictionary = weather.snapshot()
	var restored = Weather.new()
	_check(restored.restore(saved), "Five-level weather snapshot restores")
	weather.advance(0.5, Vector2(-2, 1))
	restored.advance(0.5, Vector2(-2, 1))
	_check(weather.snapshot() == restored.snapshot(), "New sky field and stronger waves replay deterministically")
	var runtime = Runtime.new()
	runtime.configure(15)
	runtime.scheduler.chance_enabled = false
	runtime.weather_change_mode = Runtime.WeatherChangeMode.SKIP_TRANSITIONS
	_check(runtime.trigger_weather("sky", "tempest"), "New tier goes through queued mode")
	runtime.advance(1.0/30, Vector2.ZERO)
	_check(runtime.weather.get_status().sky == "tempest" and runtime.weather.get_status().stage == "hold", "New tier reaches instant established state")
	var runtime_copy = Runtime.new()
	runtime_copy.configure(15)
	_check(runtime_copy.restore(runtime.snapshot()), "Joint scheduler/new-tier state restores")
	for failure in failures: printerr(failure)
	print("Five-level weather: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
