extends RigidBody3D
class_name SliceItem

signal sliced(item: SliceItem, score_value: int, hit_position: Vector3, juice_color: Color, swipe_direction: Vector3)
signal bomb_triggered(item: SliceItem, hit_position: Vector3)
signal missed(item: SliceItem)

var item_name := "fruit"
var score_value := 10
var is_bomb := false
var skin_color := Color("#cf2434")
var flesh_color := Color("#ffd6b8")
var juice_color := Color("#ff3a52")
var shape_scale := Vector3.ONE
var model_id := ""
var model_scale := 8.0
var active := true
var age := 0.0
var visual_root: Node3D

func configure(data: Dictionary) -> void:
	item_name = String(data.get("name", "fruit"))
	score_value = int(data.get("points", 10))
	is_bomb = bool(data.get("bomb", false))
	skin_color = data.get("skin", skin_color)
	flesh_color = data.get("flesh", flesh_color)
	juice_color = data.get("juice", skin_color)
	shape_scale = data.get("shape", Vector3.ONE)
	model_id = String(data.get("model", ""))
	model_scale = float(data.get("model_scale", 8.0))

func _ready() -> void:
	collision_layer = 1
	collision_mask = 2
	mass = 0.72 if not is_bomb else 1.35
	gravity_scale = 1.25
	can_sleep = false
	continuous_cd = true
	_build_collision()
	_build_visual()

func _physics_process(delta: float) -> void:
	age += delta
	if active and age > 0.8 and global_position.y < -5.2:
		active = false
		if not is_bomb:
			missed.emit(self)
		queue_free()

func slash(swipe_direction: Vector3, hit_position: Vector3) -> void:
	if not active:
		return
	active = false
	collision_layer = 0
	if is_bomb:
		bomb_triggered.emit(self, hit_position)
		queue_free()
		return
	_spawn_halves(swipe_direction)
	sliced.emit(self, score_value, hit_position, juice_color, swipe_direction)
	queue_free()

func _build_collision() -> void:
	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.58 * max(shape_scale.x, max(shape_scale.y, shape_scale.z))
	collision.shape = sphere
	add_child(collision)

func _build_visual() -> void:
	visual_root = Node3D.new()
	visual_root.name = "Visual"
	add_child(visual_root)
	if is_bomb:
		_build_bomb()
		return
	if not model_id.is_empty() and _try_add_polyhaven_model():
		return
	_build_fallback_fruit()

func _try_add_polyhaven_model() -> bool:
	var candidates := [
		"res://assets/polyhaven/%s/%s.gltf" % [model_id, model_id],
		"res://assets/polyhaven/%s/%s.glb" % [model_id, model_id]
	]
	for path in candidates:
		if not ResourceLoader.exists(path):
			continue
		var packed := load(path) as PackedScene
		if packed == null:
			continue
		var instance := packed.instantiate()
		instance.scale = Vector3.ONE * model_scale
		instance.rotation_degrees = Vector3(0, randf_range(0.0, 360.0), 0)
		visual_root.add_child(instance)
		return true
	return false

func _build_fallback_fruit() -> void:
	var fruit := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.62
	sphere.height = 1.24
	sphere.radial_segments = 48
	sphere.rings = 24
	fruit.mesh = sphere
	fruit.scale = shape_scale
	fruit.material_override = _fruit_material(skin_color, 0.38)
	visual_root.add_child(fruit)

	var stem := MeshInstance3D.new()
	var stem_mesh := CylinderMesh.new()
	stem_mesh.top_radius = 0.055
	stem_mesh.bottom_radius = 0.07
	stem_mesh.height = 0.34
	stem_mesh.radial_segments = 12
	stem.mesh = stem_mesh
	stem.position = Vector3(0, 0.72 * shape_scale.y, 0)
	stem.rotation_degrees.z = randf_range(-12.0, 12.0)
	stem.material_override = _fruit_material(Color("#49321c"), 0.82)
	visual_root.add_child(stem)

func _build_bomb() -> void:
	var core := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.64
	sphere.height = 1.28
	sphere.radial_segments = 40
	sphere.rings = 20
	core.mesh = sphere
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color("#11151b")
	metal.metallic = 0.92
	metal.roughness = 0.22
	core.material_override = metal
	visual_root.add_child(core)

	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.66
	torus.outer_radius = 0.72
	torus.rings = 40
	torus.ring_segments = 10
	ring.mesh = torus
	ring.rotation_degrees.x = 90
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color("#ff382e")
	glow.emission_enabled = true
	glow.emission = Color("#ff1f18")
	glow.emission_energy_multiplier = 5.0
	glow.roughness = 0.22
	ring.material_override = glow
	visual_root.add_child(ring)

	var fuse := MeshInstance3D.new()
	var fuse_mesh := CylinderMesh.new()
	fuse_mesh.top_radius = 0.045
	fuse_mesh.bottom_radius = 0.06
	fuse_mesh.height = 0.55
	fuse.mesh = fuse_mesh
	fuse.position = Vector3(0.18, 0.76, 0)
	fuse.rotation_degrees.z = -28
	fuse.material_override = _fruit_material(Color("#7c5b34"), 0.9)
	visual_root.add_child(fuse)

	var spark := OmniLight3D.new()
	spark.position = Vector3(0.3, 1.0, 0)
	spark.light_color = Color("#ff4b21")
	spark.light_energy = 2.8
	spark.omni_range = 2.6
	visual_root.add_child(spark)

func _spawn_halves(swipe_direction: Vector3) -> void:
	var parent_node := get_parent()
	if parent_node == null:
		return
	var split_axis := Vector3(swipe_direction.x, swipe_direction.y, 0.0).normalized()
	if split_axis.length_squared() < 0.1:
		split_axis = Vector3.RIGHT
	for side in [-1.0, 1.0]:
		var body := RigidBody3D.new()
		body.mass = 0.32
		body.gravity_scale = 1.35
		body.collision_layer = 0
		body.collision_mask = 2
		parent_node.add_child(body)
		body.global_transform = global_transform

		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = _create_half_mesh(side)
		mesh_instance.scale = shape_scale
		body.add_child(mesh_instance)

		var collision := CollisionShape3D.new()
		var sphere := SphereShape3D.new()
		sphere.radius = 0.38 * max(shape_scale.x, max(shape_scale.y, shape_scale.z))
		collision.shape = sphere
		collision.position.x = 0.24 * side
		body.add_child(collision)

		body.linear_velocity = linear_velocity + split_axis * side * 2.7 + Vector3.UP * 0.85
		body.angular_velocity = angular_velocity + Vector3(randf_range(-5, 5), randf_range(-5, 5), randf_range(-5, 5))
		var timer := get_tree().create_timer(4.5)
		timer.timeout.connect(body.queue_free)

func _create_half_mesh(side: float) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var outside := SurfaceTool.new()
	outside.begin(Mesh.PRIMITIVE_TRIANGLES)
	outside.set_material(_fruit_material(skin_color, 0.42))
	var rings := 16
	var segments := 18
	for y_index in range(rings):
		var v0 := float(y_index) / float(rings)
		var v1 := float(y_index + 1) / float(rings)
		var theta0 := v0 * PI
		var theta1 := v1 * PI
		for segment in range(segments):
			var u0 := -PI * 0.5 + PI * float(segment) / float(segments)
			var u1 := -PI * 0.5 + PI * float(segment + 1) / float(segments)
			var p00 := _half_point(theta0, u0, side)
			var p01 := _half_point(theta0, u1, side)
			var p10 := _half_point(theta1, u0, side)
			var p11 := _half_point(theta1, u1, side)
			_add_triangle(outside, p00, p10, p11, side)
			_add_triangle(outside, p00, p11, p01, side)
	outside.commit(mesh)

	var cut := SurfaceTool.new()
	cut.begin(Mesh.PRIMITIVE_TRIANGLES)
	cut.set_material(_fruit_material(flesh_color, 0.58))
	var center := Vector3.ZERO
	for i in range(32):
		var a0 := TAU * float(i) / 32.0
		var a1 := TAU * float(i + 1) / 32.0
		var p0 := Vector3(0, cos(a0) * 0.62, sin(a0) * 0.62)
		var p1 := Vector3(0, cos(a1) * 0.62, sin(a1) * 0.62)
		var normal := Vector3(-side, 0, 0)
		cut.set_normal(normal)
		cut.set_uv(Vector2(0.5, 0.5))
		cut.add_vertex(center)
		cut.set_normal(normal)
		cut.set_uv(Vector2(0.5 + p1.z * 0.7, 0.5 + p1.y * 0.7))
		cut.add_vertex(p1)
		cut.set_normal(normal)
		cut.set_uv(Vector2(0.5 + p0.z * 0.7, 0.5 + p0.y * 0.7))
		cut.add_vertex(p0)
	cut.commit(mesh)
	return mesh

func _half_point(theta: float, azimuth: float, side: float) -> Vector3:
	var sin_theta := sin(theta)
	return Vector3(side * sin_theta * cos(azimuth) * 0.62, cos(theta) * 0.62, sin_theta * sin(azimuth) * 0.62)

func _add_triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, side: float) -> void:
	var normal := (b - a).cross(c - a).normalized()
	if normal.x * side < 0.0:
		var swap := b
		b = c
		c = swap
		normal = (b - a).cross(c - a).normalized()
	for point in [a, b, c]:
		surface.set_normal(normal)
		surface.set_uv(Vector2(atan2(point.z, point.x) / TAU + 0.5, point.y + 0.5))
		surface.add_vertex(point)

func _fruit_material(color: Color, roughness_value: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness_value
	material.metallic = 0.0
	material.subsurf_scatter_enabled = true
	material.subsurf_scatter_strength = 0.18
	return material
