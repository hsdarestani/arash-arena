extends Node3D

const ITEM_SCRIPT: Script = preload("res://scripts/slice_item.gd")
const TRAIL_SCRIPT: Script = preload("res://scripts/slash_trail.gd")

var camera: Camera3D
var spawn_timer: Timer
var trail: SlashTrail
var score_label: Label
var best_label: Label
var lives_label: Label
var combo_label: Label
var start_panel: Control
var game_over_panel: Control
var final_score_label: Label

var score: int = 0
var best_score: int = 0
var lives: int = 3
var game_active: bool = false
var swipe_active: bool = false
var previous_swipe_point: Vector2 = Vector2.ZERO
var swipe_hit_ids: Dictionary = {}
var swipe_slice_count: int = 0
var elapsed: float = 0.0
var item_serial: int = 0

var fruit_catalog: Array[Dictionary] = [
	{"name":"LEMON", "points":10, "skin":Color("#e9c61f"), "flesh":Color("#fff4a8"), "juice":Color("#fff14a"), "shape":Vector3(0.92,1.08,0.92), "model":"lemon", "model_scale":9.0},
	{"name":"POMEGRANATE", "points":14, "skin":Color("#a91f30"), "flesh":Color("#e43c55"), "juice":Color("#ff234c"), "shape":Vector3(1.02,1.0,1.02), "model":"food_pomegranate_01", "model_scale":8.5},
	{"name":"KIWI", "points":12, "skin":Color("#7c5931"), "flesh":Color("#8bcc42"), "juice":Color("#8cff47"), "shape":Vector3(0.92,1.08,0.92), "model":"food_kiwi_01", "model_scale":9.0},
	{"name":"BLOOD ORANGE", "points":11, "skin":Color("#e86b22"), "flesh":Color("#ff8b34"), "juice":Color("#ff6a20"), "shape":Vector3.ONE, "model":"", "model_scale":1.0}
]

func _ready() -> void:
	randomize()
	_build_environment()
	_build_camera()
	_build_stage()
	_build_hud()
	spawn_timer = Timer.new()
	spawn_timer.wait_time = 0.86
	spawn_timer.timeout.connect(_spawn_wave)
	add_child(spawn_timer)
	_load_best_score()
	_update_hud()

func _process(delta: float) -> void:
	if game_active:
		elapsed += delta
		spawn_timer.wait_time = maxf(0.42, 0.86 - elapsed * 0.005)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		if touch.pressed:
			_begin_swipe(touch.position)
		else:
			_end_swipe()
	elif event is InputEventScreenDrag:
		_continue_swipe((event as InputEventScreenDrag).position)
	elif event is InputEventMouseButton:
		var button: InputEventMouseButton = event as InputEventMouseButton
		if button.button_index == MOUSE_BUTTON_LEFT:
			if button.pressed:
				_begin_swipe(button.position)
			else:
				_end_swipe()
	elif event is InputEventMouseMotion and swipe_active:
		_continue_swipe((event as InputEventMouseMotion).position)

func _begin_swipe(position: Vector2) -> void:
	if not game_active:
		_start_game()
	swipe_active = true
	previous_swipe_point = position
	swipe_hit_ids.clear()
	swipe_slice_count = 0
	trail.clear_trail()
	trail.add_slash_point(position)

func _continue_swipe(position: Vector2) -> void:
	if not swipe_active or not game_active:
		return
	if previous_swipe_point.distance_to(position) < 5.0:
		return
	trail.add_slash_point(position)
	var screen_delta: Vector2 = position - previous_swipe_point
	var world_swipe: Vector3 = (camera.global_transform.basis.x * screen_delta.x - camera.global_transform.basis.y * screen_delta.y).normalized()
	var sample_count: int = clampi(int(screen_delta.length() / 13.0) + 2, 2, 14)
	for index: int in range(sample_count + 1):
		var sample: Vector2 = previous_swipe_point.lerp(position, float(index) / float(sample_count))
		_raycast_slice(sample, world_swipe)
	previous_swipe_point = position

func _end_swipe() -> void:
	swipe_active = false
	swipe_hit_ids.clear()

func _raycast_slice(screen_position: Vector2, world_swipe: Vector3) -> void:
	var origin: Vector3 = camera.project_ray_origin(screen_position)
	var direction: Vector3 = camera.project_ray_normal(screen_position)
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(origin, origin + direction * 40.0, 1)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var collider: Object = hit.get("collider") as Object
	if not collider is SliceItem:
		return
	var item: SliceItem = collider as SliceItem
	var instance_id: int = item.get_instance_id()
	if swipe_hit_ids.has(instance_id):
		return
	swipe_hit_ids[instance_id] = true
	var hit_position: Vector3 = hit.get("position", item.global_position) as Vector3
	item.slash(world_swipe, hit_position)

func _build_environment() -> void:
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#07090e")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#7b8aa5")
	environment.ambient_light_energy = 0.24
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.glow_enabled = true
	environment.glow_intensity = 0.78
	environment.glow_bloom = 0.18
	environment.fog_enabled = true
	environment.fog_light_color = Color("#101522")
	environment.fog_density = 0.012
	world_environment.environment = environment
	add_child(world_environment)

	_add_spot_light(Vector3(-4.8,6.4,7.0), Vector3(-30,-26,0), Color("#ffd6a0"), 7.5, true)
	_add_spot_light(Vector3(5.5,4.2,2.0), Vector3(-15,42,0), Color("#317dff"), 8.0, false)
	var red_rim: OmniLight3D = OmniLight3D.new()
	red_rim.position = Vector3(-6.0,-1.0,0.0)
	red_rim.light_color = Color("#ff263f")
	red_rim.light_energy = 2.7
	red_rim.omni_range = 11.0
	add_child(red_rim)

func _add_spot_light(position_value: Vector3, rotation_value: Vector3, color_value: Color, energy: float, shadows: bool) -> void:
	var light: SpotLight3D = SpotLight3D.new()
	light.position = position_value
	light.rotation_degrees = rotation_value
	light.light_color = color_value
	light.light_energy = energy
	light.spot_range = 22.0
	light.spot_angle = 56.0
	light.shadow_enabled = shadows
	add_child(light)

func _build_camera() -> void:
	camera = Camera3D.new()
	camera.current = true
	camera.fov = 45.0
	camera.position = Vector3(0,1.2,11.8)
	add_child(camera)
	camera.look_at(Vector3(0,0.4,0), Vector3.UP)

func _build_stage() -> void:
	var back: MeshInstance3D = MeshInstance3D.new()
	var back_mesh: BoxMesh = BoxMesh.new()
	back_mesh.size = Vector3(18,12,0.35)
	back.mesh = back_mesh
	back.position = Vector3(0,1.0,-3.3)
	var back_material: StandardMaterial3D = StandardMaterial3D.new()
	back_material.albedo_color = Color("#0d1119")
	back_material.roughness = 0.62
	back_material.metallic = 0.35
	back.material_override = back_material
	add_child(back)

	var table: StaticBody3D = StaticBody3D.new()
	table.collision_layer = 2
	table.collision_mask = 0
	table.position = Vector3(0,-3.45,0.4)
	add_child(table)
	var table_mesh: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(15.5,0.7,6.2)
	table_mesh.mesh = box
	table_mesh.material_override = _make_table_material()
	table.add_child(table_mesh)
	var collision: CollisionShape3D = CollisionShape3D.new()
	var table_shape: BoxShape3D = BoxShape3D.new()
	table_shape.size = box.size
	collision.shape = table_shape
	table.add_child(collision)

	for x: float in [-6.8, 6.8]:
		var strip: MeshInstance3D = MeshInstance3D.new()
		var strip_mesh: BoxMesh = BoxMesh.new()
		strip_mesh.size = Vector3(0.09,7.6,0.08)
		strip.mesh = strip_mesh
		strip.position = Vector3(x,0.2,-3.05)
		var strip_material: StandardMaterial3D = StandardMaterial3D.new()
		strip_material.albedo_color = Color("#202938")
		strip_material.metallic = 0.9
		strip_material.roughness = 0.2
		strip.material_override = strip_material
		add_child(strip)

func _make_table_material() -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color("#332218")
	material.roughness = 0.48
	var diffuse_path: String = "res://assets/polyhaven/wood_table_001/table_diffuse.jpg"
	var normal_path: String = "res://assets/polyhaven/wood_table_001/table_normal.jpg"
	var roughness_path: String = "res://assets/polyhaven/wood_table_001/table_roughness.jpg"
	if ResourceLoader.exists(diffuse_path):
		material.albedo_texture = load(diffuse_path) as Texture2D
		material.uv1_scale = Vector3(2.4,2.4,2.4)
	if ResourceLoader.exists(normal_path):
		material.normal_enabled = true
		material.normal_texture = load(normal_path) as Texture2D
		material.normal_scale = 0.65
	if ResourceLoader.exists(roughness_path):
		material.roughness_texture = load(roughness_path) as Texture2D
	return material

func _spawn_wave() -> void:
	if not game_active:
		return
	var count: int = 1
	var roll: float = randf()
	if roll > 0.52:
		count = 2
	if roll > 0.88:
		count = 3
	var center: float = randf_range(-3.8,3.8)
	for index: int in range(count):
		var raw_x: float = center + (float(index) - float(count - 1) * 0.5) * randf_range(1.2,1.9)
		_spawn_item(clampf(raw_x,-5.2,5.2), index, count)

func _spawn_item(x: float, index: int, count: int) -> void:
	var data: Dictionary
	var bomb_chance: float = 0.05 + minf(0.10, elapsed / 240.0)
	if score > 90 and randf() < bomb_chance:
		data = {"name":"BOMB", "points":0, "bomb":true, "skin":Color("#10141a"), "flesh":Color("#ff301f"), "juice":Color("#ff301f"), "shape":Vector3.ONE}
	else:
		data = fruit_catalog.pick_random().duplicate(true) as Dictionary
	var item: SliceItem = ITEM_SCRIPT.new() as SliceItem
	item.configure(data)
	item.name = "%s_%d" % [String(data.get("name","ITEM")), item_serial]
	item_serial += 1
	item.position = Vector3(x,-3.1,randf_range(-0.25,0.7))
	item.rotation_degrees = Vector3(randf_range(-30,30),randf_range(0,360),randf_range(-30,30))
	item.sliced.connect(_on_item_sliced)
	item.bomb_triggered.connect(_on_bomb_triggered)
	item.missed.connect(_on_item_missed)
	add_child(item)
	var outward: float = 0.0
	if count > 1:
		outward = (float(index) - float(count - 1) * 0.5) * 1.3
	item.linear_velocity = Vector3(outward + randf_range(-0.65,0.65), randf_range(9.8,12.3), randf_range(-0.45,0.3))
	item.angular_velocity = Vector3(randf_range(-5,5),randf_range(-5,5),randf_range(-5,5))

func _on_item_sliced(_item: SliceItem, value: int, position_value: Vector3, color_value: Color, _direction: Vector3) -> void:
	swipe_slice_count += 1
	var multiplier: int = maxi(1, swipe_slice_count)
	score += value * multiplier
	_spawn_juice(position_value, color_value, 28 + swipe_slice_count * 3)
	_play_synth(600.0 + float(swipe_slice_count) * 90.0, 0.075, 0.25, false)
	Input.vibrate_handheld(18)
	if swipe_slice_count >= 2:
		_show_combo(swipe_slice_count)
	_update_hud()

func _on_bomb_triggered(_item: SliceItem, position_value: Vector3) -> void:
	_spawn_juice(position_value, Color("#ff3a1e"), 70)
	_play_synth(85.0, 0.34, 0.5, true)
	Input.vibrate_handheld(260)
	lives = 0
	_update_hud()
	_end_game()

func _on_item_missed(_item: SliceItem) -> void:
	if not game_active:
		return
	lives -= 1
	Input.vibrate_handheld(45)
	_update_hud()
	if lives <= 0:
		_end_game()

func _spawn_juice(position_value: Vector3, color_value: Color, amount_value: int) -> void:
	var particles: CPUParticles3D = CPUParticles3D.new()
	particles.one_shot = true
	particles.amount = amount_value
	particles.lifetime = 0.85
	particles.explosiveness = 0.92
	particles.randomness = 0.62
	particles.direction = Vector3(0,0.35,0.25)
	particles.spread = 180.0
	particles.initial_velocity_min = 2.2
	particles.initial_velocity_max = 6.5
	particles.gravity = Vector3(0,-9.5,0)
	particles.scale_amount_min = 0.035
	particles.scale_amount_max = 0.12
	var particle_mesh: SphereMesh = SphereMesh.new()
	particle_mesh.radius = 0.065
	particle_mesh.height = 0.13
	particle_mesh.radial_segments = 8
	particle_mesh.rings = 4
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color_value
	material.roughness = 0.28
	material.emission_enabled = true
	material.emission = color_value * 0.15
	particle_mesh.material = material
	particles.mesh = particle_mesh
	particles.position = position_value
	add_child(particles)
	particles.emitting = true
	get_tree().create_timer(1.4).timeout.connect(particles.queue_free)

func _build_hud() -> void:
	var canvas: CanvasLayer = CanvasLayer.new()
	canvas.layer = 5
	add_child(canvas)
	score_label = _make_label("000000",36,Color("#f4f6f9"))
	score_label.position = Vector2(34,25)
	canvas.add_child(score_label)
	var score_caption: Label = _make_label("SCORE",13,Color(0.65,0.72,0.82,0.75))
	score_caption.position = Vector2(37,70)
	canvas.add_child(score_caption)
	best_label = _make_label("BEST 000000",17,Color(0.67,0.75,0.86,0.8))
	best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	best_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	best_label.position = Vector2(-250,30)
	best_label.size = Vector2(210,35)
	canvas.add_child(best_label)
	lives_label = _make_label("●  ●  ●",22,Color("#ff4059"))
	lives_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lives_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	lives_label.position = Vector2(-250,64)
	lives_label.size = Vector2(210,35)
	canvas.add_child(lives_label)
	var title: Label = _make_label("SLICE LAB",18,Color(0.84,0.9,1.0,0.72))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 25
	title.offset_bottom = 60
	canvas.add_child(title)
	combo_label = _make_label("",42,Color.WHITE)
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combo_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	combo_label.position = Vector2(-220,115)
	combo_label.size = Vector2(440,60)
	combo_label.modulate.a = 0.0
	canvas.add_child(combo_label)
	trail = TRAIL_SCRIPT.new() as SlashTrail
	canvas.add_child(trail)
	start_panel = _build_overlay(canvas, false)
	game_over_panel = _build_overlay(canvas, true)

func _build_overlay(canvas: CanvasLayer, game_over: bool) -> Control:
	var root: Control = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.visible = not game_over
	canvas.add_child(root)
	var dim: ColorRect = ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.005,0.008,0.014,0.72 if game_over else 0.48)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)
	var box: VBoxContainer = VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.position = Vector2(-330,-150)
	box.size = Vector2(660,300)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation",14)
	root.add_child(box)
	var heading: Label = _make_label("RUN OVER" if game_over else "SLICE LAB", 44 if game_over else 64, Color("#f5f7fb"))
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(heading)
	if game_over:
		final_score_label = _make_label("000000",56,Color("#74b8ff"))
		final_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(final_score_label)
	else:
		var subtitle: Label = _make_label("CINEMATIC SLICE CHALLENGE",17,Color(0.5,0.73,1.0,0.95))
		subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(subtitle)
	var action_text: String = "SWIPE ANYWHERE TO PLAY AGAIN" if game_over else "SWIPE TO START"
	var action: Label = _make_label(action_text,22,Color.WHITE)
	action.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(action)
	var hint: Label = _make_label("Slice fruit • Build combos • Never touch the bomb",16,Color(0.75,0.8,0.88,0.72))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)
	return root

func _make_label(text_value: String, font_size: int, color_value: Color) -> Label:
	var label: Label = Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color_value)
	label.add_theme_color_override("font_shadow_color",Color(0,0,0,0.65))
	label.add_theme_constant_override("shadow_offset_x",2)
	label.add_theme_constant_override("shadow_offset_y",2)
	return label

func _start_game() -> void:
	for child: Node in get_children():
		if child is SliceItem:
			child.queue_free()
	score = 0
	lives = 3
	elapsed = 0.0
	game_active = true
	start_panel.visible = false
	game_over_panel.visible = false
	spawn_timer.start()
	_update_hud()
	for delay: float in [0.1,0.32,0.58]:
		get_tree().create_timer(delay).timeout.connect(_spawn_wave)

func _end_game() -> void:
	if not game_active:
		return
	game_active = false
	spawn_timer.stop()
	if score > best_score:
		best_score = score
		_save_best_score()
	final_score_label.text = "%06d" % score
	game_over_panel.visible = true
	_update_hud()

func _update_hud() -> void:
	if score_label != null:
		score_label.text = "%06d" % score
	if best_label != null:
		best_label.text = "BEST %06d" % best_score
	if lives_label != null:
		var alive: String = "●  ".repeat(maxi(lives,0)).strip_edges()
		var lost: String = "○  ".repeat(maxi(3-lives,0)).strip_edges()
		lives_label.text = (alive + "  " + lost).strip_edges()

func _show_combo(value: int) -> void:
	combo_label.text = "×%d  COMBO" % value
	combo_label.modulate = Color.WHITE
	combo_label.scale = Vector2(0.78,0.78)
	combo_label.pivot_offset = combo_label.size * 0.5
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(combo_label,"scale",Vector2.ONE,0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(combo_label,"modulate:a",0.0,0.8).set_delay(0.32)

func _load_best_score() -> void:
	if not FileAccess.file_exists("user://best_score.save"):
		return
	var file: FileAccess = FileAccess.open("user://best_score.save",FileAccess.READ)
	if file != null:
		best_score = int(file.get_as_text())

func _save_best_score() -> void:
	var file: FileAccess = FileAccess.open("user://best_score.save",FileAccess.WRITE)
	if file != null:
		file.store_string(str(best_score))

func _play_synth(frequency: float, duration: float, volume: float, noisy: bool) -> void:
	var sample_rate: int = 22050
	var sample_count: int = int(float(sample_rate) * duration)
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(sample_count * 2)
	for index: int in range(sample_count):
		var time: float = float(index) / float(sample_rate)
		var envelope: float = pow(1.0 - float(index) / float(sample_count),2.0)
		var wave: float = sin(TAU * frequency * time)
		if noisy:
			wave = wave * 0.55 + randf_range(-1.0,1.0) * 0.45
		var value: int = int(clampf(wave * envelope * volume,-1.0,1.0) * 32767.0)
		bytes.encode_s16(index * 2,value)
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = bytes
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = stream
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
