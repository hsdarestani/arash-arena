extends CharacterBody3D
class_name ArenaPlayer

signal died
signal hp_changed(current_hp: int, max_hp: int)

var max_hp: int = 100
var hp: int = 100
var speed: float = 6.2
var move_input: Vector2 = Vector2.ZERO
var attack_cooldown: float = 0.0
var invulnerability: float = 0.0
var can_control: bool = true

var visual_root: Node3D
var fallback_visual: Node3D
var model_visual: Node3D
var attack_area: Area3D
var sword_pivot: Node3D

func _ready() -> void:
	collision_layer = 1
	collision_mask = 2 | 4
	_build_collision()
	_build_visuals()
	_build_attack_area()
	hp_changed.emit(hp, max_hp)

func _build_collision() -> void:
	var shape := CapsuleShape3D.new()
	shape.radius = 0.42
	shape.height = 1.55
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position.y = 0.78
	add_child(collision)

func _build_visuals() -> void:
	visual_root = Node3D.new()
	visual_root.name = "VisualRoot"
	add_child(visual_root)
	fallback_visual = VisualFactory.create_player_fallback()
	visual_root.add_child(fallback_visual)
	sword_pivot = fallback_visual.get_node_or_null("SwordPivot")

func _build_attack_area() -> void:
	attack_area = Area3D.new()
	attack_area.name = "AttackArea"
	attack_area.collision_layer = 0
	attack_area.collision_mask = 2
	attack_area.monitoring = true
	attack_area.position = Vector3(0, 0.8, 0)
	var shape := SphereShape3D.new()
	shape.radius = 1.45
	var collision := CollisionShape3D.new()
	collision.shape = shape
	attack_area.add_child(collision)
	add_child(attack_area)

func _physics_process(delta: float) -> void:
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	invulnerability = maxf(0.0, invulnerability - delta)

	var keyboard := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var input_vector := move_input if move_input.length() > keyboard.length() else keyboard
	if not can_control:
		input_vector = Vector2.ZERO

	var direction := Vector3(input_vector.x, 0.0, input_vector.y)
	if direction.length() > 1.0:
		direction = direction.normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	velocity.y = 0.0

	if direction.length() > 0.08:
		var desired_yaw := atan2(-direction.x, -direction.z)
		visual_root.rotation.y = lerp_angle(visual_root.rotation.y, desired_yaw, minf(1.0, delta * 13.0))
		visual_root.position.y = sin(Time.get_ticks_msec() * 0.012) * 0.035
	else:
		visual_root.position.y = lerpf(visual_root.position.y, 0.0, delta * 10.0)

	move_and_slide()
	global_position.x = clampf(global_position.x, -13.8, 13.8)
	global_position.z = clampf(global_position.z, -13.8, 13.8)

	if Input.is_action_just_pressed("attack"):
		request_attack()

func request_attack() -> void:
	if not can_control or attack_cooldown > 0.0:
		return
	attack_cooldown = 0.52
	_perform_attack()
	_animate_attack()

func _perform_attack() -> void:
	for body in attack_area.get_overlapping_bodies():
		if body != self and body.has_method("take_damage"):
			body.take_damage(35, global_position)

func _animate_attack() -> void:
	var root_to_animate := sword_pivot if sword_pivot != null else visual_root
	var start_rotation := root_to_animate.rotation
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(root_to_animate, "rotation:z", start_rotation.z - 1.65, 0.11)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(root_to_animate, "rotation:z", start_rotation.z, 0.20)

	var pulse := create_tween()
	pulse.tween_property(visual_root, "scale", Vector3(1.08, 0.94, 1.08), 0.08)
	pulse.tween_property(visual_root, "scale", Vector3.ONE, 0.16)

func take_damage(amount: int) -> void:
	if invulnerability > 0.0 or hp <= 0:
		return
	invulnerability = 0.42
	hp = maxi(0, hp - amount)
	hp_changed.emit(hp, max_hp)

	var flash := create_tween()
	flash.tween_property(visual_root, "scale", Vector3(0.88, 1.12, 0.88), 0.07)
	flash.tween_property(visual_root, "scale", Vector3.ONE, 0.12)

	if hp <= 0:
		can_control = false
		died.emit()

func set_external_visual(scene: Node3D) -> void:
	if scene == null:
		return
	if model_visual != null and is_instance_valid(model_visual):
		model_visual.queue_free()
	model_visual = scene
	model_visual.name = "KayKitKnight"
	model_visual.rotation_degrees.y = 180.0
	model_visual.scale = Vector3.ONE * 1.02
	visual_root.add_child(model_visual)
	fallback_visual.visible = false
	_play_first_animation(model_visual, ["idle", "walk"])

func _play_first_animation(root: Node, preferred: Array) -> void:
	var players := root.find_children("*", "AnimationPlayer", true, false)
	for found in players:
		var player := found as AnimationPlayer
		if player == null:
			continue
		var names := player.get_animation_list()
		for key in preferred:
			for animation_name in names:
				if String(animation_name).to_lower().contains(String(key)):
					player.play(animation_name)
					return
		if names.size() > 0:
			player.play(names[0])
			return
