extends SceneTree
const Weather = preload("res://game/world/weather_simulation.gd")
const Sources = preload("res://game/world/wave_sources.gd")
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)

func _run() -> void:
	_test_signed_interference()
	_test_crossing_sources()
	_test_weather_and_replay()
	for failure in failures:
		push_error(failure)
	print("Multisource waves: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

func _test_signed_interference() -> void:
	var crest := Sources.signed_wave(PI / 2.0, 0.0, 0.8)
	_check(is_equal_approx(crest + Sources.signed_wave(PI / 2.0, 0.0, 0.3), 1.1), "Aligned sources add their different strengths")
	_check(is_equal_approx(crest + Sources.signed_wave(PI / 2.0, PI, 0.3), 0.5), "Opposing phase subtracts the weaker source")
	_check(absf(crest + Sources.signed_wave(PI / 2.0, PI, 0.8)) < 0.000001, "Equal opposite sources cancel without reducing wind strength")
	var sources := Sources.new()
	sources.configure(15)
	var reinforced := false
	var cancelled := false
	var exact_sum := true
	var finite_bound := true
	for frame in 40:
		for y in range(-6, 7):
			for x in range(-6, 7):
				var point := Vector2(x, y) * 4.0
				var parts: PackedFloat64Array = sources.contributions(point, 1.05, frame * 0.37, frame * 0.5)
				var sum := 0.0
				var largest := 0.0
				for part in parts:
					sum += part
					largest = maxf(largest, absf(part))
				var actual: float = sources.sample_height(point, 1.05, frame * 0.37, frame * 0.5)
				exact_sum = exact_sum and is_equal_approx(actual, sum)
				reinforced = reinforced or absf(actual) > largest + 0.2
				cancelled = cancelled or (largest > 0.2 and absf(actual) < 0.025)
				finite_bound = finite_bound and is_finite(actual) and absf(actual) <= 1.05 * 1.72 + 0.000001
	_check(exact_sum, "Production samples preserve the signed sum of every source")
	_check(reinforced and cancelled, "Authored wave field actually contains both reinforced and cancelled patches")
	_check(finite_bound, "All sampled targets obey the analytic sum-of-strengths bound without clamping")

func _test_crossing_sources() -> void:
	var sources := Sources.new()
	sources.configure(15)
	var repeated := Sources.new()
	repeated.configure(15)
	var other := Sources.new()
	other.configure(16)
	var point := Vector2(5.3, -8.2)
	_check(sources.contributions(point, 1.05, 2.0, 6.0) == repeated.contributions(point, 1.05, 2.0, 6.0), "Seed recreates all independent source phases")
	_check(sources.contributions(point, 1.05, 2.0, 6.0) != other.contributions(point, 1.05, 2.0, 6.0), "Different seed changes crossing-sea pattern")
	var left := false
	var right := false
	var forward := false
	var backward := false
	for direction: Vector2 in Sources.DIRECTIONS:
		left = left or direction.x < -0.3
		right = right or direction.x > 0.3
		forward = forward or direction.y > 0.3
		backward = backward or direction.y < -0.3
	_check(left and right and forward and backward, "Sources propagate across all four world directions")
	var calm_cross := 0.0
	var storm_cross := 0.0
	for frame in 120:
		var calm: PackedFloat64Array = sources.contributions(point, 0.12, frame * 0.17, frame * 0.3)
		var storm: PackedFloat64Array = sources.contributions(point, 1.05, frame * 0.17, frame * 0.3)
		for index in range(1, Sources.SOURCE_COUNT):
			calm_cross += pow(calm[index] / 0.12, 2)
			storm_cross += pow(storm[index] / 1.05, 2)
	_check(storm_cross > calm_cross * 5.0, "Tempest strengthens crossing motion relative to the calm dominant swell")
	_check(sources.contributions(point, 1.05, 2.0, 0.0) != sources.contributions(point, 1.05, 2.0, 30.0), "Independent source strength envelopes evolve with saved simulation time")

func _new_weather(seed_value: int = 15):
	var weather = Weather.new()
	weather.render_radius = 2
	weather.simulation_radius = 4
	weather.configure(seed_value)
	return weather

func _test_weather_and_replay() -> void:
	var weather = _new_weather()
	weather.set_baseline_instantly("tempest", "tempest")
	var stable := true
	var largest_height := 0.0
	for frame in 900:
		weather.advance(Weather.FIXED_STEP, Vector2(sin(frame * 0.004) * 12.0, -frame * 0.013))
		var fields: Dictionary = weather.snapshot().fields
		for index in fields.height.size():
			largest_height = maxf(largest_height, absf(fields.height[index]))
			stable = stable and is_finite(fields.height[index]) and is_finite(fields.velocity[index]) and absf(fields.velocity[index]) < 5.0
	_check(stable and largest_height < 2.0, "Thirty seconds of crossing Tempest springs and scrolling stay finite and bounded")
	var restored = _new_weather(99)
	_check(restored.restore(bytes_to_var(var_to_bytes(weather.snapshot()))), "Existing version-2 weather snapshot restores multisource motion")
	for frame in 90:
		var point := Vector2(-frame * 0.2, frame * 0.1)
		weather.advance(Weather.FIXED_STEP, point)
		restored.advance(Weather.FIXED_STEP, point)
	_check(weather.snapshot() == restored.snapshot(), "Restored seed, clock and integrated phase reproduce every spring exactly")
	var before: Dictionary = weather.snapshot()
	weather.advance(0.0, Vector2.ZERO)
	_check(before == weather.snapshot(), "Zero-time pause does not advance source phases or strengths")
	var revision: int = weather.get_status().field_revision
	var phase: float = weather.get_status().phase
	weather.set_baseline_instantly("sunny", "calm")
	_check(weather.get_status().field_revision > revision and weather.get_status().phase == phase, "Instant weather refreshes fields without restarting primary swell phase")
	_check(weather.chance_context(Vector2.ZERO).wind_intensity == 0.0, "Calm source motion does not inflate weather eligibility")
	weather.set_baseline_instantly("tempest", "tempest")
	_check(weather.chance_context(Vector2.ZERO).wind_intensity == 4.0, "Wave cancellation does not weaken Tempest weather eligibility")
	var production = Weather.new()
	production.configure(15)
	_check(production.get_status().simulated_cells == 1089 and production.cell_size == 4.0, "Multiple sources keep the fixed 33 by 33, four-metre physics grid")
