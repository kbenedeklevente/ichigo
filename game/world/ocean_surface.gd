extends Node3D
## Direct-follow P1 wave fixture; renderer and bucket share simulation time.

var _surface: MeshInstance3D
var _material: ShaderMaterial
var _far_surface: MeshInstance3D
var _far_material: ShaderMaterial

static func height_at(point: Vector3, simulation_time: float) -> float:
	return 0.15 * sin(TAU * (point.x / 8.0 - simulation_time / 4.0))

static func normal_at(point: Vector3, simulation_time: float) -> Vector3:
	var slope: float = 0.15 * TAU / 8.0 * cos(TAU * (point.x / 8.0 - simulation_time / 4.0))
	return Vector3(-slope, 1.0, 0.0).normalized()

static func flow_at(_point: Vector3, _simulation_time: float) -> Vector3:
	return Vector3.ZERO

func _ready() -> void:
	_material = ShaderMaterial.new()
	_material.shader = load("res://game/world/paper_ocean.gdshader")
	_surface = MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(120.0, 120.0)
	plane.subdivide_width = 180
	plane.subdivide_depth = 180
	_surface.mesh = plane
	_surface.material_override = _material
	_surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_surface.extra_cull_margin = 0.3
	add_child(_surface)
	_far_surface = MeshInstance3D.new()
	var far_plane := PlaneMesh.new()
	far_plane.size = Vector2(8000.0, 8000.0)
	_far_surface.mesh = far_plane
	_far_material = ShaderMaterial.new()
	_far_material.shader = _material.shader
	_far_material.set_shader_parameter("distant_surface",true)
	_far_surface.material_override = _far_material
	_far_surface.position.y = -0.25
	_far_surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_far_surface)

func update_surface(simulation_time: float, center: Vector3) -> void:
	# Only translate meshes in X/Z; shader waves sample resulting world coordinates.
	_surface.position = Vector3(center.x, 0.0, center.z)
	_far_surface.position = Vector3(center.x, -0.25, center.z)
	_material.set_shader_parameter("simulation_time", simulation_time)
	_material.set_shader_parameter("bucket_center", Vector2(center.x, center.z))
	_far_material.set_shader_parameter("bucket_center",Vector2(center.x,center.z))
