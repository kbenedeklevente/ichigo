extends SceneTree
const Breakers = preload("res://game/world/storm_breakers.gd")
const Runtime = preload("res://game/events/environment_runtime.gd")
var failures: Array[String] = []
var checks := 0
class Fields:
	var time := 0.0
	var wind := 12.0
	var sky := 4.0
	func get_status() -> Dictionary:
		return {"simulation_time": time, "phase": time * TAU / 7.5, "cell_size": 4.0, "render_radius": 8}
	func sample(_p: Vector2) -> Dictionary:
		return {"wind_strength": wind, "sky_strength": sky, "wind": Vector2.RIGHT * wind}
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
func _initialize() -> void:
	var fields := Fields.new()
	var a := Breakers.new()
	a.configure(65552)
	var maximum := 0
	for tick in range(1800):
		fields.time = (tick + 1) / 30.0
		a.advance(fields, Vector2.ZERO)
		maximum = maxi(maximum, a.active.size())
	check(a.starts > 0 and a.starts <= 24, "Extreme waves occur but global cooldown bounds starts")
	check(maximum <= Breakers.MAX_ACTIVE and a._cycles.size() == 289, "State stays bounded to coarse anchors")
	var saved: Dictionary = a.snapshot()
	var b := Breakers.new()
	check(b.restore(saved), "Live breaker state restores")
	for tick in range(600):
		fields.time += 1.0 / 30.0
		a.advance(fields, Vector2.ZERO)
		b.advance(fields, Vector2.ZERO)
	check(a.snapshot() == b.snapshot(), "Cycle rolls and active foam replay identically")
	var frozen: Dictionary = a.snapshot()
	for i in range(100):
		a.advance(fields, Vector2.ZERO)
		a.render_state()
	check(a.snapshot() == frozen, "Pause and repeated render reads cannot roll or advance effects")
	var invalid: Dictionary = frozen.duplicate(true)
	invalid.active = [{"cell": Vector2i.ZERO}]
	check(not a.restore(invalid) and a.snapshot() == frozen, "Malformed restore is atomic")
	for pair in [Vector2(0.12, 0), Vector2(9, 3), Vector2(12, 3), Vector2(9, 4)]:
		fields.wind = pair.x
		fields.sky = pair.y
		a.configure(65552)
		for tick in range(450):
			fields.time += 1.0 / 30.0
			a.advance(fields, Vector2.ZERO)
		check(a.starts == 0 and a.rolls == 0, "No extreme rolls outside maximum combined weather")
	check(Breakers.eligible({"wind_strength":11.98, "sky_strength":3.995}), "Asymptotic maximum has a narrow tolerance")
	fields.wind = 12.0
	fields.sky = 4.0
	a.configure(65552)
	a._clock = 10.0
	a.active = [{"cell":Vector2i(0,-2), "anchor":Vector2(0,-8), "direction":Vector2.RIGHT, "started":10.0, "cell_size":4.0}]
	var normal: Dictionary = a.render_state()
	check(is_equal_approx(normal.crests[0].z, 1.0) and normal.splashes[0].w == 0.0, "Growth starts at ordinary height without premature foam")
	a._clock += Breakers.RISE
	check(is_equal_approx(a.render_state().crests[0].z, Breakers.PEAK_GAIN), "Crest reaches transient peak")
	a._clock += Breakers.CRASH + 0.85
	var foam: Dictionary = a.render_state()
	check(foam.splashes[0].w > 0.95 and foam.splashes[0].z == 1.0, "Crash produces fully spread foam")
	a._clock += Breakers.FOAM
	check(a.render_state().splashes[0].w == 0.0, "Foam fades completely")
	var runtime := Runtime.new()
	runtime.configure(15)
	runtime.scheduler.chance_enabled = false
	runtime.weather_change_mode = Runtime.WeatherChangeMode.REPLACE_NOW
	runtime.trigger_weather("sky", "tempest")
	runtime.trigger_weather("wind", "tempest")
	for i in range(300): runtime.advance(1.0/30.0, Vector2.ZERO)
	check(runtime.breakers.starts > 0, "Real weather runtime starts extreme breakers")
	var copy := Runtime.new()
	copy.configure(15)
	check(copy.restore(runtime.snapshot()), "Joint version-four snapshot restores breakers")
	for i in range(30):
		runtime.advance(1.0/30.0, Vector2.ZERO)
		copy.advance(1.0/30.0, Vector2.ZERO)
	check(copy.snapshot() == runtime.snapshot(), "Joint replay preserves scheduler, physics and breakers")
	var legacy: Dictionary = runtime.snapshot()
	legacy.version = 3
	legacy.erase("breakers")
	check(copy.restore(legacy), "Previous version-three study snapshot migrates")
	check(copy.restore(copy.snapshot()), "Migrated snapshot immediately roundtrips")
	runtime.trigger_weather("wind", "calm")
	check(runtime.breakers.active.is_empty(), "Replace-now clears transient visuals immediately")
	print("Storm breaker tests: %d checks, %d failures; max concurrent %d" % [checks, failures.size(), maximum])
	for failure in failures: printerr(failure)
	quit(0 if failures.is_empty() else 1)
