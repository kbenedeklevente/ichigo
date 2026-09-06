extends RefCounted
## Temporary study rates, not locked story pacing. All sixteen combinations give
## sky and wind equal independent weights when no per-definition cooldown applies.
## Single-axis IDs are trigger-only conveniences. One incoming weather front at a
## time; a triggered request waits for finish(), while chance proposals do not queue.


static func default_definitions() -> Array[Dictionary]:
	var definitions: Array[Dictionary] = []
	for sky: String in ["sunny", "cloudy", "raincloud", "storm"]:
		for wind: String in ["calm", "breeze", "strong", "storm"]:
			definitions.append({
				"id": "weather.mix.%s.%s" % [sky, wind], "domain": "weather",
				"activation": "both", "rate_per_second": 1.0 / 960.0,
				"cooldown_seconds": 120.0, "once": false, "requires": [],
				"payload": {"sky": sky, "wind": wind},
				"priority": 0, "exclusive_group": "weather"
			})
		definitions.append(_weather_definition("sky", sky))
	for wind: String in ["calm", "breeze", "strong", "storm"]:
		definitions.append(_weather_definition("wind", wind))
	return definitions


static func _weather_definition(axis: String, value: String) -> Dictionary:
	return {
		"id": "weather.%s.%s" % [axis, value], "domain": "weather",
		"activation": "trigger", "rate_per_second": 0.0,
		"cooldown_seconds": 120.0, "once": false, "requires": [],
		"payload": {axis: value}, "priority": 0, "exclusive_group": "weather"
	}


## Runtime coordinator catalog. Legacy default_definitions remains for standalone
## director studies; the game uses this schema and one scheduler instead.
static func scheduler_definitions() -> Array[Dictionary]:
	var Chance = preload("res://game/events/event_chance.gd")
	var definitions: Array[Dictionary] = []
	var originals := default_definitions()
	# New fifth-tier combinations are explicitly trigger-only until chance balance
	# is selected; the existing sixteen stochastic rates remain unchanged.
	for sky: String in Chance.SKIES:
		for wind: String in Chance.WINDS:
			if sky != "tempest" and wind != "tempest":
				continue
			originals.append({"id": "weather.mix.%s.%s" % [sky, wind], "domain": "weather",
				"activation": "trigger", "rate_per_second": 0.0, "cooldown_seconds": 120.0,
				"once": false, "requires": [], "payload": {"sky": sky, "wind": wind},
				"priority": 0, "exclusive_group": "weather"})
	originals.append(_weather_definition("sky", "tempest"))
	originals.append(_weather_definition("wind", "tempest"))
	for original: Dictionary in originals:
		var definition: Dictionary = original.duplicate(true)
		definition["base_rate_per_second"] = definition.rate_per_second
		definition.erase("rate_per_second")
		definition["wind_time_weights"] = Chance.uniform_table()
		definition["sky_weights"] = {"sunny": 1.0, "cloudy": 1.0, "raincloud": 1.0, "storm": 1.0, "tempest": 1.0}
		definition["eligibility"] = {"requires": definition.requires}
		definitions.append(definition)
	# Re-express the existing salvage P60 and wind multipliers exactly at profile
	# anchors. All time columns are neutral until content/time balance is chosen.
	var base: float = -log(0.95) / 60.0
	definitions.append({"id": "salvage", "domain": "encounter", "activation": "both",
		"base_rate_per_second": base, "cooldown_seconds": 0.0, "once": false, "priority": 0,
		"eligibility": {}, "payload": {"handler": "salvage"},
		"wind_time_weights": [[0.6, 0.6, 0.6, 0.6], [1.0, 1.0, 1.0, 1.0], [1.3, 1.3, 1.3, 1.3], [0.5, 0.5, 0.5, 0.5], [0.5, 0.5, 0.5, 0.5]],
		"sky_weights": {"sunny": 1.0, "cloudy": (-log(0.93) / 60.0) / base,
			"raincloud": (-log(0.91) / 60.0) / base, "storm": (-log(0.96) / 60.0) / base, "tempest": (-log(0.96) / 60.0) / base}})
	return definitions
