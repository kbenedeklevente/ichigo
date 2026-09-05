extends SceneTree
## Run: Godot --headless --path . --script game/tests/weather_simulation_tests.gd
const Weather = preload("res://game/world/weather_simulation.gd")
var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	_test_profiles_and_validation()
	_test_grid_and_sampling()
	_test_front_and_response()
	_test_local_wind_direction()
	_test_determinism_and_restore()
	_test_springs()
	_test_default_budget()
	for failure in failures:
		push_error(failure)
	print("Weather simulation: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

func _new_weather():
	var weather = Weather.new()
	# Small buffer speeds behavior tests; production dimensions tested separately.
	weather.render_radius = 2
	weather.simulation_radius = 4
	weather.configure(15)
	return weather

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)

func _test_profiles_and_validation() -> void:
	for sky: String in Weather.SKY_PROFILES:
		for wind: String in Weather.WIND_PROFILES:
			var weather = _new_weather()
			_check(weather.start_event({"sky": sky, "wind": wind}), "All 16 independent sky/wind combinations accepted: %s / %s" % [sky, wind])
	var weather = _new_weather()
	var original: Dictionary = weather.snapshot()
	_check(not weather.start_event({"sky": "unknown"}), "Unknown profiles rejected")
	_check(not weather.start_event({"approach_s": NAN}), "Nonfinite duration rejected")
	_check(not weather.start_event({"hold_s": -1.0}), "Negative duration rejected")
	_check(weather.snapshot() == original, "Invalid requests do not consume RNG or change state")
	_check(weather.start_event({"wind": "strong"}), "Single-axis request accepted")
	_check(weather.get_status().sky == "sunny", "Omitted sky retains baseline")
	_check(not weather.start_event({"sky": "storm"}), "Overlapping weather cannot silently replace current event")
	var before: Dictionary = weather.snapshot()
	weather.advance(-1.0, Vector2.ZERO)
	weather.advance(NAN, Vector2.ZERO)
	weather.advance(1.0, Vector2(INF, 0.0))
	_check(weather.snapshot() == before, "Invalid advance input has no side effects")

func _test_grid_and_sampling() -> void:
	var weather = Weather.new()
	weather.configure(15)
	_check(weather.get_status().simulated_cells == 1089, "Production buffer simulates 33 by 33 cells")
	var panels: Array[Dictionary] = weather.get_panel_states()
	_check(panels.size() == 289, "Production renderer exports only 17 by 17 cells")
	var ids := {}
	var all_coherent := true
	for panel in panels:
		ids[panel.cell_id] = true
		var value: Dictionary = weather.sample(panel.position)
		all_coherent = all_coherent and absf(float(panel.height) - float(value.height)) < 0.0000001
		all_coherent = all_coherent and panel.size == weather.cell_size and panel.normal.y > 0.0
	_check(ids.size() == panels.size(), "Rendered cells have unique stable world IDs")
	_check(all_coherent, "Panel heights equal shared water samples and all cells have equal sides")
	var point := Vector2(-5.3, 2.7)
	var normal: Vector3 = weather.sample(point).normal
	var epsilon := 0.001
	var dx: float = (weather.sample(point + Vector2(epsilon, 0)).height - weather.sample(point - Vector2(epsilon, 0)).height) / (2.0 * epsilon)
	var dz: float = (weather.sample(point + Vector2(0, epsilon)).height - weather.sample(point - Vector2(0, epsilon)).height) / (2.0 * epsilon)
	_check(normal.distance_to(Vector3(-dx, 1.0, -dz).normalized()) < 0.00001, "Bilinear normals match finite differences away from cell seams")
	var old: Dictionary = weather.sample(Vector2.ZERO)
	# Less than a fixed step scrolls storage without advancing any dynamics.
	weather.advance(0.001, Vector2(-0.01, -0.01))
	_check(weather.get_status().origin == Vector2i(-17, -17), "Negative coordinates use floor rather than truncation")
	_check(weather.sample(Vector2.ZERO).height == old.height, "Grid scroll exactly preserves overlap heights")
	_check(weather.sample(Vector2.ZERO).velocity == old.velocity, "Grid scroll exactly preserves overlap spring velocity")
	var first_id: Vector2i = weather.get_panel_states()[0].cell_id
	_check(first_id == Vector2i(-9, -9), "Render subset follows negative player cell")
	_check(weather.sample(Vector2(100000, -100000)).normal.is_finite(), "Out-of-buffer sampling safely clamps to finite edge")

func _test_front_and_response() -> void:
	var weather = _new_weather()
	weather.start_event({"sky": "raincloud", "wind": "storm", "approach_s": 2.0, "hold_s": 24.0, "clearing_s": 4.0})
	var direction: Vector2 = weather.get_status().incoming_direction
	_check(absf(direction.length() - 1.0) < 0.00001, "Incoming weather has a unit random bearing")
	var previous_distance := INF
	for frame in 60:
		var player := Vector2(frame * 0.09, -frame * 0.05)
		weather.advance(1.0 / 30.0, player)
		var offset: Vector2 = weather.get_status().center - player
		_check(offset.length() <= previous_distance + 0.00001, "Front distance closes despite player movement, step %d" % frame)
		previous_distance = offset.length()
	_check(weather.get_status().stage == "hold", "Front reaches hold at scheduled approach time")
	_check(weather.get_status().center.distance_to(Vector2(59 * 0.09, -59 * 0.05)) < 0.00001, "Front centers on moving player on arrival")
	var player := Vector2.ZERO
	weather.advance(2.0, player)
	var early: Dictionary = weather.sample(player)
	var speed_fraction: float = (early.wave_speed - 0.65) / (2.5 - 0.65)
	var amplitude_fraction: float = (early.wave_amplitude - 0.12) / (0.78 - 0.12)
	_check(speed_fraction > amplitude_fraction + 0.2, "Wave speed responds before amplitude")
	_check(early.rain > 0.05 and early.cloud_cover > 0.12, "Arriving raincloud develops cloud and rain fields")
	var peak_delta := 0.0
	var last_height: float = early.height
	for frame in 780:
		weather.advance(1.0 / 30.0, player)
		var height: float = weather.sample(player).height
		peak_delta = maxf(peak_delta, absf(height - last_height))
		last_height = height
	_check(peak_delta < 0.2, "Storm growth and clearing do not snap panel heights")
	weather.advance(1.0 / 30.0, player)
	_check(not weather.get_status().active and weather.get_status().event_complete, "Weather signals completion after approach, hold and clearing")
	_check(weather.sample(player).wave_amplitude > 0.12, "Ocean retains energy after front clears")
	weather.advance(30.0, player)
	_check(weather.sample(player).wave_amplitude < 0.15, "Residual wave energy gradually decays toward baseline")
	_check(weather.sample(player).rain < 0.001, "Rain fades back to baseline")
	_check(weather.start_event({"sky": "sunny", "wind": "storm"}), "New independent event starts after completion")
	_check(not weather.get_status().event_complete, "Starting event clears previous completion flag")

func _test_determinism_and_restore() -> void:
	var a = _new_weather()
	var b = _new_weather()
	var payload := {"sky": "storm", "wind": "breeze", "approach_s": 1.0, "hold_s": 1.0, "clearing_s": 1.0}
	a.start_event(payload)
	b.start_event(payload)
	_check(a.get_status().incoming_direction == b.get_status().incoming_direction, "Identical weather seeds reproduce incoming bearings")
	a.advance(0.5, Vector2.ZERO)
	for frame in 30:
		b.advance(1.0 / 60.0, Vector2.ZERO)
	_check(absf(a.sample(Vector2.ZERO).height - b.sample(Vector2.ZERO).height) < 0.00000001, "Fixed step reproduces weather across frame grouping")
	var saved: Dictionary = a.snapshot()
	var c = _new_weather()
	_check(c.restore(bytes_to_var(var_to_bytes(saved))), "Native Variant snapshot round trip restores")
	a.advance(0.017, Vector2(-1, 2))
	c.advance(0.017, Vector2(-1, 2))
	_check(a.snapshot() == c.snapshot(), "Saved fractional accumulator, grid and RNG reproduce exact continuation")
	var invalid: Dictionary = saved.duplicate(true)
	invalid.fields.height[0] = NAN
	var before: Dictionary = c.snapshot()
	_check(not c.restore(invalid), "Corrupt nonfinite state rejected")
	_check(c.snapshot() == before, "Rejected restore leaves live simulation unchanged")
	a.advance(3.0, Vector2.ZERO)
	c.advance(3.0, Vector2.ZERO)
	a.start_event(payload)
	c.start_event(payload)
	_check(a.get_status().incoming_direction == c.get_status().incoming_direction, "Restored RNG reproduces subsequent event direction")

func _test_springs() -> void:
	var calm = _new_weather()
	var impulse = _new_weather()
	var state: Dictionary = impulse.snapshot()
	var side: int = impulse.simulation_radius * 2 + 1
	var middle: int = impulse.simulation_radius * side + impulse.simulation_radius
	state.fields.height[middle] += 0.2
	_check(impulse.restore(state), "Valid independent spring displacement restores")
	calm.advance(0.2, Vector2.ZERO)
	impulse.advance(0.2, Vector2.ZERO)
	var neighbor := Vector2(impulse.cell_size, 0)
	_check(absf(impulse.sample(neighbor).height - calm.sample(neighbor).height) > 0.00001, "A displaced panel transfers motion to connected neighbor")
	calm.advance(8.0, Vector2.ZERO)
	impulse.advance(8.0, Vector2.ZERO)
	_check(absf(impulse.sample(Vector2.ZERO).height - calm.sample(Vector2.ZERO).height) < 0.001, "Connected spring impulse damps without persistent separation")
	var stable := true
	for panel in impulse.get_panel_states():
		stable = stable and is_finite(panel.height) and absf(panel.height) < 1.0 and panel.tilt.is_finite()
	_check(stable, "Connected spring solve remains finite and bounded")

func _test_default_budget() -> void:
	var weather = Weather.new()
	weather.configure(15)
	weather.start_event({"sky": "storm", "wind": "calm", "approach_s": 0.1, "hold_s": 10.0})
	var started := Time.get_ticks_usec()
	for frame in 120:
		weather.advance(1.0 / 30.0, Vector2(frame * 0.1, -frame * 0.07))
		weather.get_panel_states()
	var mean_ms := float(Time.get_ticks_usec() - started) / 120000.0
	print("Production grid simulation + 289 panel exports: %.3f ms/fixed tick (120 ticks, non-rendering local sample)" % mean_ms)
	var local: Dictionary = weather.sample(Vector2(11.9, -8.33))
	_check(local.rain > 0.5 and local.cloud_cover > 0.6, "Storm sky develops in calm wind")
	_check(absf(local.wave_speed - 0.65) < 0.000001 and absf(local.wave_amplitude - 0.12) < 0.000001, "Calm wind preserves calm waves independently of storm sky")
	_check(weather.get_status().simulated_cells == 1089, "Travel leaves simulation allocation bounded")

func _test_local_wind_direction() -> void:
	var weather = _new_weather()
	var before: Vector2 = weather.sample(Vector2.ZERO).wind
	_check(before == Vector2.RIGHT * 0.12, "Baseline wind has a stable world direction")
	weather.start_event({"sky": "storm", "wind": "strong", "approach_s": 12.0, "hold_s": 12.0})
	_check(weather.sample(Vector2.ZERO).wind == before, "Starting a distant front does not rotate existing local wind")
	weather.advance(1.0, Vector2.ZERO)
	_check(weather.sample(Vector2.ZERO).wind.distance_to(before) < 0.000001, "Wind stays unchanged before the distant front reaches local cells")
	var previous: Vector2 = weather.sample(Vector2.ZERO).wind
	var largest_change := 0.0
	for frame in 540:
		weather.advance(1.0 / 30.0, Vector2.ZERO)
		var current: Vector2 = weather.sample(Vector2.ZERO).wind
		largest_change = maxf(largest_change, previous.distance_to(current))
		previous = current
	var target: Vector2 = weather.get_status().incoming_direction * 5.0
	_check(previous.distance_to(target) < 0.3, "Local wind gradually aligns with the arriving front")
	_check(largest_change < 0.12, "Wind vector components change smoothly through approach and hold")
	var restored = _new_weather()
	_check(restored.restore(weather.snapshot()), "Per-cell wind vectors participate in snapshots")
	_check(restored.sample(Vector2.ZERO).wind == previous, "Snapshot restores the exact local wind vector")
	var sky_only = _new_weather()
	var sky_before: Vector2 = sky_only.sample(Vector2.ZERO).wind
	sky_only.start_event({"sky": "raincloud"})
	_check(sky_only.sample(Vector2.ZERO).wind == sky_before, "A distant sky-only request also leaves existing local wind unchanged")
