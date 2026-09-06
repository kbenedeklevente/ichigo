extends SceneTree
## Variant 03 replaces raised connected geometry with upright die-cut cards.
const Weather = preload("res://game/world/weather_simulation.gd")
const Surface = preload("res://game/world/illustrated_water_surface.gd")
const Presentation = preload("res://game/world/weather_presentation.gd")
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)

func _run() -> void:
	var weather := Weather.new()
	weather.configure(15)
	var surface := Surface.new()
	surface.configure(weather)
	var presentation := Presentation.new()
	root.add_child(presentation)
	presentation.update_weather(surface, 0.0, Vector3.ZERO)
	_check(surface.get_panel_states().size() == 289, "Exactly 17 by 17 independent card anchors")
	_check(surface.get_status().simulated_cells == 1089, "A 33 by 33 shared spring/weather field underlies the cards")
	var mesh := Presentation.build_surface_mesh()
	var vertices: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	_check(vertices.size() == 4, "Each rendering primitive is a rigid four-corner card")
	for vertex in vertices:
		_check(is_zero_approx(vertex.z), "All card vertices lie in an upright XY plane")
	_check(vertices[2].y > 3.0, "Card has a substantial upright silhouette")
	var mm: MultiMesh = presentation._panels.multimesh
	_check(presentation._ribbons.multimesh.instance_count == 289, "Each cell also owns one separate low scenic ribbon")
	var first: Transform3D = mm.get_instance_transform(0)
	var second: Transform3D = mm.get_instance_transform(1)
	_check(first.origin.distance_to(second.origin) > 3.0, "Baseline cards retain separate logical-spaced anchors")
	_check(mm.get_instance_custom_data(0) != mm.get_instance_custom_data(1), "Neighbor drawings retain independent artwork choices")
	_check(presentation._ribbons.multimesh.get_instance_custom_data(0).a == 0.0, "Shader receives an explicit reclining-ribbon kind")
	var original_field: PackedByteArray = surface._field_image.get_data()
	var original_layout: int = presentation.get_density_status().layout_rebuilds
	presentation.update_weather(surface, 0.0, Vector3.ZERO)
	_check(mm.get_instance_transform(0) == first and surface._field_image.get_data() == original_field, "Paused updates preserve anchor and weather field exactly")
	weather.advance(1.0, Vector2.ZERO)
	surface.update()
	presentation.update_weather(surface, 1.0, Vector3.ZERO)
	_check(surface._field_image.get_data() != original_field, "Spring evolution reaches the shader's fixed-size texture")
	_check(mm.get_instance_transform(0) == first and presentation.get_density_status().layout_rebuilds == original_layout, "Wave motion needs no CPU anchor rebuild or per-drawing physics state")
	var fixed := surface.height_at(Vector2(0.4, 0.2))
	for angle in [12.0, 20.0, 52.0]:
		var camera := Camera3D.new()
		camera.rotation_degrees.x = -angle
		_check(is_equal_approx(surface.height_at(Vector2(0.4, 0.2)), fixed), "Camera angle does not alter invisible gameplay height")
		camera.free()
	for failure in failures:
		push_error(failure)
	print("Paper theatre cards: %d checks, %d failures" % [checks, failures.size()])
	presentation.queue_free()
	quit(0 if failures.is_empty() else 1)
