extends Node3D

var player
var pet
var bowl
var game
var power_multiplier := 1.0
var upgrade_visual_root: Node3D
var annex_door
var annex_unlocked := false
var hud_hunger: Label
var hud_grime: Label
var hud_happy: Label
var hud_held: Label
var hud_prompt: Label
var hud_message: Label
var hud_reaction: Label
var hud_shift: Label
var hud_status: Label
var hud_objective: Label
var bar_hunger: ProgressBar
var bar_grime: ProgressBar
var bar_happy: ProgressBar
var shift_time := 0.0
var stable_time := 0.0
var shift_done := false
const SHIFT_LENGTH := 180.0

var fluor_panels := []
var fluor_lights := []
var monitor_screens := []
var jar_meshes := []
var slime_patches := []
var drip_drops := []
var steam_puffs := []
var hanging_cables := []
var fan_rotor: Node3D
var silhouette_root: Node3D
var beacon_light: OmniLight3D
var world_environment: WorldEnvironment
var hud_controls: Label
var hud_guidance: Label
var pbr_cache := {}

# Controller-friendly objective guidance. A bright world-space beacon points at the
# current training/incident target instead of making new players hunt through labels.
var objective_beacon: Node3D
var objective_ring: MeshInstance3D
var objective_arrow: MeshInstance3D
var objective_light: OmniLight3D
var objective_label: Label3D
var objective_target: Node3D
var objective_key := ""

func _ready():
	seed(1337)
	_build_environment()
	_build_room()
	_build_annex()
	_build_sim_objects()
	_build_player()
	_build_hud()
	_build_objective_beacon()
	_start_ambient_audio()
	game = load("res://scripts/game_systems.gd").new()
	game.name = "GameSystems"
	add_child(game)
	game.setup(self, player, pet)

func _process(delta):
	if not is_instance_valid(player) or not is_instance_valid(pet):
		return
	hud_hunger.text = "%3d%%" % int(pet.hunger)
	hud_grime.text = "%3d%%" % int(pet.grime)
	hud_happy.text = "%3d%%" % int(pet.happiness)
	bar_hunger.value = pet.hunger
	bar_grime.value = pet.grime
	bar_happy.value = pet.happiness
	var item_name = "EMPTY HANDS"
	var held_names = {
		"food":"MEAT MUSH SCOOP", "cleaner":"BIO-SCRUBBER", "medicine":"MEDICINE INJECTOR",
		"sample_vial":"STERILE SAMPLE VIAL", "filter":"BIOFILTER CARTRIDGE", "toy":"ENRICHMENT RING",
		"scanner":"HAND SCANNER"
	}
	if held_names.has(player.held_item): item_name = held_names[player.held_item]
	hud_held.text = "HOLDING  " + item_name
	var use_hint = "[E]"
	var drop_hint = "[Q]"
	if game != null and game.release != null:
		use_hint = game.release.interact_hint()
		drop_hint = game.release.drop_hint()
	var shown_prompt: String = player.current_prompt
	if game != null and game.shift == 1 and not game.tutorial_complete:
		var pic = player.get_node_or_null("PlayerInteractionComponent")
		if pic != null and pic.interactable != null and not game.is_training_interactable_allowed(pic.interactable):
			shown_prompt = game.training_block_message()
	hud_prompt.text = (use_hint + "  " + shown_prompt) if shown_prompt != "" else ""
	if hud_controls: hud_controls.text = "%s USE     %s DROP" % [use_hint,drop_hint]
	_update_guidance_hud(use_hint)
	hud_message.text = player.message
	hud_reaction.text = pet.reaction
	_animate_environment(delta)
	_animate_objective_beacon(delta)


func _update_guidance_hud(use_hint: String) -> void:
	if hud_guidance == null:
		return
	if objective_beacon == null or not objective_beacon.visible or objective_target == null or not is_instance_valid(objective_target) or not is_instance_valid(player):
		hud_guidance.text = ""
		return
	var camera := get_viewport().get_camera_3d()
	var dist: float = (player as Node3D).global_position.distance_to(objective_target.global_position)
	var direction = ""
	if camera != null:
		var flat_to: Vector3 = objective_target.global_position - camera.global_position
		flat_to.y = 0
		if flat_to.length() > 0.01:
			var flat_forward: Vector3 = -camera.global_transform.basis.z
			flat_forward.y = 0
			if flat_forward.length() > 0.01 and flat_forward.normalized().dot(flat_to.normalized()) < -0.15:
				direction = "  •  TARGET BEHIND"
	var label_text: String = objective_label.text if objective_label != null else "OBJECTIVE"
	hud_guidance.text = "%s  •  %.1fm%s  •  %s USE" % [label_text,dist,direction,use_hint]

func _animate_environment(delta: float):
	var t = Time.get_ticks_msec() * 0.001
	for i in range(fluor_panels.size()):
		var panel = fluor_panels[i]
		var light = fluor_lights[i]
		var flicker = 1.0 + sin(t * (4.2 + i * 0.4) + i * 0.8) * 0.12
		if i == 1 and fmod(t, 6.2) < 0.18:
			flicker *= 0.22
		if i == 2 and fmod(t + 0.8, 8.8) < 0.10:
			flicker *= 0.35
		if panel and panel.material_override:
			var pm = panel.material_override as StandardMaterial3D
			pm.emission_energy_multiplier = (1.15 + flicker * 0.45) * power_multiplier
		if light:
			light.light_energy = (0.95 + flicker * 0.55) * power_multiplier

	for i in range(monitor_screens.size()):
		var screen = monitor_screens[i]
		if screen and screen.material_override:
			var sm = screen.material_override as StandardMaterial3D
			sm.emission_energy_multiplier = 0.85 + sin(t * 2.4 + i * 1.9) * 0.22 + 0.25

	for i in range(jar_meshes.size()):
		var jar = jar_meshes[i]
		if jar:
			jar.position.y = jar.get_meta("base_y") + sin(t * (1.4 + i * 0.15) + i) * 0.015

	if fan_rotor:
		fan_rotor.rotation.y += delta * 4.8

	for i in range(hanging_cables.size()):
		var cable = hanging_cables[i]
		if cable:
			cable.rotation_degrees.z = sin(t * 0.7 + i * 1.2) * 5.0

	for i in range(slime_patches.size()):
		var patch = slime_patches[i]
		if patch and patch.material_override:
			var mat = patch.material_override as StandardMaterial3D
			mat.emission_energy_multiplier = 0.16 + (sin(t * 1.8 + i * 0.9) * 0.5 + 0.5) * 0.14

	if silhouette_root:
		silhouette_root.position.x = sin(t * 0.33) * 0.65
		silhouette_root.position.y = 2.08 + sin(t * 0.85) * 0.06
		silhouette_root.rotation.y = sin(t * 0.4) * 0.18

	for i in range(drip_drops.size()):
		var drop = drip_drops[i]
		if drop == null:
			continue
		var phase = float(drop.get_meta("phase"))
		var base = drop.get_meta("base_pos")
		var cycle = fmod(t * 0.55 + phase, 1.0)
		var y_off = (1.0 - cycle) * 0.95
		drop.position = base + Vector3(0, y_off, 0)
		drop.scale = Vector3.ONE * (0.55 + sin(cycle * PI) * 0.28)

	for i in range(steam_puffs.size()):
		var puff = steam_puffs[i]
		if puff == null:
			continue
		var phase = float(puff.get_meta("phase"))
		var base = puff.get_meta("base_pos")
		var cyc = fmod(t * 0.22 + phase, 1.0)
		puff.position = base + Vector3(sin(cyc * TAU) * 0.06, cyc * 0.72, cos(cyc * TAU) * 0.05)
		puff.scale = Vector3.ONE * (0.45 + cyc * 0.45)

	if beacon_light and is_instance_valid(pet):
		var alert = max(max(pet.hunger, pet.grime), 100.0 - pet.happiness) / 100.0
		beacon_light.light_energy = 0.15 + alert * (0.45 + (sin(t * 5.2) * 0.5 + 0.5) * 1.65)

func _build_objective_beacon() -> void:
	objective_beacon = Node3D.new()
	objective_beacon.name = "ObjectiveBeacon"
	objective_beacon.visible = false
	add_child(objective_beacon)

	objective_ring = MeshInstance3D.new()
	var tor = TorusMesh.new()
	tor.inner_radius = 0.34
	tor.outer_radius = 0.48
	tor.rings = 24
	tor.ring_segments = 12
	objective_ring.mesh = tor
	objective_ring.rotation_degrees.x = 90
	var ring_mat = StandardMaterial3D.new()
	ring_mat.albedo_color = Color(1.0,0.78,0.18)
	ring_mat.roughness = 0.18
	ring_mat.emission_enabled = true
	ring_mat.emission = Color(1.0,0.42,0.04)
	ring_mat.emission_energy_multiplier = 3.0
	objective_ring.material_override = ring_mat
	objective_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	objective_beacon.add_child(objective_ring)

	objective_arrow = MeshInstance3D.new()
	var cone = CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.16
	cone.height = 0.34
	cone.radial_segments = 16
	objective_arrow.mesh = cone
	objective_arrow.position.y = 0.52
	objective_arrow.rotation_degrees.z = 180
	objective_arrow.material_override = ring_mat
	objective_arrow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	objective_beacon.add_child(objective_arrow)

	objective_light = OmniLight3D.new()
	objective_light.light_color = Color(1.0,0.52,0.10)
	objective_light.light_energy = 2.0
	objective_light.omni_range = 2.2
	objective_light.shadow_enabled = false
	objective_beacon.add_child(objective_light)

	objective_label = Label3D.new()
	objective_label.position.y = 0.86
	objective_label.text = "OBJECTIVE"
	objective_label.font_size = 28
	objective_label.modulate = Color(1.0,0.88,0.45)
	objective_label.outline_size = 7
	objective_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	objective_beacon.add_child(objective_label)

func set_objective_guidance(key: String, label_text := "OBJECTIVE") -> void:
	objective_key = key
	objective_target = _objective_node_for(key)
	if objective_beacon == null:
		return
	if objective_target == null or not is_instance_valid(objective_target):
		objective_beacon.visible = false
		return
	objective_label.text = label_text
	objective_beacon.visible = true

func clear_objective_guidance() -> void:
	objective_key = ""
	objective_target = null
	if objective_beacon:
		objective_beacon.visible = false

func _objective_node_for(key: String) -> Node3D:
	match key:
		"feeder": return get_node_or_null("MEAT_MUSH") as Node3D
		"scrubber": return get_node_or_null("BioScrubber") as Node3D
		"scanner": return get_node_or_null("ScannerDock") as Node3D
		"log": return get_node_or_null("SpecimenLogTerminal") as Node3D
		"bowl": return bowl as Node3D
		"pet": return pet as Node3D
		"ops": return get_node_or_null("OpsTerminal") as Node3D
		"medicine": return get_node_or_null("MedCabinet") as Node3D
		"sample": return get_node_or_null("SampleStation") as Node3D
		"filter_rack": return get_node_or_null("FilterRack") as Node3D
		"filter_hatch": return get_node_or_null("BiofilterHatch") as Node3D
		"toy": return get_node_or_null("ToyLocker") as Node3D
		"annex": return get_node_or_null("AnnexDoor") as Node3D
		"growth": return get_node_or_null("GrowthTerminal") as Node3D
		"automation": return get_node_or_null("AutomationTerminal") as Node3D
		"waste":
			var best: Node3D = null
			var best_dist := INF
			for w in get_tree().get_nodes_in_group("waste"):
				if not is_instance_valid(w) or not (w is Node3D): continue
				var d = player.global_position.distance_squared_to(w.global_position) if is_instance_valid(player) else 0.0
				if d < best_dist: best_dist = d; best = w
			return best
	return null

func _animate_objective_beacon(_delta: float) -> void:
	if objective_beacon == null or not objective_beacon.visible:
		return
	if objective_key == "waste":
		objective_target = _objective_node_for("waste")
	if objective_target == null or not is_instance_valid(objective_target):
		objective_beacon.visible = false
		return
	var t = Time.get_ticks_msec() * 0.001
	var base_y = 0.95
	if objective_key == "pet": base_y = 2.05
	elif objective_key == "waste": base_y = 0.62
	objective_beacon.global_position = objective_target.global_position + Vector3(0,base_y + sin(t*3.2)*0.08,0)
	objective_ring.rotation.y = t * 1.8
	objective_arrow.position.y = 0.52 + sin(t*4.0)*0.09
	objective_light.light_energy = 1.4 + (sin(t*5.0)*0.5+0.5)*1.5

func _build_environment():
	var env_node = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.012, 0.017, 0.019)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.24, 0.29, 0.28)
	env.ambient_light_energy = 0.42
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.22, 0.30, 0.27)
	env.fog_light_energy = 0.35
	env.fog_density = 0.008
	env_node.environment = env
	world_environment = env_node
	add_child(env_node)

	var key = DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-58, -28, 0)
	key.light_energy = 0.42
	key.shadow_enabled = true
	add_child(key)

	for x in [-2.8, 0.0, 2.8]:
		var sick_light = OmniLight3D.new()
		sick_light.position = Vector3(x, 3.55, -0.8)
		sick_light.light_color = Color(0.63, 0.86, 0.73)
		sick_light.light_energy = 1.45
		sick_light.omni_range = 5.6
		sick_light.shadow_enabled = x == 0.0
		add_child(sick_light)
		fluor_lights.append(sick_light)

	var warm_light = OmniLight3D.new()
	warm_light.position = Vector3(-3.7, 1.9, 2.5)
	warm_light.light_color = Color(1.0, 0.30, 0.14)
	warm_light.light_energy = 1.6
	warm_light.omni_range = 4.0
	add_child(warm_light)

	beacon_light = OmniLight3D.new()
	beacon_light.position = Vector3(3.95, 3.45, 2.95)
	beacon_light.light_color = Color(1.0, 0.18, 0.08)
	beacon_light.light_energy = 0.1
	beacon_light.omni_range = 4.2
	add_child(beacon_light)

func _mat(color: Color, rough := 0.82, metallic := 0.0):
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = metallic
	return m


func _pbr_mat(kind: String, scale := Vector3(1.0,1.0,1.0)) -> StandardMaterial3D:
	var key = kind + "_" + str(scale)
	if pbr_cache.has(key):
		return pbr_cache[key]
	var m = StandardMaterial3D.new()
	m.albedo_color = Color.WHITE
	m.uv1_triplanar = true
	m.uv1_scale = scale
	m.normal_enabled = true
	m.normal_scale = 1.0
	if kind == "floor":
		m.albedo_texture = load("res://assets/pbr/floor_tiles_albedo.webp")
		m.normal_texture = load("res://assets/pbr/floor_tiles_normal.webp")
		m.roughness_texture = load("res://assets/pbr/floor_tiles_roughness.webp")
		m.roughness = 0.92
		m.metallic = 0.0
	elif kind == "wall":
		m.albedo_texture = load("res://assets/pbr/wall_concrete_albedo.webp")
		m.normal_texture = load("res://assets/pbr/wall_concrete_normal.webp")
		m.roughness_texture = load("res://assets/pbr/wall_concrete_roughness.webp")
		m.roughness = 0.96
		m.metallic = 0.0
	elif kind == "metal":
		m.albedo_texture = load("res://assets/pbr/metal_albedo.webp")
		m.normal_texture = load("res://assets/pbr/metal_normal.webp")
		m.roughness_texture = load("res://assets/pbr/metal_roughness.webp")
		m.metallic_texture = load("res://assets/pbr/metal_metallic.webp")
		m.roughness = 0.85
		m.metallic = 1.0
		m.normal_scale = 0.85
	pbr_cache[key] = m
	return m

func _set_emissive(node: MeshInstance3D, color: Color, energy: float):
	if node and node.material_override:
		var m = node.material_override as StandardMaterial3D
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = energy

func _static_box(name_: String, pos: Vector3, size: Vector3, color: Color, script_path := "", pbr_kind := "", pbr_scale := Vector3(1.0,1.0,1.0)):
	var body = StaticBody3D.new()
	body.name = name_
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 1
	if script_path != "":
		body.set_script(load(script_path))
		var interaction = load("res://scripts/weird_pet_interaction.gd").new()
		interaction.name = "Interaction"
		interaction.input_map_action = "interact"
		interaction.interaction_text = "Interact"
		body.add_child(interaction)
	var mesh_node = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = size
	mesh_node.mesh = mesh
	mesh_node.material_override = _pbr_mat(pbr_kind, pbr_scale) if pbr_kind != "" else _mat(color)
	body.add_child(mesh_node)
	var shape_node = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	shape_node.shape = shape
	body.add_child(shape_node)
	add_child(body)
	return body

func _decor_box(name_: String, pos: Vector3, size: Vector3, color: Color, rough := 0.7, metallic := 0.0, rot := Vector3.ZERO):
	var node = MeshInstance3D.new()
	node.name = name_
	var mesh = BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = pos
	node.rotation_degrees = rot
	node.material_override = _mat(color, rough, metallic)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	return node

func _decor_cylinder(name_: String, pos: Vector3, radius: float, height: float, color: Color, rot := Vector3.ZERO, metallic := 0.0):
	var node = MeshInstance3D.new()
	node.name = name_
	var mesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 20
	node.mesh = mesh
	node.position = pos
	node.rotation_degrees = rot
	node.material_override = _mat(color, 0.45, metallic)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	return node

func _decor_sphere(name_: String, pos: Vector3, radius: float, scale_: Vector3, color: Color, rough := 0.35):
	var node = MeshInstance3D.new()
	node.name = name_
	var mesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 18
	mesh.rings = 10
	node.mesh = mesh
	node.position = pos
	node.scale = scale_
	node.material_override = _mat(color, rough)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	return node

func _label3d(text_: String, pos: Vector3, size := 32, color := Color(0.75, 0.95, 0.80), rot_y := 0.0):
	var lab = Label3D.new()
	lab.text = text_
	lab.position = pos
	lab.font_size = size
	lab.modulate = color
	lab.outline_size = 5
	lab.rotation_degrees.y = rot_y
	add_child(lab)
	return lab

func _label3d_face_room_center(text_: String, pos: Vector3, size := 32, color := Color(0.75, 0.95, 0.80), target := Vector3(0,0,0.55)):
	var lab = _label3d(text_, pos, size, color, 0.0)
	var aim = Vector3(target.x, lab.global_position.y, target.z)
	lab.look_at(aim, Vector3.UP, true)
	lab.rotation.x = 0
	lab.rotation.z = 0
	return lab

func _build_room():
	_static_box("Floor", Vector3(0,-0.15,0), Vector3(10,0.3,9), Color(0.075,0.085,0.083), "", "floor", Vector3(0.72,0.72,0.72))
	_static_box("BackWall", Vector3(0,2.25,-4.45), Vector3(10,4.5,0.25), Color(0.105,0.13,0.12), "", "wall", Vector3(0.62,0.62,0.62))
	_static_box("FrontWallL", Vector3(-3.05,2.25,4.45), Vector3(3.9,4.5,0.25), Color(0.075,0.09,0.09), "", "wall", Vector3(0.62,0.62,0.62))
	_static_box("FrontWallR", Vector3(3.05,2.25,4.45), Vector3(3.9,4.5,0.25), Color(0.075,0.09,0.09), "", "wall", Vector3(0.62,0.62,0.62))
	_static_box("FrontLintel", Vector3(0,3.75,4.45), Vector3(2.2,1.5,0.25), Color(0.075,0.09,0.09), "", "wall", Vector3(0.62,0.62,0.62))
	_static_box("LeftWall", Vector3(-4.9,2.25,0), Vector3(0.25,4.5,9), Color(0.09,0.115,0.105), "", "wall", Vector3(0.62,0.62,0.62))
	_static_box("RightWall", Vector3(4.9,2.25,0), Vector3(0.25,4.5,9), Color(0.09,0.115,0.105), "", "wall", Vector3(0.62,0.62,0.62))
	_static_box("Ceiling", Vector3(0,4.46,0), Vector3(10,0.18,9), Color(0.045,0.055,0.055), "", "metal", Vector3(0.52,0.52,0.52))

	# Keep the room visually clean at startup so actual incidents are unmistakable.

	for x in [-2.8, 0.0, 2.8]:
		_decor_box("FluorHousing", Vector3(x,4.32,-0.8), Vector3(1.75,0.12,0.55), Color(0.13,0.16,0.15),0.3,0.5)
		var panel = _decor_box("FluorPanel", Vector3(x,4.24,-0.8), Vector3(1.55,0.025,0.38), Color(0.65,0.95,0.75),0.15)
		_set_emissive(panel, Color(0.38,0.82,0.55), 1.5)
		fluor_panels.append(panel)

	_static_box("PetPlatform", Vector3(0,0.12,-1.25), Vector3(3.8,0.24,3.3), Color(0.15,0.18,0.16), "", "metal", Vector3(0.75,0.75,0.75))
	var habitat_light = OmniLight3D.new()
	habitat_light.position = Vector3(0,1.55,-1.15)
	habitat_light.light_color = Color(0.72,0.95,0.82)
	habitat_light.light_energy = 0.70
	habitat_light.omni_range = 4.0
	add_child(habitat_light)
	for x in [-1.72, 1.72]:
		_static_box("Rail", Vector3(x,0.57,-1.25), Vector3(0.07,0.9,3.3), Color(0.27,0.32,0.29), "", "metal", Vector3(1.4,1.4,1.4))
	for i in range(12):
		var stripe_col = Color(0.78,0.58,0.08) if i % 2 == 0 else Color(0.055,0.06,0.055)
		_decor_box("Hazard", Vector3(-1.72 + i*0.31,0.255,0.38), Vector3(0.28,0.035,0.13), stripe_col,0.6)

	# No ambient grime outside the habitat by default; save visual clutter for real messes.

	_decor_box("WindowFrame", Vector3(0,2.45,-4.29), Vector3(5.2,2.15,0.08), Color(0.025,0.032,0.032),0.25,0.65)
	var glass = _decor_box("WindowGlass", Vector3(0,2.45,-4.235), Vector3(4.75,1.72,0.025), Color(0.045,0.10,0.09),0.12,0.15)
	_set_emissive(glass, Color(0.015,0.07,0.055), 0.65)
	_label3d("OBSERVATION  /  SPECIMEN 07", Vector3(0,3.56,-4.17), 28, Color(0.55,0.88,0.67))
	_label3d("DO NOT KISS THE SPECIMEN", Vector3(0,1.36,-4.17), 21, Color(0.95,0.44,0.22))

	silhouette_root = Node3D.new()
	silhouette_root.position = Vector3(0,2.08,-4.16)
	add_child(silhouette_root)
	var sh_head = _decor_sphere("SilhouetteHead", silhouette_root.position + Vector3(0,0.55,-0.02), 0.18, Vector3(1.0,1.05,0.86), Color(0.02,0.03,0.03), 0.7)
	var sh_body = _decor_sphere("SilhouetteBody", silhouette_root.position + Vector3(0,0.02,-0.02), 0.32, Vector3(1.0,1.35,0.78), Color(0.02,0.03,0.03), 0.7)
	var sh_t1 = _decor_cylinder("SilhouetteT1", silhouette_root.position + Vector3(-0.18,-0.36,-0.02), 0.05, 0.8, Color(0.02,0.03,0.03), Vector3(70,0,-15))
	var sh_t2 = _decor_cylinder("SilhouetteT2", silhouette_root.position + Vector3(0.20,-0.28,-0.02), 0.05, 0.9, Color(0.02,0.03,0.03), Vector3(64,12,18))
	for n in [sh_head, sh_body, sh_t1, sh_t2]:
		n.reparent(silhouette_root)
		n.position -= silhouette_root.position

	_static_box("Cabinet", Vector3(-3.8,0.9,-2.8), Vector3(1.25,1.8,0.7), Color(0.15,0.19,0.18), "", "metal", Vector3(1.2,1.2,1.2))
	_static_box("Counter", Vector3(3.65,0.75,-2.7), Vector3(1.8,1.5,0.85), Color(0.11,0.15,0.15), "", "metal", Vector3(1.0,1.0,1.0))
	_decor_box("ShelfA", Vector3(-3.75,2.05,-3.9), Vector3(1.75,0.08,0.55), Color(0.20,0.23,0.21),0.35,0.4)
	_decor_box("ShelfB", Vector3(-3.75,2.75,-3.9), Vector3(1.75,0.08,0.55), Color(0.20,0.23,0.21),0.35,0.4)
	for i in range(5):
		var jar = _decor_cylinder("SampleJar", Vector3(-4.35 + i*0.30,2.35 + (i%2)*0.70,-3.85),0.09,0.42,Color(0.21+0.03*i,0.46,0.27),Vector3.ZERO,0.1)
		jar.set_meta("base_y", jar.position.y)
		jar_meshes.append(jar)
	_decor_cylinder("Pipe", Vector3(4.55,2.1,-1.0),0.08,3.7,Color(0.24,0.28,0.27),Vector3(90,0,0),0.7)
	_decor_cylinder("Pipe2", Vector3(4.55,3.2,1.3),0.08,2.0,Color(0.24,0.28,0.27),Vector3.ZERO,0.7)

	# animated monitors and cheap motion readouts
	var m1 = _decor_box("MonitorA", Vector3(-4.02,1.90,1.95), Vector3(0.78,0.52,0.10), Color(0.05,0.08,0.08),0.22,0.55)
	var s1 = _decor_box("ScreenA", Vector3(-3.98,1.90,2.005), Vector3(0.66,0.40,0.02), Color(0.18,0.92,0.65),0.12)
	_set_emissive(s1, Color(0.08,0.95,0.55), 1.3)
	var m2 = _decor_box("MonitorB", Vector3(4.00,2.05,1.25), Vector3(0.92,0.60,0.10), Color(0.05,0.08,0.08),0.22,0.55)
	var s2 = _decor_box("ScreenB", Vector3(3.96,2.05,1.195), Vector3(0.79,0.47,0.02), Color(0.16,0.72,0.96),0.12)
	_set_emissive(s2, Color(0.12,0.55,0.92), 1.2)
	monitor_screens.append(s1)
	monitor_screens.append(s2)
	_label3d("HEARTLIKE RHYTHM", Vector3(-4.00,2.10,2.07), 15, Color(0.90,1.0,0.95), 90.0)
	_label3d("MUCUS INDEX", Vector3(3.98,2.30,1.12), 15, Color(0.88,0.98,1.0), -90.0)

	# ceiling fan and hanging cables
	fan_rotor = Node3D.new()
	fan_rotor.name = "Rotor"
	fan_rotor.position = Vector3(0.0,4.08,1.15)
	add_child(fan_rotor)
	_decor_cylinder("FanStem", Vector3(0.0,4.22,1.15),0.04,0.38,Color(0.22,0.24,0.24),Vector3.ZERO,0.8)
	var hub = MeshInstance3D.new()
	var hub_mesh = SphereMesh.new()
	hub_mesh.radius = 0.12
	hub_mesh.height = 0.24
	hub.mesh = hub_mesh
	hub.material_override = _mat(Color(0.18,0.20,0.20),0.4,0.7)
	fan_rotor.add_child(hub)
	for i in range(4):
		var blade = MeshInstance3D.new()
		var bm = BoxMesh.new()
		bm.size = Vector3(1.15,0.03,0.16)
		blade.mesh = bm
		blade.material_override = _mat(Color(0.18,0.20,0.20),0.45,0.45)
		blade.rotation_degrees = Vector3(0,i*90,0)
		blade.position = Vector3(0.56,0,0)
		fan_rotor.add_child(blade)

	for i in range(3):
		var cable = _decor_cylinder("Cable", Vector3(-2.2 + i*1.8,3.45,2.8 - i*0.6),0.028,1.15 + i*0.12,Color(0.04,0.04,0.04),Vector3.ZERO,0.0)
		cable.set_meta("base_rot", cable.rotation_degrees)
		hanging_cables.append(cable)

	_static_box("Drain", Vector3(2.8,0.02,1.9), Vector3(1.1,0.04,1.1), Color(0.025,0.04,0.04), "", "metal", Vector3(1.6,1.6,1.6))
	for i in range(5):
		_decor_box("DrainSlot", Vector3(2.8,0.048,1.55+i*0.17), Vector3(0.82,0.015,0.045), Color(0.12,0.15,0.14),0.2,0.6)

	for i in range(3):
		var drop = _decor_sphere("PipeDrip", Vector3(4.55,3.0,1.28 + i*0.06), 0.05, Vector3(0.45,0.85,0.45), Color(0.18,0.42,0.25), 0.06)
		_set_emissive(drop, Color(0.03,0.20,0.09), 0.12)
		drop.set_meta("base_pos", Vector3(4.55,2.05,1.28 + i*0.06))
		drop.set_meta("phase", float(i) * 0.27)
		drip_drops.append(drop)
	for i in range(4):
		var puff = _decor_sphere("SteamPuff", Vector3(2.8 + i*0.05,0.16,1.85), 0.09, Vector3(0.55,0.55,0.55), Color(0.34,0.38,0.36), 0.9)
		puff.set_meta("base_pos", Vector3(2.8 + i*0.05,0.16,1.85))
		puff.set_meta("phase", float(i) * 0.21)
		steam_puffs.append(puff)

func _build_annex():
	# Connected research/automation annex unlocked in the second week.
	_static_box("AnnexFloor", Vector3(0,-0.15,7.55), Vector3(8.2,0.3,6.0), Color(0.065,0.075,0.078), "", "floor", Vector3(0.70,0.70,0.70))
	_static_box("AnnexBack", Vector3(0,2.25,10.48), Vector3(8.2,4.5,0.25), Color(0.08,0.10,0.11), "", "wall", Vector3(0.62,0.62,0.62))
	_static_box("AnnexLeft", Vector3(-4.0,2.25,7.55), Vector3(0.25,4.5,6.0), Color(0.08,0.10,0.11), "", "wall", Vector3(0.62,0.62,0.62))
	_static_box("AnnexRight", Vector3(4.0,2.25,7.55), Vector3(0.25,4.5,6.0), Color(0.08,0.10,0.11), "", "wall", Vector3(0.62,0.62,0.62))
	_static_box("AnnexCeiling", Vector3(0,4.46,7.55), Vector3(8.2,0.18,6.0), Color(0.04,0.05,0.06), "", "metal", Vector3(0.52,0.52,0.52))
	for x in [-2.4,0.0,2.4]:
		_decor_box("AnnexHousing", Vector3(x,4.30,7.6), Vector3(1.45,0.12,0.44), Color(0.11,0.14,0.15),0.3,0.5)
		var panel = _decor_box("AnnexPanel", Vector3(x,4.22,7.6), Vector3(1.28,0.025,0.31), Color(0.48,0.78,0.92),0.15)
		_set_emissive(panel, Color(0.16,0.58,0.90),1.25)
		var annex_light = OmniLight3D.new()
		annex_light.position = Vector3(x,3.75,7.6)
		annex_light.light_color = Color(0.42,0.70,0.92)
		annex_light.light_energy = 1.65
		annex_light.omni_range = 4.2
		add_child(annex_light)
	var annex_warm = OmniLight3D.new()
	annex_warm.position = Vector3(0,1.5,9.1)
	annex_warm.light_color = Color(0.90,0.34,0.16)
	annex_warm.light_energy = 1.2
	annex_warm.omni_range = 3.2
	add_child(annex_warm)
	# Research benches and machinery.
	_static_box("AnnexBenchL", Vector3(-2.85,0.78,8.25), Vector3(1.65,1.55,0.75), Color(0.12,0.16,0.18), "", "metal", Vector3(1.1,1.1,1.1))
	_static_box("AnnexBenchR", Vector3(2.85,0.78,8.25), Vector3(1.65,1.55,0.75), Color(0.12,0.16,0.18), "", "metal", Vector3(1.1,1.1,1.1))
	_decor_box("AnnexRackL",Vector3(-3.55,2.35,9.55),Vector3(0.55,2.6,0.45),Color(0.10,0.15,0.18),0.4,0.55)
	_decor_box("AnnexRackR",Vector3(3.55,2.35,9.55),Vector3(0.55,2.6,0.45),Color(0.10,0.15,0.18),0.4,0.55)
	for y in [1.45,2.05,2.65,3.25]:
		_decor_box("ArchiveTrayL",Vector3(-3.55,y,9.28),Vector3(0.42,0.15,0.12),Color(0.20,0.44,0.52),0.25,0.25)
		_decor_box("ArchiveTrayR",Vector3(3.55,y,9.28),Vector3(0.42,0.15,0.12),Color(0.44,0.22,0.20),0.25,0.25)
	for i in range(4):
		_decor_cylinder("CryoCan",Vector3(-3.25+i*0.42,1.78,8.10),0.12,0.55,Color(0.12,0.34+0.04*i,0.40),Vector3.ZERO,0.45)
	var tank = _decor_cylinder("GrowthTank",Vector3(0.0,1.35,9.25),0.72,2.45,Color(0.09,0.18,0.20),Vector3.ZERO,0.2)
	var glow = _decor_cylinder("GrowthGlow",Vector3(0.0,1.35,9.24),0.54,2.15,Color(0.10,0.58,0.48),Vector3.ZERO,0.0)
	_set_emissive(glow,Color(0.03,0.42,0.28),0.55)
	_label3d("RESEARCH ANNEX // AUTHORIZED HANDLERS",Vector3(0,3.55,10.30),20,Color(0.55,0.86,1.0),0.0)
	_label3d("AUTOMATION",Vector3(-2.85,1.85,7.82),14,Color(0.70,0.92,1.0),0.0)
	_label3d("GROWTH ANALYSIS",Vector3(2.85,1.85,7.82),14,Color(0.70,0.92,1.0),0.0)
	_static_box("AutomationTerminal",Vector3(-2.85,1.20,7.78),Vector3(0.64,0.88,0.42),Color(0.08,0.20,0.25),"res://scripts/automation_terminal.gd","metal",Vector3(1.2,1.2,1.2))
	_static_box("GrowthTerminal",Vector3(2.85,1.20,7.78),Vector3(0.64,0.88,0.42),Color(0.16,0.13,0.24),"res://scripts/growth_terminal.gd","metal",Vector3(1.2,1.2,1.2))
	# Sliding access door.
	annex_door = _static_box("AnnexDoor",Vector3(0,1.48,4.40),Vector3(1.95,2.95,0.18),Color(0.12,0.16,0.17),"res://scripts/annex_door.gd","metal",Vector3(1.0,1.0,1.0))
	_label3d("RESEARCH ANNEX  //  WEEK 2",Vector3(0,3.20,4.30),14,Color(0.58,0.80,0.92),0.0)

func set_annex_unlocked(value: bool):
	annex_unlocked = value
	if annex_door == null: return
	annex_door.set_meta("unlocked",value)
	if value:
		annex_door.position.y = 4.30
		for c in annex_door.get_children():
			if c is CollisionShape3D: c.disabled = true
	else:
		annex_door.position.y = 1.48
		for c in annex_door.get_children():
			if c is CollisionShape3D: c.disabled = false


func _face_room_center(node: Node3D, target := Vector3(0,0,0.55)):
	if node == null: return
	var aim = Vector3(target.x, node.global_position.y, target.z)
	node.look_at(aim, Vector3.UP, true)
	node.rotation.x = 0
	node.rotation.z = 0

func _build_sim_objects():
	var food = _static_box("MEAT_MUSH", Vector3(-3.75,1.25,-2.15), Vector3(0.72,0.9,0.58), Color(0.41,0.045,0.055), "res://scripts/food_bin.gd")
	food.rotation.y = 0.08
	_decor_box("FoodLid", Vector3(-3.75,1.73,-2.15), Vector3(0.78,0.12,0.64), Color(0.20,0.022,0.03),0.45)
	_label3d("MEAT\nMUSH", Vector3(-3.73,1.32,-1.84), 20, Color(1.0,0.72,0.58), 0.0)

	_static_box("BioScrubber", Vector3(3.72,1.45,-2.15), Vector3(0.40,0.74,0.30), Color(0.035,0.33,0.36), "res://scripts/cleaner_station.gd")
	_label3d("BIO-SCRUBBER", Vector3(3.72,1.91,-2.10), 17, Color(0.55,1.0,0.92), 0.0)

	var shop = _static_box("RequisitionsTerminal", Vector3(-4.15,1.20,0.70), Vector3(0.55,1.05,0.42), Color(0.10,0.19,0.17), "res://scripts/shop_terminal.gd", "metal", Vector3(1.5,1.5,1.5))
	shop.rotation.y = -0.18
	_label3d_face_room_center("REQUISITIONS", Vector3(-3.94,1.82,0.58), 15, Color(0.72,1.0,0.80))
	var shop_screen = _decor_box("ReqScreen", Vector3(-4.02,1.35,0.48), Vector3(0.38,0.36,0.035), Color(0.08,0.75,0.48),0.15)
	_set_emissive(shop_screen, Color(0.03,0.65,0.34), 1.6)

	var ops = _static_box("OpsTerminal", Vector3(4.15,1.20,0.70), Vector3(0.55,1.05,0.42), Color(0.25,0.16,0.05), "res://scripts/ops_terminal.gd", "metal", Vector3(1.5,1.5,1.5))
	ops.rotation.y = 0.18
	_label3d_face_room_center("OPS / RESET", Vector3(3.94,1.82,0.58), 15, Color(1.0,0.72,0.30))
	var ops_screen = _decor_box("OpsScreen", Vector3(4.02,1.35,0.48), Vector3(0.38,0.36,0.035), Color(0.86,0.38,0.05),0.15)
	_set_emissive(ops_screen, Color(0.90,0.22,0.02), 1.6)

	# Pass A physical simulator workstations.
	var meds = _static_box("MedCabinet", Vector3(-4.15,1.15,2.55), Vector3(0.55,0.95,0.42), Color(0.20,0.25,0.24), "res://scripts/medicine_station.gd", "metal", Vector3(1.3,1.3,1.3))
	_face_room_center(meds)
	_label3d_face_room_center("MEDS", Vector3(-3.86,1.70,2.42), 14, Color(0.76,0.95,0.90))
	var samples = _static_box("SampleStation", Vector3(-2.95,1.12,3.72), Vector3(0.66,0.90,0.42), Color(0.15,0.22,0.24), "res://scripts/sample_station.gd", "metal", Vector3(1.2,1.2,1.2))
	_face_room_center(samples)
	_label3d_face_room_center("SAMPLES", Vector3(-2.95,1.66,3.26), 13, Color(0.55,0.92,1.0))
	var filters = _static_box("FilterRack", Vector3(2.85,1.12,3.72), Vector3(0.70,0.90,0.42), Color(0.17,0.22,0.19), "res://scripts/filter_rack.gd", "metal", Vector3(1.2,1.2,1.2))
	_face_room_center(filters)
	_label3d_face_room_center("FILTERS", Vector3(2.85,1.66,3.26), 13, Color(0.72,0.95,0.72))
	var toys = _static_box("ToyLocker", Vector3(4.15,1.10,2.60), Vector3(0.55,0.90,0.42), Color(0.18,0.17,0.25), "res://scripts/toy_station.gd", "metal", Vector3(1.2,1.2,1.2))
	_face_room_center(toys)
	_label3d_face_room_center("ENRICHMENT", Vector3(3.86,1.65,2.44), 12, Color(0.70,0.75,1.0))
	var scanner = _static_box("ScannerDock", Vector3(-4.15,1.00,-0.55), Vector3(0.48,0.66,0.36), Color(0.12,0.22,0.22), "res://scripts/thermometer_station.gd", "metal", Vector3(1.1,1.1,1.1))
	_face_room_center(scanner)
	_label3d_face_room_center("SCAN", Vector3(-3.90,1.40,-0.66), 12, Color(0.55,1.0,0.90))
	var logterm = _static_box("SpecimenLogTerminal", Vector3(4.15,1.00,-0.55), Vector3(0.48,0.66,0.36), Color(0.11,0.16,0.24), "res://scripts/log_terminal.gd", "metal", Vector3(1.1,1.1,1.1))
	_face_room_center(logterm)
	_label3d_face_room_center("SPECIMEN LOG", Vector3(3.90,1.40,-0.66), 11, Color(0.64,0.82,1.0))
	var hatch = _static_box("BiofilterHatch", Vector3(3.82,0.55,-3.92), Vector3(1.25,0.82,0.18), Color(0.12,0.20,0.14), "res://scripts/filter_hatch.gd", "metal", Vector3(1.4,1.4,1.4))
	_face_room_center(hatch, Vector3(0,0,-0.8))
	_label3d_face_room_center("BIOFILTER", Vector3(3.82,1.08,-3.62), 13, Color(0.63,0.95,0.67), Vector3(0,0,-0.8))

	bowl = StaticBody3D.new()
	bowl.name = "FoodBowl"
	bowl.position = Vector3(-1.2,0.42,-0.05)
	bowl.collision_layer = 1
	bowl.collision_mask = 1
	bowl.set_script(load("res://scripts/bowl.gd"))
	var bowl_mesh = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.48
	cyl.bottom_radius = 0.56
	cyl.height = 0.18
	cyl.radial_segments = 28
	bowl_mesh.mesh = cyl
	bowl_mesh.material_override = _mat(Color(0.24,0.28,0.27), 0.24, 0.55)
	bowl.add_child(bowl_mesh)
	var rim = MeshInstance3D.new()
	var rim_mesh = TorusMesh.new()
	rim_mesh.inner_radius = 0.38
	rim_mesh.outer_radius = 0.53
	rim_mesh.rings = 24
	rim_mesh.ring_segments = 12
	rim.mesh = rim_mesh
	rim.position.y = 0.06
	rim.rotation_degrees.x = 90
	rim.material_override = _mat(Color(0.30,0.34,0.33), 0.18, 0.65)
	bowl.add_child(rim)
	var bshape = CollisionShape3D.new()
	var bcyl = CylinderShape3D.new()
	bcyl.radius = 0.58
	bcyl.height = 0.22
	bshape.shape = bcyl
	bowl.add_child(bshape)
	var bowl_interaction = load("res://scripts/weird_pet_interaction.gd").new()
	bowl_interaction.input_map_action = "interact"
	bowl_interaction.interaction_text = "Use bowl"
	bowl.add_child(bowl_interaction)
	add_child(bowl)

	pet = StaticBody3D.new()
	pet.name = "Gloop"
	pet.position = Vector3(0,0.25,-1.35)
	pet.collision_layer = 1
	pet.collision_mask = 1
	pet.set_script(load("res://scripts/pet.gd"))
	pet.rotation.y = PI
	var pet_interaction = load("res://scripts/weird_pet_interaction.gd").new()
	pet_interaction.input_map_action = "interact"
	pet_interaction.interaction_text = "Pet"
	pet.add_child(pet_interaction)
	add_child(pet)

func _build_player():
	player = load("res://scripts/player.gd").new()
	player.position = Vector3(0,0.05,3.1)
	player.speed = 4.6
	player.jump_height = 4.5
	player.gravity_multiplier = 1.9
	player.collision_layer = 1
	player.collision_mask = 1
	var shape_node = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.75
	shape_node.shape = capsule
	shape_node.position.y = 0.88
	player.add_child(shape_node)

	var head = Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, 1.58, 0)
	head.set_script(load("res://vendor/first_person/Head.gd"))
	player.add_child(head)
	head.owner = player
	var camera = Camera3D.new()
	camera.name = "Camera"
	camera.current = true
	camera.fov = 72.0
	head.add_child(camera)
	camera.owner = player

	var sprint = Node.new()
	sprint.name = "Sprint"
	sprint.set_script(load("res://vendor/first_person/Sprint.gd"))
	sprint.set("sprint_speed", 6)
	player.add_child(sprint)

	var interaction = load("res://scripts/player_interaction_component.gd").new()
	interaction.name = "PlayerInteractionComponent"
	player.add_child(interaction)
	add_child(player)

func _build_hud():
	var canvas = CanvasLayer.new()
	add_child(canvas)
	var panel = ColorRect.new()
	panel.position = Vector2(18,18)
	panel.size = Vector2(320,205)
	panel.color = Color(0.008,0.014,0.013,0.88)
	canvas.add_child(panel)
	var top_strip = ColorRect.new()
	top_strip.position = Vector2(18,18)
	top_strip.size = Vector2(320,5)
	top_strip.color = Color(0.34,0.88,0.58,0.85)
	canvas.add_child(top_strip)

	var title = _label(canvas, Vector2(32,31), "SPECIMEN CARE // GLOOP", 18)
	title.modulate = Color(0.72,1.0,0.79)
	_label(canvas, Vector2(32,62), "HUNGER", 13).modulate = Color(0.74,0.78,0.75)
	_label(canvas, Vector2(32,99), "FILTH", 13).modulate = Color(0.74,0.78,0.75)
	_label(canvas, Vector2(32,136), "MOOD", 13).modulate = Color(0.74,0.78,0.75)
	bar_hunger = _bar(canvas, Vector2(99,64), Color(0.93,0.39,0.20))
	bar_grime = _bar(canvas, Vector2(99,101), Color(0.48,0.78,0.25))
	bar_happy = _bar(canvas, Vector2(99,138), Color(0.30,0.79,0.72))
	hud_hunger = _label(canvas, Vector2(278,60), "", 13)
	hud_grime = _label(canvas, Vector2(278,97), "", 13)
	hud_happy = _label(canvas, Vector2(278,134), "", 13)
	hud_held = _label(canvas, Vector2(32,171), "HOLDING", 13)
	hud_held.modulate = Color(0.92,0.82,0.60)
	hud_status = _label(canvas, Vector2(32,196), "STABLE", 12)
	hud_status.modulate = Color(0.55,0.95,0.70)

	hud_shift = _label(canvas, Vector2(650,24), "CARE SHIFT", 15)
	hud_shift.size = Vector2(600,30)
	hud_shift.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hud_shift.modulate = Color(0.75,0.9,0.81)
	hud_objective = _label(canvas, Vector2(790,49), "FEED GLOOP  •  CLEAN INCIDENTS  •  KEEP IT CALM", 12)
	hud_objective.size = Vector2(460,26)
	hud_objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hud_objective.modulate = Color(0.58,0.65,0.62)
	hud_guidance = _label(canvas, Vector2(300,150), "", 15)
	hud_guidance.size = Vector2(680,28)
	hud_guidance.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_guidance.modulate = Color(1.0,0.78,0.28)

	hud_reaction = _label(canvas, Vector2(22,675), "", 15)
	hud_reaction.size = Vector2(900,28)
	hud_reaction.modulate = Color(0.67,0.82,0.72)

	hud_prompt = _label(canvas, Vector2(310,620), "", 20)
	hud_prompt.size = Vector2(760,35)
	hud_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_message = _label(canvas, Vector2(250,570), "", 18)
	hud_message.size = Vector2(880,35)
	hud_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_message.modulate = Color(1.0,0.82,0.48)

	hud_controls = _label(canvas, Vector2(980,650), "[E] USE     [Q] DROP", 11)
	hud_controls.size = Vector2(270,25)
	hud_controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hud_controls.modulate = Color(0.46,0.53,0.50)

	var cross = _label(canvas, Vector2(625,350), "+", 22)
	cross.size = Vector2(30,30)
	cross.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cross.modulate = Color(0.65,1.0,0.78,0.72)

func _bar(parent, pos: Vector2, fill_color: Color):
	var b = ProgressBar.new()
	b.position = pos
	b.size = Vector2(168,17)
	b.min_value = 0
	b.max_value = 100
	b.show_percentage = false
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.07,0.085,0.08,0.95)
	bg.corner_radius_top_left = 2
	bg.corner_radius_top_right = 2
	bg.corner_radius_bottom_left = 2
	bg.corner_radius_bottom_right = 2
	var fill = StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.corner_radius_top_left = 2
	fill.corner_radius_top_right = 2
	fill.corner_radius_bottom_left = 2
	fill.corner_radius_bottom_right = 2
	b.add_theme_stylebox_override("background", bg)
	b.add_theme_stylebox_override("fill", fill)
	parent.add_child(b)
	return b

func _label(parent, pos: Vector2, text_: String, font_size: int):
	var l = Label.new()
	l.position = pos
	l.text = text_
	l.add_theme_font_size_override("font_size", font_size)
	parent.add_child(l)
	return l

func _visible_waste_position(_requested: Vector3) -> Vector3:
	# Waste used to spawn on a random ring around Gloop. That could put it behind the
	# specimen, outside the habitat, or partially buried in the raised platform.
	# Use a small set of intentionally readable habitat locations, front-most first.
	var slots := [
		Vector3(-0.95,0.33,-0.28),
		Vector3(0.95,0.33,-0.28),
		Vector3(-1.22,0.33,-1.05),
		Vector3(1.22,0.33,-1.05),
		Vector3(0.0,0.33,-2.18)
	]
	var occupied: Array[Vector3] = []
	for existing in get_tree().get_nodes_in_group("waste"):
		if existing is Node3D:
			occupied.append((existing as Node3D).global_position)
	for slot in slots:
		var free := true
		for used in occupied:
			if Vector2(slot.x-used.x,slot.z-used.z).length() < 0.72:
				free = false
				break
		if free:
			return slot
	return slots[occupied.size() % slots.size()]

func spawn_waste(pos: Vector3, pet_ref):
	var waste = StaticBody3D.new()
	waste.name = "BiologicalIncident"
	waste.position = _visible_waste_position(pos)
	waste.collision_layer = 1
	waste.collision_mask = 1
	waste.set_script(load("res://scripts/waste.gd"))
	waste.pet = pet_ref
	var waste_interaction = load("res://scripts/weird_pet_interaction.gd").new()
	waste_interaction.input_map_action = "interact"
	waste_interaction.interaction_text = "Clean"
	waste.add_child(waste_interaction)
	add_child(waste)
	play_sfx("plop", waste.position, true)
	return waste

func play_sfx(sound_name: String, pos := Vector3.ZERO, spatial := false):
	var path = "res://assets/audio/%s.ogg" % sound_name
	var stream = load(path)
	if stream == null:
		return
	if spatial:
		var p3 = AudioStreamPlayer3D.new()
		p3.stream = stream
		p3.position = pos
		p3.max_distance = 12.0
		p3.volume_db = -4.0
		add_child(p3)
		p3.finished.connect(p3.queue_free)
		p3.play()
	else:
		var p = AudioStreamPlayer.new()
		p.stream = stream
		p.volume_db = -5.0
		add_child(p)
		p.finished.connect(p.queue_free)
		p.play()

func _start_ambient_audio():
	var stream = load("res://assets/audio/lab_hum.ogg")
	if stream == null:
		return
	var ambience = AudioStreamPlayer.new()
	ambience.name = "LabHum"
	ambience.stream = stream
	ambience.volume_db = -17.0
	add_child(ambience)
	ambience.finished.connect(ambience.play)
	ambience.play()

func _upgrade_prop(parent: Node3D, pos: Vector3, size: Vector3, color: Color, metallic := 0.0):
	var n = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = size
	n.mesh = bm
	n.position = pos
	n.material_override = _mat(color,0.35,metallic)
	parent.add_child(n)
	return n

func apply_performance_profile(profile: String) -> void:
	var p = profile.to_lower()
	if world_environment and world_environment.environment:
		world_environment.environment.fog_enabled = p != "low"
		world_environment.environment.fog_density = 0.005 if p == "balanced" else 0.008
	for i in range(steam_puffs.size()):
		if steam_puffs[i]: steam_puffs[i].visible = p == "quality" or (p == "balanced" and i < 2)
	for i in range(drip_drops.size()):
		if drip_drops[i]: drip_drops[i].visible = p != "low" or i == 0
	if silhouette_root: silhouette_root.visible = p != "low"
	for i in range(fluor_lights.size()):
		if fluor_lights[i]: fluor_lights[i].shadow_enabled = (p == "quality" and i == 1) or (p == "balanced" and i == 1)
	if beacon_light: beacon_light.shadow_enabled = p == "quality"
	print("PERFORMANCE_PROFILE: %s" % p)

func apply_upgrade_visuals(upgrades: Dictionary):
	if upgrade_visual_root == null:
		upgrade_visual_root = Node3D.new()
		upgrade_visual_root.name = "PurchasedUpgrades"
		add_child(upgrade_visual_root)
	for c in upgrade_visual_root.get_children():
		c.queue_free()
	if upgrades.get("heater",false):
		var heater = _upgrade_prop(upgrade_visual_root,Vector3(3.7,0.55,2.85),Vector3(0.75,0.95,0.42),Color(0.20,0.19,0.17),0.55)
		_upgrade_prop(upgrade_visual_root,Vector3(3.70,0.58,2.62),Vector3(0.50,0.12,0.04),Color(0.96,0.32,0.06),0.1)
	if upgrades.get("toy",false):
		var toy_mat = _mat(Color(0.18,0.42,0.76),0.32)
		var toy = MeshInstance3D.new()
		var tor = TorusMesh.new()
		tor.inner_radius = 0.16
		tor.outer_radius = 0.31
		toy.mesh = tor
		toy.position = Vector3(1.25,0.32,-0.25)
		toy.rotation_degrees.x = 90
		toy.material_override = toy_mat
		upgrade_visual_root.add_child(toy)
	if upgrades.get("auto_scrubber",false):
		var scrub = _upgrade_prop(upgrade_visual_root,Vector3(2.65,0.14,2.9),Vector3(0.62,0.18,0.62),Color(0.09,0.44,0.42),0.25)
		_upgrade_prop(upgrade_visual_root,Vector3(2.65,0.24,2.9),Vector3(0.28,0.05,0.28),Color(0.26,0.95,0.75),0.0)
	if upgrades.get("better_mush",false):
		_upgrade_prop(upgrade_visual_root,Vector3(-3.75,1.86,-2.15),Vector3(0.54,0.08,0.44),Color(0.98,0.68,0.18),0.1)
	if upgrades.get("soft_lights",false):
		for l in fluor_lights:
			l.light_color = Color(0.74,0.86,0.78)
	else:
		for l in fluor_lights:
			l.light_color = Color(0.63,0.86,0.73)
	if upgrades.get("emergency_battery",false):
		_upgrade_prop(upgrade_visual_root,Vector3(3.95,0.55,3.75),Vector3(0.58,0.88,0.32),Color(0.18,0.19,0.12),0.45)
		_upgrade_prop(upgrade_visual_root,Vector3(3.95,0.60,3.56),Vector3(0.32,0.08,0.03),Color(0.95,0.72,0.12),0.1)
	if upgrades.get("health_monitor",false):
		var mon = _upgrade_prop(upgrade_visual_root,Vector3(1.55,1.35,-3.95),Vector3(0.72,0.50,0.10),Color(0.06,0.11,0.12),0.35)
		var scr = _upgrade_prop(upgrade_visual_root,Vector3(1.55,1.35,-3.88),Vector3(0.58,0.36,0.02),Color(0.10,0.78,0.56),0.1)
		_set_emissive(scr,Color(0.05,0.70,0.40),1.3)
	if upgrades.get("auto_feeder",false):
		_upgrade_prop(upgrade_visual_root,Vector3(-1.65,0.70,-2.85),Vector3(0.62,1.20,0.55),Color(0.26,0.20,0.18),0.35)
		_upgrade_prop(upgrade_visual_root,Vector3(-1.65,0.28,-2.48),Vector3(0.18,0.18,0.45),Color(0.42,0.22,0.20),0.2)
	if upgrades.get("sleep_pad",false):
		_upgrade_prop(upgrade_visual_root,Vector3(1.20,0.16,-2.35),Vector3(1.30,0.10,0.82),Color(0.20,0.24,0.28),0.05)
	if upgrades.get("enrichment_screen",false):
		var es = _upgrade_prop(upgrade_visual_root,Vector3(-1.65,1.45,-3.95),Vector3(0.78,0.48,0.08),Color(0.08,0.10,0.18),0.3)
		var ep = _upgrade_prop(upgrade_visual_root,Vector3(-1.65,1.45,-3.89),Vector3(0.62,0.34,0.02),Color(0.24,0.30,0.88),0.08)
		_set_emissive(ep,Color(0.15,0.20,0.80),1.2)
	if upgrades.get("reinforced_filter",false):
		_upgrade_prop(upgrade_visual_root,Vector3(3.82,0.55,-3.78),Vector3(1.42,0.10,0.07),Color(0.34,0.48,0.34),0.55)
	if upgrades.get("blackout_lamp",false):
		var lamp = _upgrade_prop(upgrade_visual_root,Vector3(0.0,3.55,3.90),Vector3(0.65,0.12,0.28),Color(0.42,0.20,0.06),0.2)
		_set_emissive(lamp,Color(1.0,0.34,0.06),0.8)

	if upgrades.get("auto_enrichment",false):
		var ae = _upgrade_prop(upgrade_visual_root,Vector3(-2.35,1.82,8.12),Vector3(0.50,0.34,0.10),Color(0.18,0.30,0.72),0.25)
		_set_emissive(ae,Color(0.12,0.22,0.86),1.0)
	if upgrades.get("auto_filter",false):
		_upgrade_prop(upgrade_visual_root,Vector3(2.35,1.76,8.12),Vector3(0.50,0.48,0.18),Color(0.16,0.38,0.24),0.45)
	if upgrades.get("remote_diagnostics",false):
		var rd = _upgrade_prop(upgrade_visual_root,Vector3(0.0,2.90,9.48),Vector3(0.90,0.38,0.10),Color(0.08,0.18,0.28),0.35)
		_set_emissive(rd,Color(0.06,0.42,0.90),1.25)
