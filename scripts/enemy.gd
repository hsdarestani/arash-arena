extends CharacterBody3D
class_name ArenaEnemy

signal killed(points: int)

var target: ArenaPlayer
var hp: int = 55
var speed: float = 2.9
var damage: int = 10
var points: int = 10
var attack_cooldown: float = 0.0
var stagger: float = 0.0
var dead: bool = false

var visual_root: Node3D
var fallback_visual: Node3D
var model_visual: Node3D

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1 | 2 | 4
	_build_collision()
	_build_visuals()

func _build_collision() -> void:
	var shape := CapsuleShape3D.new()
	shape.radius = 0.38
	shape.height = 1.45
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position.y = 0.72
	add_child(collision)

func _build_visuals() -> void:
	visual_root = Node3D.new()
	visual_root.name = "VisualRoot"
	add_child(visual_root)
	fallback_visual = VisualFactory.create_enemy_fallback()
	visual_root.add_child(fallback_visual)

func _physics_process(delta: float) -> void:
	if dead or target == null or not is_instance_valid(target):
		velocity = Vector3.ZERO
		return
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	stagger = maxf(0.0, stagger - delta)

	var offset := target.global_position - global_position
	offset.y = 0.0
	var distance := offset.length()
	var direction := offset.normalized() if distance > 0.01 else Vector3.ZERO

	if stagger > 0.0:
		velocity = velocity.move_toward(Vector3.ZERO, delta * 14.0)
	elif distance > 1.15:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		velocity.y = 0.0
		var desired_yaw := atan2(-direction.x, -direction.z)
		visual_root.rotation.y = lerp_angle(visual_root.rotation.y, desired_yaw, minf(1.0, delta * 10.0))
	else:
		velocity = Vector3.ZERO
		if attack_cooldown <= 0.0:
			attack_cooldown = 0.9
			target.take_damage(damage)
			var lunge := create_tween()
			lunge.tween_property(visual_root, "scale", Vector3(1.12, 0.92, 1.12), 0.08)
			lunge.tween_property(visual_root, "scale", Vector3.ONE, 0.16)

	move_and_slide()

func take_damage(amount: int, source_position: Vector3 = Vector3.ZERO) -> void:
	if dead:
		return
	hp -= amount
	stagger = 0.16
	var knockback := global_position - source_position
	knockback.y = 0.0
	if knockback.length() > 0.01:
		velocity = knockback.normalized() * 5.0

	var hit_tween := create_tween()
	hit_tween.tween_property(visual_root, "scale", Vector3(0.72, 1.24, 0.72), 0.06)
	hit_tween.tween_property(visual_root, "scale", Vector3.ONE, 0.11)

	if hp <= 0:
		_die()

func _die() -> void:
	dead = true
	collision_layer = 0
	collision_mask = 0
	killed.emit(points)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(visual_root, "scale", Vector3(0.05, 0.05, 0.05), 0.34)
	tween.tween_property(visual_root, "rotation:z", 1.2, 0.34)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)

func set_external_visual(scene: Node3D) -> void:
	if scene == null:
		return
	if model_visual != null and is_instance_valid(model_visual):
		model_visual.queue_free()
	model_visual = scene
	model_visual.name = "KayKitSkeleton"
	model_visual.rotation_degrees.y = 180.0
	model_visual.scale = Vector3.ONE * 1.02
	visual_root.add_child(model_visual)
	fallback_visual.visible = false
	_play_first_animation(model_visual)

func _play_first_animation(root: Node) -> void:
	var players := root.find_children("*", "AnimationPlayer", true, false)
	for found in players:
		var player := found as AnimationPlayer
		if player == null:
			continue
		var names := player.get_animation_list()
		for animation_name in names:
			var lower := String(animation_name).to_lower()
			if lower.contains("walk") or lower.contains("run") or lower.contains("idle"):
				player.play(animation_name)
				return
		if names.size() > 0:
			player.play(names[0])
			return
