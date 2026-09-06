extends SceneTree
const Runtime = preload("res://game/events/environment_runtime.gd")
const Modifier = preload("res://game/events/local_field_modifier.gd")
var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
	var runtime = Runtime.new()
	runtime.configure(15, true)
	runtime.weather.render_radius = 1
	runtime.weather.simulation_radius = 4
	runtime.weather.configure(104744)
	_check(runtime.scheduler.trigger("weather.mix.raincloud.strong"), "Weather trigger accepted.")
	runtime.advance(13.0, Vector2.ZERO)
	_check(runtime.weather.get_status().stage == "hold", "Weather is established before encounter admission.")
	_check(runtime.trigger_encounter("salvage"), "Salvage trigger accepted.")
	runtime.advance(1.0 / 30.0, Vector2.ZERO)
	_check(runtime.encounters.get_active() != null, "An encounter can use established weather as its backdrop.")
	var frozen_elapsed: float = runtime.weather.get_status().elapsed
	var phase_before: float = runtime.weather.get_status().phase
	_check(runtime.trigger_weather("sky", "sunny"), "A new weather trigger queues while the encounter owns the lock.")
	runtime.advance(40.0, Vector2.ZERO)
	_check(runtime.weather.get_status().transition_held, "The active encounter holds weather transitions.")
	_check(is_equal_approx(runtime.weather.get_status().elapsed, frozen_elapsed), "The established front cannot enter clearing during the encounter.")
	_check(runtime.weather.get_status().phase > phase_before, "Physical wave motion continues while the weather phase is held.")
	_check(runtime.scheduler.snapshot().pending.size() == 1, "Queued weather survives the lock without dispatch.")
	_check(runtime.scheduler.snapshot().active.values().filter(func(record: Dictionary) -> bool: return not record.weather.is_empty()).size() == 1, "No second weather handler starts.")
	var event = runtime.encounters.get_active()
	_check(event.resolve("abandoned"), "The fixture can enter departure without awarding completion.")
	runtime.advance(8.0, Vector2.ZERO)
	var at: Vector2 = runtime.encounters.get_active().center
	var modified: Dictionary = runtime.weather.sample(at)
	_check(modified.current.length() > 0.0, "The departing encounter contributes a physical local current.")
	var fields_before: Dictionary = runtime.weather.snapshot().fields
	runtime.weather.set_event_modifiers([])
	var base: Dictionary = runtime.weather.sample(at)
	_check(modified.wind.distance_to(base.wind) > 0.1, "Effective wind includes the local event modifier.")
	_check(runtime.weather.snapshot().fields == fields_before, "Removing a modifier does not subtract from or corrupt base weather fields.")
	runtime.weather.set_event_modifiers(runtime.encounters.get_modifiers())
	var saved: Dictionary = runtime.snapshot()
	var restored = Runtime.new()
	_check(restored.restore(saved), "The active encounter, transition hold and modifier restore together.")
	_check(restored.weather.sample(at).current.distance_to(modified.current) < 0.000001, "Restore rebuilds the event-owned source before physics resumes.")
	runtime.encounters.report_visibility(false, false)
	runtime.advance(3.1, Vector2.ZERO)
	_check(runtime.encounters.get_active() == null, "Off-screen/out-of-range grace retires the actor.")
	_check(runtime.scheduler.quiet_remaining > 89.0, "Retirement starts the approved quiet interval.")
	_check(not runtime.weather.get_status().transition_held, "Retirement releases the weather hold.")
	_check(runtime.weather.sample(at).current.is_zero_approx(), "Retirement removes the local current source.")
	_check(runtime.encounters.get_status().outcomes[event.id].outcome == "abandoned", "Off-screen retirement does not grant a completed outcome.")
	var held_time: float = runtime.weather.get_status().elapsed
	runtime.advance(1.0, Vector2.ZERO)
	_check(runtime.weather.get_status().elapsed > held_time, "The existing front resumes its lifecycle coherently.")
	# Generic event-local matrices can add or subtract without mutating the base.
	var grid = Modifier.new()
	grid.weight = 1.0
	_check(grid.configure_grid(2, 2, 4.0, Vector2.ZERO, {"wind_x": PackedFloat64Array([-2, -2, -2, -2]), "amplitude": PackedFloat64Array([0.1, 0.1, 0.1, 0.1])}), "Optional local grid accepts signed weather deltas.")
	var original_wind: Vector2 = runtime.weather.sample(Vector2(2,2)).wind
	runtime.weather.set_event_modifiers([grid])
	_check(absf(runtime.weather.sample(Vector2(2,2)).wind.x - original_wind.x + 2.0) < 0.000001, "Grid subtraction composes in effective wind.")
	runtime.weather.set_event_modifiers([])
	_check(runtime.weather.sample(Vector2(2,2)).wind.distance_to(original_wind) < 0.000001, "Removing the grid restores base samples exactly, without cumulative drift.")
	if failures.is_empty():
		print("PASS: %d encounter/weather integration checks." % checks)
		quit(0)
	else:
		printerr("FAIL: %s" % failures)
		quit(1)

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
