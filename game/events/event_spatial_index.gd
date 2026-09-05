extends RefCounted
## Sparse broad phase. Bounds cover actor and modifier footprints, not just centers.

var cell_size: float = 16.0
var _cells: Dictionary = {}
var _entries: Dictionary = {}

func index(id: String, center: Vector2, radius: float) -> void:
	if id.is_empty() or not center.is_finite() or not is_finite(radius) or radius < 0.0 or cell_size <= 0.0:
		return
	remove(id)
	var bounds := Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2.0)
	var covered: Array[Vector2i] = _covered(bounds)
	_entries[id] = {"center": center, "radius": radius, "cells": covered}
	for cell: Vector2i in covered:
		if not _cells.has(cell):
			_cells[cell] = {}
		_cells[cell][id] = true

func remove(id: String) -> void:
	if not _entries.has(id):
		return
	for cell: Vector2i in _entries[id].cells:
		_cells[cell].erase(id)
		if _cells[cell].is_empty():
			_cells.erase(cell)
	_entries.erase(id)

func query_point(point: Vector2) -> Array[String]:
	var result: Array[String] = []
	if not point.is_finite():
		return result
	var cell := Vector2i(floori(point.x / cell_size), floori(point.y / cell_size))
	for id: String in _cells.get(cell, {}):
		if point.distance_to(_entries[id].center) <= _entries[id].radius:
			result.append(id)
	result.sort()
	return result

func query_rect(bounds: Rect2) -> Array[String]:
	var result: Array[String] = []
	if not bounds.position.is_finite() or not bounds.size.is_finite():
		return result
	bounds = bounds.abs()
	var candidates: Dictionary = {}
	for cell: Vector2i in _covered(bounds.abs()):
		for id: String in _cells.get(cell, {}):
			candidates[id] = true
	for id: String in candidates:
		var entry: Dictionary = _entries[id]
		var closest := Vector2(clampf(entry.center.x, bounds.position.x, bounds.end.x), clampf(entry.center.y, bounds.position.y, bounds.end.y))
		if closest.distance_to(entry.center) <= entry.radius:
			result.append(id)
	result.sort()
	return result

func _covered(bounds: Rect2) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for x: int in range(floori(bounds.position.x / cell_size), floori(bounds.end.x / cell_size) + 1):
		for y: int in range(floori(bounds.position.y / cell_size), floori(bounds.end.y / cell_size) + 1):
			result.append(Vector2i(x, y))
	return result
