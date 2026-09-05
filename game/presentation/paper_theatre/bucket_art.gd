extends Node3D
## Layered paper art. Origin, collision and tool anchors stay at the physical root.
## Authored for fixed azimuth with 12–52 degree pitch; no camera-driven transforms.

const GRIP := Vector3(0.38, 1.08, -0.18)
const ROD_TIP := Vector3(1.13, 1.95, -0.79)
const ART_ROOT := "res://game/presentation/paper_theatre/"
var _child: MeshInstance3D

func _ready() -> void:
	# World depth, rather than painter order, resolves the open bucket layering.
	_card("bucket_interior.svg", "InteriorAndSeat", Vector2(2.25, 1.94), Vector3(0, 0.22, -0.02), -90)
	_card("bucket_rear.svg", "RearWallAndLip", Vector2(2.60, 0.94), Vector3(0, 0.62, -0.46), -18)
	_child = _card("child_back.svg", "ChildVisual", Vector2(0.96, 1.43), Vector3(0, 1.23, -0.04), -18)
	_card("bucket_front.svg", "FrontWall", Vector2(2.66, 1.46), Vector3(0, 0.18, 0.50), -16)
	_card("bucket_rim.svg", "FrontRim", Vector2(2.66, 1.46), Vector3(0, 0.18, 0.514), -16)
	for side in [-1.0, 1.0]:
		_side_cheek(side, false)
		_side_cheek(side, true)
	_build_rod()

func _card(asset: String, label: String, size: Vector2, at: Vector3, angle: float) -> MeshInstance3D:
	var mesh := QuadMesh.new()
	mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_texture = load(ART_ROOT + asset)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	material.alpha_scissor_threshold = 0.4
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var card := MeshInstance3D.new()
	card.name = label
	card.mesh = mesh
	card.material_override = material
	card.position = at
	card.rotation_degrees.x = angle
	card.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(card)
	return card

func _build_rod() -> void:
	var direction := ROD_TIP - GRIP
	_strip(GRIP - direction * 0.16, ROD_TIP, 0.026, Color("10283d"), "DrawnRod")
	_strip(GRIP - direction * 0.13, GRIP + direction * 0.10, 0.041, Color("eee4c5"), "RodGripWrap")
	# A tiny stationary hand cutout keeps the reaching grip at the public anchor.
	_card("grip.svg", "ReachingHand", Vector2(0.135, 0.135), GRIP + Vector3(0, 0, 0.012), -18)

func _strip(start: Vector3, finish: Vector3, width: float, color: Color, label: String) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var side := Vector3.RIGHT * width * 0.5
	for point in [start - side, finish + side, start + side, start - side, finish - side, finish + side]:
		surface.set_normal(Vector3.FORWARD)
		surface.add_vertex(point)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var strip := MeshInstance3D.new()
	strip.name = label
	strip.mesh = surface.commit()
	strip.material_override = material
	strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(strip)

func get_grip_local() -> Vector3:
	return GRIP

func get_rod_tip_local() -> Vector3:
	return ROD_TIP

func update_pose(simulation_time: float, moving: bool) -> void:
	if not is_instance_valid(_child):
		return
	# Same subtle body sway as the proxy; reaching hand and rod stay anchored.
	_child.rotation.z = sin(simulation_time * 1.4) * (0.016 if moving else 0.006)

func _side_cheek(side: float, rim: bool) -> void:
	# Thin curved paper connectors close high-angle coverage between authored views.
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	const SEGMENTS := 8
	for segment in range(SEGMENTS):
		for corner in [Vector2i(0, 0), Vector2i(1, 1), Vector2i(1, 0), Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)]:
			var t := float(segment + corner.x) / SEGMENTS
			var z := lerpf(-0.53, 0.45, t)
			var outer_x := 1.16 + sin(t * PI) * 0.045
			var top_y := lerpf(0.48, 0.74, t) + sin(t * PI) * 0.035
			var x := outer_x
			var y := top_y
			if rim:
				x -= float(corner.y) * 0.12
				y += 0.006
			else:
				x = lerpf(outer_x, 1.015, float(corner.y))
				y = lerpf(top_y, -0.20, float(corner.y))
			surface.set_uv(Vector2(t, corner.y))
			surface.set_normal(Vector3.UP if rim else Vector3(side, 0, 0))
			surface.add_vertex(Vector3(side * x, y, z))
	var material := StandardMaterial3D.new()
	material.albedo_texture = load(ART_ROOT + ("bucket_side_rim.svg" if rim else "bucket_side.svg"))
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var art := MeshInstance3D.new()
	art.name = ("Right" if side > 0 else "Left") + ("PaperRimJoin" if rim else "PaperSideWall")
	art.mesh = surface.commit()
	art.material_override = material
	art.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(art)
