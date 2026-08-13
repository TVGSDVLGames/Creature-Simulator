extends CogitoStaticInteractable

var pet = null
var wobble_seed := 0.0
var flies: Array[MeshInstance3D] = []
var variant := 0

func _ready():
	super._ready()
	add_to_group("waste")
	wobble_seed = randf()*10.0
	variant = randi()%3
	_build_visual()

func _build_visual():
	var colors = [Color(0.30,0.56,0.07),Color(0.48,0.30,0.055),Color(0.12,0.43,0.36)]
	var mat = StandardMaterial3D.new()
	mat.albedo_color = colors[variant]
	mat.roughness = 0.18
	mat.emission_enabled = true
	mat.emission = colors[variant] * 0.20
	mat.emission_energy_multiplier = 0.55
	var mesh_node = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = 0.44 + variant*0.025
	mesh.height = 0.28 + variant*0.035
	mesh.radial_segments = 22
	mesh.rings = 8
	mesh_node.mesh = mesh
	mesh_node.scale = Vector3(1.48,0.46+variant*0.05,1.12)
	mesh_node.material_override = mat
	add_child(mesh_node)
	var shape_node = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.56
	shape_node.shape = shape
	shape_node.scale = Vector3(1.28,0.44,1.05)
	add_child(shape_node)
	for i in range(4+variant):
		var bubble = MeshInstance3D.new()
		var bm = SphereMesh.new()
		bm.radius = 0.065+randf()*0.045
		bm.height = bm.radius*2.0
		bubble.mesh = bm
		bubble.position = Vector3(randf_range(-0.34,0.34),0.11+randf()*0.07,randf_range(-0.26,0.26))
		bubble.material_override = mat
		add_child(bubble)
	for i in range(2):
		var fly = MeshInstance3D.new()
		var fm = SphereMesh.new()
		fm.radius = 0.018
		fm.height = 0.036
		fly.mesh = fm
		var fmat = StandardMaterial3D.new()
		fmat.albedo_color = Color(0.015,0.012,0.01)
		fly.material_override = fmat
		add_child(fly)
		flies.append(fly)

func _process(delta):
	rotation.y += delta*0.05
	var t = Time.get_ticks_msec()*0.001+wobble_seed
	var m = get_child(0)
	if m is MeshInstance3D:
		m.scale.y = 0.35+variant*0.05+sin(t*2.0)*0.028
	for i in range(flies.size()):
		flies[i].position = Vector3(cos(t*(2.3+i*0.6)+i*PI)*0.43,0.34+sin(t*3.1+i)*0.10,sin(t*(2.3+i*0.6)+i*PI)*0.38)

func get_cogito_prompt(player):
	if player.held_item == "cleaner":
		return "Scrub up the biological incident"
	if player.held_item == "food":
		return "Do NOT use MEAT MUSH on the biological incident"
	if player.held_item != "":
		return "Put away %s and get the BIO-SCRUBBER" % player.held_item.replace("_"," ").to_upper()
	return "Biological incident — get the BIO-SCRUBBER"

func on_cogito_interact(player):
	if player.held_item == "food":
		player.show_message("That is Gloop's food. This is very much not Gloop's food.")
		return
	if player.held_item != "cleaner":
		player.show_message("That tool cannot clean this. Get the bio-scrubber.")
		return
	player.show_message("SCHLORP. Mostly clean.")
	var root = get_parent()
	if root and root.has_method("play_sfx"): root.play_sfx("scrub",global_position,true)
	if is_instance_valid(pet) and pet.has_method("waste_cleaned"):
		pet.waste_cleaned()
	if root and root.game:
		root.game.on_waste_cleaned()
	queue_free()
