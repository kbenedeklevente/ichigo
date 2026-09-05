extends RefCounted
## One bridge between generic event activation and the weather event handler.
## Story progression calls director.trigger; rendering never rolls an event.

const Director = preload("res://game/events/event_director.gd")
const Catalog = preload("res://game/events/event_catalog.gd")
const Weather = preload("res://game/world/weather_simulation.gd")
const Encounters = preload("res://game/events/encounter_runtime.gd")
const STEP: float = 1.0 / 30.0

var director = Director.new()
var weather = Weather.new()
var encounters = Encounters.new()
var encounters_enabled: bool = false
var active_weather_id: String = ""
var last_source: String = ""
var last_event_id: String = ""
var selected_sky: String = "sunny"
var selected_wind: String = "calm"
var _accumulator: float = 0.0

func configure(seed_value: int = 15, enable_encounters: bool = false) -> void:
	director.configure(Catalog.default_definitions(), seed_value)
	# Front placement has a separate RNG stream from activation decisions.
	weather.configure(seed_value + 104729)
	encounters.configure(seed_value + 7919)
	encounters_enabled = enable_encounters
	active_weather_id = ""
	last_source = ""
	last_event_id = ""
	selected_sky = "sunny"
	selected_wind = "calm"
	_accumulator = 0.0

func trigger_weather(axis: String, condition: String) -> bool:
	if axis == "sky" and Weather.SKY_PROFILES.has(condition):
		selected_sky = condition
	elif axis == "wind" and Weather.WIND_PROFILES.has(condition):
		selected_wind = condition
	else:
		return false
	return director.trigger("weather.mix.%s.%s" % [selected_sky, selected_wind])

func advance(delta: float, player_position: Vector2, flags: Array[String] = []) -> void:
	if not is_finite(delta) or delta <= 0.0 or not player_position.is_finite():
		return
	_accumulator += delta
	while _accumulator + 0.0000001 >= STEP:
		_accumulator = maxf(0.0, _accumulator - STEP)
		var occupied: bool = false
		if encounters_enabled:
			var state: Dictionary = weather.get_status()
			var conditions := {"sky": state.sky, "wind": state.wind}
			var can_start: bool = state.stage in ["idle", "hold"] and director.snapshot().pending.is_empty()
			encounters.advance(STEP, player_position, conditions, can_start)
			occupied = encounters.get_active() != null
			weather.set_event_modifiers(encounters.get_modifiers())
		weather.set_transition_hold(occupied)
		weather.advance(STEP, player_position)
		if not active_weather_id.is_empty() and not weather.get_status().active:
			director.finish(active_weather_id, "completed")
			active_weather_id = ""
		for event: Dictionary in director.advance(STEP, {"flags": flags, "admission_blocked": occupied}):
			if event.domain != "weather":
				# Future handlers own their completion. Never grant rewards here.
				continue
			if weather.start_event(event.payload):
				active_weather_id = event.id
				last_event_id = event.id
				last_source = event.source
			else:
				director.finish(event.id, "failed")

func snapshot() -> Dictionary:
	return {"version": 2, "director": director.snapshot(), "weather": weather.snapshot(),
		"encounters": encounters.snapshot(), "encounters_enabled": encounters_enabled,
		"active_weather_id": active_weather_id, "last_source": last_source,
		"last_event_id": last_event_id, "selected_sky": selected_sky,
		"selected_wind": selected_wind, "accumulator": _accumulator}

func restore(data: Dictionary) -> bool:
	if data.get("version", 0) != 2 or not data.get("director") is Dictionary or not data.get("weather") is Dictionary or not data.get("encounters") is Dictionary:
		return false
	var restored_director = Director.new()
	restored_director.configure(Catalog.default_definitions(), 15)
	var restored_weather = Weather.new()
	var restored_encounters = Encounters.new()
	if not restored_director.restore(data.director) or not restored_weather.restore(data.weather) or not restored_encounters.restore(data.encounters):
		return false
	var remaining: float = float(data.get("accumulator", -1.0))
	if not is_finite(remaining) or remaining < 0.0 or remaining >= STEP:
		return false
	var restored_id: String = str(data.get("active_weather_id", ""))
	var restored_sky: String = str(data.get("selected_sky", ""))
	var restored_wind: String = str(data.get("selected_wind", ""))
	if not Weather.SKY_PROFILES.has(restored_sky) or not Weather.WIND_PROFILES.has(restored_wind):
		return false
	if bool(restored_weather.get_status().active) != (not restored_id.is_empty()):
		return false
	if not restored_id.is_empty() and not restored_director.snapshot().active.has(restored_id):
		return false
	director = restored_director
	weather = restored_weather
	encounters = restored_encounters
	encounters_enabled = bool(data.get("encounters_enabled", false))
	weather.set_event_modifiers(encounters.get_modifiers() if encounters_enabled else [])
	active_weather_id = str(data.get("active_weather_id", ""))
	last_source = str(data.get("last_source", ""))
	last_event_id = str(data.get("last_event_id", ""))
	selected_sky = restored_sky
	selected_wind = restored_wind
	_accumulator = remaining
	return true
