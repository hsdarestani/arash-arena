extends Node3D

const ITEM_SCRIPT: Script = preload("res://scripts/slice_item.gd")
const TRAIL_SCRIPT: Script = preload("res://scripts/slash_trail.gd")

var camera: Camera3D
var spawn_timer: Timer
var trail: SlashTrail
var ui_font: Font
var ui_font_bold: Font

var game_active: bool = false
var transition_locked: bool = false
var swipe_active: bool = false
var previous_swipe_point: Vector2 = Vector2.ZERO
var swipe_hit_ids: Dictionary = {}
var swipe_slice_count: int = 0

var coins: int = 0
var best_revenue: int = 0
var knife_level: int = 0
var counter_level: int = 0
var sign_level: int = 0

var session_revenue: int = 0
var served_orders: int = 0
var customer_hearts: int = 3
var order_time_left: float = 0.0
var order_time_total: float = 18.0
var current_order: Dictionary = {}
var remaining_ingredients: Dictionary = {}
var order_serial: int = 0
var item_serial: int = 0
var customer_index: int = 0
var combo_chain: int = 0
var order_streak: int = 0

var menu_overlay: Control
var game_over_overlay: Control
var menu_coins_label: Label
var summary_label: Label
var hud_coins_label: Label
var hud_revenue_label: Label
var hearts_label: Label
var order_title_label: Label
var order_customer_label: Label
var order_timer_bar: ProgressBar
var order_ingredients_box: HBoxContainer
var feedback_label: Label
var combo_label: Label
var upgrades_box: HBoxContainer

var ingredient_catalog: Dictionary = {
	"LEMON": {
		"name":"LEMON", "fa":"لیمو", "points":12,
		"skin":Color("#e7c31d"), "flesh":Color("#fff0a0"), "juice":Color("#ffe948"),
		"shape":Vector3(0.92,1.08,0.92), "model":"lemon", "model_scale":9.0
	},
	"POMEGRANATE": {
		"name":"POMEGRANATE", "fa":"انار", "points":16,
		"skin":Color("#9f1e32"), "flesh":Color("#ed4562"), "juice":Color("#ff294e"),
		"shape":Vector3(1.02,1.0,1.02), "model":"food_pomegranate_01", "model_scale":8.5
	},
	"KIWI": {
		"name":"KIWI", "fa":"کیوی", "points":14,
		"skin":Color("#76532f"), "flesh":Color("#8dce48"), "juice":Color("#92f04f"),
		"shape":Vector3(0.92,1.06,0.92), "model":"food_kiwi_01", "model_scale":9.0
	},
	"APPLE": {
		"name":"APPLE", "fa":"سیب", "points":13,
		"skin":Color("#bd2433"), "flesh":Color("#fff0cf"), "juice":Color("#ffd6ad"),
		"shape":Vector3(1.0,0.96,1.0), "model":"food_apple_01", "model_scale":8.8
	},
	"ONION": {
		"name":"ONION", "fa":"پیاز", "points":12,
		"skin":Color("#b78342"), "flesh":Color("#f4e0ad"), "juice":Color("#f7d996"),
		"shape":Vector3(1.0,0.95,1.0), "model":"yellow_onion", "model_scale":8.5
	},
	"POTATO": {
		"name":"POTATO", "fa":"سیب‌زمینی", "points":15,
		"skin":Color("#a95339"), "flesh":Color("#ffd98c"), "juice":Color("#eab65b"),
		"shape":Vector3(0.82,1.28,0.82), "model":"sweet_potato", "model_scale":8.5
	},
	"BUN": {
		"name":"BUN", "fa":"نان", "points":18,
		"skin":Color("#bd702a"), "flesh":Color("#ffe0a4"), "juice":Color("#f3b861"),
		"shape":Vector3(1.25,0.72,1.05), "model":"hamburger_buns", "model_scale":2.2
	},
	"TOMATO": {
		"name":"TOMATO", "fa":"گوجه", "points":13,
		"skin":Color("#d8322f"), "flesh":Color("#ff6a58"), "juice":Color("#ff4938"),
		"shape":Vector3(1.0,0.92,1.0), "model":"", "model_scale":1.0
	}
}

var order_catalog: Array[Dictionary] = [
	{"title":"آب‌انار مخصوص", "customer":"مریم", "reward":70, "ingredients":{"POMEGRANATE":2, "LEMON":1}},
	{"title":"ساندویچ دکه", "customer":"امیر", "reward":82, "ingredients":{"BUN":1, "ONION":1, "TOMATO":1}},
	{"title":"سیب‌زمینی ویژه", "customer":"سارا", "reward":88, "ingredients":{"POTATO":2, "ONION":1}},
	{"title":"سالاد میوه", "customer":"رضا", "reward":76, "ingredients":{"APPLE":1, "KIWI":1, "LEMON":1}},
	{"title":"پک مهمانی", "customer":"نگار", "reward":105, "ingredients":{"POMEGRANATE":1, "APPLE":1, "KIWI":1, "LEMON":1}},
	{"title":"ساندویچ دوبل", "customer":"علی", "reward":110, "ingredients":{"BUN":2, "TOMATO":1, "ONION":1}}
]

func _ready() -> void:
	randomize()
	_load_fonts()
	_load_save()
	_build_environment()
	_build_camera()
	_build_kiosk()
	_build_hud()
	_build_spawner()
	_update_menu()
	_update_hud()

func _process(delta: float) -> void:
	if not game_active or transition_locked:
		return
	order_time_left = maxf(0.0, order_time_left - delta)
	if order_timer_bar != null:
		order_timer_bar.value = order_time_left
	if order_time_left <= 0.0:
		_fail_order("مشتری منتظر ماند!")
	spawn_timer.wait_time = maxf(0.42, 0.78 - float(served_orders) * 0.018)

func _unhandled_input(event: InputEvent) -> void:
	if not game_active or transition_locked:
		return
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

func _load_fonts() -> void:
	if ResourceLoader.exists("res://assets/fonts/Vazirmatn-Regular.ttf"):
		ui_font = load("res://assets/fonts/Vazirmatn-Regular.ttf") as Font
	if ResourceLoader.exists("res://assets/fonts/Vazirmatn-Bold.ttf"):
		ui_font_bold = load("res://assets/fonts/Vazirmatn-Bold.ttf") as Font

func _build_environment() -> void:
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#090b13")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#8292af")
	environment.ambient_light_energy = 0.32
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.glow_enabled = true
	environment.glow_intensity = 1.05
	environment.glow_bloom = 0.22
	environment.fog_enabled = true
	environment.fog_light_color = Color("#171322")
	environment.fog_density = 0.008
	world_environment.environment = environment
	add_child(world_environment)

	_add_spot(Vector3(-5.7,6.8,6.5), Vector3(-31,-28,0), Color("#ffd39b"), 9.0, true)
	_add_spot(Vector3(5.5,4.5,3.0), Vector3(-18,43,0), Color("#4e80ff"), 7.0, false)
	_add_spot(Vector3(0,5.8,-0.5), Vector3(-20,0,0), Color("#ff8a54"), 4.0, false)

func _add_spot(position_value: Vector3, rotation_value: Vector3, color_value: Color, energy: float, shadows: bool) -> void:
	var light: SpotLight3D = SpotLight3D.new()
	light.position = position_value
	light.rotation_degrees = rotation_value
	light.light_color = color_value
	light.light_energy = energy
	light.spot_range = 22.0
	light.spot_angle = 58.0
	light.shadow_enabled = shadows
	add_child(light)

func _build_camera() -> void:
	camera = Camera3D.new()
	camera.current = true
	camera.fov = 46.0
	camera.position = Vector3(0,1.15,12.4)
	add_child(camera)
	camera.look_at(Vector3(0,0.15,0), Vector3.UP)

func _build_kiosk() -> void:
	_build_back_wall()
	_build_awning()
	_build_counter()
	_build_shelves()
	_build_hanging_lights()
	_build_steam_pot()

func _build_back_wall() -> void:
	var wall: MeshInstance3D = MeshInstance3D.new()
	var wall_mesh: BoxMesh = BoxMesh.new()
	wall_mesh.size = Vector3(18.0,10.0,0.45)
	wall.mesh = wall_mesh
	wall.position = Vector3(0,0.8,-4.1)
	wall.material_override = _material(Color("#131722"),0.62,0.1)
	add_child(wall)

	for row: int in range(5):
		for column: int in range(13):
			var tile: MeshInstance3D = MeshInstance3D.new()
			var tile_mesh: BoxMesh = BoxMesh.new()
			tile_mesh.size = Vector3(1.18,0.72,0.055)
			tile.mesh = tile_mesh
			tile.position = Vector3(-7.1 + float(column) * 1.18, -1.0 + float(row) * 0.72, -3.84)
			var shade: float = 0.16 + float((row + column) % 3) * 0.014
			tile.material_override = _material(Color(shade,shade * 1.03,shade * 1.12),0.28,0.0)
			add_child(tile)

func _build_awning() -> void:
	for index: int in range(12):
		var strip: MeshInstance3D = MeshInstance3D.new()
		var mesh: BoxMesh = BoxMesh.new()
		mesh.size = Vector3(1.35,0.42,2.4)
		strip.mesh = mesh
		strip.position = Vector3(-7.45 + float(index) * 1.35,4.05,-2.55)
		strip.rotation_degrees.x = -9.0
		var color_value: Color = Color("#9f2033") if index % 2 == 0 else Color("#ead9b8")
		strip.material_override = _material(color_value,0.5,0.0)
		add_child(strip)

	var trim: MeshInstance3D = MeshInstance3D.new()
	var trim_mesh: BoxMesh = BoxMesh.new()
	trim_mesh.size = Vector3(16.5,0.18,0.18)
	trim.mesh = trim_mesh
	trim.position = Vector3(0,3.75,-1.45)
	trim.material_override = _material(Color("#e7bc65"),0.22,0.72)
	add_child(trim)

func _build_counter() -> void:
	var counter: StaticBody3D = StaticBody3D.new()
	counter.collision_layer = 2
	counter.collision_mask = 0
	counter.position = Vector3(0,-3.5,0.25)
	add_child(counter)

	var counter_mesh: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(16.2,0.82,5.1)
	counter_mesh.mesh = box
	counter_mesh.material_override = _wood_material()
	counter.add_child(counter_mesh)

	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = box.size
	collision.shape = shape
	counter.add_child(collision)

	var prep: MeshInstance3D = MeshInstance3D.new()
	var prep_mesh: BoxMesh = BoxMesh.new()
	prep_mesh.size = Vector3(6.6,0.08,2.25)
	prep.mesh = prep_mesh
	prep.position = Vector3(0,-3.04,0.15)
	prep.material_override = _material(Color("#59616c"),0.2,0.86)
	add_child(prep)

	for x: float in [-6.8,6.8]:
		var crate: MeshInstance3D = MeshInstance3D.new()
		var crate_mesh: BoxMesh = BoxMesh.new()
		crate_mesh.size = Vector3(2.1,1.1,1.6)
		crate.mesh = crate_mesh
		crate.position = Vector3(x,-2.55,-1.4)
		crate.material_override = _material(Color("#5d3822"),0.76,0.0)
		add_child(crate)

func _build_shelves() -> void:
	for y_value: float in [0.65,2.05]:
		var shelf: MeshInstance3D = MeshInstance3D.new()
		var shelf_mesh: BoxMesh = BoxMesh.new()
		shelf_mesh.size = Vector3(6.8,0.16,0.72)
		shelf.mesh = shelf_mesh
		shelf.position = Vector3(-4.25,y_value,-3.35)
		shelf.material_override = _material(Color("#70482d"),0.58,0.0)
		add_child(shelf)
		for index: int in range(6):
			var jar: MeshInstance3D = MeshInstance3D.new()
			var jar_mesh: CylinderMesh = CylinderMesh.new()
			jar_mesh.top_radius = 0.18
			jar_mesh.bottom_radius = 0.2
			jar_mesh.height = 0.52 + float(index % 2) * 0.12
			jar_mesh.radial_segments = 18
			jar.mesh = jar_mesh
			jar.position = Vector3(-6.8 + float(index) * 1.02,y_value + 0.36,-3.2)
			var jar_colors: Array[Color] = [Color("#d94b3d"),Color("#e5b94e"),Color("#5f9d58"),Color("#b65c86")]
			jar.material_override = _material(jar_colors[index % jar_colors.size()],0.28,0.05)
			add_child(jar)

func _build_hanging_lights() -> void:
	for index: int in range(3):
		var x_value: float = -3.8 + float(index) * 3.8
		var cable: MeshInstance3D = MeshInstance3D.new()
		var cable_mesh: CylinderMesh = CylinderMesh.new()
		cable_mesh.top_radius = 0.018
		cable_mesh.bottom_radius = 0.018
		cable_mesh.height = 1.45
		cable.mesh = cable_mesh
		cable.position = Vector3(x_value,3.0,-1.9)
		cable.material_override = _material(Color("#181818"),0.82,0.1)
		add_child(cable)

		var bulb: MeshInstance3D = MeshInstance3D.new()
		var bulb_mesh: SphereMesh = SphereMesh.new()
		bulb_mesh.radius = 0.16
		bulb_mesh.height = 0.32
		bulb.mesh = bulb_mesh
		bulb.position = Vector3(x_value,2.25,-1.9)
		var bulb_material: StandardMaterial3D = _material(Color("#ffd28d"),0.18,0.0)
		bulb_material.emission_enabled = true
		bulb_material.emission = Color("#ffb85d")
		bulb_material.emission_energy_multiplier = 4.0
		bulb.material_override = bulb_material
		add_child(bulb)

		var light: OmniLight3D = OmniLight3D.new()
		light.position = bulb.position
		light.light_color = Color("#ffbd72")
		light.light_energy = 2.3
		light.omni_range = 5.5
		add_child(light)

func _build_steam_pot() -> void:
	var pot: MeshInstance3D = MeshInstance3D.new()
	var pot_mesh: CylinderMesh = CylinderMesh.new()
	pot_mesh.top_radius = 0.7
	pot_mesh.bottom_radius = 0.62
	pot_mesh.height = 0.75
	pot_mesh.radial_segments = 32
	pot.mesh = pot_mesh
	pot.position = Vector3(5.75,-2.65,-1.1)
	pot.material_override = _material(Color("#444b54"),0.18,0.9)
	add_child(pot)

	var steam: CPUParticles3D = CPUParticles3D.new()
	steam.position = Vector3(5.75,-2.1,-1.1)
	steam.amount = 18
	steam.lifetime = 2.5
	steam.randomness = 0.85
	steam.direction = Vector3.UP
	steam.spread = 18.0
	steam.initial_velocity_min = 0.5
	steam.initial_velocity_max = 1.35
	steam.gravity = Vector3(0,0.25,0)
	steam.scale_amount_min = 0.12
	steam.scale_amount_max = 0.34
	var steam_mesh: SphereMesh = SphereMesh.new()
	steam_mesh.radius = 0.12
	steam_mesh.height = 0.24
	steam_mesh.radial_segments = 8
	steam_mesh.rings = 4
	var steam_material: StandardMaterial3D = StandardMaterial3D.new()
	steam_material.albedo_color = Color(0.85,0.9,1.0,0.16)
	steam_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	steam_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	steam_mesh.material = steam_material
	steam.mesh = steam_mesh
	steam.emitting = true
	add_child(steam)

func _wood_material() -> StandardMaterial3D:
	var material: StandardMaterial3D = _material(Color("#4b2c1e"),0.5,0.0)
	var diffuse_path: String = "res://assets/polyhaven/wood_table_001/table_diffuse.jpg"
	var normal_path: String = "res://assets/polyhaven/wood_table_001/table_normal.jpg"
	var roughness_path: String = "res://assets/polyhaven/wood_table_001/table_roughness.jpg"
	if ResourceLoader.exists(diffuse_path):
		material.albedo_texture = load(diffuse_path) as Texture2D
		material.uv1_scale = Vector3(2.6,2.6,2.6)
	if ResourceLoader.exists(normal_path):
		material.normal_enabled = true
		material.normal_texture = load(normal_path) as Texture2D
		material.normal_scale = 0.7
	if ResourceLoader.exists(roughness_path):
		material.roughness_texture = load(roughness_path) as Texture2D
	return material

func _material(color_value: Color, roughness_value: float, metallic_value: float) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color_value
	material.roughness = roughness_value
	material.metallic = metallic_value
	return material

func _build_spawner() -> void:
	spawn_timer = Timer.new()
	spawn_timer.wait_time = 0.76
	spawn_timer.timeout.connect(_spawn_wave)
	add_child(spawn_timer)

func _build_hud() -> void:
	var canvas: CanvasLayer = CanvasLayer.new()
	canvas.layer = 10
	add_child(canvas)
	_build_top_hud(canvas)
	_build_order_card(canvas)
	_build_feedback(canvas)
	trail = TRAIL_SCRIPT.new() as SlashTrail
	canvas.add_child(trail)
	menu_overlay = _build_menu_overlay(canvas)
	game_over_overlay = _build_game_over_overlay(canvas)
	_build_vignette(canvas)

func _build_top_hud(canvas: CanvasLayer) -> void:
	var top_bar: Panel = Panel.new()
	top_bar.position = Vector2(22,18)
	top_bar.size = Vector2(510,78)
	top_bar.add_theme_stylebox_override("panel",_panel_style(Color(0.025,0.035,0.06,0.88),24,Color(1.0,0.72,0.35,0.2),1))
	canvas.add_child(top_bar)

	hud_coins_label = _label("سکه  ۰",24,Color("#ffd267"),true)
	hud_coins_label.position = Vector2(24,10)
	hud_coins_label.size = Vector2(165,34)
	top_bar.add_child(hud_coins_label)

	hud_revenue_label = _label("فروش  ۰",20,Color("#ecf2ff"),false)
	hud_revenue_label.position = Vector2(185,13)
	hud_revenue_label.size = Vector2(175,32)
	top_bar.add_child(hud_revenue_label)

	hearts_label = _label("♥  ♥  ♥",24,Color("#ff526d"),true)
	hearts_label.position = Vector2(360,10)
	hearts_label.size = Vector2(130,34)
	hearts_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top_bar.add_child(hearts_label)

	var kiosk_badge: Panel = Panel.new()
	kiosk_badge.position = Vector2(24,48)
	kiosk_badge.size = Vector2(462,20)
	kiosk_badge.add_theme_stylebox_override("panel",_panel_style(Color(1.0,0.55,0.2,0.11),10,Color.TRANSPARENT,0))
	top_bar.add_child(kiosk_badge)
	var badge_text: Label = _label("دکه‌چی  •  سفارش سریع، مشتری راضی",13,Color(0.9,0.82,0.7,0.88),false)
	badge_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	badge_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kiosk_badge.add_child(badge_text)

func _build_order_card(canvas: CanvasLayer) -> void:
	var card: Panel = Panel.new()
	card.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	card.position = Vector2(-390,18)
	card.size = Vector2(368,205)
	card.add_theme_stylebox_override("panel",_panel_style(Color(0.035,0.045,0.075,0.94),26,Color(0.4,0.68,1.0,0.25),1))
	canvas.add_child(card)

	var avatar: Control = _build_avatar()
	avatar.position = Vector2(248,20)
	card.add_child(avatar)

	order_customer_label = _label("مشتری",15,Color(0.65,0.74,0.88,0.82),false)
	order_customer_label.position = Vector2(22,18)
	order_customer_label.size = Vector2(210,26)
	order_customer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	card.add_child(order_customer_label)

	order_title_label = _label("سفارش",25,Color("#ffffff"),true)
	order_title_label.position = Vector2(22,42)
	order_title_label.size = Vector2(210,38)
	order_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	card.add_child(order_title_label)

	order_ingredients_box = HBoxContainer.new()
	order_ingredients_box.position = Vector2(20,91)
	order_ingredients_box.size = Vector2(328,58)
	order_ingredients_box.alignment = BoxContainer.ALIGNMENT_CENTER
	order_ingredients_box.add_theme_constant_override("separation",8)
	card.add_child(order_ingredients_box)

	order_timer_bar = ProgressBar.new()
	order_timer_bar.position = Vector2(20,165)
	order_timer_bar.size = Vector2(328,16)
	order_timer_bar.show_percentage = false
	order_timer_bar.add_theme_stylebox_override("background",_panel_style(Color(0.1,0.12,0.18,0.9),8,Color.TRANSPARENT,0))
	order_timer_bar.add_theme_stylebox_override("fill",_panel_style(Color("#ff9c3d"),8,Color.TRANSPARENT,0))
	card.add_child(order_timer_bar)

func _build_feedback(canvas: CanvasLayer) -> void:
	feedback_label = _label("",30,Color.WHITE,true)
	feedback_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	feedback_label.position = Vector2(-260,118)
	feedback_label.size = Vector2(520,58)
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.modulate.a = 0.0
	canvas.add_child(feedback_label)

	combo_label = _label("",45,Color("#ffe170"),true)
	combo_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	combo_label.position = Vector2(-260,180)
	combo_label.size = Vector2(520,70)
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combo_label.modulate.a = 0.0
	canvas.add_child(combo_label)

func _build_menu_overlay(canvas: CanvasLayer) -> Control:
	var root: Control = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(root)

	var dim: ColorRect = ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.015,0.018,0.03,0.72)
	root.add_child(dim)

	var panel: Panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-500,-285)
	panel.size = Vector2(1000,570)
	panel.add_theme_stylebox_override("panel",_panel_style(Color(0.025,0.033,0.055,0.97),34,Color(1.0,0.68,0.28,0.25),1))
	root.add_child(panel)

	var eyebrow: Label = _label("بازی آشپزی و مدیریت دکه",18,Color("#ffba5c"),false)
	eyebrow.position = Vector2(55,42)
	eyebrow.size = Vector2(420,32)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	panel.add_child(eyebrow)

	var title: Label = _label("دکه‌چی",76,Color("#ffffff"),true)
	title.position = Vector2(55,68)
	title.size = Vector2(420,105)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	panel.add_child(title)

	var subtitle: Label = _label("مواد سفارش را ببر، مشتری را راضی نگه دار و دکه‌ات را ارتقا بده.",20,Color(0.76,0.82,0.92,0.86),false)
	subtitle.position = Vector2(52,176)
	subtitle.size = Vector2(425,70)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	panel.add_child(subtitle)

	menu_coins_label = _label("سکه‌های من: ۰",23,Color("#ffd267"),true)
	menu_coins_label.position = Vector2(55,260)
	menu_coins_label.size = Vector2(420,42)
	menu_coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	panel.add_child(menu_coins_label)

	var start_button: Button = _button("شروع کار",26,Color("#f59b3d"))
	start_button.position = Vector2(55,330)
	start_button.size = Vector2(420,74)
	start_button.pressed.connect(_start_game)
	panel.add_child(start_button)

	var hint: Label = _label("با کشیدن انگشت مواد را برش بده؛ مواد اشتباه رضایت مشتری را کم می‌کند.",15,Color(0.65,0.72,0.82,0.72),false)
	hint.position = Vector2(55,424)
	hint.size = Vector2(420,72)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	panel.add_child(hint)

	var divider: ColorRect = ColorRect.new()
	divider.position = Vector2(515,38)
	divider.size = Vector2(1,494)
	divider.color = Color(1,1,1,0.09)
	panel.add_child(divider)

	var upgrade_title: Label = _label("ارتقای دکه",30,Color.WHITE,true)
	upgrade_title.position = Vector2(555,42)
	upgrade_title.size = Vector2(390,46)
	upgrade_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	panel.add_child(upgrade_title)

	var upgrade_note: Label = _label("درآمد بازی را خرج کن تا سفارش‌های بیشتری بگیری.",16,Color(0.68,0.75,0.86,0.8),false)
	upgrade_note.position = Vector2(555,88)
	upgrade_note.size = Vector2(390,34)
	upgrade_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	panel.add_child(upgrade_note)

	upgrades_box = HBoxContainer.new()
	upgrades_box.position = Vector2(548,140)
	upgrades_box.size = Vector2(402,350)
	upgrades_box.alignment = BoxContainer.ALIGNMENT_CENTER
	upgrades_box.add_theme_constant_override("separation",10)
	panel.add_child(upgrades_box)
	return root

func _build_game_over_overlay(canvas: CanvasLayer) -> Control:
	var root: Control = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.visible = false
	canvas.add_child(root)
	var dim: ColorRect = ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.01,0.012,0.022,0.82)
	root.add_child(dim)
	var panel: Panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-335,-230)
	panel.size = Vector2(670,460)
	panel.add_theme_stylebox_override("panel",_panel_style(Color(0.03,0.04,0.07,0.98),32,Color(1.0,0.7,0.3,0.25),1))
	root.add_child(panel)
	var title: Label = _label("پایان شیفت",48,Color.WHITE,true)
	title.position = Vector2(45,42)
	title.size = Vector2(580,70)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title)
	summary_label = _label("",24,Color(0.82,0.88,0.98,0.94),false)
	summary_label.position = Vector2(65,128)
	summary_label.size = Vector2(540,145)
	summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(summary_label)
	var replay: Button = _button("شیفت بعدی",24,Color("#f59b3d"))
	replay.position = Vector2(90,300)
	replay.size = Vector2(490,66)
	replay.pressed.connect(_start_game)
	panel.add_child(replay)
	var menu_button: Button = _button("بازگشت و ارتقا",18,Color("#27334b"))
	menu_button.position = Vector2(90,378)
	menu_button.size = Vector2(490,48)
	menu_button.pressed.connect(_return_to_menu)
	panel.add_child(menu_button)
	return root

func _build_vignette(canvas: CanvasLayer) -> void:
	var vignette: ColorRect = ColorRect.new()
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader: Shader = Shader.new()
	shader.code = "shader_type canvas_item; void fragment(){ vec2 p=UV-vec2(0.5); float d=dot(p,p); float v=smoothstep(0.16,0.52,d); COLOR=vec4(0.0,0.0,0.02,v*0.64); }"
	var shader_material: ShaderMaterial = ShaderMaterial.new()
	shader_material.shader = shader
	vignette.material = shader_material
	canvas.add_child(vignette)

func _build_avatar() -> Control:
	var root: Control = Control.new()
	root.size = Vector2(96,96)
	var back: Panel = Panel.new()
	back.size = Vector2(96,96)
	back.add_theme_stylebox_override("panel",_panel_style(Color("#2b3d5c"),48,Color(0.5,0.75,1.0,0.25),2))
	root.add_child(back)
	var body: Panel = Panel.new()
	body.position = Vector2(19,58)
	body.size = Vector2(58,42)
	body.add_theme_stylebox_override("panel",_panel_style(Color("#cf465b"),22,Color.TRANSPARENT,0))
	root.add_child(body)
	var head: Panel = Panel.new()
	head.position = Vector2(28,19)
	head.size = Vector2(40,48)
	head.add_theme_stylebox_override("panel",_panel_style(Color("#e0ad83"),22,Color.TRANSPARENT,0))
	root.add_child(head)
	var hair: Panel = Panel.new()
	hair.position = Vector2(24,13)
	hair.size = Vector2(48,30)
	hair.add_theme_stylebox_override("panel",_panel_style(Color("#30221f"),20,Color.TRANSPARENT,0))
	root.add_child(hair)
	head.move_to_front()
	return root

func _panel_style(color_value: Color, radius: int, border_color: Color, border_width: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color_value
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_right = border_width
	style.border_width_top = border_width
	style.border_width_bottom = border_width
	style.shadow_color = Color(0,0,0,0.32)
	style.shadow_size = 12
	style.shadow_offset = Vector2(0,5)
	return style

func _label(text_value: String, size_value: int, color_value: Color, bold: bool) -> Label:
	var label: Label = Label.new()
	label.text = text_value
	label.text_direction = Control.TEXT_DIRECTION_RTL
	label.add_theme_font_size_override("font_size",size_value)
	label.add_theme_color_override("font_color",color_value)
	label.add_theme_color_override("font_shadow_color",Color(0,0,0,0.6))
	label.add_theme_constant_override("shadow_offset_x",2)
	label.add_theme_constant_override("shadow_offset_y",2)
	if bold and ui_font_bold != null:
		label.add_theme_font_override("font",ui_font_bold)
	elif ui_font != null:
		label.add_theme_font_override("font",ui_font)
	return label

func _button(text_value: String, size_value: int, color_value: Color) -> Button:
	var button: Button = Button.new()
	button.text = text_value
	button.text_direction = Control.TEXT_DIRECTION_RTL
	button.add_theme_font_size_override("font_size",size_value)
	button.add_theme_color_override("font_color",Color.WHITE)
	button.add_theme_color_override("font_hover_color",Color.WHITE)
	if ui_font_bold != null:
		button.add_theme_font_override("font",ui_font_bold)
	button.add_theme_stylebox_override("normal",_panel_style(color_value,18,Color(1,1,1,0.12),1))
	button.add_theme_stylebox_override("hover",_panel_style(color_value.lightened(0.08),18,Color(1,1,1,0.22),1))
	button.add_theme_stylebox_override("pressed",_panel_style(color_value.darkened(0.1),18,Color(1,1,1,0.1),1))
	return button

func _start_game() -> void:
	_clear_items()
	game_active = true
	transition_locked = false
	swipe_active = false
	session_revenue = 0
	served_orders = 0
	customer_hearts = 3
	combo_chain = 0
	order_streak = 0
	menu_overlay.visible = false
	game_over_overlay.visible = false
	_start_next_order()
	spawn_timer.start()
	_update_hud()
	for delay: float in [0.15,0.42,0.72]:
		get_tree().create_timer(delay).timeout.connect(_spawn_wave)

func _return_to_menu() -> void:
	game_active = false
	transition_locked = false
	spawn_timer.stop()
	_clear_items()
	game_over_overlay.visible = false
	menu_overlay.visible = true
	_update_menu()

func _start_next_order() -> void:
	transition_locked = false
	_clear_items()
	var available_count: int = mini(order_catalog.size(),3 + served_orders / 2)
	var selected_index: int = randi_range(0,available_count - 1)
	if order_catalog.size() > 1 and selected_index == customer_index:
		selected_index = (selected_index + 1) % available_count
	customer_index = selected_index
	current_order = order_catalog[selected_index].duplicate(true) as Dictionary
	remaining_ingredients = (current_order.get("ingredients",{}) as Dictionary).duplicate(true)
	order_time_total = 18.0 + float(counter_level) * 1.5 - minf(4.0,float(served_orders) * 0.2)
	order_time_left = order_time_total
	order_serial += 1
	order_timer_bar.max_value = order_time_total
	order_timer_bar.value = order_time_left
	order_customer_label.text = "مشتری: %s" % String(current_order.get("customer","مشتری"))
	order_title_label.text = String(current_order.get("title","سفارش جدید"))
	_update_order_ingredients()
	_show_feedback("سفارش جدید",Color("#9bc5ff"))

func _spawn_wave() -> void:
	if not game_active or transition_locked:
		return
	var count: int = 1
	var roll: float = randf()
	if roll > 0.55:
		count = 2
	if roll > 0.9 and served_orders >= 2:
		count = 3
	var center: float = randf_range(-3.7,3.7)
	for index: int in range(count):
		var x_value: float = clampf(center + (float(index) - float(count - 1) * 0.5) * randf_range(1.35,1.95),-5.2,5.2)
		_spawn_item(x_value,index,count)

func _spawn_item(x_value: float, index: int, count: int) -> void:
	var key: String = _choose_spawn_key()
	var data: Dictionary = (ingredient_catalog[key] as Dictionary).duplicate(true)
	var item: SliceItem = ITEM_SCRIPT.new() as SliceItem
	item.configure(data)
	item.name = "%s_%d" % [key,item_serial]
	item_serial += 1
	item.position = Vector3(x_value,-3.05,randf_range(-0.1,0.75))
	item.rotation_degrees = Vector3(randf_range(-25,25),randf_range(0,360),randf_range(-25,25))
	item.sliced.connect(_on_item_sliced)
	item.bomb_triggered.connect(_on_hazard)
	item.missed.connect(_on_item_missed)
	add_child(item)
	var outward: float = 0.0
	if count > 1:
		outward = (float(index) - float(count - 1) * 0.5) * 1.1
	item.linear_velocity = Vector3(outward + randf_range(-0.55,0.55),randf_range(9.6,11.8),randf_range(-0.4,0.28))
	item.angular_velocity = Vector3(randf_range(-4.5,4.5),randf_range(-4.5,4.5),randf_range(-4.5,4.5))

func _choose_spawn_key() -> String:
	var needed: Array[String] = []
	for key_variant: Variant in remaining_ingredients.keys():
		var key: String = String(key_variant)
		if int(remaining_ingredients.get(key,0)) > 0:
			needed.append(key)
	if not needed.is_empty() and randf() < 0.68:
		return needed[randi_range(0,needed.size() - 1)]
	var all_keys: Array[String] = []
	for key_variant: Variant in ingredient_catalog.keys():
		all_keys.append(String(key_variant))
	return all_keys[randi_range(0,all_keys.size() - 1)]

func _begin_swipe(position: Vector2) -> void:
	swipe_active = true
	previous_swipe_point = position
	swipe_hit_ids.clear()
	swipe_slice_count = 0
	trail.clear_trail()
	trail.add_slash_point(position)

func _continue_swipe(position: Vector2) -> void:
	if not swipe_active or not game_active or transition_locked:
		return
	if previous_swipe_point.distance_to(position) < 5.0:
		return
	trail.add_slash_point(position)
	var screen_delta: Vector2 = position - previous_swipe_point
	var world_swipe: Vector3 = (camera.global_transform.basis.x * screen_delta.x - camera.global_transform.basis.y * screen_delta.y).normalized()
	var sample_count: int = clampi(int(screen_delta.length() / 12.0) + 2,2,16)
	for index: int in range(sample_count + 1):
		var sample: Vector2 = previous_swipe_point.lerp(position,float(index) / float(sample_count))
		_raycast_slice(sample,world_swipe)
	previous_swipe_point = position

func _end_swipe() -> void:
	swipe_active = false
	swipe_hit_ids.clear()

func _raycast_slice(screen_position: Vector2, world_swipe: Vector3) -> void:
	var origin: Vector3 = camera.project_ray_origin(screen_position)
	var direction: Vector3 = camera.project_ray_normal(screen_position)
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(origin,origin + direction * 42.0,1)
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
	var hit_position: Vector3 = hit.get("position",item.global_position) as Vector3
	item.slash(world_swipe,hit_position)

func _on_item_sliced(item: SliceItem, base_value: int, position_value: Vector3, color_value: Color, _direction: Vector3) -> void:
	if not game_active or transition_locked:
		return
	_spawn_juice(position_value,color_value,26 + swipe_slice_count * 4)
	_play_slice_sound(560.0 + float(swipe_slice_count) * 80.0)
	Input.vibrate_handheld(16)
	var key: String = item.item_name
	var needed_count: int = int(remaining_ingredients.get(key,0))
	if needed_count > 0:
		remaining_ingredients[key] = needed_count - 1
		swipe_slice_count += 1
		combo_chain += 1
		var knife_multiplier: float = 1.0 + float(knife_level) * 0.12
		var combo_multiplier: float = 1.0 + float(mini(combo_chain,8) - 1) * 0.08
		var earned: int = int(round(float(base_value) * knife_multiplier * combo_multiplier))
		session_revenue += earned
		_show_feedback("+%d  درست!" % earned,Color("#8ef0a5"))
		if swipe_slice_count >= 2:
			_show_combo(swipe_slice_count)
		_update_order_ingredients()
		_update_hud()
		if _order_is_complete():
			_complete_order()
	else:
		combo_chain = 0
		order_time_left = maxf(0.0,order_time_left - 2.6)
		_show_feedback("این تو سفارش نبود!",Color("#ff6d7d"))
		Input.vibrate_handheld(65)

func _on_hazard(_item: SliceItem, position_value: Vector3) -> void:
	_spawn_juice(position_value,Color("#ff3a1e"),60)
	_fail_order("مواد سوخت!")

func _on_item_missed(item: SliceItem) -> void:
	if not game_active or transition_locked:
		return
	var key: String = item.item_name
	if int(remaining_ingredients.get(key,0)) > 0:
		order_time_left = maxf(0.0,order_time_left - 1.1)

func _order_is_complete() -> bool:
	for value: Variant in remaining_ingredients.values():
		if int(value) > 0:
			return false
	return true

func _complete_order() -> void:
	if transition_locked:
		return
	transition_locked = true
	spawn_timer.stop()
	var base_reward: int = int(current_order.get("reward",60))
	var speed_bonus: int = int(round(order_time_left * 1.5))
	var streak_bonus: int = order_streak * 8
	var sign_multiplier: float = 1.0 + float(sign_level) * 0.1
	var reward: int = int(round(float(base_reward + speed_bonus + streak_bonus) * sign_multiplier))
	coins += reward
	session_revenue += reward
	served_orders += 1
	order_streak += 1
	best_revenue = maxi(best_revenue,session_revenue)
	_save_game()
	_show_feedback("سفارش تحویل شد  +%d سکه" % reward,Color("#ffd267"))
	_play_success_sound()
	Input.vibrate_handheld(45)
	_update_hud()
	get_tree().create_timer(1.15).timeout.connect(_start_next_order_and_resume)

func _start_next_order_and_resume() -> void:
	if not game_active:
		return
	_start_next_order()
	spawn_timer.start()
	_spawn_wave()

func _fail_order(message: String) -> void:
	if transition_locked or not game_active:
		return
	transition_locked = true
	spawn_timer.stop()
	customer_hearts -= 1
	combo_chain = 0
	order_streak = 0
	_show_feedback(message,Color("#ff6377"))
	_play_fail_sound()
	Input.vibrate_handheld(130)
	_update_hud()
	if customer_hearts <= 0:
		get_tree().create_timer(1.0).timeout.connect(_end_game)
	else:
		get_tree().create_timer(1.0).timeout.connect(_start_next_order_and_resume)

func _end_game() -> void:
	game_active = false
	transition_locked = false
	spawn_timer.stop()
	_clear_items()
	best_revenue = maxi(best_revenue,session_revenue)
	_save_game()
	summary_label.text = "فروش این شیفت: %d\nسفارش تحویل‌شده: %d\nبهترین فروش: %d\nسکه کل: %d" % [session_revenue,served_orders,best_revenue,coins]
	game_over_overlay.visible = true
	_update_hud()

func _update_order_ingredients() -> void:
	for child: Node in order_ingredients_box.get_children():
		child.queue_free()
	var ingredients: Dictionary = current_order.get("ingredients",{}) as Dictionary
	for key_variant: Variant in ingredients.keys():
		var key: String = String(key_variant)
		var total: int = int(ingredients.get(key,0))
		var remaining: int = int(remaining_ingredients.get(key,0))
		var done: int = total - remaining
		var data: Dictionary = ingredient_catalog[key] as Dictionary
		var chip: Panel = Panel.new()
		chip.custom_minimum_size = Vector2(96,56)
		var complete: bool = remaining <= 0
		var chip_color: Color = Color(0.12,0.42,0.25,0.82) if complete else Color(0.09,0.12,0.19,0.92)
		chip.add_theme_stylebox_override("panel",_panel_style(chip_color,15,Color(1,1,1,0.09),1))
		order_ingredients_box.add_child(chip)
		var label: Label = _label("✓ %s" % String(data.get("fa",key)) if complete else "%s  %d/%d" % [String(data.get("fa",key)),done,total],14,Color.WHITE,complete)
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		chip.add_child(label)

func _update_hud() -> void:
	if hud_coins_label != null:
		hud_coins_label.text = "سکه  %d" % coins
	if hud_revenue_label != null:
		hud_revenue_label.text = "فروش  %d" % session_revenue
	if hearts_label != null:
		var alive: String = "♥  ".repeat(maxi(customer_hearts,0)).strip_edges()
		var lost: String = "♡  ".repeat(maxi(3-customer_hearts,0)).strip_edges()
		hearts_label.text = (alive + "  " + lost).strip_edges()

func _update_menu() -> void:
	if menu_coins_label != null:
		menu_coins_label.text = "سکه‌های من: %d" % coins
	if upgrades_box == null:
		return
	for child: Node in upgrades_box.get_children():
		child.queue_free()
	upgrades_box.add_child(_upgrade_card("چاقوی تیز", "امتیاز هر برش", knife_level,120 + knife_level * 90,0))
	upgrades_box.add_child(_upgrade_card("میز سریع", "زمان بیشتر سفارش", counter_level,150 + counter_level * 110,1))
	upgrades_box.add_child(_upgrade_card("تابلوی دکه", "سکه بیشتر", sign_level,180 + sign_level * 130,2))

func _upgrade_card(title_value: String, subtitle_value: String, level: int, cost: int, upgrade_type: int) -> Panel:
	var card: Panel = Panel.new()
	card.custom_minimum_size = Vector2(124,330)
	card.add_theme_stylebox_override("panel",_panel_style(Color(0.055,0.07,0.11,0.94),20,Color(1,1,1,0.08),1))
	var title: Label = _label(title_value,19,Color.WHITE,true)
	title.position = Vector2(10,24)
	title.size = Vector2(104,36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(title)
	var level_label: Label = _label("سطح %d" % level,15,Color("#ffbd62"),true)
	level_label.position = Vector2(10,70)
	level_label.size = Vector2(104,30)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(level_label)
	var subtitle: Label = _label(subtitle_value,13,Color(0.72,0.78,0.88,0.8),false)
	subtitle.position = Vector2(10,116)
	subtitle.size = Vector2(104,70)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(subtitle)
	var benefit: Label = _label(_upgrade_benefit(upgrade_type,level),14,Color("#8ed9ff"),true)
	benefit.position = Vector2(10,198)
	benefit.size = Vector2(104,42)
	benefit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(benefit)
	var button: Button = _button("%d سکه" % cost,14,Color("#33415d"))
	button.position = Vector2(10,262)
	button.size = Vector2(104,48)
	button.disabled = coins < cost or level >= 5
	button.pressed.connect(_buy_upgrade.bind(upgrade_type,cost))
	card.add_child(button)
	return card

func _upgrade_benefit(upgrade_type: int, level: int) -> String:
	if upgrade_type == 0:
		return "+%d%% امتیاز" % (level * 12)
	if upgrade_type == 1:
		return "+%.1f ثانیه" % (float(level) * 1.5)
	return "+%d%% سکه" % (level * 10)

func _buy_upgrade(upgrade_type: int, cost: int) -> void:
	if coins < cost:
		return
	coins -= cost
	if upgrade_type == 0:
		knife_level = mini(5,knife_level + 1)
	elif upgrade_type == 1:
		counter_level = mini(5,counter_level + 1)
	else:
		sign_level = mini(5,sign_level + 1)
	_save_game()
	_update_menu()
	_play_success_sound()

func _show_feedback(text_value: String, color_value: Color) -> void:
	feedback_label.text = text_value
	feedback_label.add_theme_color_override("font_color",color_value)
	feedback_label.modulate = Color.WHITE
	feedback_label.scale = Vector2(0.82,0.82)
	feedback_label.pivot_offset = feedback_label.size * 0.5
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(feedback_label,"scale",Vector2.ONE,0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(feedback_label,"modulate:a",0.0,0.7).set_delay(0.55)

func _show_combo(value: int) -> void:
	combo_label.text = "کمبو ×%d" % value
	combo_label.modulate = Color.WHITE
	combo_label.scale = Vector2(0.7,0.7)
	combo_label.pivot_offset = combo_label.size * 0.5
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(combo_label,"scale",Vector2.ONE,0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(combo_label,"modulate:a",0.0,0.75).set_delay(0.35)

func _spawn_juice(position_value: Vector3, color_value: Color, amount_value: int) -> void:
	var particles: CPUParticles3D = CPUParticles3D.new()
	particles.one_shot = true
	particles.amount = amount_value
	particles.lifetime = 0.85
	particles.explosiveness = 0.95
	particles.randomness = 0.68
	particles.direction = Vector3(0,0.3,0.2)
	particles.spread = 180.0
	particles.initial_velocity_min = 2.2
	particles.initial_velocity_max = 6.8
	particles.gravity = Vector3(0,-9.4,0)
	particles.scale_amount_min = 0.028
	particles.scale_amount_max = 0.115
	var particle_mesh: SphereMesh = SphereMesh.new()
	particle_mesh.radius = 0.055
	particle_mesh.height = 0.11
	particle_mesh.radial_segments = 7
	particle_mesh.rings = 4
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color_value
	material.roughness = 0.24
	material.emission_enabled = true
	material.emission = color_value * 0.12
	particle_mesh.material = material
	particles.mesh = particle_mesh
	particles.position = position_value
	add_child(particles)
	particles.emitting = true
	get_tree().create_timer(1.35).timeout.connect(particles.queue_free)

func _clear_items() -> void:
	for child: Node in get_children():
		if child is SliceItem:
			child.queue_free()

func _play_slice_sound(frequency: float) -> void:
	_play_synth(frequency,0.065,0.22,false)

func _play_success_sound() -> void:
	_play_synth(660.0,0.1,0.22,false)
	get_tree().create_timer(0.11).timeout.connect(_play_synth.bind(880.0,0.12,0.2,false))

func _play_fail_sound() -> void:
	_play_synth(120.0,0.24,0.3,true)

func _play_synth(frequency: float, duration: float, volume: float, noisy: bool) -> void:
	var sample_rate: int = 22050
	var sample_count: int = int(float(sample_rate) * duration)
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(sample_count * 2)
	for index: int in range(sample_count):
		var time_value: float = float(index) / float(sample_rate)
		var envelope: float = pow(1.0 - float(index) / float(sample_count),2.0)
		var wave: float = sin(TAU * frequency * time_value)
		if noisy:
			wave = wave * 0.55 + randf_range(-1.0,1.0) * 0.45
		var sample_value: int = int(clampf(wave * envelope * volume,-1.0,1.0) * 32767.0)
		bytes.encode_s16(index * 2,sample_value)
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

func _load_save() -> void:
	if not FileAccess.file_exists("user://dakechi_save.json"):
		return
	var file: FileAccess = FileAccess.open("user://dakechi_save.json",FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return
	var data: Dictionary = parsed as Dictionary
	coins = int(data.get("coins",0))
	best_revenue = int(data.get("best_revenue",0))
	knife_level = int(data.get("knife_level",0))
	counter_level = int(data.get("counter_level",0))
	sign_level = int(data.get("sign_level",0))

func _save_game() -> void:
	var data: Dictionary = {
		"coins":coins,
		"best_revenue":best_revenue,
		"knife_level":knife_level,
		"counter_level":counter_level,
		"sign_level":sign_level
	}
	var file: FileAccess = FileAccess.open("user://dakechi_save.json",FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data))
