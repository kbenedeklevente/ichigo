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
