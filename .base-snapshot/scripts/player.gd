extends MovementController
class_name CogitoPlayer

var held_item := ""
var current_prompt := ""
var message := ""
var message_timer := 0.0
var player_attributes: Dictionary = {}
var held_root: Node3D
var held_base_pos := Vector3(0.34,-0.30,-0.62)

func _ready() -> void:
	name = "Player"
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_setup_held_root()

func _process(delta: float) -> void:
	if message_timer > 0.0:
		message_timer -= delta
		if message_timer <= 0.0:
			message = ""
	if held_root:
		var moving = Vector2(velocity.x, velocity.z).length()
		var t = Time.get_ticks_msec() * 0.001
		var bob = min(moving / max(0.1, speed), 1.0)
		held_root.position = held_base_pos + Vector3(sin(t*7.0)*0.012, abs(sin(t*7.0))*0.012,0) * bob
		held_root.rotation.z = sin(t*5.0) * 0.025 * bob

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("drop_item") and held_item != "":
		set_held_item("")
		show_message("Dropped what you were holding.")

func _setup_held_root():
	var cam = get_viewport().get_camera_3d()
	if cam == null:
		return
	held_root = Node3D.new()
	held_root.name = "HeldItemVisual"
	held_root.position = held_base_pos
	cam.add_child(held_root)

func _clear_held_visual():
	if held_root == null:
		_setup_held_root()
	if held_root:
		for c in held_root.get_children():
			c.queue_free()

func _mesh_box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, rough := 0.6, metallic := 0.0):
	var n = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = size
	n.mesh = bm
	n.position = pos
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = rough
	mat.metallic = metallic
	n.material_override = mat
	parent.add_child(n)
	return n

func _mesh_sphere(parent: Node3D, pos: Vector3, scale_: Vector3, color: Color, rough := 0.45):
	var n = MeshInstance3D.new()
	var sm = SphereMesh.new()
	sm.radius = 0.11
	sm.height = 0.22
	sm.radial_segments = 18
	sm.rings = 10
	n.mesh = sm
	n.position = pos
	n.scale = scale_
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = rough
	n.material_override = mat
	parent.add_child(n)
	return n

func _refresh_held_visual():
	_clear_held_visual()
	if held_root == null or held_item == "":
		return
	if held_item == "food":
		var handle = _mesh_box(held_root, Vector3(0,-0.02,0), Vector3(0.055,0.055,0.42), Color(0.22,0.23,0.22),0.3,0.6)
		handle.rotation.x = deg_to_rad(-10)
		_mesh_sphere(held_root, Vector3(0,0.035,-0.25), Vector3(1.75,0.55,1.35), Color(0.76,0.24,0.28),0.28)
		_mesh_sphere(held_root, Vector3(0.07,0.07,-0.25), Vector3(0.55,0.40,0.55), Color(0.94,0.54,0.52),0.22)
	elif held_item == "cleaner":
		_mesh_box(held_root, Vector3(0,0.0,0), Vector3(0.12,0.16,0.46), Color(0.035,0.27,0.30),0.35,0.35)
		_mesh_box(held_root, Vector3(0,0.01,-0.27), Vector3(0.30,0.10,0.13), Color(0.08,0.56,0.59),0.4,0.1)
		for x in [-0.10,-0.05,0.0,0.05,0.10]:
			_mesh_box(held_root, Vector3(x,-0.06,-0.31), Vector3(0.018,0.09,0.045), Color(0.62,0.93,0.84),0.65)
		var lamp = _mesh_box(held_root, Vector3(0.0,0.10,-0.17), Vector3(0.05,0.035,0.05), Color(0.35,1.0,0.78),0.2)
		var m = lamp.material_override as StandardMaterial3D
		m.emission_enabled = true
		m.emission = Color(0.15,0.8,0.45)
		m.emission_energy_multiplier = 2.0
	elif held_item == "medicine":
		_mesh_box(held_root, Vector3(0,0,-0.08), Vector3(0.055,0.055,0.38), Color(0.72,0.78,0.80),0.28,0.55)
		_mesh_box(held_root, Vector3(0,0,-0.31), Vector3(0.11,0.13,0.16), Color(0.78,0.16,0.16),0.32,0.15)
		_mesh_box(held_root, Vector3(0,0,-0.43), Vector3(0.018,0.018,0.18), Color(0.75,0.78,0.78),0.22,0.8)
	elif held_item == "sample_vial":
		_mesh_box(held_root, Vector3(0,0,-0.18), Vector3(0.09,0.18,0.09), Color(0.36,0.75,0.82),0.18,0.05)
		_mesh_box(held_root, Vector3(0,0.11,-0.18), Vector3(0.10,0.05,0.10), Color(0.10,0.18,0.22),0.4,0.5)
	elif held_item == "filter":
		_mesh_box(held_root, Vector3(0,-0.02,-0.15), Vector3(0.34,0.25,0.14), Color(0.18,0.30,0.22),0.55,0.15)
		for x in [-0.12,-0.06,0.0,0.06,0.12]: _mesh_box(held_root, Vector3(x,-0.02,-0.225), Vector3(0.025,0.20,0.02), Color(0.52,0.70,0.54),0.65)
	elif held_item == "toy":
		var ring = MeshInstance3D.new()
		var tor = TorusMesh.new()
		tor.inner_radius = 0.09; tor.outer_radius = 0.18
		ring.mesh = tor; ring.position = Vector3(0,0,-0.18); ring.rotation_degrees.x = 90
		var rm = StandardMaterial3D.new(); rm.albedo_color = Color(0.22,0.45,0.88); rm.roughness = 0.34
		ring.material_override = rm; held_root.add_child(ring)
	elif held_item == "scanner":
		_mesh_box(held_root, Vector3(0,0,-0.10), Vector3(0.13,0.20,0.36), Color(0.07,0.18,0.19),0.32,0.25)
		var sc = _mesh_box(held_root, Vector3(0,0.02,-0.30), Vector3(0.09,0.08,0.04), Color(0.26,0.95,0.78),0.18)
		var sm = sc.material_override as StandardMaterial3D; sm.emission_enabled = true; sm.emission = Color(0.08,0.72,0.46); sm.emission_energy_multiplier = 1.7

func set_held_item(item_name: String) -> void:
	held_item = item_name
	_refresh_held_visual()
	if item_name != "":
		var root = get_parent()
		if root and root.has_method("play_sfx"):
			root.play_sfx("pickup")

func show_message(text: String, duration := 2.5) -> void:
	message = text
	message_timer = duration
