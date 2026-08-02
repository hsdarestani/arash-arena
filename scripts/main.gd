extends Node3D

var player: ArenaPlayer
var controls: MobileControls
var camera: Camera3D
var spawn_timer: Timer
var asset_loader: CC0AssetLoader
var enemy_model: PackedScene
var score: int = 0
var elapsed: float = 0.0
var game_over: bool = false

var score_label: Label
var hp_bar: ProgressBar
var status_label: Label
var game_over_panel: Control
var final_score_label: Label

func _ready() -> void:
	_setup_input_map()
	seed(20260802)
	_build_environment()
	_build_arena()
	_build_player()
	_build_camera()
	_build_hud()
	_build_spawner()
	_build_asset_loader()

func _setup_input_map() -> void:
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("move_up", [KEY_W, KEY_UP])
	_add_key_action("move_down", [KEY_S, KEY_DOWN])
	_add_key_action("attack", [KEY_SPACE])
	_add_key_action("restart", [KEY_R])
	var has_mouse_attack := false
	for existing in InputMap.action_get_events("attack"):
		if existing is InputEventMouseButton:
			has_mouse_attack = true
			break
	if not has_mouse_attack:
		var mouse := InputEventMouseButton.new()
		mouse.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("attack", mouse)

func _add_key_action(action_name: StringName, keys: Array) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for key in keys:
		var already_exists := false
		for existing in InputMap.action_get_events(action_name):
			if existing is InputEventKey and (existing as InputEventKey).physical_keycode == key:
				already_exists = true
				break
		if not already_exists:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action_name, event)

func _process(delta: float) -> void:
	if not game_over:
		elapsed += delta
		player.move_input = controls.get_move_vector()
	_update_camera(delta)
	if game_over and Input.is_action_just_pressed("restart"):
		_restart_game()

func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#17101f")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#c9a46f")
	environment.ambient_light_energy = 0.58
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.glow_enabled = true
	environment.glow_intensity = 0.65
	world_environment.environment = environment
	add_child(world_environment)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -28, 0)
	sun.light_color = Color("#ffe0a1")
	sun.light_energy = 1.55
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 38.0
	add_child(sun)

	var rim := OmniLight3D.new()
	rim.position = Vector3(-6, 6, 5)
	rim.light_color = Color("#a34cff")
	rim.light_energy = 2.1
	rim.omni_range = 17.0
	add_child(rim)

func _build_arena() -> void:
	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = 4
	floor_body.collision_mask = 0
	floor_body.name = "ArenaFloor"
	add_child(floor_body)

	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(30, 30)
	floor_mesh.subdivide_width = 6
	floor_mesh.subdivide_depth = 6
	var floor_visual := VisualFactory.mesh_instance(floor_mesh, Color("#5a3e35"))
	var floor_mat := VisualFactory.material(Color("#5a3e35"), 0.94)
	floor_visual.material_override = floor_mat
	floor_body.add_child(floor_visual)

	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(30, 0.4, 30)
	var floor_collision := CollisionShape3D.new()
	floor_collision.shape = floor_shape
	floor_collision.position.y = -0.2
	floor_body.add_child(floor_collision)

	_build_border_walls()
	_build_ruins()
	_build_center_emblem()

func _build_border_walls() -> void:
	var wall_color := Color("#2c2134")
	for data in [
		{"p": Vector3(0, 0.75, -15), "s": Vector3(30, 1.5, 0.6)},
		{"p": Vector3(0, 0.75, 15), "s": Vector3(30, 1.5, 0.6)},
		{"p": Vector3(-15, 0.75, 0), "s": Vector3(0.6, 1.5, 30)},
		{"p": Vector3(15, 0.75, 0), "s": Vector3(0.6, 1.5, 30)}
	]:
		var wall := StaticBody3D.new()
		wall.collision_layer = 4
		wall.position = data.p
		var box_mesh := BoxMesh.new()
		box_mesh.size = data.s
		wall.add_child(VisualFactory.mesh_instance(box_mesh, wall_color))
		var shape := BoxShape3D.new()
		shape.size = data.s
		var collision := CollisionShape3D.new()
		collision.shape = shape
		wall.add_child(collision)
		add_child(wall)

func _build_ruins() -> void:
	var positions := [
		Vector3(-11, 0, -11), Vector3(11, 0, -11),
		Vector3(-11, 0, 11), Vector3(11, 0, 11),
		Vector3(-7.5, 0, -12.5), Vector3(7.5, 0, 12.5)
	]
	for i in positions.size():
		var column := Node3D.new()
		column.position = positions[i]
		column.rotation_degrees.y = randf_range(-12.0, 12.0)
		add_child(column)

		var base_mesh := CylinderMesh.new()
		base_mesh.top_radius = 0.9
		base_mesh.bottom_radius = 1.05
		base_mesh.height = 0.45
		column.add_child(VisualFactory.mesh_instance(base_mesh, Color("#84634b"), Vector3(0, 0.22, 0)))

		var shaft_mesh := CylinderMesh.new()
		shaft_mesh.top_radius = 0.52
		shaft_mesh.bottom_radius = 0.68
		shaft_mesh.height = 3.0 + randf_range(-0.6, 0.5)
		column.add_child(VisualFactory.mesh_instance(shaft_mesh, Color("#a47a55"), Vector3(0, 1.75, 0)))

		var cap_mesh := BoxMesh.new()
		cap_mesh.size = Vector3(1.5, 0.35, 1.5)
		column.add_child(VisualFactory.mesh_instance(cap_mesh, Color("#70516a"), Vector3(0, 3.35, 0)))

	for i in 16:
		var rock_mesh := SphereMesh.new()
		rock_mesh.radius = randf_range(0.22, 0.55)
		rock_mesh.height = rock_mesh.radius * 1.55
		var angle := randf() * TAU
		var radius := randf_range(8.5, 13.0)
		var rock := VisualFactory.mesh_instance(rock_mesh, Color("#4a3541"), Vector3(cos(angle) * radius, rock_mesh.radius * 0.45, sin(angle) * radius))
		rock.scale = Vector3(randf_range(0.8, 1.7), randf_range(0.5, 1.0), randf_range(0.8, 1.6))
		rock.rotation_degrees = Vector3(randf_range(-20, 20), randf_range(0, 180), randf_range(-20, 20))
		add_child(rock)

func _build_center_emblem() -> void:
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 2.1
	ring_mesh.outer_radius = 2.25
	var ring := VisualFactory.mesh_instance(ring_mesh, Color("#d19a37"), Vector3(0, 0.035, 0))
	var mat := VisualFactory.material(Color("#d19a37"), 0.35, 0.55)
	mat.emission_enabled = true
	mat.emission = Color("#6e3516")
	mat.emission_energy_multiplier = 1.4
	ring.material_override = mat
	add_child(ring)

	for i in 8:
		var angle := TAU * float(i) / 8.0
		var tile_mesh := BoxMesh.new()
		tile_mesh.size = Vector3(0.22, 0.05, 1.0)
		var tile := VisualFactory.mesh_instance(tile_mesh, Color("#b9762a"), Vector3(cos(angle) * 1.2, 0.035, sin(angle) * 1.2))
		tile.rotation.y = -angle
		add_child(tile)

func _build_player() -> void:
	player = ArenaPlayer.new()
	player.name = "Player"
	player.position = Vector3.ZERO
	player.hp_changed.connect(_on_player_hp_changed)
	player.died.connect(_on_player_died)
	add_child(player)

func _build_camera() -> void:
	camera = Camera3D.new()
	camera.name = "Camera"
	camera.current = true
	camera.fov = 48.0
	camera.position = Vector3(0, 14.0, 11.0)
	add_child(camera)
	camera.look_at(Vector3(0, 0.5, 0), Vector3.UP)

func _update_camera(delta: float) -> void:
	if camera == null or player == null:
		return
	var target_position := player.global_position + Vector3(0, 14.0, 11.0)
	camera.global_position = camera.global_position.lerp(target_position, 1.0 - exp(-delta * 4.5))
	camera.look_at(player.global_position + Vector3(0, 0.55, 0), Vector3.UP)

func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "HUD"
	add_child(canvas)

	var overlay := ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.color = Color(0.06, 0.025, 0.08, 0.10)
	canvas.add_child(overlay)

	var top_panel := PanelContainer.new()
	top_panel.position = Vector2(28, 24)
	top_panel.size = Vector2(286, 102)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.035, 0.025, 0.055, 0.82)
	panel_style.border_color = Color(0.82, 0.57, 0.18, 0.75)
	panel_style.set_border_width_all(2)
	panel_style.corner_radius_top_left = 18
	panel_style.corner_radius_top_right = 18
	panel_style.corner_radius_bottom_left = 18
	panel_style.corner_radius_bottom_right = 18
	top_panel.add_theme_stylebox_override("panel", panel_style)
	canvas.add_child(top_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	top_panel.add_child(vbox)

	score_label = Label.new()
	score_label.text = "SCORE  0000"
	score_label.add_theme_font_size_override("font_size", 27)
	score_label.add_theme_color_override("font_color", Color("#ffd77a"))
	vbox.add_child(score_label)

	hp_bar = ProgressBar.new()
	hp_bar.min_value = 0
	hp_bar.max_value = 100
	hp_bar.value = 100
	hp_bar.custom_minimum_size = Vector2(250, 22)
	hp_bar.show_percentage = false
	var hp_bg := StyleBoxFlat.new()
	hp_bg.bg_color = Color(0.12, 0.06, 0.09, 0.9)
	hp_bg.corner_radius_top_left = 8
	hp_bg.corner_radius_top_right = 8
	hp_bg.corner_radius_bottom_left = 8
	hp_bg.corner_radius_bottom_right = 8
	var hp_fill := StyleBoxFlat.new()
	hp_fill.bg_color = Color("#e95245")
	hp_fill.corner_radius_top_left = 8
	hp_fill.corner_radius_top_right = 8
	hp_fill.corner_radius_bottom_left = 8
	hp_fill.corner_radius_bottom_right = 8
	hp_bar.add_theme_stylebox_override("background", hp_bg)
	hp_bar.add_theme_stylebox_override("fill", hp_fill)
	vbox.add_child(hp_bar)

	var title := Label.new()
	title.text = "ARASH: ARENA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 24
	title.offset_bottom = 66
	title.add_theme_font_size_override("font_size", 31)
	title.add_theme_color_override("font_color", Color("#f7e5bd"))
	canvas.add_child(title)

	status_label = Label.new()
	status_label.text = "CC0 art loads automatically • WASD / touch to move"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	status_label.offset_top = 66
	status_label.offset_bottom = 98
	status_label.modulate = Color(1, 1, 1, 0.58)
	status_label.add_theme_font_size_override("font_size", 15)
	canvas.add_child(status_label)

	controls = MobileControls.new()
	canvas.add_child(controls)
	controls.attack_pressed.connect(_on_attack_pressed)

	_build_game_over_ui(canvas)

func _build_game_over_ui(canvas: CanvasLayer) -> void:
	game_over_panel = Control.new()
	game_over_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_over_panel.visible = false
	canvas.add_child(game_over_panel)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.025, 0.015, 0.04, 0.82)
	game_over_panel.add_child(dim)

	var card := PanelContainer.new()
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.position = Vector2(-230, -155)
	card.size = Vector2(460, 310)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#171020")
	style.border_color = Color("#d69b36")
	style.set_border_width_all(3)
	style.corner_radius_top_left = 28
	style.corner_radius_top_right = 28
	style.corner_radius_bottom_left = 28
	style.corner_radius_bottom_right = 28
	card.add_theme_stylebox_override("panel", style)
	game_over_panel.add_child(card)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 20)
	card.add_child(box)

	var heading := Label.new()
	heading.text = "THE ARENA CLAIMED YOU"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 27)
	heading.add_theme_color_override("font_color", Color("#ffd77a"))
	box.add_child(heading)

	final_score_label = Label.new()
	final_score_label.text = "SCORE 0"
	final_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	final_score_label.add_theme_font_size_override("font_size", 42)
	box.add_child(final_score_label)

	var restart_button := Button.new()
	restart_button.text = "FIGHT AGAIN"
	restart_button.custom_minimum_size = Vector2(280, 62)
	restart_button.add_theme_font_size_override("font_size", 22)
	restart_button.pressed.connect(_restart_game)
	box.add_child(restart_button)

func _build_spawner() -> void:
	spawn_timer = Timer.new()
	spawn_timer.wait_time = 1.35
	spawn_timer.autostart = true
	spawn_timer.timeout.connect(_spawn_enemy)
	add_child(spawn_timer)
	for i in 3:
		_spawn_enemy()

func _build_asset_loader() -> void:
	asset_loader = CC0AssetLoader.new()
	asset_loader.player_model_ready.connect(_on_player_model_ready)
	asset_loader.enemy_model_ready.connect(_on_enemy_model_ready)
	asset_loader.status_changed.connect(_on_asset_status_changed)
	add_child(asset_loader)

func _spawn_enemy() -> void:
	if game_over:
		return
	var enemy := ArenaEnemy.new()
	enemy.target = player
	enemy.speed = minf(5.0, 2.75 + elapsed * 0.018)
	enemy.hp = 55 + int(elapsed / 28.0) * 8
	enemy.damage = mini(20, 9 + int(elapsed / 35.0) * 2)
	enemy.killed.connect(_on_enemy_killed)
	var angle := randf() * TAU
	var radius := randf_range(11.5, 13.5)
	enemy.position = Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
	add_child(enemy)
	if enemy_model != null:
		var model := enemy_model.instantiate() as Node3D
		if model != null:
			enemy.set_external_visual(model)
	spawn_timer.wait_time = maxf(0.52, 1.35 - elapsed * 0.006)

func _on_attack_pressed() -> void:
	player.request_attack()

func _on_enemy_killed(points: int) -> void:
	score += points
	score_label.text = "SCORE  %04d" % score
	if score % 100 == 0:
		player.hp = mini(player.max_hp, player.hp + 12)
		player.hp_changed.emit(player.hp, player.max_hp)

func _on_player_hp_changed(current_hp: int, max_hp: int) -> void:
	if hp_bar != null:
		hp_bar.max_value = max_hp
		hp_bar.value = current_hp

func _on_player_died() -> void:
	game_over = true
	spawn_timer.stop()
	controls.process_mode = Node.PROCESS_MODE_DISABLED
	controls.visible = false
	final_score_label.text = "SCORE  %d" % score
	game_over_panel.visible = true

func _restart_game() -> void:
	get_tree().reload_current_scene()

func _on_player_model_ready(packed: PackedScene) -> void:
	var model := packed.instantiate() as Node3D
	if model != null:
		player.set_external_visual(model)

func _on_enemy_model_ready(packed: PackedScene) -> void:
	enemy_model = packed
	for child in get_children():
		if child is ArenaEnemy:
			var model := enemy_model.instantiate() as Node3D
			if model != null:
				(child as ArenaEnemy).set_external_visual(model)

func _on_asset_status_changed(message: String) -> void:
	status_label.text = message
	var tween := create_tween()
	tween.tween_interval(2.6)
	tween.tween_property(status_label, "modulate:a", 0.0, 1.0)
