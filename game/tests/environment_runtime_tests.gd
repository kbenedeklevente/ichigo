extends SceneTree
## Cross-system activation, lifecycle, persistence, and pause-by-no-advance tests.
const Runtime = preload("res://game/events/environment_runtime.gd")
var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
	var runtime = _runtime()
	_check(runtime.scheduler.trigger("weather.mix.storm.strong"), "A progression trigger admits mixed weather.")
	runtime.advance(1.0 / 30.0, Vector2.ZERO)
	_check(runtime.active_weather_id == "weather.mix.storm.strong", "The shared handler receives the triggered event.")
	_check(runtime.last_source == "trigger", "The activation source remains explicit.")
	runtime.advance(14.0, Vector2(8.0, -4.0))
	var state: Dictionary = runtime.weather.get_status()
	_check(state.stage == "hold", "The front reaches its established stage.")
	_check(state.center.distance_to(Vector2(8.0, -4.0)) < 0.001, "An incoming event centers on the moving player.")
	_check(not runtime.scheduler.weather_owner.is_empty(), "Arrival does not automatically finish the event.")
	var saved: Dictionary = runtime.snapshot()
	var restored = _runtime()
	_check(restored.restore(saved), "A joint active director/weather snapshot restores.")
	for index in range(12):
		var point := Vector2(8.0 + index * 0.1, -4.0)
		runtime.advance(0.1, point)
		restored.advance(0.1, point)
		_check(absf(runtime.weather.sample(point).height - restored.weather.sample(point).height) < 0.0000001, "Restored panel dynamics continue identically.")
	_check(runtime.snapshot() == restored.snapshot(), "Both RNG streams, front progress and director state replay together.")
	var invalid: Dictionary = saved.duplicate(true)
	invalid.active_weather_id = "missing"
	var before: Dictionary = restored.snapshot()
	_check(not restored.restore(invalid), "A mismatched active handler snapshot is rejected.")
	_check(restored.snapshot() == before, "Rejected restore is atomic.")
	runtime.advance(28.0, Vector2(8.0, -4.0))
	_check(runtime.scheduler.snapshot().completed.get("trigger:0", {}).get("outcome") == "completed", "Completion follows the full weather lifecycle.")
	_check(runtime.scheduler.weather_owner.is_empty(), "Finished weather releases the exclusive group.")
	_check(not runtime.scheduler.trigger("weather.mix.storm.strong"), "Finished weather respects its cooldown.")
	var first = _runtime()
	var second = _runtime()
	first.advance(8.0, Vector2.ZERO)
	for index in range(80):
		second.advance(0.1, Vector2.ZERO)
	_check(first.scheduler.snapshot() == second.scheduler.snapshot(), "Rendered frame partition does not change chance scheduling.")
	_check(absf(first.weather.sample(Vector2.ZERO).height - second.weather.sample(Vector2.ZERO).height) < 0.0000001, "Rendered frame partition does not change connected water physics.")
	var random_runtime = _runtime()
	for index in range(300):
		random_runtime.advance(1.0, Vector2.ZERO)
		if random_runtime.last_source == "chance":
			break
	_check(random_runtime.last_source == "chance", "Chance activation reaches the same handler without a story trigger.")
	_check(random_runtime.weather.get_status().active, "Chance activation starts a physical weather front.")
	if failures.is_empty():
		print("PASS: %d environment runtime integration checks." % checks)
		quit(0)
	else:
		printerr("FAIL: %s" % failures)
		quit(1)

func _runtime():
	var runtime = Runtime.new()
	runtime.configure(15)
	# Same solver with a small valid subset; production bounds tested separately.
	runtime.weather.render_radius = 1
	runtime.weather.simulation_radius = 3
	runtime.weather.configure(104744)
	return runtime

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
