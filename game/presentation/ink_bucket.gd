extends Node3D
## Original paper drawings; simulation root and fishing anchors are retained.
const GRIP := Vector3(0.38, 1.08, -0.18)
const ROD_TIP := Vector3(1.13, 1.95, -0.79)
var _child: MeshInstance3D

func _ready() -> void:
	_card("res://game/presentation/ink/interior.svg", Vector2(2.6, 1.8), Vector3(0, 0.54, -0.1), -72)
	_child = _card("res://game/presentation/ink/child.svg", Vector2(0.90, 1.43), Vector3(0, 1.23, -0.04), -18)
	_card("res://game/presentation/ink/bucket.svg", Vector2(2.66, 1.46), Vector3(0, 0.18, 0.50), -16)
	var rod := ImmediateMesh.new()
	rod.surface_begin(Mesh.PRIMITIVE_LINES)
	rod.surface_add_vertex(GRIP)
	rod.surface_add_vertex(ROD_TIP)
	rod.surface_end()
	var rod_view := MeshInstance3D.new()
	rod_view.mesh = rod
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color("263f48")
	rod_view.material_override = material
	add_child(rod_view)

func _card(path: String, size: Vector2, at: Vector3, angle: float) -> MeshInstance3D:
	var mesh := QuadMesh.new()
	mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_texture = load(path)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	material.alpha_scissor_threshold = 0.4
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var card := MeshInstance3D.new()
	card.mesh = mesh
	card.material_override = material
	card.position = at
	card.rotation_degrees.x = angle
	card.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(card)
	return card

func get_grip_local() -> Vector3:
	return GRIP

func get_rod_tip_local() -> Vector3:
	return ROD_TIP

func update_pose(time: float, moving: bool) -> void:
	_child.rotation.z = sin(time * 1.4) * (0.016 if moving else 0.006)
