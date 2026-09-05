extends Node3D
## Procedural P1 art. Origin is the physical bucket waterline; all motion is visual.

const GRIP := Vector3(0.38, 1.08, -0.18)
const ROD_TIP := Vector3(1.13, 1.95, -0.79)
const STAVE_COUNT := 22

var _child: Node3D
var _wood: Array[StandardMaterial3D] = []
var _paper: StandardMaterial3D
var _skin: StandardMaterial3D
var _blue: StandardMaterial3D
var _hair: StandardMaterial3D


func _ready() -> void:
	_paper = _material(Color("e9ddbb"))
	_skin = _material(Color("d7b991"))
	_blue = _material(Color("447489"))
	_hair = _material(Color("55483f"))
	for color in ["896348", "9b7353", "a37b58", "795940", "ad825b"]:
		_wood.append(_material(Color(color)))
	_build_bucket()
	_build_child()
	_build_rod()


func get_grip_local() -> Vector3:
	return GRIP


func get_rod_tip_local() -> Vector3:
	return ROD_TIP


func update_pose(simulation_time: float, moving: bool) -> void:
	if not is_instance_valid(_child):
		return
	# The reaching hand and rod remain at their declared anchors.
	_child.rotation.z = sin(simulation_time * 1.4) * (0.016 if moving else 0.006)


func _build_bucket() -> void:
	# Separate thick staves form a genuinely open vessel, with small paper seams.
	for index in range(STAVE_COUNT):
		var angle := TAU * float(index) / float(STAVE_COUNT)
		var half_span := PI / float(STAVE_COUNT) - 0.004
		_wedge(self, angle - half_span, angle + half_span,
			-0.4, 0.80, 0.96, 1.15, 0.067, _wood[index % _wood.size()])
		# A thicker exposed lip makes the opening visible at both camera extremes.
		_wedge(self, angle - half_span, angle + half_span,
			0.765, 0.835, 1.175, 1.175, 0.108, _wood[(index + 2) % _wood.size()])
	var floor_mesh := CylinderMesh.new()
	floor_mesh.top_radius = 0.915
	floor_mesh.bottom_radius = 0.915
	floor_mesh.height = 0.045
	floor_mesh.radial_segments = STAVE_COUNT
	_instance(self, floor_mesh, Vector3(0.0, -0.35, 0.0), _wood[1])
	var band := _material(Color("66797a"))
	for band_height in [-0.19, 0.53]:
		var radius := lerpf(0.96, 1.15, (band_height + 0.4) / 1.2) + 0.014
		for index in range(STAVE_COUNT):
			_wedge(self, TAU * index / STAVE_COUNT, TAU * (index + 1) / STAVE_COUNT,
				band_height - 0.027, band_height + 0.027, radius, radius + 0.009, 0.017, band)
	# Seat and interior floor establish containment without filling the opening.
	_box(self, Vector3(1.72, 0.065, 0.34), Vector3(0.0, 0.35, 0.12), _wood[2])


func _build_child() -> void:
	_child = Node3D.new()
	_child.name = "ChildVisual"
	add_child(_child)
	# Small child, broad loose jersey, no specified gender/age or sport styling.
	var jersey := SurfaceTool.new()
	jersey.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lower_left := Vector3(-0.34, 0.55, 0.19)
	var lower_right := Vector3(0.34, 0.55, 0.19)
	var upper_right := Vector3(0.24, 1.31, 0.14)
	var upper_left := Vector3(-0.24, 1.31, 0.14)
	_quad(jersey, lower_left, lower_right, upper_right, upper_left)
	_quad(jersey, upper_left + Vector3(0, 0, -0.30), upper_right + Vector3(0, 0, -0.30),
		lower_right + Vector3(0, 0, -0.36), lower_left + Vector3(0, 0, -0.36))
	_quad(jersey, lower_left + Vector3(0, 0, -0.36), lower_left, upper_left,
		upper_left + Vector3(0, 0, -0.30))
	_quad(jersey, lower_right, lower_right + Vector3(0, 0, -0.36),
		upper_right + Vector3(0, 0, -0.30), upper_right)
	_quad(jersey, upper_left, upper_right, upper_right + Vector3(0, 0, -0.30),
		upper_left + Vector3(0, 0, -0.30))
	_instance(_child, jersey.commit(), Vector3.ZERO, _blue)
	_box(_child, Vector3(0.23, 0.28, 0.31), Vector3(-0.31, 1.14, -0.01), _blue)
	_box(_child, Vector3(0.23, 0.28, 0.31), Vector3(0.31, 1.14, -0.01), _blue)
	_box(_child, Vector3(0.61, 0.035, 0.025), Vector3(0.0, 0.61, 0.198), _paper)
	_sphere(_child, Vector3(0.0, 1.32, -0.015), Vector3(0.10, 0.13, 0.09), _skin)
	_sphere(_child, Vector3(0.0, 1.56, -0.02), Vector3(0.225, 0.235, 0.20), _skin)
	for side in [-1.0, 1.0]:
		_sphere(_child, Vector3(side * 0.217, 1.54, -0.02), Vector3(0.045, 0.06, 0.04), _skin)
	# Irregular hair locks have no brim or accessory; the child faces local -Z.
	_sphere(_child, Vector3(0.0, 1.65, 0.045), Vector3(0.23, 0.17, 0.18), _hair)
	for index in range(5):
		var x := (float(index) - 2.0) * 0.083
		_sphere(_child, Vector3(x, 1.735 + 0.025 * sin(index * 2.1), -0.05),
			Vector3(0.073, 0.07, 0.09), _hair)
	_sphere(_child, Vector3(-0.34, 0.945, -0.055), Vector3(0.055, 0.095, 0.055), _skin)
	# Tiny legs and feet partly disappear behind the front wall, as real depth dictates.
	for side in [-1.0, 1.0]:
		_sphere(_child, Vector3(side * 0.16, 0.52, -0.02), Vector3(0.067, 0.13, 0.068), _skin)
		_sphere(_child, Vector3(side * 0.16, 0.42, -0.085), Vector3(0.08, 0.055, 0.12), _paper)
	var number := Label3D.new()
	number.name = "UnmirroredJersey15"
	number.text = "15"
	number.font_size = 96
	number.pixel_size = 0.0031
	number.outline_size = 0
	number.modulate = Color("f4edd6")
	number.position = Vector3(0.0, 1.01, 0.18)
	number.rotation.x = deg_to_rad(3.76)
	number.double_sided = false
	number.shaded = true
	_child.add_child(number)


func _build_rod() -> void:
	_sphere(self, GRIP, Vector3(0.064, 0.066, 0.064), _skin)
	var rod_material := _material(Color("665b47"))
	_between(self, GRIP - (ROD_TIP - GRIP) * 0.16, ROD_TIP, 0.021, rod_material)
	_between(self, GRIP - (ROD_TIP - GRIP) * 0.13, GRIP + (ROD_TIP - GRIP) * 0.10,
		0.029, _paper)


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.95
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


func _instance(parent: Node3D, mesh: Mesh, at: Vector3, material: Material) -> MeshInstance3D:
	var result := MeshInstance3D.new()
	result.mesh = mesh
	result.material_override = material
	result.position = at
	parent.add_child(result)
	return result


func _box(parent: Node3D, size: Vector3, at: Vector3, material: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	_instance(parent, mesh, at, material)


func _sphere(parent: Node3D, at: Vector3, radii: Vector3, material: Material) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	_instance(parent, mesh, at, material).scale = radii


func _between(parent: Node3D, start: Vector3, end: Vector3, radius: float, material: Material) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 0.62
	mesh.bottom_radius = radius
	mesh.height = start.distance_to(end)
	mesh.radial_segments = 8
	var instance := _instance(parent, mesh, (start + end) * 0.5, material)
	instance.quaternion = Quaternion(Vector3.UP, (end - start).normalized())


func _wedge(parent: Node3D, a: float, b: float, bottom: float, top: float,
		bottom_radius: float, top_radius: float, thickness: float, material: Material) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points: Array[Vector3] = []
	for level in [0, 1]:
		var y := bottom if level == 0 else top
		var radius := bottom_radius if level == 0 else top_radius
		for inset in [0.0, thickness]:
			for angle in [a, b]:
				points.append(Vector3(sin(angle) * (radius - inset), y, cos(angle) * (radius - inset)))
	_quad(surface, points[0], points[1], points[5], points[4])
	_quad(surface, points[3], points[2], points[6], points[7])
	_quad(surface, points[4], points[5], points[7], points[6])
	_quad(surface, points[2], points[3], points[1], points[0])
	_quad(surface, points[2], points[0], points[4], points[6])
	_quad(surface, points[1], points[3], points[7], points[5])
	_instance(parent, surface.commit(), Vector3.ZERO, material)


func _quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	var normal := (b - a).cross(c - a).normalized()
	# Godot uses clockwise front faces; retain the outward geometric normal.
	for vertex in [a, c, b, a, d, c]:
		surface.set_normal(normal)
		surface.add_vertex(vertex)
