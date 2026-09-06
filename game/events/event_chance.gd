extends RefCounted
## Pure authoring validation/evaluation. Weights are relative hazards, not percents.
const SKIES := ["sunny", "cloudy", "raincloud", "storm"]
const TIME_ANCHORS := [0.0, 0.25, 0.5, 0.75] # dawn, day, dusk, night; matches weather daylight

static func valid_number(value: Variant, minimum: float = 0.0) -> bool:
	return (value is float or value is int) and is_finite(float(value)) and float(value) >= minimum

static func validate(definition: Dictionary) -> bool:
	if not valid_number(definition.get("base_rate_per_second", 0.0)):
		return false
	var table: Variant = definition.get("wind_time_weights", [])
	if not table is Array or table.size() != 4:
		return false
	for row: Variant in table:
		if not row is Array or row.size() != 4:
			return false
		for weight: Variant in row:
			if not valid_number(weight):
				return false
	var sky: Variant = definition.get("sky_weights", {})
	if not sky is Dictionary or sky.size() != 4:
		return false
	for name: String in SKIES:
		if not valid_number(sky.get(name)):
			return false
	var rules: Variant = definition.get("eligibility", {})
	if not rules is Dictionary:
		return false
	for key: Variant in rules:
		if key not in ["requires", "excludes", "wind_min", "wind_max", "excluded_skies", "excluded_time_ranges"]:
			return false
	for key: String in ["requires", "excludes", "excluded_skies"]:
		if not rules.get(key, []) is Array:
			return false
		for entry: Variant in rules.get(key, []):
			if not entry is String or entry.is_empty() or (key == "excluded_skies" and entry not in SKIES):
				return false
	for key: String in ["wind_min", "wind_max"]:
		if rules.has(key) and (not valid_number(rules[key]) or rules[key] > 3):
			return false
	if rules.get("wind_min", 0.0) > rules.get("wind_max", 3.0):
		return false
	if not rules.get("excluded_time_ranges", []) is Array:
		return false
	for interval: Variant in rules.get("excluded_time_ranges", []):
		if not interval is Array or interval.size() != 2:
			return false
		for boundary: Variant in interval:
			if not valid_number(boundary) or boundary >= 1.0:
				return false
		if interval[0] == interval[1]:
			return false
	return true

static func exclusion(definition: Dictionary, context: Dictionary) -> String:
	var rules: Dictionary = definition.get("eligibility", {})
	var flags: Array = context.get("flags", [])
	for flag: String in rules.get("requires", []):
		if flag not in flags:
			return "missing:" + flag
	for flag: String in rules.get("excludes", []):
		if flag in flags:
			return "excluded:" + flag
	var wind: float = float(context.get("wind_intensity", -1.0))
	var phase: float = float(context.get("day_phase", -1.0))
	var sky: String = str(context.get("sky", ""))
	if not is_finite(wind) or wind < 0 or wind > 3 or not is_finite(phase) or phase < 0 or phase >= 1 or sky not in SKIES:
		return "invalid_environment"
	if wind < float(rules.get("wind_min", 0.0)) or wind > float(rules.get("wind_max", 3.0)):
		return "wind"
	if sky in rules.get("excluded_skies", []):
		return "sky"
	for interval: Array in rules.get("excluded_time_ranges", []):
		var inside: bool = phase >= interval[0] and phase < interval[1] if interval[0] < interval[1] else phase >= interval[0] or phase < interval[1]
		if inside:
			return "time"
	return ""

static func evaluate(definition: Dictionary, context: Dictionary) -> Dictionary:
	var reason: String = exclusion(definition, context)
	if not reason.is_empty():
		return {"rate": 0.0, "reason": reason}
	var wind: float = float(context.wind_intensity)
	var time: float = float(context.day_phase) * 4.0
	var w0: int = mini(floori(wind), 3)
	var w1: int = mini(w0 + 1, 3)
	var t0: int = floori(time) % 4
	var t1: int = (t0 + 1) % 4
	var table: Array = definition.wind_time_weights
	var weight: float = lerpf(lerpf(table[w0][t0], table[w0][t1], time - floor(time)), lerpf(table[w1][t0], table[w1][t1], time - floor(time)), wind - w0)
	var sky_weight: float = 0.0
	# Interpolated local cloud-cover mixture, independent of wind. Categorical
	# sky remains available for explicit hard exclusions.
	var mix: Dictionary = context.get("sky_mix", {context.sky: 1.0})
	for sky: String in SKIES:
		sky_weight += float(mix.get(sky, 0.0)) * float(definition.sky_weights[sky])
	var rate: float = float(definition.base_rate_per_second) * weight * sky_weight
	return {"rate": rate if is_finite(rate) else 0.0, "reason": "" if rate > 0 else "zero_weight",
		"base_rate": definition.base_rate_per_second, "wind_time_weight": weight, "sky_weight": sky_weight}

static func probability(rate: float, dt: float) -> float:
	return 1.0 - exp(-rate * dt) if is_finite(rate) and is_finite(dt) and rate > 0 and dt > 0 else 0.0

static func uniform_table(weight: float = 1.0) -> Array:
	return [[weight, weight, weight, weight], [weight, weight, weight, weight], [weight, weight, weight, weight], [weight, weight, weight, weight]]
