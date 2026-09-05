extends Node3D
## P1 playable laboratory. All art and numerical framing settings are provisional.

const CameraRig = preload("res://game/camera/orbit_camera.gd")
const Ocean = preload("res://game/world/ocean_surface.gd")
const BucketArt = preload("res://game/presentation/bucket_proxy.gd")
const FishArt = preload("res://game/presentation/fish_proxy.gd")

var camera: Camera3D
var ocean: Node3D
var bucket: Node3D
var fishes: Array[Node3D] = []
var simulation_time: float = 0.0
var paused: bool = false
var capture_mode: bool = false
var committed_point: Vector3 = Vector3.ZERO
var has_committed_point: bool = false
var preview: MeshInstance3D
var committed: MeshInstance3D
var fishing_line: MeshInstance3D
var line_material: StandardMaterial3D
var hud: CanvasLayer
var pitch_slider: HSlider
var pitch_label: Label
var mode_label: Label
var footer_label: Label
var pause_button: Button
var _candidate: Dictionary = {"valid":false}
var _mouse_over_controls: bool = false
var _suppress_commit: bool = false
var _controller_cursor: Vector2 = Vector2(640,400)
var _using_controller: bool = false
var _capture_directory: String = ""

func _ready() -> void:
	_register_input()
	_build_environment()
	ocean = Ocean.new()
	add_child(ocean)
	bucket = BucketArt.new()
	bucket.name = "BucketSimulationRoot"
	add_child(bucket)
	var body := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = 1.15
	cylinder.height = 1.2
	collider.shape = cylinder
	collider.position.y = 0.2
	body.add_child(collider)
	bucket.add_child(body)
	for index in range(6):
		var fish: Node3D = FishArt.new()
		add_child(fish)
		fishes.append(fish)
	camera = CameraRig.new()
	add_child(camera)
	preview = _ring(Color("f4edd6"),0.23)
	committed = _ring(Color("e2b58d"),0.27)
	committed.visible = false
	line_material = _unshaded(Color("e9ddbb"))
	fishing_line = MeshInstance3D.new()
	fishing_line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(fishing_line)
	_build_hud()
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			_capture_directory = argument.trim_prefix("--capture-dir=")
	if not _capture_directory.is_empty():
		capture_mode = true
		paused = true
		simulation_time = 1.5
		call_deferred("_capture_views")
	_update_scene(0.0)

func _build_environment() -> void:
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var material := ShaderMaterial.new()
	material.shader = load("res://game/world/paper_sky.gdshader")
	sky.sky_material = material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("cbd1bc")
	environment.ambient_light_energy = 0.35
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	environment_node.environment = environment
	add_child(environment_node)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38,-28,0)
	sun.light_color = Color("f4edd6")
	sun.light_energy = 0.72
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 35.0
	add_child(sun)

func _process(delta: float) -> void:
	if not paused:
		simulation_time += delta
		var movement := Input.get_vector("move_left","move_right","move_forward","move_back")
		bucket.position += CameraRig.steering_vector(movement,camera.basis) * 2.0 * delta
		var tilt: float = Input.get_axis("tilt_lower","tilt_higher")
		if absf(tilt) > 0.01:
			camera.set_pitch(camera.pitch_degrees + tilt * 25.0 * delta)
		_update_controller(delta)
	_update_scene(delta if not paused else 0.0)
	if not paused:
		_update_preview()
	else:
		preview.visible = false
	if _suppress_commit and not Input.is_action_pressed("commit_target"):
		_suppress_commit = false
	_update_hud()

func _update_scene(delta: float) -> void:
	bucket.position.y = Ocean.height_at(bucket.position,simulation_time)
	bucket.update_pose(simulation_time,Input.get_vector("move_left","move_right","move_forward","move_back").length()>0.1 and not paused)
	ocean.update_surface(simulation_time,bucket.position)
	for index in range(fishes.size()):
		var t: float = simulation_time * 0.12 + float(index) * 0.55
		# Deterministic local motion, independent of camera and player heading.
		var p := Vector3(sin(t)*2.4+2.2+float(index%2)*0.5,0,-3.2+cos(t)*1.2-float(index)*0.48)
		p.y = Ocean.height_at(p,simulation_time) + 0.032
		fishes[index].position = p
		fishes[index].rotation.y = -t + PI*0.5
		fishes[index].update_pose(simulation_time + index)
	camera.focus_position = Vector3(bucket.position.x,1.5,bucket.position.z-0.8)
	camera.update_camera(delta)
	if has_committed_point:
		committed.position = Vector3(committed_point.x,Ocean.height_at(committed_point,simulation_time)+0.045,committed_point.z)
		_draw_line(bucket.to_global(bucket.get_rod_tip_local()),committed.position)
	else:
		fishing_line.mesh = null

func _update_controller(delta: float) -> void:
	if Input.get_connected_joypads().is_empty():
		return
	var device: int = Input.get_connected_joypads()[0]
	var aim := Vector2(Input.get_joy_axis(device,JOY_AXIS_RIGHT_X),Input.get_joy_axis(device,JOY_AXIS_RIGHT_Y))
	if aim.length()>0.18:
		_using_controller = true
		_controller_cursor += aim * 480.0 * delta
		_controller_cursor = _controller_cursor.clamp(Vector2.ZERO,get_viewport().get_visible_rect().size)

func _update_preview() -> void:
	var screen_point: Vector2 = _controller_cursor if _using_controller else get_viewport().get_mouse_position()
	if _mouse_over_controls and not _using_controller:
		preview.visible = false
		_candidate = {"valid":false}
		return
	var origin: Vector3 = camera.project_ray_origin(screen_point)
	var direction: Vector3 = camera.project_ray_normal(screen_point)
	_candidate = CameraRig.resolve_plane_hit(origin,direction,bucket.position)
	if _candidate.valid:
		var hit: Vector3 = _candidate.point
		# Refine the mean-plane guess against the SAME height function rendered by the ocean.
		var distance: float = origin.distance_to(hit)
		for iteration in range(5):
			var point: Vector3 = origin+direction*distance
			var normal: Vector3 = Ocean.normal_at(point,simulation_time)
			var derivative: float = direction.y + normal.x/normal.y * direction.x
			if absf(derivative)<0.0001:
				_candidate.valid = false
				break
			distance -= (point.y-Ocean.height_at(point,simulation_time))/derivative
		hit = origin+direction*distance
		if distance<0 or distance>200 or Vector2(hit.x-bucket.position.x,hit.z-bucket.position.z).length()>12.0:
			_candidate.valid = false
		var query := PhysicsRayQueryParameters3D.create(origin,hit)
		if not get_world_3d().direct_space_state.intersect_ray(query).is_empty():
			_candidate.valid = false
		_candidate.point = hit
	preview.visible = _candidate.valid
	if _candidate.valid:
		preview.position = _candidate.point + Vector3.UP*0.04

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_using_controller = false
	if event.is_action_pressed("toggle_hud"):
		hud.visible = not hud.visible
		_mouse_over_controls = false
		return
	if event.is_action_pressed("pause_study"):
		_set_paused(not paused)
		return
	if paused:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.set_pitch(camera.pitch_degrees+2.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.set_pitch(camera.pitch_degrees-2.0)
	if event.is_action_pressed("cancel_target"):
		has_committed_point = false
		committed.visible = false
	if event.is_action_pressed("commit_target") and not _suppress_commit:
		_update_preview()
		if _candidate.get("valid",false):
			committed_point = _candidate.point
			has_committed_point = true
			committed.visible = true

func _set_paused(value: bool) -> void:
	paused = value
	_suppress_commit = true
	pause_button.text = "Resume" if paused else "Pause"
	pitch_slider.editable = not paused

func _register_input() -> void:
	_action("move_left",[KEY_A],JOY_AXIS_LEFT_X,-1.0)
	_action("move_right",[KEY_D],JOY_AXIS_LEFT_X,1.0)
	_action("move_forward",[KEY_W],JOY_AXIS_LEFT_Y,-1.0)
	_action("move_back",[KEY_S],JOY_AXIS_LEFT_Y,1.0)
	_action("tilt_lower",[KEY_Q])
	_action("tilt_higher",[KEY_E])
	_action("toggle_hud",[KEY_TAB])
	_action("pause_study",[KEY_ESCAPE])
	_action("cancel_target",[KEY_BACKSPACE])
	_action("commit_target",[KEY_SPACE])
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("commit_target",click)
	var right_click := InputEventMouseButton.new()
	right_click.button_index = MOUSE_BUTTON_RIGHT
	InputMap.action_add_event("cancel_target",right_click)
	for entry in [["commit_target",JOY_BUTTON_A],["cancel_target",JOY_BUTTON_B],["pause_study",JOY_BUTTON_START]]:
		var button := InputEventJoypadButton.new()
		button.button_index = entry[1]
		InputMap.action_add_event(entry[0],button)
	for entry in [["tilt_lower",JOY_BUTTON_LEFT_SHOULDER],["tilt_higher",JOY_BUTTON_RIGHT_SHOULDER]]:
		var button := InputEventJoypadButton.new()
		button.button_index = entry[1]
		InputMap.action_add_event(entry[0],button)

func _action(name: String, keys: Array, axis: int = -1, value: float = 0.0) -> void:
	if not InputMap.has_action(name):
		InputMap.add_action(name,0.18)
	for key in keys:
		var input := InputEventKey.new()
		input.physical_keycode = key
		InputMap.action_add_event(name,input)
	if axis>=0:
		var stick := InputEventJoypadMotion.new()
		stick.axis = axis
		stick.axis_value = value
		InputMap.action_add_event(name,stick)

func _build_hud() -> void:
	hud = CanvasLayer.new()
	add_child(hud)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(root)
	var theme := Theme.new()
	theme.default_font_size = 15
	theme.set_color("font_color","Label",Color("f4edd6"))
	theme.set_color("font_color","Button",Color("183e57"))
	theme.set_color("font_color","CheckButton",Color("f4edd6"))
	var button_style := StyleBoxFlat.new()
	button_style.bg_color = Color("e9ddbb")
	button_style.set_corner_radius_all(5)
	button_style.content_margin_left = 13
	button_style.content_margin_right = 13
	button_style.content_margin_top = 8
	button_style.content_margin_bottom = 8
	theme.set_stylebox("normal","Button",button_style)
	var hover: StyleBoxFlat = button_style.duplicate()
	hover.bg_color = Color("fff3d4")
	theme.set_stylebox("hover","Button",hover)
	theme.set_stylebox("pressed","Button",hover)
	root.theme = theme
	var title := Label.new()
	title.text = "I C H I G O"
	title.position = Vector2(34,26)
	title.add_theme_font_size_override("font_size",27)
	root.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "CAMERA STUDY  /  01"
	subtitle.position = Vector2(35,62)
	subtitle.add_theme_font_size_override("font_size",11)
	root.add_child(subtitle)
	mode_label = Label.new()
	mode_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	mode_label.position = Vector2(-260,31)
	mode_label.size.x = 225
	mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(mode_label)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 24
	panel.offset_right = -24
	panel.offset_top = -119
	panel.offset_bottom = -24
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.075,0.19,0.24,0.90)
	panel_style.set_corner_radius_all(8)
	panel_style.content_margin_left = 20
	panel_style.content_margin_right = 20
	panel_style.content_margin_top = 12
	panel_style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel",panel_style)
	panel.mouse_entered.connect(func(): _mouse_over_controls = true)
	panel.mouse_exited.connect(func(): _mouse_over_controls = false)
	root.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",10)
	panel.add_child(column)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",14)
	column.add_child(row)
	pitch_label = Label.new()
	pitch_label.custom_minimum_size.x = 84
	row.add_child(pitch_label)
	pitch_slider = HSlider.new()
	pitch_slider.min_value = 12
	pitch_slider.max_value = 52
	pitch_slider.step = 0.5
	pitch_slider.value = 20
	pitch_slider.custom_minimum_size.x = 140
	pitch_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pitch_slider.value_changed.connect(func(value: float):
		if not paused: camera.set_pitch(value))
	row.add_child(pitch_slider)
	for preset in [["Sky",12.0],["Travel",20.0],["Detail",52.0]]:
		var button := Button.new()
		button.text = preset[0]
		var angle: float = preset[1]
		button.pressed.connect(func():
			if not paused: camera.set_pitch(angle))
		row.add_child(button)
	pause_button = Button.new()
	pause_button.text = "Pause"
	pause_button.pressed.connect(func(): _set_paused(not paused))
	row.add_child(pause_button)
	footer_label = Label.new()
	footer_label.text = "WASD move  ·  Q / E or scroll tilt  ·  Click water to place line  ·  Right click clear  ·  Tab hide study controls"
	footer_label.add_theme_font_size_override("font_size",12)
	footer_label.modulate = Color("b2c4c0")
	column.add_child(footer_label)

func _update_hud() -> void:
	pitch_slider.set_value_no_signal(camera.pitch_degrees)
	pitch_label.text = "View  %.0f°" % camera.pitch_degrees
	mode_label.text = "PAUSED" if paused else "PROVISIONAL FORMS"

func _unshaded(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	return material

func _ring(color: Color, radius: float) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius-0.018
	mesh.outer_radius = radius+0.018
	mesh.rings = 24
	mesh.ring_segments = 6
	instance.mesh = mesh
	instance.material_override = _unshaded(color)
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)
	return instance

func _draw_line(start: Vector3, finish: Vector3) -> void:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP,line_material)
	for index in range(25):
		var t: float = float(index)/24.0
		var p: Vector3 = start.lerp(finish,t)
		p.y -= sin(t*PI)*0.32
		mesh.surface_add_vertex(p)
	mesh.surface_end()
	fishing_line.mesh = mesh

func _capture_views() -> void:
	DirAccess.make_dir_recursive_absolute(_capture_directory)
	preview.visible = false
	for angle in [12.0,20.0,26.0,38.0,52.0]:
		camera.set_pitch(angle,true)
		_update_scene(0.0)
		_update_hud()
		for frame in range(5):
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var image: Image = get_viewport().get_texture().get_image()
		var path := _capture_directory.path_join("camera-%02d.png" % int(angle))
		var error: Error = image.save_png(path)
		print("CAPTURE ",path," status=",error)
	get_tree().quit()
