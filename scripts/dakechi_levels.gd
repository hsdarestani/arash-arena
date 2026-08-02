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

var stage_panel: Panel
var stage_chapter_label: Label
var stage_title_label: Label
var stage_rule_label: Label
var stage_goal_label: Label
var stage_stars_label: Label
var stage_lock_label: Label
var stage_start_button: Button
var difficulty_buttons: Array[Button] = []

var difficulty_catalog: Array[Dictionary] = [
	{"name":"معمولی", "time":1.0, "spawn":1.0, "hazard":0.0, "distractor":0.0, "reward":1.0, "hearts":3},
	{"name":"سخت", "time":0.82, "spawn":1.18, "hazard":0.055, "distractor":0.09, "reward":1.35, "hearts":3},
	{"name":"استاد", "time":0.68, "spawn":1.38, "hazard":0.12, "distractor":0.16, "reward":1.75, "hearts":2}
]

func _ready() -> void:
	_install_expanded_orders()
	super._ready()
	selected_stage = clampi(selected_stage,1,MAX_STAGE)
	_add_stage_selector()
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

func _add_stage_selector() -> void:
	if menu_overlay == null:
		return
	stage_panel = Panel.new()
	stage_panel.position = Vector2(26,145)
	stage_panel.size = Vector2(430,440)
	stage_panel.z_index = 50
	stage_panel.add_theme_stylebox_override("panel",_panel_style(Color(0.035,0.05,0.085,0.98),26,Color(0.45,0.68,1.0,0.22),1))
	menu_overlay.add_child(stage_panel)

	stage_chapter_label = _label("فصل",16,Color("#86b8ff"),true)
	stage_chapter_label.position = Vector2(25,20)
	stage_chapter_label.size = Vector2(380,28)
	stage_chapter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_panel.add_child(stage_chapter_label)

	stage_title_label = _label("مرحله ۱",38,Color.WHITE,true)
	stage_title_label.position = Vector2(70,52)
	stage_title_label.size = Vector2(290,55)
	stage_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_panel.add_child(stage_title_label)

	var previous_button: Button = _button("‹",30,Color("#283754"))
	previous_button.position = Vector2(16,57)
	previous_button.size = Vector2(54,50)
	previous_button.pressed.connect(_change_stage.bind(-1))
	stage_panel.add_child(previous_button)

	var next_button: Button = _button("›",30,Color("#283754"))
	next_button.position = Vector2(360,57)
	next_button.size = Vector2(54,50)
	next_button.pressed.connect(_change_stage.bind(1))
	stage_panel.add_child(next_button)

	stage_rule_label = _label("شیفت معمولی",22,Color("#ffbd62"),true)
	stage_rule_label.position = Vector2(25,120)
	stage_rule_label.size = Vector2(380,36)
	stage_rule_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_panel.add_child(stage_rule_label)

	stage_goal_label = _label("هدف مرحله",16,Color(0.8,0.86,0.95,0.9),false)
	stage_goal_label.position = Vector2(25,164)
	stage_goal_label.size = Vector2(380,72)
	stage_goal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_goal_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stage_goal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stage_panel.add_child(stage_goal_label)

	stage_stars_label = _label("☆ ☆ ☆",31,Color("#ffd267"),true)
	stage_stars_label.position = Vector2(25,236)
	stage_stars_label.size = Vector2(380,42)
	stage_stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_panel.add_child(stage_stars_label)

	stage_lock_label = _label("",14,Color("#ff8190"),true)
	stage_lock_label.position = Vector2(25,278)
	stage_lock_label.size = Vector2(380,26)
	stage_lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_panel.add_child(stage_lock_label)

	var difficulty_box: HBoxContainer = HBoxContainer.new()
	difficulty_box.position = Vector2(17,310)
	difficulty_box.size = Vector2(396,42)
	difficulty_box.alignment = BoxContainer.ALIGNMENT_CENTER
	difficulty_box.add_theme_constant_override("separation",7)
	stage_panel.add_child(difficulty_box)

	for index in range(difficulty_catalog.size()):
		var difficulty_button: Button = _button(String(difficulty_catalog[index].get("name","")),14,Color("#31415f"))
		difficulty_button.custom_minimum_size = Vector2(122,40)
		difficulty_button.pressed.connect(_select_difficulty.bind(index))
		difficulty_box.add_child(difficulty_button)
		difficulty_buttons.append(difficulty_button)

	stage_start_button = _button("شروع مرحله",21,Color("#f59b3d"))
	stage_start_button.position = Vector2(25,370)
	stage_start_button.size = Vector2(380,52)
	stage_start_button.pressed.connect(_start_game)
	stage_panel.add_child(stage_start_button)

func _change_stage(delta_value: int) -> void:
	selected_stage = clampi(selected_stage + delta_value,1,MAX_STAGE)
	_update_menu()

func _select_difficulty(index: int) -> void:
	selected_difficulty = clampi(index,0,difficulty_catalog.size() - 1)
	_save_game()
	_update_menu()

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
	for delay_value in [0.18,0.48,0.82]:
		get_tree().create_timer(float(delay_value)).timeout.connect(_spawn_wave)

func _start_next_order() -> void:
	if served_orders >= int(active_stage.get("target_orders",3)):
		_finish_stage(true)
		return
	transition_locked = false
	_clear_items()
	var selected_index: int = _draw_stage_order()
	last_stage_order = selected_index
	current_order = order_catalog[selected_index].duplicate(true)
	var customer_type: Dictionary = _choose_customer_type()
	current_order["customer_type"] = customer_type
	var ingredients: Dictionary = (current_order.get("ingredients",{}) as Dictionary).duplicate(true)
	if bool(customer_type.get("extra",false)):
		var ingredient_keys: Array = ingredients.keys()
		if not ingredient_keys.is_empty():
			var extra_key: String = String(ingredient_keys[randi_range(0,ingredient_keys.size() - 1)])
			ingredients[extra_key] = int(ingredients.get(extra_key,0)) + 1
	current_order["ingredients"] = ingredients
	remaining_ingredients = ingredients.duplicate(true)
	order_had_mistake = false
	var customer_time: float = float(customer_type.get("time",1.0))
	var pressure_time: float = 1.0 - adaptive_pressure * 0.32
	order_time_total = float(active_stage.get("base_time",18.0)) * float(active_difficulty.get("time",1.0)) * customer_time * pressure_time
	order_time_total += float(counter_level) * 1.25
	order_time_total = maxf(5.8,order_time_total)
	order_time_left = order_time_total
	order_serial += 1
	order_timer_bar.max_value = order_time_total
	order_timer_bar.value = order_time_left
	order_customer_label.text = "%s • %s" % [String(current_order.get("customer","مشتری")),String(customer_type.get("name","معمولی"))]
	order_title_label.text = String(current_order.get("title","سفارش جدید"))
	_update_order_ingredients()
	_show_feedback("سفارش %d از %d" % [served_orders + 1,int(active_stage.get("target_orders",3))],Color("#9bc5ff"))

func _choose_customer_type() -> Dictionary:
	var customer_types: Array[Dictionary] = [
		{"name":"معمولی", "time":1.0, "reward":1.0},
		{"name":"عجول", "time":0.78, "reward":1.25},
		{"name":"ولخرج", "time":0.95, "reward":1.5},
		{"name":"سفارش بزرگ", "time":1.12, "reward":1.45, "extra":true},
		{"name":"سخت‌گیر", "time":0.9, "reward":1.35, "strict":true}
	]
	var available_count: int = mini(customer_types.size(),1 + int(selected_stage / 3))
	var rule_name: String = String(active_stage.get("rule",""))
	if rule_name == "rush":
		return customer_types[1].duplicate(true)
	if rule_name == "accuracy":
		return customer_types[4].duplicate(true)
	if rule_name == "boss":
		return customer_types[3].duplicate(true)
	return customer_types[randi_range(0,available_count - 1)].duplicate(true)

func _draw_stage_order() -> int:
	if stage_order_bag.is_empty():
		_refill_stage_order_bag()
	if stage_order_bag.is_empty():
		return 0
	var selected_index: int = int(stage_order_bag.pop_back())
	if selected_index == last_stage_order and not stage_order_bag.is_empty():
		var replacement_index: int = int(stage_order_bag.pop_back())
		stage_order_bag.push_front(selected_index)
		selected_index = replacement_index
	return selected_index

func _refill_stage_order_bag() -> void:
	stage_order_bag.clear()
	var max_ingredients: int = int(active_stage.get("max_ingredients",2))
	for index in range(order_catalog.size()):
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
	var item_count: int = 1
	var wave_power: float = float(active_stage.get("chapter",1)) * 0.08 + float(selected_difficulty) * 0.12 + adaptive_pressure
	var wave_roll: float = randf()
	if wave_roll < 0.48 + wave_power:
		item_count = 2
	if wave_roll < 0.12 + wave_power * 0.35 and selected_stage >= 5:
		item_count = 3
	if String(active_stage.get("rule","")) == "rush" and randf() < 0.45:
		item_count = mini(4,item_count + 1)
	var center_x: float = randf_range(-3.7,3.7)
	for index in range(item_count):
		var x_value: float = clampf(center_x + (float(index) - float(item_count - 1) * 0.5) * randf_range(1.35,1.95),-5.2,5.2)
		_spawn_item(x_value,index,item_count)

func _spawn_stage_hazard(x_value: float) -> void:
	var hazard_data: Dictionary = {
		"name":"HAZARD",
		"points":0,
		"bomb":true,
		"skin":Color("#11151b"),
		"flesh":Color("#ff3a1e"),
		"juice":Color("#ff3a1e"),
		"shape":Vector3.ONE,
		"model":"",
		"model_scale":1.0
	}
	var item: SliceItem = ITEM_SCRIPT.new() as SliceItem
	item.configure(hazard_data)
	item.name = "Hazard_%d" % item_serial
	item_serial += 1
	item.position = Vector3(x_value,-3.05,randf_range(0.0,0.65))
	item.bomb_triggered.connect(_on_hazard)
	item.missed.connect(_on_item_missed)
	add_child(item)
	var launch_speed: float = 10.2 + float(active_stage.get("chapter",1)) * 0.25
	item.linear_velocity = Vector3(randf_range(-0.8,0.8),randf_range(launch_speed,launch_speed + 1.8),randf_range(-0.35,0.25))
	item.angular_velocity = Vector3(randf_range(-4,4),randf_range(-4,4),randf_range(-4,4))

func _choose_spawn_key() -> String:
	var needed_keys: Array[String] = []
	for key_value in remaining_ingredients.keys():
		var ingredient_key: String = String(key_value)
		if int(remaining_ingredients.get(ingredient_key,0)) > 0:
			needed_keys.append(ingredient_key)
	var needed_bias: float = float(active_stage.get("needed_bias",0.7)) - float(active_difficulty.get("distractor",0.0)) - adaptive_pressure * 0.12
	if not needed_keys.is_empty() and randf() < clampf(needed_bias,0.35,0.82):
		return needed_keys[randi_range(0,needed_keys.size() - 1)]
	var all_keys: Array[String] = []
	for key_value in ingredient_catalog.keys():
		all_keys.append(String(key_value))
	return all_keys[randi_range(0,all_keys.size() - 1)]

func _on_item_sliced(item: SliceItem, base_value: int, position_value: Vector3, color_value: Color, direction_value: Vector3) -> void:
	if not game_active or transition_locked:
		return
	var needed_before: int = int(remaining_ingredients.get(item.item_name,0))
	if needed_before > 0:
		correct_cuts_stage += 1
	else:
		wrong_cuts_stage += 1
		order_had_mistake = true
	super._on_item_sliced(item,base_value,position_value,color_value,direction_value)
	max_combo_stage = maxi(max_combo_stage,combo_chain)
	if needed_before <= 0:
		var customer_type: Dictionary = current_order.get("customer_type",{}) as Dictionary
		if bool(active_stage.get("strict",false)) or bool(customer_type.get("strict",false)):
			_fail_order("مشتری سخت‌گیر اشتباه را قبول نکرد!")
		else:
			order_time_left = maxf(0.0,order_time_left - float(active_stage.get("wrong_penalty",2.5)))
	_update_hud()

func _on_item_missed(item: SliceItem) -> void:
	if game_active and not transition_locked and not item.is_bomb:
		if int(remaining_ingredients.get(item.item_name,0)) > 0:
			missed_needed_stage += 1
			order_had_mistake = true
			order_time_left = maxf(0.0,order_time_left - float(active_stage.get("miss_penalty",1.0)))
	super._on_item_missed(item)
	_update_hud()

func _complete_order() -> void:
	if transition_locked:
		return
	var coins_before: int = coins
	var revenue_before: int = session_revenue
	var customer_type: Dictionary = current_order.get("customer_type",{}) as Dictionary
	super._complete_order()
	var gained_coins: int = maxi(0,coins - coins_before)
	var reward_multiplier: float = float(active_difficulty.get("reward",1.0)) * float(customer_type.get("reward",1.0))
	var extra_reward: int = maxi(0,int(round(float(gained_coins) * (reward_multiplier - 1.0))))
	coins += extra_reward
	session_revenue = revenue_before + (session_revenue - revenue_before) + extra_reward
	if order_had_mistake:
		perfect_orders = 0
		adaptive_pressure = maxf(0.0,adaptive_pressure - 0.05)
	else:
		perfect_orders += 1
		adaptive_pressure = minf(0.25,float(perfect_orders) * 0.045)
	best_revenue = maxi(best_revenue,session_revenue)
	_save_game()
	_update_hud()

func _fail_order(message: String) -> void:
	order_had_mistake = true
	perfect_orders = 0
	adaptive_pressure = maxf(0.0,adaptive_pressure - 0.08)
	super._fail_order(message)

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
	var earned_stars: int = 0
	var stage_bonus: int = 0
	if success:
		earned_stars = 1
		if customer_hearts >= mini(2,stage_start_hearts) and accuracy >= 0.80:
			earned_stars = 2
		if customer_hearts == stage_start_hearts and accuracy >= 0.93 and max_combo_stage >= int(active_stage.get("combo_target",3)) and wrong_cuts_stage == 0:
			earned_stars = 3
		stage_stars[str(selected_stage)] = maxi(int(stage_stars.get(str(selected_stage),0)),earned_stars)
		unlocked_stage = maxi(unlocked_stage,mini(MAX_STAGE,selected_stage + 1))
		stage_bonus = int(round(float(80 + selected_stage * 14 + earned_stars * 45) * float(active_difficulty.get("reward",1.0))))
		coins += stage_bonus
		var star_text: String = "★ ".repeat(earned_stars) + "☆ ".repeat(3 - earned_stars)
		summary_label.text = "مرحله %d کامل شد!\n%s\n\nسفارش‌ها: %d از %d\nدقت: %d٪   |   بیشترین کمبو: %d\nفروش: %d   |   جایزه مرحله: %d سکه" % [selected_stage,star_text.strip_edges(),served_orders,int(active_stage.get("target_orders",3)),int(round(accuracy * 100.0)),max_combo_stage,session_revenue,stage_bonus]
	else:
		summary_label.text = "مرحله %d ناموفق بود\n\nسفارش‌ها: %d از %d\nدقت: %d٪   |   اشتباه‌ها: %d\nفروش این تلاش: %d\n\nارتقا بده یا سختی پایین‌تر را امتحان کن." % [selected_stage,served_orders,int(active_stage.get("target_orders",3)),int(round(accuracy * 100.0)),wrong_cuts_stage + missed_needed_stage,session_revenue]
	_save_game()
	game_over_overlay.visible = true
	_update_hud()

func _get_stage_accuracy() -> float:
	var total_actions: int = correct_cuts_stage + wrong_cuts_stage + missed_needed_stage
	if total_actions <= 0:
		return 1.0
	return float(correct_cuts_stage) / float(total_actions)

func _update_hud() -> void:
	super._update_hud()
	if hearts_label != null:
		hearts_label.text = ("♥ ".repeat(maxi(customer_hearts,0)) + "♡ ".repeat(maxi(stage_start_hearts - customer_hearts,0))).strip_edges()
	if hud_revenue_label != null and not active_stage.is_empty():
		hud_revenue_label.text = "مرحله %d  •  %d/%d  •  فروش %d" % [selected_stage,served_orders,int(active_stage.get("target_orders",3)),session_revenue]
	if combo_label != null and game_active:
		combo_label.text = "کمبو %d  •  دقت %d٪  •  %s" % [max_combo_stage,int(round(_get_stage_accuracy() * 100.0)),String(active_difficulty.get("name",""))]

func _update_menu() -> void:
	super._update_menu()
	if stage_panel == null:
		return
	var stage_data: Dictionary = _get_stage(selected_stage)
	stage_chapter_label.text = "فصل %d • %s" % [int(stage_data.get("chapter",1)),String(stage_data.get("chapter_name",""))]
	stage_title_label.text = "مرحله %d" % selected_stage
	stage_rule_label.text = String(stage_data.get("rule_name",""))
	var extra_goal: String = ""
	var rule_name: String = String(stage_data.get("rule",""))
	if rule_name == "accuracy":
		extra_goal = " • یک اشتباه = رد سفارش"
	elif rule_name == "hazards":
		extra_goal = " • مواد سوخته را لمس نکن"
	elif rule_name == "combo":
		extra_goal = " • هدف کمبو %d" % int(stage_data.get("combo_target",3))
	elif rule_name == "rush":
		extra_goal = " • موج‌های چندتایی و زمان کمتر"
	elif rule_name == "boss":
		extra_goal = " • سفارش‌های بزرگ و خطر بیشتر"
	stage_goal_label.text = "تحویل %d سفارش%s" % [int(stage_data.get("target_orders",3)),extra_goal]
	var stars: int = int(stage_stars.get(str(selected_stage),0))
	stage_stars_label.text = ("★ ".repeat(stars) + "☆ ".repeat(3 - stars)).strip_edges()
	var locked: bool = selected_stage > unlocked_stage
	if locked:
		stage_lock_label.text = "قفل است؛ ابتدا مرحله %d را کامل کن" % (selected_stage - 1)
	else:
		stage_lock_label.text = "زمان پایه هر سفارش: %.1f ثانیه" % float(stage_data.get("base_time",18.0))
	stage_start_button.disabled = locked
	stage_start_button.text = "مرحله قفل است" if locked else "شروع مرحله"
	for index in range(difficulty_buttons.size()):
		var difficulty_button: Button = difficulty_buttons[index]
		var is_selected: bool = index == selected_difficulty
		difficulty_button.modulate = Color.WHITE if is_selected else Color(0.72,0.76,0.84,0.8)
		difficulty_button.text = "✓ %s" % String(difficulty_catalog[index].get("name","")) if is_selected else String(difficulty_catalog[index].get("name",""))
	if menu_coins_label != null:
		menu_coins_label.text = "سکه‌های من: %d  •  مراحل باز: %d/%d" % [coins,unlocked_stage,MAX_STAGE]

func _load_save() -> void:
	super._load_save()
	if not FileAccess.file_exists("user://dakechi_save.json"):
		return
	var file: FileAccess = FileAccess.open("user://dakechi_save.json",FileAccess.READ)
	if file == null:
		return
	var parsed_data: Variant = JSON.parse_string(file.get_as_text())
	if not parsed_data is Dictionary:
		return
	var data: Dictionary = parsed_data as Dictionary
	unlocked_stage = clampi(int(data.get("unlocked_stage",1)),1,MAX_STAGE)
	selected_stage = clampi(int(data.get("selected_stage",unlocked_stage)),1,MAX_STAGE)
	selected_difficulty = clampi(int(data.get("selected_difficulty",0)),0,difficulty_catalog.size() - 1)
	var saved_stars: Variant = data.get("stage_stars",{})
	if saved_stars is Dictionary:
		stage_stars = (saved_stars as Dictionary).duplicate(true)

func _save_game() -> void:
	var data: Dictionary = {
		"coins":coins,
		"best_revenue":best_revenue,
		"knife_level":knife_level,
		"counter_level":counter_level,
		"sign_level":sign_level,
		"unlocked_stage":unlocked_stage,
		"selected_stage":selected_stage,
		"selected_difficulty":selected_difficulty,
		"stage_stars":stage_stars
	}
	var file: FileAccess = FileAccess.open("user://dakechi_save.json",FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data))
