extends RefCounted
class_name VisualFactory

static func material(color: Color, roughness: float = 0.85, metallic: float = 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	return mat

static func mesh_instance(mesh: Mesh, color: Color, position: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = position
	node.material_override = material(color)
	return node

static func create_player_fallback() -> Node3D:
	var root := Node3D.new()
	root.name = "FallbackKnight"

	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.42
	body_mesh.height = 1.15
	var body := mesh_instance(body_mesh, Color("#39455f"), Vector3(0, 0.9, 0))
	root.add_child(body)

	var armor_mesh := CylinderMesh.new()
	armor_mesh.top_radius = 0.48
	armor_mesh.bottom_radius = 0.58
	armor_mesh.height = 0.65
	var armor := mesh_instance(armor_mesh, Color("#a8742a"), Vector3(0, 1.05, 0))
	root.add_child(armor)

	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.32
	head_mesh.height = 0.64
	var head := mesh_instance(head_mesh, Color("#d9b28c"), Vector3(0, 1.72, 0))
	root.add_child(head)

	var helmet_mesh := CylinderMesh.new()
	helmet_mesh.top_radius = 0.30
	helmet_mesh.bottom_radius = 0.36
	helmet_mesh.height = 0.33
	var helmet := mesh_instance(helmet_mesh, Color("#59627b"), Vector3(0, 1.91, 0))
	root.add_child(helmet)

	var sword_root := Node3D.new()
	sword_root.name = "SwordPivot"
	sword_root.position = Vector3(0.52, 1.05, 0)
	root.add_child(sword_root)

	var blade_mesh := BoxMesh.new()
	blade_mesh.size = Vector3(0.10, 0.90, 0.10)
	var blade := mesh_instance(blade_mesh, Color("#dce5ed"), Vector3(0, -0.35, 0))
	blade.material_override = material(Color("#dce5ed"), 0.25, 0.65)
	sword_root.add_child(blade)

	var guard_mesh := BoxMesh.new()
	guard_mesh.size = Vector3(0.42, 0.09, 0.12)
	var guard := mesh_instance(guard_mesh, Color("#c79231"), Vector3(0, 0.10, 0))
	sword_root.add_child(guard)
	sword_root.rotation_degrees.z = -25.0

	return root

static func create_enemy_fallback() -> Node3D:
	var root := Node3D.new()
	root.name = "FallbackSkeleton"

	var bone := Color("#d7d1b7")
	var dark := Color("#3a293d")

	var pelvis_mesh := BoxMesh.new()
	pelvis_mesh.size = Vector3(0.55, 0.32, 0.34)
	root.add_child(mesh_instance(pelvis_mesh, dark, Vector3(0, 0.74, 0)))

	var torso_mesh := BoxMesh.new()
	torso_mesh.size = Vector3(0.62, 0.72, 0.30)
	root.add_child(mesh_instance(torso_mesh, bone, Vector3(0, 1.18, 0)))

	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.31
	head_mesh.height = 0.62
	root.add_child(mesh_instance(head_mesh, bone, Vector3(0, 1.77, 0)))

	for side in [-1.0, 1.0]:
		var arm_mesh := CylinderMesh.new()
		arm_mesh.top_radius = 0.07
		arm_mesh.bottom_radius = 0.07
		arm_mesh.height = 0.75
		var arm := mesh_instance(arm_mesh, bone, Vector3(0.40 * side, 1.14, 0))
		arm.rotation_degrees.z = 18.0 * side
		root.add_child(arm)

		var leg_mesh := CylinderMesh.new()
		leg_mesh.top_radius = 0.08
		leg_mesh.bottom_radius = 0.08
		leg_mesh.height = 0.74
		var leg := mesh_instance(leg_mesh, bone, Vector3(0.18 * side, 0.36, 0))
		root.add_child(leg)

	return root
