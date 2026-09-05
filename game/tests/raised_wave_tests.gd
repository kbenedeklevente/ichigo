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
	var ribbon: Transform3D = presentation._ribbon_transforms[0]
	_check(absf(ribbon.basis.y.z) > 1.3, "Low scenery spans depth between upright crest rows")
	_check(ribbon.origin != presentation._card_transforms[0].origin, "Low scenery has its own staggered anchor")
	var first := presentation._card_transforms[0]
	var second := presentation._card_transforms[1]
	_check(first.origin.distance_to(second.origin) > 3.0, "Cards retain separate world anchors")
	_check(first.basis != second.basis, "Different cards have independent roots and pivots")
	var before: Array[Transform3D] = []
	for i in range(mm.instance_count):
		before.append(presentation._card_transforms[i])
	presentation.update_weather(surface, 0.0, Vector3.ZERO)
	_check(presentation._card_transforms[0] == before[0], "Paused updates preserve card pose exactly")
	weather.advance(1.0, Vector2.ZERO)
	surface.update()
	presentation.update_weather(surface, 1.0, Vector3.ZERO)
	var changed := 0
	for i in range(mm.instance_count):
		if presentation._card_transforms[i] != before[i]:
			changed += 1
	_check(changed > 200, "The shared spring solver moves independently posed cards")
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
