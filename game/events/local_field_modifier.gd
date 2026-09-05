extends RefCounted
## Event-relative, additive field values. Wind/current are m/s; amplitude is m.
## Sampling never mutates the base simulation or this source.

var origin: Vector2 = Vector2.ZERO
var radius: float = 14.0
var weight: float = 0.0
var wind_delta: Vector2 = Vector2.ZERO
var current_delta: Vector2 = Vector2.ZERO
var amplitude_delta: float = 0.0
var _grid_width: int = 0
var _grid_height: int = 0
var _grid_cell_size: float = 1.0
var _grid_origin: Vector2 = Vector2.ZERO
var _grid_values: Dictionary = {}

## Values live at square-cell centers; local_origin is the first center relative
## to origin. The footprint extends half a cell beyond outer centers. Missing
## channels are zero. An enabled grid replaces the analytic source, and weight
## blends either source. Packed arrays are copied, so callers cannot mutate them.
func configure_grid(width: int, height: int, cell_size: float, local_origin: Vector2, values: Dictionary) -> bool:
	if width < 1 or height < 1 or width > 256 or height > 256 or not is_finite(cell_size) or cell_size <= 0.0 or not local_origin.is_finite():
		return false
	var copied: Dictionary = {}
	for key in values:
		if not key in ["wind_x", "wind_y", "current_x", "current_y", "amplitude"]:
			return false
		if not (values[key] is PackedFloat64Array or values[key] is PackedFloat32Array) or values[key].size() != width * height:
			return false
		var channel := PackedFloat64Array(Array(values[key]))
		for value: float in channel:
			if not is_finite(value):
				return false
		copied[key] = channel.duplicate()
	_grid_width = width
	_grid_height = height
	_grid_cell_size = cell_size
	_grid_origin = local_origin
	_grid_values = copied
	return true

func clear_grid() -> void:
	_grid_width = 0
	_grid_height = 0
	_grid_values.clear()

func get_bounds() -> Rect2:
	if _grid_width > 0:
		return Rect2(origin + _grid_origin - Vector2.ONE * _grid_cell_size * 0.5,
			Vector2(_grid_width, _grid_height) * _grid_cell_size)
	return Rect2(origin - Vector2.ONE * radius, Vector2.ONE * radius * 2.0)

func sample(point: Vector2) -> Dictionary:
	if _grid_width > 0:
		return _sample_grid(point)
	var blend: float = 0.0
	if radius > 0.0 and point.is_finite():
		var distance: float = point.distance_to(origin) / radius
		# Flat central core lets the actor feel the full current; smooth finite edge.
		blend = clampf(1.0 - smoothstep(0.25, 1.0, distance), 0.0, 1.0) * clampf(weight, 0.0, 1.0)
	return {"wind_delta": wind_delta * blend, "current_delta": current_delta * blend,
		"amplitude_delta": amplitude_delta * blend}

func _sample_grid(point: Vector2) -> Dictionary:
	var result: Dictionary = {"wind_delta": Vector2.ZERO, "current_delta": Vector2.ZERO, "amplitude_delta": 0.0}
	if not point.is_finite() or not get_bounds().has_point(point):
		return result
	var local: Vector2 = (point - origin - _grid_origin) / _grid_cell_size
	local = local.clamp(Vector2.ZERO, Vector2(_grid_width - 1, _grid_height - 1))
	var x0: int = floori(local.x)
	var y0: int = floori(local.y)
	var x1: int = mini(x0 + 1, _grid_width - 1)
	var y1: int = mini(y0 + 1, _grid_height - 1)
	var channels: Dictionary = {}
	for key: String in _grid_values:
		var values: PackedFloat64Array = _grid_values[key]
		var row0: float = lerpf(values[y0 * _grid_width + x0], values[y0 * _grid_width + x1], local.x - x0)
		var row1: float = lerpf(values[y1 * _grid_width + x0], values[y1 * _grid_width + x1], local.x - x0)
		channels[key] = lerpf(row0, row1, local.y - y0) * clampf(weight, 0.0, 1.0)
	result.wind_delta = Vector2(channels.get("wind_x", 0.0), channels.get("wind_y", 0.0))
	result.current_delta = Vector2(channels.get("current_x", 0.0), channels.get("current_y", 0.0))
	result.amplitude_delta = channels.get("amplitude", 0.0)
	return result
