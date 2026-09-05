extends Node3D
## One visible salvage fixture. Its position is owned by the event instance.

var _drawing := MeshInstance3D.new()

func _ready() -> void:
	var mesh := QuadMesh.new()
	mesh.size = Vector2(1.8, 0.9)
	_drawing.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_texture = preload("res://game/presentation/salvage_marker.svg")
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_drawing.material_override = material
	_drawing.rotation.x = -PI * 0.32
	_drawing.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_drawing)
	visible = false

func update_encounter(encounters, surface, camera: Camera3D, player: Vector3) -> void:
	var event = encounters.get_active()
	visible = event != null
	if event == null:
		return
	var height: float = surface.sample(event.center).height
	position = Vector3(event.center.x, height + 0.12, event.center.y)
	var radius: float = maxf(event.bounds_radius, 1.0)
	var viewport: Rect2 = camera.get_viewport().get_visible_rect().grow(96.0)
	var projected := Rect2()
	var initialized := false
	var in_front := false
	var behind := false
	# Project full actor bounds, rather than retiring when just its center leaves.
	for x in [-radius, radius]:
		for y in [-radius, radius]:
			for z in [-radius, radius]:
				var corner := position + Vector3(x, y, z)
				if camera.is_position_behind(corner):
					behind = true
					continue
				in_front = true
				var point: Vector2 = camera.unproject_position(corner)
				if not initialized:
					projected = Rect2(point, Vector2.ZERO)
					initialized = true
				else:
					projected = projected.expand(point)
	var on_screen: bool = in_front and (behind or projected.intersects(viewport, true))
	var near_player: bool = event.center.distance_to(Vector2(player.x, player.z)) <= 12.0 + radius
	encounters.report_visibility(on_screen, near_player)
