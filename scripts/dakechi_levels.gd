extends "res://scripts/dakechi.gd"

const MAX_STAGE: int = 30

var unlocked_stage: int = 1
var selected_stage: int = 1
var selected_difficulty: int = 0
var stage_stars: Dictionary = {}

var active_stage: Dictionary = {}
var active_difficulty: Dictionary = {}
var stage_start_hearts: int = 3
var correct_cuts_stage: int = 0
var wrong_cuts_stage: int = 0
var missed_needed_stage: int = 0
var max_combo_stage: int = 0
var order_had_mistake: bool = false
var perfect_orders: int = 0
var adaptive_pressure: float = 0.0
var stage_order_bag: Array[int] = []
var last_stage_order: int = -1

var stage_chapter_label: Label
var stage_title_label: Label
var stage_rule_label: Label
var stage_goal_label: Label
var stage_stars_label: Label
var stage_lock_label: Label
var stage_start_button: Button
var difficulty_buttons: Array[Button] = []
var stage_progress_label: Label
var accuracy_label: Label
var result_title_label: Label
var result_replay_button: Button

var difficulty_catalog: Array[Dictionary] = [
	{"name":"معمولی", "time":1.0, "spawn":1.0, "hazard":0.0, "distractor":0.0, "reward":1.0, "hearts":3},
	{"name":"سخت", "time":0.82, "spawn":1.18, "hazard":0.055, "distractor":0.09, "reward":1.35, "hearts":3},
	{"name":"استاد", "time":0.68, "spawn":1.38, "hazard":0.12, "distractor":0.16, "reward":1.75, "hearts":2}
]

func _ready() -> void:
	_install_expanded_orders()
	super._ready()
	selected_stage = clampi(unlocked_stage,1,MAX_STAGE)
	_update_menu()

func _install_expanded_orders() -> void:
	order_catalog = [
		{"title":"آب‌لیموی تازه", "customer":"مریم", "reward":55, "unlock":1, "ingredients":{"LEMON":2}},
		{"title":"سیب قاچ‌شده", "customer":"امیر", "reward":58, "unlock":1, "ingredients":{"APPLE":2}},
		{"title":"آب‌انار مخصوص", "customer":"سارا", "reward":70, "unlock":2, "ingredients":{"POMEGRANATE":2,"LEMON":1}},
		{"title":"سالاد میوه کوچک", "customer":"رضا", "reward":72, "unlock":2, "ingredients":{"APPLE":1,"KIWI":1,"LEMON":1}},
		{"title":"سیب‌زمینی دکه", "customer":"نگار", "reward":74, "unlock":3, "ingredients":{"POTATO":2}},
		{"title":"ساندویچ ساده", "customer":"علی", "reward":82, "unlock":3, "ingredients":{"BUN":1,"TOMATO":1}},
		{"title":"پیاز و سیب‌زمینی", "customer":"نسترن", "reward":88, "unlock":4, "ingredients":{"POTATO":2,"ONION":1}},
		{"title":"ساندویچ دکه", "customer":"سامان", "reward":92, "unlock":4, "ingredients":{"BUN":1,"ONION":1,"TOMATO":1}},
		{"title":"میوه سه‌رنگ", "customer":"رها", "reward":96, "unlock":5, "ingredients":{"APPLE":1,"KIWI":1,"POMEGRANATE":1}},
		{"title":"پک ترش و شیرین", "customer":"پویان", "reward":98, "unlock":6, "ingredients":{"LEMON":2,"APPLE":1,"POMEGRANATE":1}},
		{"title":"ساندویچ دوبل", "customer":"مهسا", "reward":112, "unlock":7, "ingredients":{"BUN":2,"TOMATO":1,"ONION":1}},
		{"title":"سالاد میوه بزرگ", "customer":"کیان", "reward":118, "unlock":8, "ingredients":{"APPLE":2,"KIWI":2,"LEMON":1}},
		{"title":"پک مهمانی", "customer":"آیدا", "reward":124, "unlock":9, "ingredients":{"POMEGRANATE":1,"APPLE":1,"KIWI":1,"LEMON":1}},
		{"title":"سیب‌زمینی دوبل", "customer":"پارسا", "reward":128, "unlock":10, "ingredients":{"POTATO":3,"ONION":1,"TOMATO":1}},
		{"title":"میوه انرژی‌زا", "customer":"یاسمن", "reward":132, "unlock":11, "ingredients":{"KIWI":2,"APPLE":1,"LEMON":2}},
		{"title":"ساندویچ خانوادگی", "customer":"آرین", "reward":145, "unlock":12, "ingredients":{"BUN":2,"TOMATO":2,"ONION":2}},
		{"title":"انار و کیوی ویژه", "customer":"ترانه", "reward":148, "unlock":14, "ingredients":{"POMEGRANATE":2,"KIWI":2,"LEMON":1}},
		{"title":"پک چهار فصل", "customer":"مانی", "reward":158, "unlock":16, "ingredients":{"APPLE":2,"KIWI":1,"POMEGRANATE":1,"LEMON":1}},
		{"title":"دیس سیب‌زمینی", "customer":"هلیا", "reward":164, "unlock":18, "ingredients":{"POTATO":3,"ONION":2,"TOMATO":1}},
		{"title":"ساندویچ سه‌طبقه", "customer":"شایان", "reward":178, "unlock":20, "ingredients":{"BUN":3,"TOMATO":2,"ONION":2}},
		{"title":"میوه‌بار کامل", "customer":"دریا", "reward":188, "unlock":22, "ingredients":{"APPLE":2,"KIWI":2,"POMEGRANATE":2,"LEMON":1}},
		{"title":"سفارش شبانه", "customer":"بردیا", "reward":198, "unlock":24, "ingredients":{"BUN":2,"POTATO":2,"TOMATO":2,"ONION":1}},
		{"title":"پک جشن", "customer":"ستایش", "reward":212, "unlock":26, "ingredients":{"APPLE":2,"KIWI":2,"POMEGRANATE":2,"LEMON":2}},
		{"title":"سفارش رئیس", "customer":"آقای مدیر", "reward":235, "unlock":28, "ingredients":{"BUN":3,"POTATO":2,"TOMATO":2,"ONION":2}}
	]

func _get_stage(stage_number: int) -> Dictionary:
	var chapter: int = int((stage_number - 1) / 6) + 1
	var slot: int = (stage_number - 1) % 6
	var rule_ids: Array[String] = ["normal","rush","accuracy","hazards","combo","boss"]
	var rule_names: Array[String] = ["شیفت معمولی","ساعت شلوغی","مشتری سخت‌گیر","مواد سوخته","چالش کمبو","رئیس مرحله"]
	var chapter_names: Array[String] = ["کوچه‌ی اول","بازار شب","میدان شلوغ","خیابان مرکزی","دکه‌ی افسانه‌ای"]
	var target_orders: int = 2 + chapter + int(slot / 2)
	if slot == 5:
		target_orders += 2
	var base_time: float = 19.5 - float(chapter - 1) * 1.05 - float(slot) * 0.42
	var spawn_interval: float = 0.84 - float(chapter - 1) * 0.055 - float(slot) * 0.025
	var hazard_chance: float = 0.0
	if slot == 3:
		hazard_chance = 0.09 + float(chapter) * 0.018
	elif slot == 5:
		hazard_chance = 0.055 + float(chapter) * 0.015
	return {
		"number":stage_number,
		"chapter":chapter,
		"chapter_name":chapter_names[chapter - 1],
		"rule":rule_ids[slot],
		"rule_name":rule_names[slot],
		"target_orders":target_orders,
		"base_time":maxf(9.0,base_time),
		"spawn_interval":maxf(0.43,spawn_interval),
		"hazard_chance":hazard_chance,
		"strict":slot == 2,
		"combo_target":2 + chapter + slot,
		"max_ingredients":mini(5,2 + chapter),
		"needed_bias":maxf(0.52,0.76 - float(chapter - 1) * 0.035 - float(slot) * 0.01),
		"wrong_penalty":2.2 + float(chapter) * 0.35,
		"miss_penalty":0.8 + float(chapter) * 0.22
	}

func _process(delta: float) -> void:
	if not game_active or transition_locked:
		return
	order_time_left = maxf(0.0,order_time_left - delta)
	if order_timer_bar != null:
		order_timer_bar.value = order_time_left
	if order_time_left <= 0.0:
		_fail_order("وقت سفارش تمام شد!")
	var base_interval: float = float(active_stage.get("spawn_interval",0.8))
	var difficulty_speed: float = float(active_difficulty.get("spawn",1.0))
	spawn_timer.wait_time = maxf(0.27,base_interval / difficulty_speed - adaptive_pressure * 0.22)

func _build_top_hud(canvas: CanvasLayer) -> void:
	var top_bar: Panel = Panel.new()
	top_bar.position = Vector2(18,16)
	top_bar.size = Vector2(675,82)
	top_bar.add_theme_stylebox_override("panel",_panel_style(Color(0.025,0.035,0.06,0.9),24,Color(1.0,0.72,0.35,0.2),1))
	canvas.add_child(top_bar)
	hud_coins_label = _label("سکه ۰",21,Color("#ffd267"),true)
	hud_coins_label.position = Vector2(22,10)
	hud_coins_label.size = Vector2(145,30)
	top_bar.add_child(hud_coins_label)
	hud_revenue_label = _label("فروش ۰",19,Color("#ecf2ff"),false)
	hud_revenue_label.position = Vector2(170,12)
	hud_revenue_label.size = Vector2(140,30)
	top_bar.add_child(hud_revenue_label)
	hearts_label = _label("♥ ♥ ♥",22,Color("#ff526d"),true)
	hearts_label.position = Vector2(315,10)
	hearts_label.size = Vector2(120,30)
	hearts_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_bar.add_child(hearts_label)
	stage_progress_label = _label("مرحله ۱",16,Color("#9bc5ff"),true)
	stage_progress_label.position = Vector2(445,9)
	stage_progress_label.size = Vector2(205,30)
	stage_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top_bar.add_child(stage_progress_label)
	accuracy_label = _label("دقت ۱۰۰٪",14,Color(0.78,0.86,0.96,0.85),false)
	accuracy_label.position = Vector2(22,49)
	accuracy_label.size = Vector2(628,24)
	accuracy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top_bar.add_child(accuracy_label)

func _build_menu_overlay(canvas: CanvasLayer) -> Control:
	var root: Control = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(root)
	var dim: ColorRect = ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.015,0.018,0.03,0.78)
	root.add_child(dim)
	var panel: Panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-555,-305)
	panel.size = Vector2(1110,610)
	panel.add_theme_stylebox_override("panel",_panel_style(Color(0.025,0.033,0.055,0.98),34,Color(1.0,0.68,0.28,0.25),1))
	root.add_child(panel)
	var title: Label = _label("دکه‌چی",58,Color.WHITE,true)
	title.position = Vector2(40,28)
	title.size = Vector2(440,78)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	panel.add_child(title)
	menu_coins_label = _label("سکه‌های من: ۰",20,Color("#ffd267"),true)
	menu_coins_label.position = Vector2(40,100)
	menu_coins_label.size = Vector2(440,34)
	menu_coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	panel.add_child(menu_coins_label)
	var stage_panel: Panel = Panel.new()
	stage_panel.position = Vector2(38,150)
	stage_panel.size = Vector2(470,390)
	stage_panel.add_theme_stylebox_override("panel",_panel_style(Color(0.045,0.06,0.095,0.96),26,Color(0.45,0.68,1.0,0.18),1))
	panel.add_child(stage_panel)
	stage_chapter_label = _label("فصل",16,Color("#86b8ff"),true)
	stage_chapter_label.position = Vector2(30,22)
	stage_chapter_label.size = Vector2(410,28)
	stage_chapter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_panel.add_child(stage_chapter_label)
	stage_title_label = _label("مرحله ۱",38,Color.WHITE,true)
	stage_title_label.position = Vector2(70,52)
	stage_title_label.size = Vector2(330,55)
	stage_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_panel.add_child(stage_title_label)
	var previous_button: Button = _button("‹",30,Color("#283754"))
	previous_button.position = Vector2(18,57)
	previous_button.size = Vector2(52,50)
	previous_button.pressed.connect(_change_stage.bind(-1))
	stage_panel.add_child(previous_button)
	var next_button: Button = _button("›",30,Color("#283754"))
	next_button.position = Vector2(400,57)
	next_button.size = Vector2(52,50)
	next_button.pressed.connect(_change_stage.bind(1))
	stage_panel.add_child(next_button)
	stage_rule_label = _label("شیفت معمولی",22,Color("#ffbd62"),true)
	stage_rule_label.position = Vector2(30,122)
	stage_rule_label.size = Vector2(410,36)
	stage_rule_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_panel.add_child(stage_rule_label)
	stage_goal_label = _label("هدف مرحله",17,Color(0.78,0.84,0.93,0.9),false)
	stage_goal_label.position = Vector2(35,165)
	stage_goal_label.size = Vector2(400,70)
	stage_goal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_goal_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stage_goal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stage_panel.add_child(stage_goal_label)
	stage_stars_label = _label("☆ ☆ ☆",32,Color("#ffd267"),true)
	stage_stars_label.position = Vector2(30,238)
	stage_stars_label.size = Vector2(410,45)
	stage_stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_panel.add_child(stage_stars_label)
	stage_lock_label = _label("",16,Color("#ff7c8c"),true)
	stage_lock_label.position = Vector2(30,284)
	stage_lock_label.size = Vector2(410,28)
	stage_lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_panel.add_child(stage_lock_label)
	var difficulty_title: Label = _label("درجه سختی",15,Color(0.7,0.78,0.9,0.82),false)
	difficulty_title.position = Vector2(30,312)
	difficulty_title.size = Vector2(410,24)
	difficulty_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_panel.add_child(difficulty_title)
	var difficulty_box: HBoxContainer = HBoxContainer.new()
	difficulty_box.position = Vector2(27,342)
	difficulty_box.size = Vector2(416,42)
	difficulty_box.alignment = BoxContainer.ALIGNMENT_CENTER
	difficulty_box.add_theme_constant_override("separation",8)
	stage_panel.add_child(difficulty_box)
	for index: int in range(difficulty_catalog.size()):
		var diff_button: Button = _button(String(difficulty_catalog[index].get("name","")),14,Color("#31415f"))
		diff_button.custom_minimum_size = Vector2(128,40)
		diff_button.pressed.connect(_select_difficulty.bind(index))
		difficulty_box.add_child(diff_button)
		difficulty_buttons.append(diff_button)
	stage_start_button = _button("شروع مرحله",23,Color("#f59b3d"))
	stage_start_button.position = Vector2(38,552)
	stage_start_button.size = Vector2(470,54)
	stage_start_button.pressed.connect(_start_game)
	panel.add_child(stage_start_button)
	var divider: ColorRect = ColorRect.new()
	divider.position = Vector2(540,35)
	divider.size = Vector2(1,535)
	divider.color = Color(1,1,1,0.09)
	panel.add_child(divider)
	var upgrade_title: Label = _label("ارتقای دائمی دکه",27,Color.WHITE,true)
	upgrade_title.position = Vector2(575,45)
	upgrade_title.size = Vector2(490,42)
	upgrade_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	panel.add_child(upgrade_title)
	var note: Label = _label("ارتقاها در همه مرحله‌ها فعال‌اند؛ سختی بالاتر پاداش بیشتری دارد.",15,Color(0.68,0.75,0.86,0.8),false)
	note.position = Vector2(575,90)
	note.size = Vector2(490,50)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(note)
	upgrades_box = HBoxContainer.new()
	upgrades_box.position = Vector2(565,160)
	upgrades_box.size = Vector2(510,380)
	upgrades_box.alignment = BoxContainer.ALIGNMENT_CENTER
	upgrades_box.add_theme_constant_override("separation",12)
	panel.add_child(upgrades_box)
	return root

func _build_game_over_overlay(canvas: CanvasLayer) -> Control:
	var root: Control = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.visible = false
	canvas.add_child(root)
	var dim: ColorRect = ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.01,0.012,0.022,0.84)
	root.add_child(dim)
	var panel: Panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-350,-245)
	panel.size = Vector2(700,490)
	panel.add_theme_stylebox_override("panel",_panel_style(Color(0.03,0.04,0.07,0.98),32,Color(1.0,0.7,0.3,0.25),1))
	root.add_child(panel)
	result_title_label = _label("نتیجه مرحله",45,Color.WHITE,true)
	result_title_label.position = Vector2(50,36)
	result_title_label.size = Vector2(600,65)
	result_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(result_title_label)
	summary_label = _label("",22,Color(0.82,0.88,0.98,0.94),false)
	summary_label.position = Vector2(55,112)
	summary_label.size = Vector2(590,205)
	summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(summary_label)
	result_replay_button = _button("تلاش دوباره",22,Color("#f59b3d"))
	result_replay_button.position = Vector2(95,335)
	result_replay_button.size = Vector2(510,62)
	result_replay_button.pressed.connect(_start_game)
	panel.add_child(result_replay_button)
	var menu_button: Button = _button("انتخاب مرحله و ارتقا",17,Color("#27334b"))
	menu_button.position = Vector2(95,410)
	menu_button.size = Vector2(510,48)
	menu_button.pressed.connect(_return_to_menu)
	panel.add_child(menu_button)
	return root

func _change_stage(delta_value: int) -> void:
	selected_stage = clampi(selected_stage + delta_value,1,MAX_STAGE)
	_update_menu()

func _select_difficulty(index: int) -> void:
	selected_difficulty = clampi(index,0,difficulty_catalog.size() - 1)
	_save_game()
	_update_menu()

func _start_game() -> void:
	if selected_stage > unlocked_stage:
		return
	_clear_items()
	active_stage = _get_stage(selected_stage)
	active_difficulty = difficulty_catalog[selected_difficulty].duplicate(true)
	game_active = true
	transition_locked = false
	swipe_active = false
	session_revenue = 0
	served_orders = 0
	stage_start_hearts = int(active_difficulty.get("hearts",3))
	customer_hearts = stage_start_hearts
	combo_chain = 0
	order_streak = 0
	correct_cuts_stage = 0
	wrong_cuts_stage = 0
	missed_needed_stage = 0
	max_combo_stage = 0
	perfect_orders = 0
	adaptive_pressure = 0.0
	stage_order_bag.clear()
	last_stage_order = -1
	menu_overlay.visible = false
	game_over_overlay.visible = false
	_start_next_order()
	spawn_timer.start()
	_update_hud()
	_show_feedback("مرحله %d • %s" % [selected_stage,String(active_stage.get("rule_name",""))],Color("#9bc5ff"))
	for delay: float in [0.18,0.48,0.82]:
		get_tree().create_timer(delay).timeout.connect(_spawn_wave)

func _start_next_order() -> void:
	if served_orders >= int(active_stage.get("target_orders",3)):
		_finish_stage(true)
		return
	transition_locked = false
	_clear_items()
	var selected_index: int = _draw_stage_order()
	last_stage_order = selected_index
	current_order = order_catalog[selected_index].duplicate(true)
	var trait: Dictionary = _choose_customer_trait()
	current_order["trait"] = trait
	var ingredients: Dictionary = (current_order.get("ingredients",{}) as Dictionary).duplicate(true)
	if bool(trait.get("extra",false)):
		var keys: Array = ingredients.keys()
		if not keys.is_empty():
			var extra_key: String = String(keys[randi_range(0,keys.size() - 1)])
			ingredients[extra_key] = int(ingredients.get(extra_key,0)) + 1
	current_order["ingredients"] = ingredients
	remaining_ingredients = ingredients.duplicate(true)
	order_had_mistake = false
	var trait_time: float = float(trait.get("time",1.0))
	var pressure_time: float = 1.0 - adaptive_pressure * 0.32
	order_time_total = float(active_stage.get("base_time",18.0)) * float(active_difficulty.get("time",1.0)) * trait_time * pressure_time
	order_time_total += float(counter_level) * 1.25
	order_time_total = maxf(5.8,order_time_total)
	order_time_left = order_time_total
	order_serial += 1
	order_timer_bar.max_value = order_time_total
	order_timer_bar.value = order_time_left
	order_customer_label.text = "%s • %s" % [String(current_order.get("customer","مشتری")),String(trait.get("name","معمولی"))]
	order_title_label.text = String(current_order.get("title","سفارش جدید"))
	_update_order_ingredients()
	_show_feedback("سفارش %d از %d" % [served_orders + 1,int(active_stage.get("target_orders",3))],Color("#9bc5ff"))

func _choose_customer_trait() -> Dictionary:
	var traits: Array[Dictionary] = [
		{"name":"معمولی", "time":1.0, "reward":1.0},
		{"name":"عجول", "time":0.78, "reward":1.25},
		{"name":"ولخرج", "time":0.95, "reward":1.5},
		{"name":"سفارش بزرگ", "time":1.12, "reward":1.45, "extra":true},
		{"name":"سخت‌گیر", "time":0.9, "reward":1.35, "strict":true}
	]
	var available: int = mini(traits.size(),1 + int(selected_stage / 3))
	var rule: String = String(active_stage.get("rule",""))
	if rule == "rush":
		return traits[1].duplicate(true)
	if rule == "accuracy":
		return traits[4].duplicate(true)
	if rule == "boss":
		return traits[3].duplicate(true)
	return traits[randi_range(0,available - 1)].duplicate(true)

func _draw_stage_order() -> int:
	if stage_order_bag.is_empty():
		_refill_stage_order_bag()
	if stage_order_bag.is_empty():
		return 0
	var index: int = int(stage_order_bag.pop_back())
	if index == last_stage_order and not stage_order_bag.is_empty():
		var replacement: int = int(stage_order_bag.pop_back())
		stage_order_bag.push_front(index)
		index = replacement
	return index

func _refill_stage_order_bag() -> void:
	stage_order_bag.clear()
	var max_ingredients: int = int(active_stage.get("max_ingredients",2))
	for index: int in range(order_catalog.size()):
		var recipe: Dictionary = order_catalog[index]
		var ingredients: Dictionary = recipe.get("ingredients",{}) as Dictionary
		if int(recipe.get("unlock",1)) <= selected_stage and ingredients.size() <= max_ingredients:
			stage_order_bag.append(index)
	stage_order_bag.shuffle()

func _spawn_wave() -> void:
	if not game_active or transition_locked:
		return
	var hazard_chance: float = float(active_stage.get("hazard_chance",0.0)) + float(active_difficulty.get("hazard",0.0))
	if selected_stage >= 4 and randf() < hazard_chance:
		_spawn_stage_hazard(randf_range(-4.6,4.6))
	var count: int = 1
	var wave_power: float = float(active_stage.get("chapter",1)) * 0.08 + float(selected_difficulty) * 0.12 + adaptive_pressure
	var roll: float = randf()
	if roll < 0.48 + wave_power:
		count = 2
	if roll < 0.12 + wave_power * 0.35 and selected_stage >= 5:
		count = 3
	if String(active_stage.get("rule","")) == "rush" and randf() < 0.45:
		count = mini(4,count + 1)
	var center: float = randf_range(-3.7,3.7)
	var pattern: int = randi_range(0,2)
	for index: int in range(count):
		var spacing: float = 1.45 if pattern != 1 else 1.9
		var x_value: float = clampf(center + (float(index) - float(count - 1) * 0.5) * spacing,-5.2,5.2)
		_spawn_stage_item(x_value,index,count,pattern)

func _spawn_stage_item(x_value: float, index: int, count: int, pattern: int) -> void:
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
		outward = (float(index) - float(count - 1) * 0.5) * (1.1 if pattern != 2 else -1.4)
	var launch: float = 9.7 + float(active_stage.get("chapter",1)) * 0.28 + float(selected_difficulty) * 0.45
	var height_variation: float = float(index % 2) * 0.7 if pattern == 1 else 0.0
	item.linear_velocity = Vector3(outward + randf_range(-0.55,0.55),randf_range(launch,launch + 2.0) + height_variation,randf_range(-0.4,0.28))
	item.angular_velocity = Vector3(randf_range(-5.5,5.5),randf_range(-5.5,5.5),randf_range(-5.5,5.5))

func _spawn_stage_hazard(x_value: float) -> void:
	var data: Dictionary = {"name":"HAZARD", "points":0, "bomb":true, "skin":Color("#11151b"), "flesh":Color("#ff3a1e"), "juice":Color("#ff3a1e"), "shape":Vector3.ONE, "model":"", "model_scale":1.0}
	var item: SliceItem = ITEM_SCRIPT.new() as SliceItem
	item.configure(data)
	item.name = "Hazard_%d" % item_serial
	item_serial += 1
	item.position = Vector3(x_value,-3.05,randf_range(0.0,0.65))
	item.bomb_triggered.connect(_on_hazard)
	item.missed.connect(_on_item_missed)
	add_child(item)
	var launch: float = 10.2 + float(active_stage.get("chapter",1)) * 0.25
	item.linear_velocity = Vector3(randf_range(-0.8,0.8),randf_range(launch,launch + 1.8),randf_range(-0.35,0.25))
	item.angular_velocity = Vector3(randf_range(-4,4),randf_range(-4,4),randf_range(-4,4))

func _choose_spawn_key() -> String:
	var needed: Array[String] = []
	for key_variant: Variant in remaining_ingredients.keys():
		var key: String = String(key_variant)
		if int(remaining_ingredients.get(key,0)) > 0:
			needed.append(key)
	var needed_bias: float = float(active_stage.get("needed_bias",0.7)) - float(active_difficulty.get("distractor",0.0)) - adaptive_pressure * 0.12
	if not needed.is_empty() and randf() < clampf(needed_bias,0.35,0.82):
		return needed[randi_range(0,needed.size() - 1)]
	var all_keys: Array[String] = []
	for key_variant: Variant in ingredient_catalog.keys():
		all_keys.append(String(key_variant))
	return all_keys[randi_range(0,all_keys.size() - 1)]

func _on_item_sliced(item: SliceItem, base_value: int, position_value: Vector3, color_value: Color, _direction: Vector3) -> void:
	if not game_active or transition_locked:
		return
	_spawn_juice(position_value,color_value,26 + swipe_slice_count * 4)
	_play_slice_sound(560.0 + float(swipe_slice_count) * 80.0)
	Input.vibrate_handheld(16)
	var key: String = item.item_name
	var needed_count: int = int(remaining_ingredients.get(key,0))
	if needed_count > 0:
		correct_cuts_stage += 1
		remaining_ingredients[key] = needed_count - 1
		swipe_slice_count += 1
		combo_chain += 1
		max_combo_stage = maxi(max_combo_stage,combo_chain)
		var earned: int = int(round(float(base_value) * (1.0 + float(knife_level) * 0.12) * (1.0 + float(mini(combo_chain,10) - 1) * 0.08) * float(active_difficulty.get("reward",1.0))))
		session_revenue += earned
		_show_feedback("+%d  درست!" % earned,Color("#8ef0a5"))
		if swipe_slice_count >= 2:
			_show_combo(swipe_slice_count)
		_update_order_ingredients()
		_update_hud()
		if _order_is_complete():
			_complete_order()
	else:
		wrong_cuts_stage += 1
		order_had_mistake = true
		combo_chain = 0
		var trait: Dictionary = current_order.get("trait",{}) as Dictionary
		if bool(active_stage.get("strict",false)) or bool(trait.get("strict",false)):
			_fail_order("مشتری سخت‌گیر اشتباه را قبول نکرد!")
			return
		order_time_left = maxf(0.0,order_time_left - float(active_stage.get("wrong_penalty",2.5)))
		_show_feedback("این ماده توی سفارش نبود!",Color("#ff6d7d"))
		Input.vibrate_handheld(65)
		_update_hud()

func _on_item_missed(item: SliceItem) -> void:
	if not game_active or transition_locked or item.is_bomb:
		return
	var key: String = item.item_name
	if int(remaining_ingredients.get(key,0)) > 0:
		missed_needed_stage += 1
		order_had_mistake = true
		combo_chain = 0
		order_time_left = maxf(0.0,order_time_left - float(active_stage.get("miss_penalty",1.0)))
		_update_hud()

func _complete_order() -> void:
	if transition_locked:
		return
	transition_locked = true
	spawn_timer.stop()
	var trait: Dictionary = current_order.get("trait",{}) as Dictionary
	var reward: int = int(round(float(int(current_order.get("reward",60)) + int(round(order_time_left * 1.7)) + order_streak * 9) * (1.0 + float(sign_level) * 0.1) * float(active_difficulty.get("reward",1.0)) * float(trait.get("reward",1.0))))
	coins += reward
	session_revenue += reward
	served_orders += 1
	order_streak += 1
	if order_had_mistake:
		perfect_orders = 0
		adaptive_pressure = maxf(0.0,adaptive_pressure - 0.05)
	else:
		perfect_orders += 1
		adaptive_pressure = minf(0.25,float(perfect_orders) * 0.045)
	best_revenue = maxi(best_revenue,session_revenue)
	_save_game()
	_show_feedback("تحویل شد  +%d سکه" % reward,Color("#ffd267"))
	_play_success_sound()
	Input.vibrate_handheld(45)
	_update_hud()
	get_tree().create_timer(1.0).timeout.connect(_start_next_order_and_resume)

func _fail_order(message: String) -> void:
	if transition_locked or not game_active:
		return
	transition_locked = true
	spawn_timer.stop()
	customer_hearts -= 1
	combo_chain = 0
	order_streak = 0
	perfect_orders = 0
	adaptive_pressure = maxf(0.0,adaptive_pressure - 0.08)
	_show_feedback(message,Color("#ff6377"))
	_play_fail_sound()
	Input.vibrate_handheld(130)
	_update_hud()
	if customer_hearts <= 0:
		get_tree().create_timer(0.9).timeout.connect(_finish_stage.bind(false))
	else:
		get_tree().create_timer(0.95).timeout.connect(_start_next_order_and_resume)

func _end_game() -> void:
	_finish_stage(false)

func _finish_stage(success: bool) -> void:
	if not game_active:
		return
	game_active = false
	transition_locked = false
	spawn_timer.stop()
	_clear_items()
	best_revenue = maxi(best_revenue,session_revenue)
	var accuracy: float = _get_stage_accuracy()
	var stars: int = 0
	var stage_bonus: int = 0
	if success:
		stars = 1
		if customer_hearts >= mini(2,stage_start_hearts) and accuracy >= 0.80:
			stars = 2
		if customer_hearts == stage_start_hearts and accuracy >= 0.93 and max_combo_stage >= int(active_stage.get("combo_target",3)) and wrong_cuts_stage == 0:
			stars = 3
		stage_stars[str(selected_stage)] = maxi(int(stage_stars.get(str(selected_stage),0)),stars)
		unlocked_stage = maxi(unlocked_stage,mini(MAX_STAGE,selected_stage + 1))
		stage_bonus = int(round(float(80 + selected_stage * 14 + stars * 45) * float(active_difficulty.get("reward",1.0))))
		coins += stage_bonus
		result_title_label.text = "مرحله کامل شد!"
		result_replay_button.text = "اجرای دوباره"
		var star_text: String = "★ ".repeat(stars) + "☆ ".repeat(3 - stars)
		summary_label.text = "%s\n\nسفارش‌ها: %d از %d\nدقت: %d٪   |   بیشترین کمبو: %d\nفروش: %d   |   جایزه مرحله: %d سکه" % [star_text.strip_edges(),served_orders,int(active_stage.get("target_orders",3)),int(round(accuracy * 100.0)),max_combo_stage,session_revenue,stage_bonus]
	else:
		result_title_label.text = "مرحله ناموفق بود"
		result_replay_button.text = "تلاش دوباره"
		summary_label.text = "قلب‌های مشتری تمام شد.\n\nسفارش‌ها: %d از %d\nدقت: %d٪   |   اشتباه: %d\nفروش این تلاش: %d\n\nارتقا بده یا سختی پایین‌تر را امتحان کن." % [served_orders,int(active_stage.get("target_orders",3)),int(round(accuracy * 100.0)),wrong_cuts_stage + missed_needed_stage,session_revenue]
	_save_game()
	game_over_overlay.visible = true
	_update_hud()

func _get_stage_accuracy() -> float:
	var total: int = correct_cuts_stage + wrong_cuts_stage + missed_needed_stage
	return 1.0 if total <= 0 else float(correct_cuts_stage) / float(total)

func _update_hud() -> void:
	if hud_coins_label != null:
		hud_coins_label.text = "سکه %d" % coins
	if hud_revenue_label != null:
		hud_revenue_label.text = "فروش %d" % session_revenue
	if hearts_label != null:
		hearts_label.text = ("♥ ".repeat(maxi(customer_hearts,0)) + "♡ ".repeat(maxi(stage_start_hearts - customer_hearts,0))).strip_edges()
	if stage_progress_label != null and not active_stage.is_empty():
		stage_progress_label.text = "مرحله %d • %d/%d سفارش" % [selected_stage,served_orders,int(active_stage.get("target_orders",3))]
	if accuracy_label != null:
		var difficulty_name: String = String(active_difficulty.get("name",difficulty_catalog[selected_difficulty].get("name","")))
		accuracy_label.text = "دقت %d٪  •  کمبو %d  •  سختی %s" % [int(round(_get_stage_accuracy() * 100.0)),max_combo_stage,difficulty_name]

func _update_menu() -> void:
	super._update_menu()
	if menu_coins_label != null:
		menu_coins_label.text = "سکه‌های من: %d  •  مراحل باز: %d/%d" % [coins,unlocked_stage,MAX_STAGE]
	var stage_data: Dictionary = _get_stage(selected_stage)
	if stage_chapter_label != null:
		stage_chapter_label.text = "فصل %d • %s" % [int(stage_data.get("chapter",1)),String(stage_data.get("chapter_name",""))]
	if stage_title_label != null:
		stage_title_label.text = "مرحله %d" % selected_stage
	if stage_rule_label != null:
		stage_rule_label.text = String(stage_data.get("rule_name",""))
	if stage_goal_label != null:
		var extra_goal: String = ""
		var rule: String = String(stage_data.get("rule",""))
		if rule == "accuracy": extra_goal = " • یک برش اشتباه = رد سفارش"
		elif rule == "hazards": extra_goal = " • مواد سوخته را لمس نکن"
		elif rule == "combo": extra_goal = " • هدف کمبو %d" % int(stage_data.get("combo_target",3))
		elif rule == "rush": extra_goal = " • موج‌های چندتایی و زمان کمتر"
		elif rule == "boss": extra_goal = " • سفارش‌های بزرگ و مواد خطرناک"
		stage_goal_label.text = "تحویل %d سفارش%s" % [int(stage_data.get("target_orders",3)),extra_goal]
	if stage_stars_label != null:
		var stars: int = int(stage_stars.get(str(selected_stage),0))
		stage_stars_label.text = ("★ ".repeat(stars) + "☆ ".repeat(3 - stars)).strip_edges()
	var locked: bool = selected_stage > unlocked_stage
	if stage_lock_label != null:
		stage_lock_label.text = "🔒 ابتدا مرحله %d را کامل کن" % (selected_stage - 1) if locked else "زمان پایه هر سفارش: %.1f ثانیه" % float(stage_data.get("base_time",18.0))
	if stage_start_button != null:
		stage_start_button.disabled = locked
		stage_start_button.text = "مرحله قفل است" if locked else "شروع مرحله"
	for index: int in range(difficulty_buttons.size()):
		var button: Button = difficulty_buttons[index]
		var active: bool = index == selected_difficulty
		button.modulate = Color.WHITE if active else Color(0.72,0.76,0.84,0.8)
		button.text = "✓ %s" % String(difficulty_catalog[index].get("name","")) if active else String(difficulty_catalog[index].get("name",""))

func _upgrade_card(title_value: String, subtitle_value: String, level: int, cost: int, upgrade_type: int) -> Panel:
	var card: Panel = Panel.new()
	card.custom_minimum_size = Vector2(154,360)
	card.add_theme_stylebox_override("panel",_panel_style(Color(0.055,0.07,0.11,0.94),20,Color(1,1,1,0.08),1))
	var title: Label = _label(title_value,18,Color.WHITE,true)
	title.position = Vector2(10,24)
	title.size = Vector2(134,36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(title)
	var level_label: Label = _label("سطح %d" % level,15,Color("#ffbd62"),true)
	level_label.position = Vector2(10,70)
	level_label.size = Vector2(134,30)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(level_label)
	var subtitle: Label = _label(subtitle_value,13,Color(0.72,0.78,0.88,0.8),false)
	subtitle.position = Vector2(10,116)
	subtitle.size = Vector2(134,70)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(subtitle)
	var benefit: Label = _label(_upgrade_benefit(upgrade_type,level),14,Color("#8ed9ff"),true)
	benefit.position = Vector2(10,205)
	benefit.size = Vector2(134,42)
	benefit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(benefit)
	var button: Button = _button("%d سکه" % cost,14,Color("#33415d"))
	button.position = Vector2(12,285)
	button.size = Vector2(130,52)
	button.disabled = coins < cost or level >= 5
	button.pressed.connect(_buy_upgrade.bind(upgrade_type,cost))
	card.add_child(button)
	return card

func _load_save() -> void:
	super._load_save()
	if not FileAccess.file_exists("user://dakechi_save.json"):
		return
	var file: FileAccess = FileAccess.open("user://dakechi_save.json",FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return
	var data: Dictionary = parsed as Dictionary
	unlocked_stage = clampi(int(data.get("unlocked_stage",1)),1,MAX_STAGE)
	selected_difficulty = clampi(int(data.get("selected_difficulty",0)),0,difficulty_catalog.size() - 1)
	var saved_stars: Variant = data.get("stage_stars",{})
	if saved_stars is Dictionary:
		stage_stars = (saved_stars as Dictionary).duplicate(true)

func _save_game() -> void:
	var data: Dictionary = {"coins":coins,"best_revenue":best_revenue,"knife_level":knife_level,"counter_level":counter_level,"sign_level":sign_level,"unlocked_stage":unlocked_stage,"selected_difficulty":selected_difficulty,"stage_stars":stage_stars}
	var file: FileAccess = FileAccess.open("user://dakechi_save.json",FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data))
