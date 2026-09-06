extends RefCounted
## Scheduler owns admission; weather and encounter handlers own execution.
const Scheduler = preload("res://game/events/environment_scheduler.gd")
const Catalog = preload("res://game/events/event_catalog.gd")
const Weather = preload("res://game/world/weather_simulation.gd")
const Encounters = preload("res://game/events/encounter_runtime.gd")
const STEP: float = 1.0 / 30.0

var scheduler = Scheduler.new()
var weather = Weather.new()
var encounters = Encounters.new()
var encounters_enabled: bool = false
var active_weather_id: String = ""
var last_source: String = ""
var last_event_id: String = ""
var selected_sky: String = "sunny"
var selected_wind: String = "calm"
## Lab preference, deliberately not a world-save field. Event payloads own their policy.
enum WeatherChangeMode { TRANSITIONS, SKIP_TRANSITIONS, REPLACE_NOW }
var weather_change_mode: WeatherChangeMode = WeatherChangeMode.TRANSITIONS
var _accumulator: float = 0.0

func configure(seed_value: int = 15, enable_encounters: bool = false) -> void:
	scheduler.configure(Catalog.scheduler_definitions(), seed_value)
	weather.configure(seed_value + 104729)
	encounters.configure(seed_value + 7919)
	encounters_enabled = enable_encounters
	active_weather_id = ""
	last_source = ""
	last_event_id = ""
	selected_sky = "sunny"
	selected_wind = "calm"
	_accumulator = 0.0
	weather_change_mode = WeatherChangeMode.TRANSITIONS

func trigger_weather(axis: String, condition: String) -> bool:
	var sky: String = selected_sky
	var wind: String = selected_wind
	if axis == "sky" and Weather.SKY_PROFILES.has(condition):
		sky = condition
	elif axis == "wind" and Weather.WIND_PROFILES.has(condition):
		wind = condition
	else:
		return false
	if weather_change_mode == WeatherChangeMode.REPLACE_NOW:
		scheduler.interrupt_weather_for_testing()
		weather.set_baseline_instantly(sky, wind)
		active_weather_id = ""
		last_event_id = "weather.mix.%s.%s" % [sky, wind]
		last_source = "trigger"
	elif not scheduler.trigger("weather.mix.%s.%s" % [sky, wind]):
		return false
	selected_sky = sky
	selected_wind = wind
	return true

func trigger_encounter(id: String = "salvage", flags: Array[String] = []) -> bool:
	return encounters_enabled and scheduler.trigger(id, {"flags": flags})

func submit_story(request_id: String, weather_id: String, encounter_id: String, flags: Array[String] = []) -> String:
	if not encounters_enabled:
		return "invalid"
	return scheduler.submit_story(request_id, weather_id, encounter_id, {"flags": flags})

func advance(delta: float, player_position: Vector2, flags: Array[String] = []) -> void:
	if not is_finite(delta) or delta <= 0.0 or not player_position.is_finite():
		return
	_accumulator += delta
	while _accumulator + 0.0000001 >= STEP:
		_accumulator = maxf(0.0, _accumulator - STEP)
		var previous = encounters.get_active()
		if encounters_enabled:
			encounters.advance_managed(STEP, player_position)
			if previous != null and encounters.get_active() == null:
				scheduler.finish_encounter(previous.outcome)
		var context: Dictionary = weather.chance_context(player_position)
		context.flags = flags
		context.encounters_enabled = encounters_enabled
		weather.set_transition_hold(encounters.get_active() != null)
		for command: Dictionary in scheduler.advance(STEP, context):
			if command.kind == "start_weather":
				var payload: Dictionary = command.payload.duplicate(true)
				if weather_change_mode == WeatherChangeMode.SKIP_TRANSITIONS:
					payload.instant = true
				if weather.start_event(payload, player_position):
					active_weather_id = command.id
					last_event_id = command.id
					last_source = command.source
				else:
					scheduler.finish_weather("failed")
			elif command.kind == "start_encounter":
				if command.payload.get("handler") == "salvage" and encounters.start_scheduled(player_position, command.source):
					last_event_id = command.id
					last_source = command.source
				else:
					scheduler.finish_encounter("failed")
		weather.set_event_modifiers(encounters.get_modifiers() if encounters_enabled else [])
		weather.set_transition_hold(encounters.get_active() != null)
		weather.advance(STEP, player_position)
		if not active_weather_id.is_empty() and not weather.get_status().active:
			scheduler.finish_weather()
			active_weather_id = ""

func snapshot() -> Dictionary:
	return {"version": 3, "scheduler": scheduler.snapshot(), "weather": weather.snapshot(),
		"encounters": encounters.snapshot(), "encounters_enabled": encounters_enabled,
		"active_weather_id": active_weather_id, "last_source": last_source,
		"last_event_id": last_event_id, "selected_sky": selected_sky,
		"selected_wind": selected_wind, "accumulator": _accumulator}

func restore(data: Dictionary) -> bool:
	# This study format deliberately rejects v2 rather than silently losing an
	# old director queue. Native Variant snapshots are not released player saves.
	if data.get("version") != 3 or not data.get("scheduler") is Dictionary or not data.get("weather") is Dictionary or not data.get("encounters") is Dictionary:
		return false
	var restored_scheduler = Scheduler.new()
	restored_scheduler.configure(Catalog.scheduler_definitions(), 15)
	var restored_weather = Weather.new()
	var restored_encounters = Encounters.new()
	if not restored_scheduler.restore(data.scheduler) or not restored_weather.restore(data.weather) or not restored_encounters.restore(data.encounters):
		return false
	if not data.get("encounters_enabled") is bool or not data.get("active_weather_id") is String or not data.get("selected_sky") is String or not data.get("selected_wind") is String:
		return false
	var remaining: float = float(data.get("accumulator", -1.0))
	if not is_finite(remaining) or remaining < 0.0 or remaining >= STEP:
		return false
	if not Weather.SKY_PROFILES.has(data.selected_sky) or not Weather.WIND_PROFILES.has(data.selected_wind):
		return false
	if not data.get("last_event_id") is String or data.get("last_source") not in ["", "trigger", "chance"]:
		return false
	var state: Dictionary = restored_scheduler.get_status()
	var front: Dictionary = restored_weather.get_status()
	if bool(front.active) != (not state.weather_owner.is_empty()) or bool(front.active) != (not data.active_weather_id.is_empty()):
		return false
	if front.active:
		var request: Dictionary = state.active[state.weather_owner]
		if request.weather != data.active_weather_id:
			return false
		var payload: Dictionary = restored_scheduler.definition(request.weather).payload
		if front.sky != payload.get("sky", restored_weather.baseline_sky) or front.wind != payload.get("wind", restored_weather.baseline_wind):
			return false
	var actor = restored_encounters.get_active()
	var expected_actor: bool = not state.encounter_owner.is_empty() and state.active[state.encounter_owner].phase == "encounter"
	if (actor != null) != expected_actor or front.transition_held != (actor != null):
		return false
	if actor != null:
		var request: Dictionary = state.active[state.encounter_owner]
		if request.encounter != actor.definition_id or request.source != actor.source or front.stage not in ["idle", "hold"]:
			return false
	if not data.encounters_enabled and (actor != null or not state.encounter_owner.is_empty()):
		return false
	# Managed handlers have no independent pending work or chance/quiet timers.
	if not data.encounters.pending.is_empty() or data.encounters.chance_steps != 0 or data.encounters.quiet_remaining != 0.0:
		return false
	scheduler = restored_scheduler
	weather = restored_weather
	encounters = restored_encounters
	encounters_enabled = data.encounters_enabled
	weather.set_event_modifiers(encounters.get_modifiers() if encounters_enabled else [])
	active_weather_id = data.active_weather_id
	last_source = data.last_source
	last_event_id = data.last_event_id
	selected_sky = data.selected_sky
	selected_wind = data.selected_wind
	_accumulator = remaining
	return true
