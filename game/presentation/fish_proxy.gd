extends Node3D
## Thin provisional fish, 0.55 m long, facing local -Z. Root motion is external.

var _tail: Node3D
var _body: Node3D


func _ready() -> void:
	var body_material := _material(Color("789e9d"))
	var fin_material := _material(Color("447489"))
	_body = Node3D.new()
	add_child(_body)
	_polygon(_body, [Vector2(0.0, -0.275), Vector2(0.051, -0.19),
		Vector2(0.080, -0.07), Vector2(0.062, 0.06), Vector2(0.026, 0.16),
		Vector2(-0.026, 0.16), Vector2(-0.062, 0.06), Vector2(-0.080, -0.07),
		Vector2(-0.051, -0.19)], 0.032, body_material)
	for side in [-1.0, 1.0]:
		_polygon(_body, [Vector2(side * 0.055, -0.09), Vector2(side * 0.127, 0.025),
			Vector2(side * 0.047, 0.015)], 0.009, fin_material)
		var eye := MeshInstance3D.new()
		var eye_mesh := SphereMesh.new()
		eye_mesh.radius = 0.010
		eye_mesh.height = 0.020
		eye_mesh.radial_segments = 8
		eye_mesh.rings = 4
		eye.mesh = eye_mesh
		eye.material_override = _material(Color("183e57"))
		eye.position = Vector3(side * 0.035, 0.019, -0.186)
		_body.add_child(eye)
	_tail = Node3D.new()
	_tail.position.z = 0.145
	_body.add_child(_tail)
	_polygon(_tail, [Vector2(0.0, -0.012), Vector2(0.084, 0.130),
		Vector2(0.0, 0.092), Vector2(-0.084, 0.130)], 0.012, fin_material)


func update_pose(time: float) -> void:
	if not is_instance_valid(_tail):
		return
	# A local tail hinge approximates body bend without moving the simulation root.
	_tail.rotation.y = sin(time * 8.0) * 0.30
	_body.rotation.y = sin(time * 8.0 - 0.8) * 0.045


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.97
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


func _polygon(parent: Node3D, outline: Array[Vector2], thickness: float, material: Material) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Thin extrusion preserves a small side silhouette at low camera angles.
	for index in range(outline.size()):
		var next := (index + 1) % outline.size()
		var a := Vector3(outline[index].x, thickness * 0.5, outline[index].y)
		var b := Vector3(outline[next].x, thickness * 0.5, outline[next].y)
		var c := Vector3(b.x, -thickness * 0.5, b.z)
		var d := Vector3(a.x, -thickness * 0.5, a.z)
		_triangle(surface, Vector3(0, thickness * 0.5, 0), a, b, Vector3.UP)
		_triangle(surface, Vector3(0, -thickness * 0.5, 0), d, c, Vector3.DOWN)
		var normal := Vector3(a.x + b.x, 0.0, a.z + b.z).normalized()
		_triangle(surface, a, d, c, normal)
		_triangle(surface, a, c, b, normal)
	var mesh := MeshInstance3D.new()
	mesh.mesh = surface.commit()
	mesh.material_override = material
	parent.add_child(mesh)


func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, normal: Vector3) -> void:
	var vertices: Array[Vector3] = [a, b, c]
	if (b - a).cross(c - a).dot(normal) > 0.0:
		vertices = [a, c, b]
	for vertex in vertices:
		surface.set_normal(normal)
		surface.add_vertex(vertex)
