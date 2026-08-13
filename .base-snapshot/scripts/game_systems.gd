extends Node
class_name GloopGameSystems

const MAX_SHIFTS := 20
const SHIFT_LENGTH := 210.0
const SHOP_PAGE_SIZE := 6
const LOG_PAGE_SIZE := 5

var root: Node3D
var player: Node
var pet: Node
var shift := 1
var credits := 50
var shift_time := 0.0
var stable_time := 0.0
var shift_active := false
var shift_complete := false
var last_score := 0
var last_pay := 0
var upgrades := {
	"better_mush":false, "toy":false, "heater":false, "auto_scrubber":false, "soft_lights":false,
	"reinforced_filter":false, "emergency_battery":false, "health_monitor":false, "deluxe_bowl":false,
	"odor_neutralizer":false, "quiet_fan":false, "sleep_pad":false, "enrichment_screen":false,
	"auto_feeder":false, "med_dispenser":false, "sample_analyzer":false, "incident_alarm":false,
	"trust_treats":false, "floor_sealant":false, "blackout_lamp":false,
	"auto_enrichment":false, "auto_filter":false, "remote_diagnostics":false
}
var stock := {"medicine":1, "filter":1, "vial":2, "toy_chew":0}
var shop_items: Array = []
var shop_page := 0
var shop_buttons: Array[Button] = []
var shop_page_label: Label
var log_catalog := {}
var log_unlocked: Array = []
var log_panel: Control
var log_text: Label
var log_page_label: Label
var log_page := 0
var last_logged_behavior := ""
var total_samples := 0
var total_waste_cleaned := 0
var total_feeds := 0
var dialogue_flags := {}
var incidents_seen := []
var incident_count := 0
var active_incident := ""
var incident_timer := 0.0
var next_incident_at := 36.0
var feeder_jammed := false
var cold_snap := false
var biofilter_clogged := false
var inspection_active := false
var simulation_active := false
var title_open := false
var menu_open := false
var dialogue_open := false
var test_mode := false
var save_path := "user://gloop_save.cfg"
var settings_path := "user://gloop_settings.cfg"
var automation_state := {"feeder":true,"scrubber":true,"enrichment":true,"filter":true}
var auto_feed_cooldown := 8.0
var auto_enrich_cooldown := 18.0
var auto_filter_cooldown := 0.0
var growth_stage := 0
var mutation_path := "baseline"
var tutorial_step := 0
var tutorial_complete := false
var tutorial_waste_spawned := false
var tutorial_log_seen := false
var ea_complete := false
var sandbox_mode := false

var canvas: CanvasLayer
var credits_label: Label
var behavior_label: Label
var incident_label: Label
var title_panel: Control
var pause_panel: Control
var summary_panel: Control
var shop_panel: Control
var dialogue_panel: Control
var options_panel: Control
var summary_text: Label
var shop_credits: Label
var dialogue_text: Label
var dialogue_response: Label
var dialogue_buttons: Array[Button] = []
var title_continue: Button
var invert_button: Button
var sensitivity_label: Label
var sensitivity_slider: HSlider
var tutorial_label: Label
var automation_panel: Control
var automation_status: Label
var automation_buttons: Array[Button] = []
var ending_panel: Control
var ending_text: Label
var look_inverted := false
var look_sensitivity := 2.0
var options_return := "title"
var rng := RandomNumberGenerator.new()
var release: Node = null

func _init_depth_data() -> void:
	shop_items = [
		{"id":"better_mush","name":"FORTIFIED MEAT MUSH","cost":35,"kind":"upgrade","desc":"Feeding removes substantially more hunger."},
		{"id":"toy","name":"ENRICHMENT TOY LICENSE","cost":30,"kind":"upgrade","desc":"Unlocks physical chew-ring play and stronger petting."},
		{"id":"heater","name":"HABITAT HEATER","cost":45,"kind":"upgrade","desc":"Protects mood during cold incidents."},
		{"id":"auto_scrubber","name":"PASSIVE FLOOR SCRUBBER","cost":60,"kind":"upgrade","desc":"Slowly reduces habitat filth."},
		{"id":"soft_lights","name":"SOFT-LIGHT BALLAST","cost":25,"kind":"upgrade","desc":"Reduces environmental stress."},
		{"id":"reinforced_filter","name":"REINFORCED BIOFILTER","cost":50,"kind":"upgrade","desc":"Biofilter clogs build grime more slowly."},
		{"id":"emergency_battery","name":"EMERGENCY BATTERY","cost":55,"kind":"upgrade","desc":"Power failures no longer plunge the room fully dark."},
		{"id":"health_monitor","name":"CONTINUOUS HEALTH MONITOR","cost":65,"kind":"upgrade","desc":"Adds passive health recovery when Gloop is stable."},
		{"id":"deluxe_bowl","name":"DEEP FEEDING BASIN","cost":40,"kind":"upgrade","desc":"Food bowl capacity increases from 3 to 5 portions."},
		{"id":"odor_neutralizer","name":"ODOR NEUTRALIZER","cost":50,"kind":"upgrade","desc":"Slows normal grime accumulation."},
		{"id":"quiet_fan","name":"QUIET VENT FAN","cost":35,"kind":"upgrade","desc":"Further reduces stress and room agitation."},
		{"id":"sleep_pad","name":"THERMAL SLEEP PAD","cost":45,"kind":"upgrade","desc":"Gloop gets tired more slowly."},
		{"id":"enrichment_screen","name":"ENRICHMENT DISPLAY","cost":55,"kind":"upgrade","desc":"Boredom rises more slowly."},
		{"id":"auto_feeder","name":"MICRO AUTO-FEEDER","cost":80,"kind":"upgrade","desc":"Slows hunger accumulation between feedings."},
		{"id":"med_dispenser","name":"CALIBRATED MED DISPENSER","cost":60,"kind":"upgrade","desc":"Medicine restores substantially more health."},
		{"id":"sample_analyzer","name":"SAMPLE ANALYZER","cost":50,"kind":"upgrade","desc":"Biological samples pay a larger research bonus."},
		{"id":"incident_alarm","name":"EARLY INCIDENT ALARM","cost":45,"kind":"upgrade","desc":"Adds time to incident response windows."},
		{"id":"trust_treats","name":"TRUST CONDITIONING TREATS","cost":70,"kind":"upgrade","desc":"Care interactions build trust faster."},
		{"id":"floor_sealant","name":"BIO-RESISTANT FLOOR SEALANT","cost":50,"kind":"upgrade","desc":"Fresh waste adds less filth."},
		{"id":"blackout_lamp","name":"BLACKOUT TASK LAMP","cost":35,"kind":"upgrade","desc":"Reduces stress during full blackout events."},
		{"id":"auto_enrichment","name":"AUTO-ENRICHMENT ARM","cost":95,"kind":"upgrade","desc":"Annex automation can consume enrichment rings when boredom gets dangerous."},
		{"id":"auto_filter","name":"AUTOMATIC FILTER SWAP","cost":110,"kind":"upgrade","desc":"Annex automation can consume a spare cartridge to clear biofilter incidents."},
		{"id":"remote_diagnostics","name":"REMOTE DIAGNOSTIC LINK","cost":90,"kind":"upgrade","desc":"Sensor faults resolve automatically and growth analysis becomes more precise."},
		{"id":"medicine","name":"MEDICINE REFILL x2","cost":18,"kind":"stock","amount":2,"desc":"Two single-use injector doses."},
		{"id":"filter","name":"BIOFILTER PACK x2","cost":16,"kind":"stock","amount":2,"desc":"Two replacement wall cartridges."},
		{"id":"vial","name":"STERILE VIAL PACK x3","cost":12,"kind":"stock","amount":3,"desc":"Three sample collection vials."},
		{"id":"toy_chew","name":"ENRICHMENT RINGS x3","cost":15,"kind":"stock","amount":3,"desc":"Three disposable play rings. Requires toy license."}
	]
	log_catalog = {
		"care_feed":["CARE","Direct feeding","Gloop will accept meat mush directly from the scoop."],
		"care_pet":["CARE","Physical contact","Gentle contact improves mood and, slowly, trust."],
		"care_medicine":["CARE","Medication","Single-use injectors restore health but annoy the specimen."],
		"care_sample":["CARE","Biological sampling","Calm specimens can be sampled for a research bonus."],
		"care_play":["CARE","Enrichment play","Disposable rings dramatically reduce boredom."],
		"care_scan":["CARE","Diagnostic scanning","The hand scanner reports health, hunger and behavior state."],
		"care_clean":["CARE","Sanitation","Biological incidents must be scrubbed before they compound habitat filth."],
		"state_curious":["BEHAVIOR","Curious","Baseline attentive behavior."],
		"state_hungry":["BEHAVIOR","Hungry","Food-seeking attention becomes obvious."],
		"state_ravenous":["BEHAVIOR","Ravenous","Critical hunger. Keep fingers clear."],
		"state_sick":["BEHAVIOR","Sick","Critical health state."],
		"state_feverish":["BEHAVIOR","Feverish","Moderate health impairment; medication is recommended."],
		"state_sleeping":["BEHAVIOR","Sleeping","Extreme sleepiness suppresses normal activity."],
		"state_angry":["BEHAVIOR","Angry","Very low mood produces aggressive body language."],
		"state_distressed":["BEHAVIOR","Distressed","Extreme grime produces visible stress."],
		"state_restless":["BEHAVIOR","Restless","Severe boredom; enrichment is overdue."],
		"state_guarded":["BEHAVIOR","Guarded","Low trust. Gloop watches the handler's hands."],
		"state_drowsy":["BEHAVIOR","Drowsy","Sleep pressure is becoming visible."],
		"state_playful":["BEHAVIOR","Playful","Low boredom and high mood produce mischievous play."],
		"state_clingy":["BEHAVIOR","Clingy","Very high trust makes separation difficult."],
		"state_affectionate":["BEHAVIOR","Affectionate","High-trust contact seeking."],
		"state_content":["BEHAVIOR","Content","All primary needs are comfortably controlled."],
		"incident_power":["INCIDENT","Power dip","Lighting bus failure; reset through OPS."],
		"incident_feeder":["INCIDENT","Feeder jam","Mush feeder locks until reset."],
		"incident_cold":["INCIDENT","Cold snap","Habitat temperature falls rapidly."],
		"incident_inspection":["INCIDENT","Surprise inspection","Management checks hunger, filth and mood."],
		"incident_biofilter":["INCIDENT","Biofilter clog","Requires a physical replacement cartridge."],
		"incident_fever":["INCIDENT","Fever event","Requires medicine administered directly to Gloop."],
		"incident_tantrum":["INCIDENT","Enrichment tantrum","Play with Gloop to settle the episode."],
		"incident_bad_batch":["INCIDENT","Bad food batch","Feeder is locked while contaminated stock is purged."],
		"incident_sensor_fault":["INCIDENT","Sensor disagreement","Confirm Gloop's condition with the hand scanner."],
		"incident_contamination":["INCIDENT","Containment contamination","Clean all biological incidents before clearing OPS."],
		"incident_blackout":["INCIDENT","Full blackout","Emergency lighting only until OPS reset."],
		"incident_noise":["INCIDENT","Ultrasonic noise","Vent hardware agitates the specimen."],
		"incident_sample_request":["INCIDENT","Research sample request","Collect a sample before the deadline."],
		"incident_overheat":["INCIDENT","Habitat overheat","Mood and health degrade until OPS reset."],
		"incident_transfer_audit":["INCIDENT","Transfer audit","Late-contract compliance audit with stricter targets."],
		"milestone_trust50":["MILESTONE","Handler recognized","Trust passed 50%. Gloop now clearly differentiates you from staff."],
		"milestone_samples5":["MILESTONE","Research contributor","Five viable samples collected."],
		"milestone_shift7":["MILESTONE","One week survived","Seven shifts completed without reassignment."],
		"milestone_shift14":["MILESTONE","Contract extension","Fourteen shifts logged. Management quietly extends the assignment."],
		"milestone_shift20":["MILESTONE","Early Access contract complete","Twenty shifts survived. The research annex now treats you as permanent staff."],
		"facility_annex":["FACILITY","Research Annex","Second-week clearance opens the connected research and automation room."],
		"facility_growth":["FACILITY","Growth analysis","The annex tracks Gloop's visible growth stage and mutation profile."],
		"automation_feeder":["AUTOMATION","Automatic feeding","Installed auto-feeder can portion mush into the bowl when hunger rises."],
		"automation_scrubber":["AUTOMATION","Passive sanitation","Installed scrubber can continuously suppress habitat grime."],
		"automation_enrichment":["AUTOMATION","Automatic enrichment","An annex arm can consume stocked rings when boredom becomes dangerous."],
		"automation_filter":["AUTOMATION","Automatic filter service","A stocked cartridge can be consumed automatically during a biofilter clog."],
		"mutation_social":["MUTATION","Social adaptation","High trust produces longer crown tendrils and warmer facial pigmentation."],
		"mutation_defensive":["MUTATION","Defensive adaptation","Low trust produces darker neck frills and denser protective growths."],
		"mutation_late":["MUTATION","Mature sensory growth","Late-contract sensory structures emerge around the scalp and jaw." ]
	}

func setup(root_node: Node3D, player_node: Node, pet_node: Node) -> void:
	root = root_node
	player = player_node
	pet = pet_node
	process_mode = Node.PROCESS_MODE_ALWAYS
	rng.randomize()
	_init_depth_data()
	_ensure_input_actions()
	_build_ui()
	_load_settings()
	_apply_look_settings()
	release = load("res://scripts/release_manager.gd").new()
	release.name = "ReleaseManager"
	add_child(release)
	release.setup(self, root, player, pet, canvas)
	# Migration may have copied legacy look settings into the renamed user-data folder.
	_load_settings()
	_apply_look_settings()
	_apply_upgrades()
	var args = OS.get_cmdline_user_args()
	if "--filthpause-test" in args:
		test_mode = true
		save_path = "user://gloop_filthpause_test.cfg"
		_start_new_game(false)
		call_deferred("_run_filthpause_test")
	elif "--newplayer-test" in args:
		test_mode = true
		save_path = "user://gloop_newplayer_test.cfg"
		_start_new_game(false)
		call_deferred("_run_newplayer_test")
	elif "--controllerfix-test" in args:
		test_mode = true
		save_path = "user://gloop_controllerfix_test.cfg"
		_start_new_game(false)
		call_deferred("_run_controllerfix_test")
	elif "--passc-test" in args:
		test_mode = true
		save_path = "user://gloop_passc_test.cfg"
		_start_new_game(false)
		call_deferred("_run_passc_test")
	elif "--fullgame-test" in args or "--passb-test" in args:
		test_mode = true
		save_path = "user://gloop_passb_test.cfg"
		_start_new_game(false)
		call_deferred("_run_self_test")
	elif "--preview-filth" in args:
		_start_new_game(false)
		tutorial_complete = true
		shift = 2
		_start_shift()
		root.spawn_waste(Vector3(-0.9,0,-0.3),pet)
		root.spawn_waste(Vector3(0.9,0,-0.3),pet)
		player.position = Vector3(0,0.05,2.55)
	elif "--preview-passc-settings" in args:
		_start_new_game(false)
		call_deferred("_preview_passc_settings")
	elif "--preview-passc-achievements" in args:
		_start_new_game(false)
		shift=10; pet.trust=60.0; total_samples=5; total_waste_cleaned=25; growth_stage=2; mutation_path="social"
		for id in log_catalog.keys():
			if log_unlocked.size()<25: log_unlocked.append(id)
		incidents_seen=["power","feeder","cold","biofilter","inspection","fever","tantrum","bad_batch","sensor_fault","contamination"]
		for k in ["auto_feeder","auto_scrubber","auto_enrichment","auto_filter"]: upgrades[k]=true
		release._check_achievements()
		call_deferred("_preview_passc_achievements")
	elif "--preview-passb" in args:
		_start_new_game(false)
		shift=10; credits=850; tutorial_complete=true; mutation_path="social"
		for id in ["auto_feeder","auto_scrubber","auto_enrichment","auto_filter","health_monitor","enrichment_screen","soft_lights"]: upgrades[id]=true
		stock["toy_chew"]=4; stock["filter"]=4; _apply_upgrades(); _start_shift(); player.position=Vector3(0,0.05,9.45)
	elif "--skip-title" in args:
		_start_new_game(false)
	else:
		_show_title()

func _preview_passc_settings() -> void:
	if release != null: release.open_advanced()

func _preview_passc_achievements() -> void:
	if release != null: release.open_achievements()

func _process(delta: float) -> void:
	if not simulation_active or shift_complete:
		if root and root.has_method("clear_objective_guidance"): root.clear_objective_guidance()
		_update_labels(); return
	if not is_instance_valid(pet): return
	var training_active := shift == 1 and not tutorial_complete
	# First-time handler training is untimed. Players should learn the room without
	# losing care score or burning half of Shift 1 while figuring out controls.
	if not training_active:
		shift_time += delta
		if pet.hunger < 72.0 and pet.grime < 72.0 and pet.happiness > 30.0 and pet.health > 35.0 and pet.boredom < 90.0:
			stable_time += delta
	_run_automation(delta)
	_update_tutorial()
	_update_objective_guidance()
	if upgrades["heater"]: pet.happiness = min(100.0, pet.happiness + delta * 0.018)
	if active_incident != "":
		incident_timer -= delta
		match active_incident:
			"cold": pet.happiness = max(0.0,pet.happiness - delta * (0.18 if not upgrades["heater"] else 0.035))
			"biofilter": pet.grime = min(100.0,pet.grime + delta * (0.055 if upgrades["reinforced_filter"] else 0.13))
			"fever": pet.health = max(0.0,pet.health - delta * 0.16)
			"tantrum":
				pet.happiness = max(0.0,pet.happiness - delta * 0.12); pet.boredom = min(100.0,pet.boredom + delta * 0.20)
			"noise": pet.happiness = max(0.0,pet.happiness - delta * 0.15 * pet.stress_resistance)
			"contamination": pet.grime = min(100.0,pet.grime + delta * 0.16)
			"overheat":
				pet.happiness = max(0.0,pet.happiness - delta * 0.15); pet.health = max(0.0,pet.health - delta * 0.06)
			"blackout": pet.happiness = max(0.0,pet.happiness - delta * (0.035 if upgrades["blackout_lamp"] else 0.10) * pet.stress_resistance)
		if active_incident in ["inspection","transfer_audit"] and incident_timer <= 0.0:
			_finish_inspection(active_incident == "transfer_audit")
		elif incident_timer <= 0.0:
			credits = max(0,credits-10); pet.happiness = max(0.0,pet.happiness-7.0)
			_clear_incident("Management remotely intervened. -$10 service fee.")
	var incident_max = 2 if shift <= 4 else 3
	if active_incident == "" and incident_count < incident_max and shift_time >= next_incident_at and (tutorial_complete or shift > 1):
		_start_random_incident()
	if shift_time >= 10.0 and (tutorial_complete or shift > 1) and not dialogue_flags.get("shift_%d_intro" % shift,false) and not menu_open and active_incident == "":
		dialogue_flags["shift_%d_intro" % shift] = true; _start_shift_dialogue()
	if pet.trust >= 50.0: unlock_log("milestone_trust50",false)
	if not training_active and shift_time >= SHIFT_LENGTH: _complete_shift()
	_update_labels()

func _unhandled_input(event: InputEvent) -> void:
	# Explicit controller UI handling. Godot's default UI mappings vary by platform
	# and controller database, so A/Cross and Start both activate the highlighted
	# choice while B/Circle backs out of menus.
	if event is InputEventJoypadButton and event.pressed and (menu_open or dialogue_open or title_open):
		if event.button_index in [JOY_BUTTON_A, JOY_BUTTON_START]:
			if _activate_focused_control():
				get_viewport().set_input_as_handled()
				return
		elif event.button_index == JOY_BUTTON_B:
			if _controller_back():
				get_viewport().set_input_as_handled()
				return

	if event.is_action_pressed("pause_game") and not title_open and not dialogue_open:
		if menu_open:
			_close_all_menus()
		else:
			_open_pause()
		get_viewport().set_input_as_handled()

func _activate_focused_control() -> bool:
	var focus = get_viewport().gui_get_focus_owner()
	if focus is BaseButton:
		var b := focus as BaseButton
		if not b.disabled and b.visible:
			b.emit_signal("pressed")
			return true
	return false

func _controller_back() -> bool:
	if release != null and release.has_method("has_open_panel") and release.has_open_panel():
		release.handle_back()
		return true
	if dialogue_open:
		var close_b = dialogue_panel.find_child("DialogueClose",true,false)
		if close_b and close_b.visible:
			_close_dialogue()
			return true
		return false
	if options_panel and options_panel.visible:
		_close_options(); return true
	if shop_panel and shop_panel.visible:
		_close_shop_return(); return true
	if log_panel and log_panel.visible:
		_close_log_return(); return true
	if automation_panel and automation_panel.visible:
		_close_all_menus(); return true
	if pause_panel and pause_panel.visible:
		_close_all_menus(); return true
	return false

func _ensure_input_actions() -> void:
	_ensure_key_action("pause_game",KEY_ESCAPE)
	_ensure_joy_button("pause_game",JOY_BUTTON_START)
	# Make controller menu behavior deterministic on Xbox/PlayStation-style pads.
	_ensure_joy_button("ui_accept",JOY_BUTTON_A)
	_ensure_joy_button("ui_cancel",JOY_BUTTON_B)
	_ensure_joy_button("ui_up",JOY_BUTTON_DPAD_UP)
	_ensure_joy_button("ui_down",JOY_BUTTON_DPAD_DOWN)
	_ensure_joy_button("ui_left",JOY_BUTTON_DPAD_LEFT)
	_ensure_joy_button("ui_right",JOY_BUTTON_DPAD_RIGHT)
	_ensure_joy_axis("ui_up",JOY_AXIS_LEFT_Y,-1.0)
	_ensure_joy_axis("ui_down",JOY_AXIS_LEFT_Y,1.0)
	_ensure_joy_axis("ui_left",JOY_AXIS_LEFT_X,-1.0)
	_ensure_joy_axis("ui_right",JOY_AXIS_LEFT_X,1.0)

func _ensure_key_action(action: String, code: Key) -> void:
	if not InputMap.has_action(action): InputMap.add_action(action)
	for e in InputMap.action_get_events(action):
		if e is InputEventKey and (e.keycode == code or e.physical_keycode == code): return
	var key = InputEventKey.new(); key.keycode = code; InputMap.action_add_event(action,key)

func _ensure_joy_button(action: String, button: JoyButton) -> void:
	if not InputMap.has_action(action): InputMap.add_action(action)
	for e in InputMap.action_get_events(action):
		if e is InputEventJoypadButton and e.button_index == button: return
	var pad = InputEventJoypadButton.new(); pad.button_index = button; InputMap.action_add_event(action,pad)

func _ensure_joy_axis(action: String, axis: JoyAxis, value: float) -> void:
	if not InputMap.has_action(action): InputMap.add_action(action)
	for e in InputMap.action_get_events(action):
		if e is InputEventJoypadMotion and e.axis == axis and sign(e.axis_value) == sign(value): return
	var motion = InputEventJoypadMotion.new(); motion.axis = axis; motion.axis_value = value; InputMap.action_add_event(action,motion)

func _panel(parent: Node, rect: Rect2, color := Color(0.008,0.014,0.013,0.95)) -> ColorRect:
	var p = ColorRect.new()
	p.position = rect.position
	p.size = rect.size
	p.color = color
	parent.add_child(p)
	return p

func _label(parent: Node, pos: Vector2, text_: String, size_: int, dims := Vector2.ZERO) -> Label:
	var l = Label.new()
	l.position = pos
	l.text = text_
	l.add_theme_font_size_override("font_size", size_)
	if dims != Vector2.ZERO:
		l.size = dims
	parent.add_child(l)
	return l

func _button(parent: Node, pos: Vector2, text_: String, width := 320.0) -> Button:
	var b = Button.new()
	b.position = pos
	b.size = Vector2(width, 44)
	b.text = text_
	b.add_theme_font_size_override("font_size", 17)
	parent.add_child(b)
	return b

func _build_ui() -> void:
	canvas = CanvasLayer.new()
	canvas.layer = 50
	add_child(canvas)
	credits_label = _label(canvas, Vector2(930,77), "CREDITS $50", 14, Vector2(320,24))
	credits_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	credits_label.modulate = Color(0.92,0.82,0.52)
	behavior_label = _label(canvas, Vector2(930,98), "GLOOP: CURIOUS", 12, Vector2(320,22))
	behavior_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	behavior_label.modulate = Color(0.60,0.86,0.77)
	incident_label = _label(canvas, Vector2(330,84), "", 15, Vector2(620,28))
	incident_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	incident_label.modulate = Color(1.0,0.55,0.28)

	_build_title_ui()
	_build_pause_ui()
	_build_summary_ui()
	_build_shop_ui()
	_build_log_ui()
	_build_dialogue_ui()
	_build_options_ui()
	_build_automation_ui()
	_build_ending_ui()
	tutorial_label = _label(canvas,Vector2(300,118),"",14,Vector2(680,52))
	tutorial_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tutorial_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_label.modulate = Color(0.95,0.88,0.55)

func _make_modal() -> Control:
	var c = Control.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	c.hide()
	canvas.add_child(c)
	var dim = ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0,0,0,0.76)
	c.add_child(dim)
	return c

func _build_title_ui() -> void:
	title_panel = _make_modal()
	var p = _panel(title_panel, Rect2(360,120,560,470), Color(0.008,0.016,0.014,0.98))
	var title = _label(p, Vector2(30,34), "SPECIMEN CARE", 38, Vector2(500,55))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color(0.67,1.0,0.78)
	var sub = _label(p, Vector2(30,92), "GLOOP // EMPLOYEE ACCESS BUILD", 15, Vector2(500,28))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.modulate = Color(0.55,0.64,0.59)
	var new_b = _button(p, Vector2(120,165), "NEW CARE FILE")
	new_b.pressed.connect(func(): _start_new_game(true))
	title_continue = _button(p, Vector2(120,220), "CONTINUE")
	title_continue.pressed.connect(_continue_game)
	var controls_b = _button(p, Vector2(120,275), "OPTIONS / CONTROLS")
	controls_b.pressed.connect(_open_options)
	var quit_b = _button(p, Vector2(120,330), "QUIT")
	quit_b.pressed.connect(func(): get_tree().quit())
	var note = _label(p, Vector2(70,400), "Twenty shifts. Unlock the research annex. Grow the habitat. Do not discuss its speech with management.", 13, Vector2(420,45))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	new_b.focus_neighbor_bottom = title_continue.get_path()

func _build_pause_ui() -> void:
	pause_panel = _make_modal()
	var p = _panel(pause_panel, Rect2(430,105,420,525))
	var t = _label(p, Vector2(40,25), "SHIFT PAUSED", 29, Vector2(340,45))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var resume = _button(p, Vector2(50,85), "RESUME", 320)
	resume.pressed.connect(_close_all_menus)
	var shop = _button(p, Vector2(50,140), "REQUISITIONS / SHOP", 320)
	shop.pressed.connect(_open_shop)
	var log_b = _button(p, Vector2(50,195), "SPECIMEN LOG", 320)
	log_b.pressed.connect(open_specimen_log)
	var options_b = _button(p, Vector2(50,250), "OPTIONS / CONTROLS", 320)
	options_b.pressed.connect(_open_options)
	var save_b = _button(p, Vector2(50,305), "SAVE CARE FILE", 320)
	save_b.pressed.connect(func(): save_game(); _toast("Care file saved."))
	var title_b = _button(p, Vector2(50,360), "SAVE & TITLE", 320)
	title_b.pressed.connect(func(): save_game(); _show_title())
	var note = _label(p, Vector2(50,425), "Pass B: 20-shift contract • annex • automation • growth • specimen discoveries", 12, Vector2(320,55))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _build_summary_ui() -> void:
	summary_panel = _make_modal()
	var p = _panel(summary_panel, Rect2(350,95,580,545))
	var t = _label(p, Vector2(35,25), "CARE SHIFT COMPLETE", 29, Vector2(510,42))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary_text = _label(p, Vector2(65,82), "", 17, Vector2(450,205))
	summary_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var shop_b = _button(p, Vector2(130,305), "SPEND PAY / SHOP")
	shop_b.pressed.connect(_open_shop)
	var log_b = _button(p, Vector2(130,360), "REVIEW SPECIMEN LOG")
	log_b.pressed.connect(open_specimen_log)
	var next_b = _button(p, Vector2(130,415), "START NEXT SHIFT")
	next_b.pressed.connect(_next_shift)
	var save_b = _button(p, Vector2(130,470), "SAVE CARE FILE")
	save_b.pressed.connect(func(): save_game(); _toast("Care file saved."))

func _build_shop_ui() -> void:
	shop_panel = _make_modal()
	var p = _panel(shop_panel, Rect2(225,55,830,625))
	var t = _label(p, Vector2(35,20), "BIOLOGICAL REQUISITIONS", 28, Vector2(760,40))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_credits = _label(p, Vector2(35,60), "CREDITS", 17, Vector2(760,26))
	shop_credits.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_page_label = _label(p, Vector2(35,88), "", 13, Vector2(760,22))
	shop_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_page_label.modulate = Color(0.60,0.70,0.65)
	shop_buttons.clear()
	for i in range(SHOP_PAGE_SIZE):
		var b = _button(p, Vector2(55,120 + i*68), "...", 455)
		b.pressed.connect(_buy_shop_slot.bind(i))
		shop_buttons.append(b)
		var d = _label(p, Vector2(530,125 + i*68), "", 12, Vector2(240,45))
		d.name = "ShopDesc%d" % i
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.modulate = Color(0.64,0.70,0.67)
	var prev = _button(p, Vector2(55,545), "◀ PREV", 180)
	prev.name = "ShopPrev"; prev.pressed.connect(_shop_prev)
	var next = _button(p, Vector2(245,545), "NEXT ▶", 180)
	next.name = "ShopNext"; next.pressed.connect(_shop_next)
	var close_b = _button(p, Vector2(500,545), "BACK", 270)
	close_b.pressed.connect(_close_shop_return)

func _build_log_ui() -> void:
	log_panel = _make_modal()
	var p = _panel(log_panel, Rect2(245,65,790,590), Color(0.008,0.014,0.018,0.98))
	var t = _label(p, Vector2(30,20), "SPECIMEN 07 // FIELD LOG", 27, Vector2(730,38))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	log_page_label = _label(p, Vector2(30,62), "", 13, Vector2(730,24))
	log_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	log_page_label.modulate = Color(0.55,0.72,0.78)
	log_text = _label(p, Vector2(55,100), "", 15, Vector2(680,380))
	log_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var prev = _button(p, Vector2(55,510), "◀ PREV", 180)
	prev.name = "LogPrev"; prev.pressed.connect(_log_prev)
	var next = _button(p, Vector2(245,510), "NEXT ▶", 180)
	next.name = "LogNext"; next.pressed.connect(_log_next)
	var back = _button(p, Vector2(500,510), "BACK", 235)
	back.pressed.connect(_close_log_return)

func open_specimen_log() -> void:
	tutorial_log_seen = true
	_hide_modals()
	menu_open = true
	simulation_active = false
	_set_gameplay_enabled(false)
	log_panel.show()
	_refresh_log()
	var buttons = log_panel.find_children("","Button",true,false)
	if buttons.size() > 0: buttons[0].grab_focus()

func _refresh_log() -> void:
	var ordered: Array = log_unlocked.duplicate()
	ordered.sort()
	var pages = max(1, int(ceil(float(max(1,ordered.size())) / LOG_PAGE_SIZE)))
	log_page = clamp(log_page,0,pages-1)
	log_page_label.text = "DISCOVERED %d / %d   •   PAGE %d / %d" % [ordered.size(),log_catalog.size(),log_page+1,pages]
	var lines: Array[String] = []
	if ordered.is_empty():
		lines.append("NO VERIFIED ENTRIES. Interact with Gloop, use care equipment, and survive incidents to populate the file.")
	else:
		var start = log_page * LOG_PAGE_SIZE
		for i in range(start,min(start+LOG_PAGE_SIZE,ordered.size())):
			var id = ordered[i]
			var e = log_catalog.get(id,["UNKNOWN",id,"No description."])
			lines.append("[%s]  %s\n%s" % [e[0],e[1],e[2]])
	log_text.text = "\n\n".join(lines)
	var prev = log_panel.find_child("LogPrev",true,false); var next = log_panel.find_child("LogNext",true,false)
	if prev: prev.disabled = log_page <= 0
	if next: next.disabled = log_page >= pages-1

func _log_prev() -> void:
	log_page = max(0,log_page-1); _refresh_log()
func _log_next() -> void:
	log_page += 1; _refresh_log()
func _close_log_return() -> void:
	if shift_complete: _show_summary()
	elif title_open: _show_title()
	else: _close_all_menus()

func _build_dialogue_ui() -> void:
	dialogue_panel = _make_modal()
	var p = _panel(dialogue_panel, Rect2(230,335,820,330), Color(0.012,0.016,0.015,0.98))
	var speaker = _label(p, Vector2(30,20), "GLOOP", 20, Vector2(760,30))
	speaker.modulate = Color(0.70,0.96,0.78)
	dialogue_text = _label(p, Vector2(30,58), "", 18, Vector2(760,80))
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_response = _label(p, Vector2(30,140), "", 14, Vector2(760,35))
	dialogue_response.modulate = Color(0.92,0.77,0.48)
	for i in range(3):
		var b = _button(p, Vector2(30 + i * 255,195), "...", 245)
		b.pressed.connect(_choose_dialogue.bind(i))
		dialogue_buttons.append(b)
	var close_b = _button(p, Vector2(250,260), "CONTINUE SHIFT", 320)
	close_b.name = "DialogueClose"
	close_b.hide()
	close_b.pressed.connect(_close_dialogue)
	var hint = _label(p, Vector2(175,305), "A / CROSS or START / OPTIONS: SELECT   •   B / CIRCLE: BACK", 11, Vector2(470,20))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.modulate = Color(0.52,0.62,0.57)

func _build_options_ui() -> void:
	options_panel = _make_modal()
	var p = _panel(options_panel, Rect2(390,145,500,435))
	var t = _label(p, Vector2(35,25), "OPTIONS / CONTROLS", 28, Vector2(430,42))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	invert_button = _button(p, Vector2(90,105), "VERTICAL LOOK: NORMAL", 320)
	invert_button.pressed.connect(_toggle_invert)
	sensitivity_label = _label(p, Vector2(90,175), "LOOK SENSITIVITY: 2.0", 16, Vector2(320,28))
	sensitivity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sensitivity_slider = HSlider.new()
	sensitivity_slider.position = Vector2(90,210)
	sensitivity_slider.size = Vector2(320,32)
	sensitivity_slider.min_value = 0.8
	sensitivity_slider.max_value = 4.0
	sensitivity_slider.step = 0.1
	sensitivity_slider.value = look_sensitivity
	sensitivity_slider.value_changed.connect(_set_sensitivity)
	p.add_child(sensitivity_slider)
	var controls = _label(p, Vector2(65,270), "WASD / LEFT STICK  MOVE
MOUSE / RIGHT STICK  LOOK
E / A  USE     Q / B  DROP
ESC / START  PAUSE
A/CROSS or START  CONFIRM MENUS", 14, Vector2(370,125))
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.modulate = Color(0.68,0.75,0.71)
	var back = _button(p, Vector2(90,375), "BACK", 320)
	back.pressed.connect(_close_options)

func _build_automation_ui() -> void:
	automation_panel = _make_modal()
	var p = _panel(automation_panel,Rect2(350,100,580,520),Color(0.006,0.014,0.020,0.98))
	var t = _label(p,Vector2(35,24),"ANNEX AUTOMATION CONTROL",27,Vector2(510,40))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	automation_status = _label(p,Vector2(55,75),"",14,Vector2(470,70))
	automation_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	automation_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	automation_buttons.clear()
	for i in range(4):
		var b = _button(p,Vector2(100,160+i*58),"...",380)
		b.pressed.connect(_toggle_automation.bind(i))
		automation_buttons.append(b)
	var back = _button(p,Vector2(100,410),"RETURN TO ANNEX",380)
	back.pressed.connect(_close_all_menus)

func _build_ending_ui() -> void:
	ending_panel = _make_modal()
	var p = _panel(ending_panel,Rect2(315,90,650,550),Color(0.008,0.012,0.018,0.99))
	var t = _label(p,Vector2(35,28),"CURRENT EARLY ACCESS MILESTONE",28,Vector2(580,44))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.modulate = Color(0.65,0.90,1.0)
	ending_text = _label(p,Vector2(70,100),"",17,Vector2(510,270))
	ending_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ending_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var sandbox = _button(p,Vector2(135,395),"CONTINUE OPEN CARE / SANDBOX",380)
	sandbox.pressed.connect(_enter_sandbox)
	var title_b = _button(p,Vector2(135,455),"SAVE & RETURN TO TITLE",380)
	title_b.pressed.connect(func(): ea_complete=true; save_game(); _show_title())

func open_automation_panel() -> void:
	if shift < 8:
		_toast("Automation annex access begins during Shift 8.")
		return
	_hide_modals(); menu_open=true; simulation_active=false; _set_gameplay_enabled(false)
	automation_panel.show(); _refresh_automation()
	for b in automation_buttons:
		if not b.disabled: b.grab_focus(); break

func _refresh_automation() -> void:
	if automation_status == null: return
	automation_status.text = "AUTOMATION CONSUMES SUPPLIES WHEN REQUIRED.  CREDITS $%d  •  RINGS %d  •  FILTERS %d" % [credits,get_stock("toy_chew"),get_stock("filter")]
	var defs = [["feeder","AUTO FEEDER","auto_feeder"],["scrubber","FLOOR SCRUBBER","auto_scrubber"],["enrichment","ENRICHMENT ARM","auto_enrichment"],["filter","FILTER SWAP","auto_filter"]]
	for i in range(defs.size()):
		var d=defs[i]; var installed=upgrades.get(d[2],false); var enabled=automation_state.get(d[0],true)
		automation_buttons[i].text = "%s: %s" % [d[1],("ON" if enabled else "OFF") if installed else "NOT INSTALLED"]
		automation_buttons[i].disabled = not installed

func _toggle_automation(index: int) -> void:
	var ids=["feeder","scrubber","enrichment","filter"]
	if index<0 or index>=ids.size(): return
	var id=ids[index]; automation_state[id]=not bool(automation_state.get(id,true)); _refresh_automation(); save_game()

func _show_ea_ending() -> void:
	_hide_modals(); menu_open=true; simulation_active=false; _set_gameplay_enabled(false); ending_panel.show()
	ending_text.text = "TWENTY SHIFTS COMPLETE.\n\nManagement has classified Gloop as a long-term adaptive specimen. The Research Annex records a %s mutation profile and a handler-trust score of %d%%.\n\nA transfer order prints, then immediately retracts. Gloop looks toward the annex door and says: ‘I think they finally decided which one of us belongs here.’\n\nThis marks the end of the current authored Early Access progression. Open Care continues indefinitely with your upgrades, discoveries, incidents and automation intact." % [mutation_path.to_upper(),int(pet.trust)]
	unlock_log("milestone_shift20",false); ea_complete=true; save_game()
	var end_buttons = ending_panel.find_children("","Button",true,false)
	if end_buttons.size() > 0: end_buttons[0].grab_focus()

func _enter_sandbox() -> void:
	ea_complete=true; sandbox_mode=true; shift=MAX_SHIFTS; shift_time=0.0; stable_time=0.0; _start_shift(); save_game()

func _open_options() -> void:
	options_return = "title" if title_panel.visible else "pause"
	_hide_modals()
	menu_open = true
	simulation_active = false
	_set_gameplay_enabled(false)
	options_panel.show()
	_refresh_options()
	invert_button.grab_focus()

func _close_options() -> void:
	if options_return == "title":
		_show_title()
	else:
		_open_pause()

func _toggle_invert() -> void:
	look_inverted = not look_inverted
	_apply_look_settings()
	_refresh_options()
	_save_settings()

func _set_sensitivity(value: float) -> void:
	look_sensitivity = value
	_apply_look_settings()
	_refresh_options()
	_save_settings()

func _refresh_options() -> void:
	if invert_button:
		invert_button.text = "VERTICAL LOOK: %s" % ("INVERTED" if look_inverted else "NORMAL")
	if sensitivity_label:
		sensitivity_label.text = "LOOK SENSITIVITY: %.1f" % look_sensitivity
	if sensitivity_slider and abs(sensitivity_slider.value-look_sensitivity) > 0.01:
		sensitivity_slider.value = look_sensitivity

func _apply_look_settings() -> void:
	if not is_instance_valid(player): return
	var head = player.get_node_or_null("Head")
	if head:
		head.invert_y = look_inverted
		if head.has_method("set_look_sensitivity"):
			head.set_look_sensitivity(look_sensitivity)

func _show_title() -> void:
	_hide_modals()
	if release != null and release.has_method("hide_panels"): release.hide_panels()
	title_open = true
	menu_open = true
	simulation_active = false
	_set_gameplay_enabled(false)
	title_panel.show()
	title_continue.disabled = not (FileAccess.file_exists(save_path) or FileAccess.file_exists(save_path + ".bak"))
	var focus = title_continue if not title_continue.disabled else title_panel.find_children("","Button",true,false)[0]
	if focus is Button:
		focus.grab_focus()

func _start_new_game(clear_save := true) -> void:
	if clear_save:
		for old_path in [save_path, save_path + ".bak", save_path + ".tmp"]:
			if FileAccess.file_exists(old_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(old_path))
	shift = 1
	credits = 60
	for k in upgrades.keys(): upgrades[k] = false
	stock = {"medicine":1,"filter":1,"vial":2,"toy_chew":0}
	dialogue_flags.clear()
	incidents_seen.clear()
	log_unlocked.clear()
	total_samples = 0; total_waste_cleaned = 0; total_feeds = 0
	automation_state = {"feeder":true,"scrubber":true,"enrichment":true,"filter":true}
	growth_stage=0; mutation_path="baseline"; tutorial_step=0; tutorial_complete=false; tutorial_waste_spawned=false; tutorial_log_seen=false; ea_complete=false; sandbox_mode=false
	pet.hunger = 42.0; pet.grime = 24.0; pet.happiness = 58.0; pet.health = 82.0
	pet.trust = 5.0; pet.boredom = 35.0; pet.sleepiness = 18.0
	unlock_log("state_curious",false)
	_apply_upgrades()
	_start_shift()

func _continue_game() -> void:
	if load_game():
		_start_shift(true)
	else:
		_start_new_game(false)

func _start_shift(from_load := false) -> void:
	_hide_modals()
	title_open = false; menu_open = false; dialogue_open = false
	shift_complete = false; shift_active = true; simulation_active = true
	if not from_load:
		shift_time = 0.0; stable_time = 0.0
	incident_count = 0; active_incident = ""; incident_timer = 0.0
	feeder_jammed = false; cold_snap = false; biofilter_clogged = false; inspection_active = false
	next_incident_at = 30.0 + rng.randf_range(0.0,12.0)
	root.power_multiplier = 1.0
	_set_gameplay_enabled(true)
	_apply_upgrades(); _apply_look_settings()
	_update_progression()
	if is_instance_valid(root) and root.has_method("set_annex_unlocked"): root.set_annex_unlocked(shift >= 8)
	if shift >= 8: unlock_log("facility_annex",false)
	if shift == 7: unlock_log("milestone_shift7")
	if shift == 14: unlock_log("milestone_shift14")
	if shift == 20: unlock_log("milestone_shift20",false)
	if not (shift == 1 and not tutorial_complete):
		_toast("SHIFT %d / %d — %s" % [shift,MAX_SHIFTS,_shift_objective(shift)],4.0)

func _complete_shift() -> void:
	if shift_complete: return
	shift_complete = true; shift_active = false; simulation_active = false
	var ratio = stable_time / max(1.0, shift_time)
	last_score = int(clamp(ratio * 100.0,0.0,100.0))
	var base_pay = 20 + shift * 3
	var performance = int(last_score * 0.34)
	var trust_bonus = 8 if pet.trust >= 50.0 else (4 if pet.trust >= 30.0 else 0)
	var research_bonus = 4 if total_samples > 0 and shift % 3 == 0 else 0
	last_pay = base_pay + performance + trust_bonus + research_bonus
	if pet.health <= 0.0: last_pay = 0
	credits += last_pay
	pet.sleepiness = min(100.0, pet.sleepiness + 8.0)
	if pet.trust >= 50.0: unlock_log("milestone_trust50",false)
	_show_summary(); save_game()

func _show_summary() -> void:
	_hide_modals(); menu_open = true; _set_gameplay_enabled(false); summary_panel.show()
	var state = pet.behavior_state.to_upper()
	var ending_note = ""
	if shift >= MAX_SHIFTS and not sandbox_mode:
		ending_note = "\n\nEARLY ACCESS MILESTONE: authored twenty-shift contract complete."
	elif sandbox_mode:
		ending_note = "\n\nOPEN CARE SANDBOX: authored progression complete; incidents and care continue."
	summary_text.text = "SHIFT %d / %d\nCARE SCORE: %d%%\nPAY: $%d\nGLOOP: %s\nTRUST: %d%%    HEALTH: %d%%\nCARE ACTIONS: %d FEEDS • %d CLEANUPS • %d SAMPLES\nLOG: %d/%d    CREDITS: $%d%s" % [shift,MAX_SHIFTS,last_score,last_pay,state,int(pet.trust),int(pet.health),total_feeds,total_waste_cleaned,total_samples,log_unlocked.size(),log_catalog.size(),credits,ending_note]
	var buttons = summary_panel.find_children("","Button",true,false)
	if buttons.size() > 0: buttons[0].grab_focus()

func _next_shift() -> void:
	if shift >= MAX_SHIFTS and not sandbox_mode:
		_show_ea_ending()
		return
	if shift < MAX_SHIFTS:
		shift += 1
	pet.hunger = clamp(pet.hunger + 10.0,0.0,100.0)
	pet.grime = clamp(pet.grime + 4.0,0.0,100.0)
	pet.sleepiness = max(0.0,pet.sleepiness - 22.0)
	pet.boredom = clamp(pet.boredom + 7.0,0.0,100.0)
	shift_time = 0.0; stable_time = 0.0
	_start_shift(); save_game()

func _open_pause() -> void:
	_hide_modals()
	menu_open = true
	simulation_active = false
	_set_gameplay_enabled(false)
	pause_panel.show()
	var buttons = pause_panel.find_children("","Button",true,false)
	if buttons.size() > 0:
		buttons[0].grab_focus()

func _open_shop() -> void:
	_hide_modals()
	menu_open = true
	simulation_active = false
	_set_gameplay_enabled(false)
	shop_panel.show()
	_refresh_shop()
	var buttons = shop_panel.find_children("","Button",true,false)
	for b in buttons:
		if b is Button and not b.disabled:
			b.grab_focus()
			break

func open_shop_from_world(_player_ref = null) -> void:
	_open_shop()

func _refresh_shop() -> void:
	shop_credits.text = "AVAILABLE CREDITS: $%d   •   MED %d  FILTER %d  VIAL %d  RINGS %d" % [credits,get_stock("medicine"),get_stock("filter"),get_stock("vial"),get_stock("toy_chew")]
	var pages = int(ceil(float(shop_items.size()) / SHOP_PAGE_SIZE))
	shop_page = clamp(shop_page,0,max(0,pages-1))
	shop_page_label.text = "REQUISITION PAGE %d / %d" % [shop_page+1,pages]
	for i in range(SHOP_PAGE_SIZE):
		var idx = shop_page * SHOP_PAGE_SIZE + i
		var b = shop_buttons[i]
		var d = shop_panel.find_child("ShopDesc%d" % i,true,false)
		if idx >= shop_items.size():
			b.hide()
			if d: d.hide()
			continue
		b.show()
		if d: d.show()
		var item: Dictionary = shop_items[idx]
		b.set_meta("shop_index",idx)
		var owned = item["kind"] == "upgrade" and upgrades.get(item["id"],false)
		b.text = "%s  —  %s" % [item["name"],("INSTALLED" if owned else "$%d" % int(item["cost"]))]
		b.disabled = owned or credits < int(item["cost"]) or (item["id"] == "toy_chew" and not upgrades.get("toy",false)) or (item["id"] in ["auto_enrichment","auto_filter","remote_diagnostics"] and shift < 8)
		if d: d.text = item["desc"] + ("\nStock now: %d" % get_stock(item["id"]) if item["kind"] == "stock" else "")
	var prev = shop_panel.find_child("ShopPrev",true,false); var next = shop_panel.find_child("ShopNext",true,false)
	if prev: prev.disabled = shop_page <= 0
	if next: next.disabled = shop_page >= pages-1

func _buy_upgrade(id: String, cost: int) -> void:
	# Backward-compatible helper used by automated tests.
	for item in shop_items:
		if item["id"] == id and item["kind"] == "upgrade":
			_buy_item(item)
			return

func _buy_shop_slot(slot: int) -> void:
	var idx = shop_page * SHOP_PAGE_SIZE + slot
	if idx < 0 or idx >= shop_items.size(): return
	_buy_item(shop_items[idx])

func _buy_item(item: Dictionary) -> void:
	var cost = int(item["cost"])
	var id = String(item["id"])
	if credits < cost: return
	if item["kind"] == "upgrade":
		if upgrades.get(id,false): return
		credits -= cost
		upgrades[id] = true
		_apply_upgrades()
		unlock_log("upgrade_%s" % id, false)
		_toast("Installed: %s" % String(item["name"]))
	else:
		credits -= cost
		stock[id] = get_stock(id) + int(item.get("amount",1))
		_toast("Stocked: %s" % String(item["name"]))
	save_game()
	_refresh_shop()

func _shop_prev() -> void:
	shop_page = max(0,shop_page-1); _refresh_shop()
func _shop_next() -> void:
	shop_page += 1; _refresh_shop()

func get_stock(id: String) -> int:
	return int(stock.get(id,0))

func consume_stock(id: String) -> bool:
	var n = get_stock(id)
	if n <= 0: return false
	stock[id] = n - 1
	save_game()
	return true

func unlock_log(id: String, announce := true) -> void:
	if not log_catalog.has(id) or id in log_unlocked: return
	log_unlocked.append(id)
	if announce: _toast("SPECIMEN LOG UPDATED: %s" % String(log_catalog[id][1]),2.2)

func on_behavior_discovered(state: String) -> void:
	unlock_log("state_%s" % state, false)
	if pet.trust >= 50.0: unlock_log("milestone_trust50",false)

func on_feed() -> void:
	total_feeds += 1
	unlock_log("care_feed",false)

func on_sample_collected() -> void:
	total_samples += 1
	credits += int(pet.sample_value)
	unlock_log("care_sample")
	_toast("Sample sealed. Research bonus +$%d." % int(pet.sample_value),3.0)
	if total_samples >= 5: unlock_log("milestone_samples5")
	resolve_special_incident("sample_request")
	save_game()

func on_waste_cleaned() -> void:
	total_waste_cleaned += 1
	unlock_log("care_clean",false)
	if active_incident == "contamination" and get_tree().get_nodes_in_group("waste").size() <= 1:
		# queue_free happens just after this callback, so <=1 means this is the last visible mess.
		resolve_special_incident("contamination")

func resolve_special_incident(id: String) -> void:
	if active_incident != id: return
	credits += 5
	pet.trust = min(100.0,pet.trust + 1.5)
	_clear_incident("Special response complete. +$5 care bonus.")

func _apply_upgrades() -> void:
	if not is_instance_valid(pet): return
	pet.food_power = 36.0 if upgrades.get("better_mush",false) else 27.0
	pet.petting_power = 8.0 if upgrades.get("toy",false) else 4.0
	var stress = 1.0
	if upgrades.get("soft_lights",false): stress *= 0.72
	if upgrades.get("quiet_fan",false): stress *= 0.78
	pet.stress_resistance = stress
	pet.med_power = 36.0 if upgrades.get("med_dispenser",false) else 24.0
	pet.sample_value = 15 if upgrades.get("sample_analyzer",false) else 8
	pet.waste_grime_penalty = 8.0 if upgrades.get("floor_sealant",false) else 14.0
	pet.boredom_rate_multiplier = 0.62 if upgrades.get("enrichment_screen",false) else 1.0
	pet.sleep_rate_multiplier = 0.62 if upgrades.get("sleep_pad",false) else 1.0
	pet.health_regen_bonus = 0.012 if upgrades.get("health_monitor",false) else 0.0
	pet.hunger_rate_multiplier = 1.0
	pet.grime_rate_multiplier = 0.72 if upgrades.get("odor_neutralizer",false) else 1.0
	pet.trust_interact_bonus = 0.55 if upgrades.get("trust_treats",false) else 0.0
	if is_instance_valid(root) and root.bowl and root.bowl.has_method("set_capacity"):
		root.bowl.set_capacity(5 if upgrades.get("deluxe_bowl",false) else 3)
	if is_instance_valid(root) and root.has_method("apply_upgrade_visuals"):
		root.apply_upgrade_visuals(upgrades)

func _update_progression() -> void:
	var stage = 0
	if shift >= 5: stage = 1
	if shift >= 9: stage = 2
	if shift >= 14: stage = 3
	if shift >= 18: stage = 4
	if mutation_path == "baseline" and shift >= 8:
		mutation_path = "social" if pet.trust >= 38.0 and pet.happiness >= 45.0 else "defensive"
		unlock_log("mutation_%s" % mutation_path)
	growth_stage = stage
	if is_instance_valid(pet) and pet.has_method("set_progression_stage"):
		pet.set_progression_stage(growth_stage,mutation_path)
	if growth_stage >= 4: unlock_log("mutation_late",false)

func _run_automation(delta: float) -> void:
	auto_feed_cooldown=max(0.0,auto_feed_cooldown-delta); auto_enrich_cooldown=max(0.0,auto_enrich_cooldown-delta); auto_filter_cooldown=max(0.0,auto_filter_cooldown-delta)
	if upgrades.get("auto_scrubber",false) and automation_state.get("scrubber",true):
		pet.grime=max(0.0,pet.grime-delta*0.10); unlock_log("automation_scrubber",false)
	if upgrades.get("auto_feeder",false) and automation_state.get("feeder",true) and auto_feed_cooldown<=0.0 and pet.hunger>68.0:
		if root.bowl and root.bowl.has_method("add_portion") and root.bowl.add_portion():
			auto_feed_cooldown=28.0; credits=max(0,credits-1); unlock_log("automation_feeder",false)
	if upgrades.get("auto_enrichment",false) and automation_state.get("enrichment",true) and auto_enrich_cooldown<=0.0 and pet.boredom>76.0 and get_stock("toy_chew")>0:
		stock["toy_chew"]=get_stock("toy_chew")-1; pet.boredom=max(0.0,pet.boredom-32.0); pet.happiness=min(100.0,pet.happiness+7.0); auto_enrich_cooldown=42.0; unlock_log("automation_enrichment",false); _toast("AUTO-ENRICHMENT deployed a stocked ring.")
	if active_incident=="biofilter" and upgrades.get("auto_filter",false) and automation_state.get("filter",true) and auto_filter_cooldown<=0.0 and get_stock("filter")>0:
		stock["filter"]=get_stock("filter")-1; auto_filter_cooldown=20.0; unlock_log("automation_filter",false); _clear_incident("AUTOMATION replaced the saturated biofilter cartridge.")
	if active_incident=="sensor_fault" and upgrades.get("remote_diagnostics",false) and incident_timer < 24.0:
		_clear_incident("Remote diagnostic link reconciled the sensor fault.")

func _use_hint() -> String:
	if release != null:
		return release.interact_hint()
	return "[E]"

func _drop_hint() -> String:
	if release != null:
		return release.drop_hint()
	return "[Q]"

func _update_tutorial() -> void:
	if tutorial_complete or shift != 1:
		if tutorial_label: tutorial_label.text=""
		return
	var use = _use_hint()
	var drop = _drop_hint()
	match tutorial_step:
		0:
			tutorial_label.text="TRAINING 1/5 — Follow AMBER marker to MEAT MUSH • %s TAKE" % use
			if player.held_item=="food":
				tutorial_step=1
				_toast("Good. Bring the mush to Gloop or his bowl.",2.4)
		1:
			tutorial_label.text="TRAINING 2/5 — Look at Gloop or bowl • %s FEED   •   %s DROP" % [use,drop]
			if total_feeds>0:
				tutorial_step=2
				_toast("Feeding logged. Next: take the hand scanner.",2.4)
		2:
			tutorial_label.text="TRAINING 3/5 — Take HAND SCANNER, then %s on Gloop • %s drops tools" % [use,drop]
			if "care_scan" in log_unlocked:
				tutorial_step=3
				_toast("Diagnostic logged. Drop the scanner and get the bio-scrubber.",3.0)
				if not tutorial_waste_spawned:
					tutorial_waste_spawned=true; root.spawn_waste(pet.global_position+Vector3(1.1,0,0.7),pet)
		3:
			tutorial_label.text="TRAINING 4/5 — %s DROP current tool • take BIO-SCRUBBER • %s CLEAN HABITAT MESS" % [drop,use]
			if total_waste_cleaned>0:
				tutorial_step=4
				_toast("Cleanup logged. One last step: check the Specimen Log.",2.6)
		4:
			tutorial_label.text="TRAINING 5/5 — Follow AMBER marker to SPECIMEN LOG • %s OPEN" % use
			if tutorial_log_seen:
				tutorial_complete=true
				tutorial_label.text="TRAINING COMPLETE — keep Gloop stable until shift end."
				_toast("Handler certification recorded. Incidents are now live.",4.0)
				save_game()


func is_training_interactable_allowed(body: Node) -> bool:
	if shift != 1 or tutorial_complete or body == null:
		return true
	var n := String(body.name)
	match tutorial_step:
		0: return n == "MEAT_MUSH"
		1:
			if player.held_item == "food": return n in ["Gloop","FoodBowl"]
			return n == "MEAT_MUSH"
		2:
			if player.held_item == "scanner": return n == "Gloop"
			return n == "ScannerDock"
		3:
			if player.held_item == "cleaner": return body.is_in_group("waste")
			return n == "BioScrubber"
		4: return n == "SpecimenLogTerminal"
	return true

func training_block_message() -> String:
	if shift != 1 or tutorial_complete:
		return ""
	match tutorial_step:
		0: return "Training: follow the amber marker to the MEAT MUSH feeder first."
		1: return "Training: feed Gloop or load his bowl with the mush you're holding."
		2: return "Training: take the HAND SCANNER, then scan Gloop."
		3: return "Training: drop the current tool if needed, take the BIO-SCRUBBER, then clean the marked habitat mess."
		4: return "Training: open the marked SPECIMEN LOG terminal."
	return "Follow the amber training marker."

func _update_objective_guidance() -> void:
	if root == null or not root.has_method("set_objective_guidance"):
		return
	if menu_open or dialogue_open or title_open or not simulation_active:
		root.clear_objective_guidance(); return

	# First-shift training: guide the player's eyes and feet to the actual object.
	if shift == 1 and not tutorial_complete:
		match tutorial_step:
			0: root.set_objective_guidance("feeder","1/5 • TAKE MEAT MUSH")
			1:
				if player.held_item == "food": root.set_objective_guidance("pet","2/5 • FEED GLOOP")
				else: root.set_objective_guidance("feeder","2/5 • GET MEAT MUSH")
			2:
				if player.held_item == "scanner": root.set_objective_guidance("pet","3/5 • SCAN GLOOP")
				else: root.set_objective_guidance("scanner","3/5 • TAKE SCANNER")
			3:
				if player.held_item == "cleaner": root.set_objective_guidance("waste","4/5 • CLEAN HABITAT MESS")
				else: root.set_objective_guidance("scrubber","4/5 • TAKE BIO-SCRUBBER")
			4: root.set_objective_guidance("log","5/5 • OPEN SPECIMEN LOG")
		return

	# Incidents also point to the physical response object, especially the first
	# time a player sees a new simulator task.
	match active_incident:
		"power","feeder","cold","bad_batch","blackout","noise","overheat": root.set_objective_guidance("ops","INCIDENT • USE OPS")
		"biofilter":
			if player.held_item == "filter": root.set_objective_guidance("filter_hatch","INSTALL FILTER")
			else: root.set_objective_guidance("filter_rack","TAKE REPLACEMENT FILTER")
		"fever":
			if player.held_item == "medicine": root.set_objective_guidance("pet","ADMINISTER MEDICINE")
			else: root.set_objective_guidance("medicine","TAKE MEDICINE")
		"tantrum":
			if player.held_item == "toy": root.set_objective_guidance("pet","GIVE ENRICHMENT RING")
			else: root.set_objective_guidance("toy","TAKE ENRICHMENT RING")
		"sensor_fault":
			if player.held_item == "scanner": root.set_objective_guidance("pet","SCAN GLOOP")
			else: root.set_objective_guidance("scanner","TAKE HAND SCANNER")
		"contamination":
			if player.held_item == "cleaner": root.set_objective_guidance("waste","CLEAN BIOHAZARD")
			else: root.set_objective_guidance("scrubber","TAKE BIO-SCRUBBER")
		"sample_request":
			if player.held_item == "sample_vial": root.set_objective_guidance("pet","COLLECT SAMPLE")
			else: root.set_objective_guidance("sample","TAKE SAMPLE VIAL")
		_:
			root.clear_objective_guidance()

func _close_shop_return() -> void:
	if shift_complete:
		_show_summary()
	else:
		_close_all_menus()

func _close_all_menus() -> void:
	_hide_modals()
	if release != null and release.has_method("hide_panels"): release.hide_panels()
	menu_open = false
	dialogue_open = false
	title_open = false
	if shift_active and not shift_complete:
		simulation_active = true
		_set_gameplay_enabled(true)

func _hide_modals() -> void:
	for c in [title_panel,pause_panel,summary_panel,shop_panel,log_panel,dialogue_panel,options_panel,automation_panel,ending_panel]:
		if c:
			c.hide()

func _set_gameplay_enabled(enabled: bool) -> void:
	if is_instance_valid(player):
		player.set_process(enabled)
		player.set_physics_process(enabled)
		player.set_process_input(enabled)
		player.set_process_unhandled_input(enabled)
	if is_instance_valid(pet):
		pet.set_process(enabled)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if enabled else Input.MOUSE_MODE_VISIBLE

func _start_random_incident() -> void:
	var defs = [
		["power",1],["feeder",1],["cold",1],["inspection",2],["biofilter",2],
		["fever",3],["tantrum",3],["bad_batch",4],["sensor_fault",4],["contamination",5],
		["blackout",5],["noise",6],["sample_request",6],["overheat",7],["transfer_audit",10]
	]
	var options: Array[String] = []
	for d in defs:
		if shift >= int(d[1]): options.append(String(d[0]))
	if options.is_empty(): return
	# Prefer unseen incidents but allow repeats after the available pool has been sampled.
	var unseen: Array[String] = []
	for id in options:
		if id not in incidents_seen: unseen.append(id)
	var source = unseen if not unseen.is_empty() else options
	var id = source[rng.randi_range(0,source.size()-1)]
	if id not in incidents_seen: incidents_seen.append(id)
	unlock_log("incident_%s" % id,false)
	incident_count += 1
	next_incident_at = shift_time + 45.0 + rng.randf_range(0.0,18.0)
	active_incident = id
	incident_timer = 32.0 + (10.0 if upgrades["incident_alarm"] else 0.0)
	match id:
		"power":
			root.power_multiplier = 0.52 if upgrades["emergency_battery"] else 0.18
			pet.happiness = max(0.0,pet.happiness - 5.0 * pet.stress_resistance)
			_toast("INCIDENT: POWER DIP. Reset lighting bus at OPS.",4.0)
		"feeder": feeder_jammed = true; _toast("INCIDENT: MEAT MUSH FEEDER JAM. Reset it at OPS.",4.0)
		"cold": cold_snap = true; _toast("INCIDENT: HABITAT TEMPERATURE CRASH. Restore heat at OPS.",4.0)
		"inspection": inspection_active = true; incident_timer = 28.0 + (10.0 if upgrades["incident_alarm"] else 0.0); _toast("SURPRISE INSPECTION: hunger <70, filth <55, mood >40.",5.0)
		"biofilter": biofilter_clogged = true; pet.grime = min(100.0,pet.grime+7.0); _toast("BIOFILTER CLOG: take a FILTER cartridge and replace it at the wall hatch.",5.0)
		"fever": pet.health = min(pet.health,58.0); _toast("MEDICAL ALERT: Gloop is feverish. Bring MEDICINE from the cabinet.",5.0)
		"tantrum": pet.boredom = max(pet.boredom,88.0); _toast("ENRICHMENT TANTRUM: calm Gloop with a chew ring.",5.0)
		"bad_batch": feeder_jammed = true; _toast("CONTAMINATED FOOD BATCH: OPS must purge feeder stock.",5.0)
		"sensor_fault": _toast("SENSOR DISAGREEMENT: verify Gloop manually with the HAND SCANNER.",5.0)
		"contamination":
			root.spawn_waste(pet.global_position+Vector3(1.25,0,0.6),pet); root.spawn_waste(pet.global_position+Vector3(-1.1,0,-0.45),pet)
			_toast("CONTAINMENT CONTAMINATION: clean every biological incident.",5.0)
		"blackout": root.power_multiplier = 0.32 if upgrades["blackout_lamp"] else 0.06; _toast("FULL BLACKOUT: emergency task lighting only. Reset OPS.",5.0)
		"noise": _toast("ULTRASONIC VENT NOISE: Gloop is becoming agitated. Reset fan at OPS.",5.0)
		"sample_request": _toast("RESEARCH REQUEST: collect and seal a SAMPLE before timeout.",5.0)
		"overheat": _toast("HABITAT OVERHEAT: restore thermal control at OPS.",5.0)
		"transfer_audit": inspection_active = true; incident_timer = 34.0 + (10.0 if upgrades["incident_alarm"] else 0.0); _toast("TRANSFER AUDIT: hunger <60, filth <45, mood >50, health >55.",6.0)

func resolve_incident_from_world(_player_ref = null) -> void:
	if active_incident == "": _toast("OPS: all systems nominal."); return
	if active_incident in ["inspection","transfer_audit"]:
		_toast("The auditor is watching the habitat. Meet the displayed care targets."); return
	if active_incident == "biofilter": _toast("OPS cannot bypass a saturated cartridge. Replace the wall BIOFILTER."); return
	if active_incident == "fever": _toast("Software cannot medicate Gloop. Use a MEDICINE injector."); return
	if active_incident == "tantrum": _toast("Gloop is ignoring the terminal. Use physical ENRICHMENT."); return
	if active_incident == "sample_request": _toast("Research requires an actual specimen vial."); return
	if active_incident == "sensor_fault": _toast("OPS needs an independent HAND SCAN before reset."); return
	if active_incident == "contamination":
		if not get_tree().get_nodes_in_group("waste").is_empty(): _toast("Sanitation incomplete. Clean every visible biological incident."); return
	credits += 3; pet.trust = min(100.0,pet.trust+1.0)
	_clear_incident("System restored. +$3 incident response bonus.")

func _finish_inspection(strict := false) -> void:
	var pass_ = (pet.hunger < 60.0 and pet.grime < 45.0 and pet.happiness > 50.0 and pet.health > 55.0) if strict else (pet.hunger < 70.0 and pet.grime < 55.0 and pet.happiness > 40.0)
	if pass_:
		credits += 18 if strict else 15; pet.trust = min(100.0,pet.trust+2.0)
		_clear_incident(("TRANSFER AUDIT PASSED. +$18." if strict else "INSPECTION PASSED. +$15 compliance bonus."))
	else:
		credits = max(0,credits-(16 if strict else 12)); pet.happiness = max(0.0,pet.happiness-4.0)
		_clear_incident(("TRANSFER AUDIT FAILED. -$16." if strict else "INSPECTION FAILED. -$12 sanitation penalty."))

func _clear_incident(message_: String) -> void:
	root.power_multiplier = 1.0; feeder_jammed = false; cold_snap = false; biofilter_clogged = false; inspection_active = false
	active_incident = ""; incident_timer = 0.0; _toast(message_,3.2); save_game()

func get_incident_prompt() -> String:
	if active_incident == "": return "OPS TERMINAL — systems nominal"
	match active_incident:
		"inspection","transfer_audit": return "OPS — auditor monitoring habitat"
		"biofilter": return "OPS — replace physical BIOFILTER cartridge"
		"fever": return "OPS — administer MEDICINE directly"
		"tantrum": return "OPS — use ENRICHMENT RING on Gloop"
		"sample_request": return "OPS — collect sterile SAMPLE"
		"sensor_fault": return "OPS — confirm with HAND SCANNER"
		"contamination": return "OPS — clean all contamination"
		_: return "RESET %s" % active_incident.replace("_"," ").to_upper()

func is_feeder_jammed() -> bool:
	return feeder_jammed

func on_pet_interacted() -> void:
	if menu_open or dialogue_open or not shift_active:
		return
	if shift_time > 18.0 and rng.randf() < 0.18:
		var lines = [
			["Do you pet all your coworkers this much?", ["Only the useful ones.","You looked lonely.","Please stop talking."], [1,2,-2]],
			["I remember the person before you. I don't remember where they went.", ["What happened to them?","That's unsettling.","Management says you're lying."], [2,1,-2]],
			["The drain tastes different after midnight.", ["You taste the drain?","Good to know.","I did not need that information."], [1,0,-1]],
			["The new room smells like cold metal and old decisions.",["You've been in there?","It is for your care.","Stay out of it."],[2,1,-1]],
			["My hair keeps getting longer. I can feel every strand separately.",["Does it hurt?","It looks good.","That's horrifying."],[2,2,-1]],
			["The automatic feeder is efficient. I hate that I like it.",["Machines understand you.","I still prefer feeding you.","Good. Less work."],[1,3,-1]],
			["When the lights go out, I can still see the observer.",["What observer?","I believe you.","Stop trying to scare me."],[2,3,-2]],
			["You smell different after you come back from the annex.",["Different how?","You're tracking me?","Mind your business."],[2,1,-1]],
			["I think I am growing faster when you talk to me.",["Then I'll keep talking.","That makes no sense.","Maybe we should stop."],[3,0,-2]]
		]
		var d = lines[rng.randi_range(0,lines.size()-1)]
		_start_dialogue(d[0],d[1],d[2])

func _start_shift_dialogue() -> void:
	var data = {
		1:["You keep staring. Is that part of the job?", ["You're TALKING?","Management didn't mention this.","Eat your mush."], [2,1,-2]],
		2:["You came back. The other one usually didn't.", ["Of course I came back.","Who was the other one?","I need the paycheck."], [2,2,0]],
		3:["The people behind the glass think I can't see them.", ["I see them too.","Ignore them.","They're probably studying me."], [2,0,1]],
		4:["I had a name before 'Gloop.' I think it had two syllables.", ["Try to remember it.","Gloop suits you.","Names aren't important."], [3,1,-1]],
		5:["The new scanner hurts my eyes even when it's off.", ["I'll use it quickly.","That's probably impossible.","Good. Hold still."], [2,-1,-2]],
		6:["You take pieces of me away in little glass tubes.", ["They pay for samples.","I can stop if you want.","It's part of your care."], [0,3,1]],
		7:["A week. You are officially the longest-lasting one.", ["Congratulations to both of us.","What happened to the others?","Don't get sentimental."], [3,2,-1]],
		8:["I learned the sound your shoes make before the door opens.", ["You wait for me?","That's creepy.","Useful observation."], [3,-1,1]],
		9:["The filters smell like outside for three seconds when they're new.", ["Do you remember outside?","I'll bring you one fresh.","That's just packaging."], [3,2,-1]],
		10:["They used the word transfer again today.", ["Where are they taking you?","I heard.","Maybe you'll like the next place."], [3,1,-2]],
		11:["If I asked you to leave the hatch open, would that count as a care task?", ["Nice try.","Maybe.","Absolutely not."], [2,3,-1]],
		12:["I think my old hair was shorter.", ["This is better.","You had normal hair?","We can trim it."], [2,3,0]],
		13:["The observer behind the glass hasn't moved in hours.", ["I noticed.","Don't look at it.","There's nobody there."], [2,1,-2]],
		14:["Fourteen shifts. Are you still doing a job?", ["Not anymore.","Mostly.","Yes."], [5,1,-3]],
		15:["The annex says I am adapting to you. That seems rude to both of us.",["Maybe we're adapting together.","It is just data.","Don't flatter yourself."],[4,1,-2]],
		16:["I heard them arguing about whether my speech is learned or remembered.",["What do you remember?","You are clearly learning.","Ignore them."],[4,1,2]],
		17:["There is a door behind the growth tank. They never use it while you're here.",["I'll look for it.","Probably maintenance.","Stop watching the staff."],[3,0,-2]],
		18:["Something changed in my neck last night. The machine called it mature.",["How do you feel?","The scan looks stable.","Gross."],[4,2,-2]],
		19:["They printed a transfer order. Then shredded it.",["You're staying here.","Maybe it was a mistake.","Not my problem."],[5,1,-3]],
		20:["If this is your last scheduled shift, what happens to me tomorrow?",["I come back anyway.","We'll find out together.","Someone else takes over."],[6,4,-5]]
	}
	var d = data.get(shift,data[1]); _start_dialogue(d[0],d[1],d[2])

var current_choice_trust := []

func _start_dialogue(text_: String, choices: Array, trust_values: Array) -> void:
	if dialogue_open or menu_open:
		return
	dialogue_open = true
	menu_open = true
	simulation_active = false
	_set_gameplay_enabled(false)
	_hide_modals()
	dialogue_panel.show()
	dialogue_text.text = text_
	dialogue_response.text = ""
	current_choice_trust = trust_values
	for i in range(dialogue_buttons.size()):
		dialogue_buttons[i].text = choices[i] if i < choices.size() else "..."
		dialogue_buttons[i].disabled = i >= choices.size()
		dialogue_buttons[i].show()
	var close_b = dialogue_panel.find_child("DialogueClose",true,false)
	if close_b: close_b.hide()
	dialogue_buttons[0].grab_focus()

func _choose_dialogue(index: int) -> void:
	if index >= current_choice_trust.size():
		return
	var delta = int(current_choice_trust[index])
	pet.trust = clamp(pet.trust + delta,0.0,100.0)
	pet.happiness = clamp(pet.happiness + float(delta) * 0.8,0.0,100.0)
	var responses = [
		"Gloop studies your face for a little too long.",
		"One eyebrow rises. Several hair-tentacles copy it.",
		"Gloop makes a thoughtful noise that sounds medically concerning."
	]
	dialogue_response.text = responses[(index + shift) % responses.size()] + "  Trust %s%d." % ["+" if delta >= 0 else "",delta]
	for b in dialogue_buttons: b.hide()
	var close_b = dialogue_panel.find_child("DialogueClose",true,false)
	if close_b:
		close_b.show()
		close_b.grab_focus()

func _close_dialogue() -> void:
	dialogue_open = false
	menu_open = false
	dialogue_panel.hide()
	if shift_active and not shift_complete:
		simulation_active = true
		_set_gameplay_enabled(true)

func _shift_objective(n: int) -> String:
	var objectives = {
		1:"LEARN ROUTINE • FEED • CLEAN • SCAN",
		2:"HANDLE FILTERS • KEEP GLOOP STABLE",
		3:"LEARN MEDICATION • BUILD TRUST",
		4:"MANAGE BOREDOM • SURVIVE NEW INCIDENTS",
		5:"CONTROL CONTAMINATION • COLLECT SAMPLES",
		6:"RESEARCH REQUESTS • KEEP HEALTH HIGH",
		7:"ONE-WEEK REVIEW • UPGRADE HABITAT",
		8:"SECOND-WEEK ROUTINE • REDUCE MANUAL WORK",
		9:"KEEP TRUST >35 • MAINTAIN STOCK",
		10:"TRANSFER AUDITS BEGIN • STAY PREPARED",
		11:"BALANCE CARE • RESEARCH • INCIDENTS",
		12:"HIGH-VARIANCE SHIFT • WATCH HEALTH",
		13:"PRE-FINAL AUDIT • KEEP ALL NEEDS CONTROLLED",
		14:"CONTRACT EXTENSION • REVIEW GROWTH",
		15:"ANNEX RESEARCH • BALANCE AUTOMATION",
		16:"MAINTAIN TRUST • COLLECT DATA",
		17:"HIGH INCIDENT LOAD • CHECK ANNEX",
		18:"MATURE GROWTH • KEEP HEALTH >60",
		19:"TRANSFER PREP • STOCK SUPPLIES",
		20:"FINAL AUTHORED SHIFT • KEEP GLOOP STABLE"
	}
	return objectives.get(n,"KEEP GLOOP ALIVE")

func _update_labels() -> void:
	if not is_instance_valid(pet): return
	credits_label.text = "CREDITS  $%d" % credits
	behavior_label.text = "GLOOP: %s  •  TRUST %d%%  •  HEALTH %d%%  •  BOREDOM %d%%" % [pet.behavior_state.to_upper(),int(pet.trust),int(pet.health),int(pet.boredom)]
	if root and root.hud_shift:
		if shift == 1 and not tutorial_complete:
			root.hud_shift.text = "SHIFT 1/%d  •  HANDLER TRAINING  •  CLOCK PAUSED" % MAX_SHIFTS
		else:
			var shown = min(shift_time,SHIFT_LENGTH)
			root.hud_shift.text = "SHIFT %d/%d  %02d:%02d / %02d:%02d" % [shift,MAX_SHIFTS,int(shown)/60,int(shown)%60,int(SHIFT_LENGTH)/60,int(SHIFT_LENGTH)%60]
	if root and root.hud_status:
		root.hud_status.text = "HEALTH %d%%  •  TRUST %d%%  •  SLEEP %d%%" % [int(pet.health),int(pet.trust),int(pet.sleepiness)]
	if root and root.hud_objective:
		if shift == 1 and not tutorial_complete:
			root.hud_objective.text = "FOLLOW AMBER MARKER • COMPLETE HANDLER TRAINING"
		else:
			root.hud_objective.text = ("OPEN CARE SANDBOX • MAINTAIN / RESEARCH / EXPERIMENT" if sandbox_mode else _shift_objective(shift))
	if active_incident != "": incident_label.text = "⚠ %s  %02d" % [active_incident.replace("_"," ").to_upper(),max(0,int(incident_timer))]
	else: incident_label.text = ""

func _save_settings() -> void:
	var cfg = ConfigFile.new()
	cfg.set_value("settings","invert_y",look_inverted)
	cfg.set_value("settings","look_sensitivity",look_sensitivity)
	cfg.save(settings_path)

func _load_settings() -> void:
	var cfg = ConfigFile.new()
	if cfg.load(settings_path) == OK:
		look_inverted = bool(cfg.get_value("settings","invert_y",false))
		look_sensitivity = float(cfg.get_value("settings","look_sensitivity",2.0))

func save_game() -> void:
	if test_mode and save_path == "": return
	var cfg = ConfigFile.new()
	cfg.set_value("game","shift",shift); cfg.set_value("game","credits",credits)
	cfg.set_value("game","shift_time",shift_time); cfg.set_value("game","stable_time",stable_time)
	cfg.set_value("game","upgrades",upgrades); cfg.set_value("game","stock",stock)
	cfg.set_value("game","dialogue_flags",dialogue_flags); cfg.set_value("game","incidents_seen",incidents_seen)
	cfg.set_value("game","log_unlocked",log_unlocked); cfg.set_value("game","total_samples",total_samples)
	cfg.set_value("game","total_waste_cleaned",total_waste_cleaned); cfg.set_value("game","total_feeds",total_feeds)
	cfg.set_value("game","automation_state",automation_state); cfg.set_value("game","growth_stage",growth_stage); cfg.set_value("game","mutation_path",mutation_path)
	cfg.set_value("game","tutorial_step",tutorial_step); cfg.set_value("game","tutorial_complete",tutorial_complete); cfg.set_value("game","tutorial_log_seen",tutorial_log_seen); cfg.set_value("game","ea_complete",ea_complete); cfg.set_value("game","sandbox_mode",sandbox_mode)
	cfg.set_value("settings","invert_y",look_inverted); cfg.set_value("settings","look_sensitivity",look_sensitivity)
	cfg.set_value("pet","hunger",pet.hunger); cfg.set_value("pet","grime",pet.grime); cfg.set_value("pet","happiness",pet.happiness)
	cfg.set_value("pet","health",pet.health); cfg.set_value("pet","trust",pet.trust); cfg.set_value("pet","boredom",pet.boredom); cfg.set_value("pet","sleepiness",pet.sleepiness)
	if release != null:
		var save_err = release.safe_save_config(cfg,save_path)
		if save_err != OK: push_error("SAVE FAILED: %s" % save_err)
	else:
		cfg.save(save_path)

func load_game() -> bool:
	var cfg
	if release != null:
		cfg = release.load_with_recovery(save_path)
		if cfg == null: return false
	else:
		cfg = ConfigFile.new()
		if cfg.load(save_path) != OK: return false
	shift = int(cfg.get_value("game","shift",1)); credits = int(cfg.get_value("game","credits",60))
	shift_time = float(cfg.get_value("game","shift_time",0.0)); stable_time = float(cfg.get_value("game","stable_time",0.0))
	var saved_upgrades = cfg.get_value("game","upgrades",{})
	for k in saved_upgrades.keys(): upgrades[k] = saved_upgrades[k]
	stock = cfg.get_value("game","stock",stock)
	dialogue_flags = cfg.get_value("game","dialogue_flags",{}); incidents_seen = cfg.get_value("game","incidents_seen",[])
	log_unlocked = cfg.get_value("game","log_unlocked",[]); total_samples = int(cfg.get_value("game","total_samples",0))
	total_waste_cleaned = int(cfg.get_value("game","total_waste_cleaned",0)); total_feeds = int(cfg.get_value("game","total_feeds",0))
	automation_state = cfg.get_value("game","automation_state",automation_state); growth_stage=int(cfg.get_value("game","growth_stage",0)); mutation_path=String(cfg.get_value("game","mutation_path","baseline"))
	tutorial_step=int(cfg.get_value("game","tutorial_step",0)); tutorial_complete=bool(cfg.get_value("game","tutorial_complete",false)); tutorial_log_seen=bool(cfg.get_value("game","tutorial_log_seen",false)); ea_complete=bool(cfg.get_value("game","ea_complete",false)); sandbox_mode=bool(cfg.get_value("game","sandbox_mode",false))
	look_inverted = bool(cfg.get_value("settings","invert_y",false)); look_sensitivity = float(cfg.get_value("settings","look_sensitivity",2.0))
	pet.hunger = float(cfg.get_value("pet","hunger",42.0)); pet.grime = float(cfg.get_value("pet","grime",24.0)); pet.happiness = float(cfg.get_value("pet","happiness",58.0))
	pet.health = float(cfg.get_value("pet","health",82.0)); pet.trust = float(cfg.get_value("pet","trust",5.0)); pet.boredom = float(cfg.get_value("pet","boredom",35.0)); pet.sleepiness = float(cfg.get_value("pet","sleepiness",18.0))
	_apply_upgrades()
	_apply_look_settings()
	_update_progression()
	if is_instance_valid(root) and root.has_method("set_annex_unlocked"):
		root.set_annex_unlocked(shift >= 8)
	return true

func _toast(text_: String, duration := 2.8) -> void:
	if is_instance_valid(player) and player.has_method("show_message"):
		player.show_message(text_,duration)

func _run_filthpause_test() -> void:
	print("FILTH_PAUSE_TEST_BEGIN")
	tutorial_complete = true
	shift = 2
	_start_shift()
	shift_time = 37.0
	# Every spawned mess must snap to the raised habitat and sit above its surface.
	var spawned: Array = []
	for i in range(5):
		spawned.append(root.spawn_waste(Vector3(4.0-i,0.0,3.5),pet))
	await get_tree().process_frame
	for item in spawned:
		assert(item != null)
		assert(abs(item.global_position.x) <= 1.30)
		assert(item.global_position.z <= -0.20 and item.global_position.z >= -2.25)
		assert(item.global_position.y >= 0.30)
	# Pause and every options/release subpanel must freeze the shift clock.
	var frozen := shift_time
	_open_pause(); _process(2.5); assert(abs(shift_time-frozen)<0.001)
	_open_options(); _process(2.5); assert(abs(shift_time-frozen)<0.001)
	if release != null:
		release.open_advanced(); _process(2.5); assert(abs(shift_time-frozen)<0.001)
		release.open_bindings(); _process(2.5); assert(abs(shift_time-frozen)<0.001)
		release.open_achievements(); _process(2.5); assert(abs(shift_time-frozen)<0.001)
	_close_all_menus()
	var before := shift_time
	_process(1.0)
	assert(shift_time > before + 0.9)
	print("FILTH_PAUSE_TEST_PASS waste=VISIBLE_HABITAT_ONLY size=LARGE menus=PAUSE_CLOCK")
	for path in [save_path,save_path+".bak",save_path+".tmp"]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	get_tree().quit()

func _run_newplayer_test() -> void:
	print("NEW_PLAYER_TEST_BEGIN")
	assert(shift == 1 and not tutorial_complete and tutorial_step == 0)
	# Tutorial should not be interrupted by random incidents.
	shift_time = 90.0; next_incident_at = 1.0; active_incident = ""; _process(0.01)
	assert(active_incident == "")
	# Dynamic training copy exposes the current input and drop controls.
	_update_tutorial(); assert("TRAINING 1/5" in tutorial_label.text and "TAKE" in tutorial_label.text)
	# Run the first-session learning sequence.
	player.set_held_item("food"); _update_tutorial(); assert(tutorial_step == 1)
	total_feeds = 1; player.set_held_item(""); _update_tutorial(); assert(tutorial_step == 2)
	player.set_held_item("scanner"); unlock_log("care_scan",false); _update_tutorial(); assert(tutorial_step == 3 and tutorial_waste_spawned)
	player.set_held_item("cleaner"); total_waste_cleaned = 1; _update_tutorial(); assert(tutorial_step == 4)
	tutorial_log_seen = true; _update_tutorial(); assert(tutorial_complete)
	# Once trained, incidents are allowed again.
	shift_time = 95.0; next_incident_at = 1.0; incident_count = 0; active_incident = ""; _process(0.01)
	assert(active_incident != "")
	# Stations must never silently overwrite another held tool.
	var feeder=get_node("../MEAT_MUSH"); var scrubber=get_node("../BioScrubber")
	player.set_held_item("scanner"); feeder.on_cogito_interact(player); assert(player.held_item == "scanner")
	scrubber.on_cogito_interact(player); assert(player.held_item == "scanner")
	# Controller dialogue confirmation remains dual-path.
	active_incident=""; _start_dialogue("Fresh handler choice",["ONE","TWO","THREE"],[1,0,-1]); dialogue_buttons[0].grab_focus()
	var a_ev=InputEventJoypadButton.new(); a_ev.button_index=JOY_BUTTON_A; a_ev.pressed=true; _unhandled_input(a_ev); assert(dialogue_response.text.length()>0); _close_dialogue()
	print("NEW_PLAYER_TEST_PASS tutorial=5/5 incidents=DEFERRED stations=NO_OVERWRITE controller=A_START guidance=AMBER")
	get_tree().quit()

func _run_controllerfix_test() -> void:
	print("CONTROLLER_FIX_TEST_BEGIN")
	# UI actions: deterministic D-pad/left-stick navigation and A/B face buttons.
	for action in ["ui_accept","ui_cancel","ui_up","ui_down","ui_left","ui_right"]: assert(InputMap.has_action(action))
	var accept_a=false; var cancel_b=false; var up_dpad=false
	for e in InputMap.action_get_events("ui_accept"):
		if e is InputEventJoypadButton and e.button_index==JOY_BUTTON_A: accept_a=true
	for e in InputMap.action_get_events("ui_cancel"):
		if e is InputEventJoypadButton and e.button_index==JOY_BUTTON_B: cancel_b=true
	for e in InputMap.action_get_events("ui_up"):
		if e is InputEventJoypadButton and e.button_index==JOY_BUTTON_DPAD_UP: up_dpad=true
	assert(accept_a and cancel_b and up_dpad)
	# Dialogue: both A/Cross and Start activate the highlighted response.
	_start_dialogue("Controller START test",["ONE","TWO","THREE"],[1,0,-1]); assert(dialogue_open)
	dialogue_buttons[1].grab_focus()
	var start_ev=InputEventJoypadButton.new(); start_ev.button_index=JOY_BUTTON_START; start_ev.pressed=true
	_unhandled_input(start_ev); assert(dialogue_response.text.length()>0)
	_close_dialogue()
	_start_dialogue("Controller A test",["ONE","TWO","THREE"],[1,0,-1]); dialogue_buttons[2].grab_focus()
	var a_ev=InputEventJoypadButton.new(); a_ev.button_index=JOY_BUTTON_A; a_ev.pressed=true
	_unhandled_input(a_ev); assert(dialogue_response.text.length()>0)
	_close_dialogue()
	# Release/input subpanels must not stack and B returns through the hierarchy.
	release.open_advanced(); assert(release.advanced_panel.visible)
	release.open_bindings(); assert(release.bind_panel.visible and not release.advanced_panel.visible)
	release.handle_back(); assert(release.advanced_panel.visible and not release.bind_panel.visible)
	release.handle_back(); assert(options_panel.visible and not release.advanced_panel.visible)
	_close_options(); _close_all_menus()
	# Scrubber no longer needs a precision ray hit: a nearby habitat mess in front is acquired.
	player.set_held_item("cleaner")
	var w = root.spawn_waste(player.global_position + Vector3(0,0,-1.4),pet)
	await get_tree().process_frame
	var pic = player.get_node_or_null("PlayerInteractionComponent") as PlayerInteractionComponent
	assert(pic != null)
	var cam = get_viewport().get_camera_3d(); assert(cam != null)
	var acquired = pic._find_cleanable_waste(cam)
	assert(acquired != null)
	var before = total_waste_cleaned
	var wi = pic._interaction_for(acquired); assert(wi != null); wi.interact(pic)
	await get_tree().process_frame
	assert(total_waste_cleaned == before + 1)
	# Guidance follows the first-shift routine and incident response targets.
	tutorial_complete=false; shift=1; tutorial_step=0; _update_objective_guidance(); assert(root.objective_key=="feeder" and root.objective_beacon.visible)
	tutorial_step=3; player.set_held_item("cleaner"); root.spawn_waste(pet.global_position+Vector3(0.8,0,0.5),pet); _update_objective_guidance(); assert(root.objective_key=="waste")
	tutorial_complete=true; active_incident="fever"; player.set_held_item(""); _update_objective_guidance(); assert(root.objective_key=="medicine")
	player.set_held_item("medicine"); _update_objective_guidance(); assert(root.objective_key=="pet")
	print("CONTROLLER_FIX_TEST_PASS scrubber=FORGIVING ui=A_START_B guidance=ACTIVE")
	for path in [save_path,save_path+".bak",save_path+".tmp"]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	get_tree().quit()

func _run_passc_test() -> void:
	print("PASS_C_TEST_BEGIN")
	assert(release != null)
	# Controller coverage and tunable deadzone/sensitivity.
	for action in ["move_forward","move_back","move_left","move_right","look_left","look_right","look_up","look_down","interact","drop_item","jump","sprint","pause_game"]:
		assert(InputMap.has_action(action))
	var required_pad=["interact","drop_item","jump","sprint","pause_game"]
	for action in required_pad:
		var has_pad=false
		for ev in InputMap.action_get_events(action):
			if ev is InputEventJoypadButton: has_pad=true
		assert(has_pad)
	release.controller_deadzone=0.12; release.controller_sensitivity=1.6; release._apply_controller()
	assert(abs(InputMap.action_get_deadzone("look_left")-0.12)<0.001)
	var head=player.get_node_or_null("Head"); assert(head and abs(float(head.controller_sensitivity)-1.6)<0.01)
	# Rebinding keeps analog axes while replacing keyboard/button events.
	var test_key=InputEventKey.new(); test_key.physical_keycode=KEY_K; release._apply_binding_event("interact",test_key,"keyboard")
	assert(release._binding_text("interact","keyboard")=="K")
	release._reset_bindings(); assert(release._binding_text("interact","keyboard")=="E")
	# Local achievement mirror exercises the same IDs Steam will receive.
	shift=8; last_score=97; total_samples=5; total_waste_cleaned=25; log_unlocked=[]
	for id in log_catalog.keys():
		if log_unlocked.size()<25: log_unlocked.append(id)
	incidents_seen=["power","feeder","cold","biofilter","inspection","fever","tantrum","bad_batch","sensor_fault","contamination"]
	pet.trust=70.0; mutation_path="social"; growth_stage=2
	for k in ["auto_feeder","auto_scrubber","auto_enrichment","auto_filter"]: upgrades[k]=true
	release._check_achievements()
	for id in ["FIRST_SHIFT","PERFECT_SHIFT","WEEK_ONE","ANNEX_ACCESS","TRUST_50","SAMPLES_5","CLEAN_25","INCIDENTS_10","LOG_25","AUTOMATED","SOCIAL_MUTATION"]:
		assert(release.unlocked_achievements.get(id,false))
	# Save recovery: second save creates backup; corrupt primary must restore the first valid snapshot.
	credits=123; shift=6; pet.health=77.0; save_game()
	credits=456; shift=7; pet.health=66.0; save_game()
	assert(FileAccess.file_exists(save_path+".bak"))
	var f=FileAccess.open(save_path,FileAccess.WRITE); f.store_string("THIS SAVE IS INTENTIONALLY CORRUPT"); f.close()
	credits=0; shift=1; pet.health=1.0
	assert(load_game()); assert(credits==123 and shift==6 and int(pet.health)==77)
	# Performance profiles are runtime-switchable.
	for profile in ["low","balanced","quality"]:
		release.performance_profile=profile; release._apply_performance()
	release.performance_profile="balanced"; release._apply_performance()
	# Contract achievement.
	ea_complete=true; release._check_achievements(); assert(release.unlocked_achievements.get("CONTRACT_COMPLETE",false))
	print("PASS_C_TEST_PASS achievements=%d deadzone=%.2f sensitivity=%.1f recovered_credits=%d recovered_shift=%d" % [release.unlocked_achievements.size(),release.controller_deadzone,release.controller_sensitivity,credits,shift])
	for path in [save_path,save_path+".bak",save_path+".tmp",release.achievements_path,release.release_settings_path]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	get_tree().quit()

func _run_self_test() -> void:
	print("PASS_B_TEST_BEGIN")
	assert(MAX_SHIFTS == 20); assert(shop_items.size() >= 27); credits = 5000
	_buy_upgrade("better_mush",35); _buy_upgrade("toy",30); _buy_upgrade("med_dispenser",60); _buy_upgrade("sample_analyzer",50); _buy_upgrade("deluxe_bowl",40); shift=10; _buy_upgrade("auto_enrichment",95); _buy_upgrade("auto_filter",110); _buy_upgrade("remote_diagnostics",90)
	assert(upgrades["better_mush"] and upgrades["toy"] and upgrades["deluxe_bowl"] and upgrades["auto_enrichment"] and upgrades["auto_filter"] and upgrades["remote_diagnostics"])
	mutation_path="social"; growth_stage=3; pet.set_progression_stage(growth_stage,mutation_path); assert(pet.progression_stage==3 and pet.social_mutation_root.visible)
	root.set_annex_unlocked(true); assert(root.annex_unlocked)
	# Automation actions themselves.
	upgrades["auto_feeder"]=true; upgrades["auto_scrubber"]=true; automation_state={"feeder":true,"scrubber":true,"enrichment":true,"filter":true}; root.bowl.portions=0; pet.hunger=82.0; auto_feed_cooldown=0.0
	_run_automation(0.2); assert(root.bowl.portions==1)
	stock["toy_chew"]=2; pet.boredom=92.0; auto_enrich_cooldown=0.0; _run_automation(0.2); assert(pet.boredom<70.0 and get_stock("toy_chew")==1)
	stock["filter"]=2; active_incident="biofilter"; incident_timer=30.0; auto_filter_cooldown=0.0; _run_automation(0.2); assert(active_incident=="" and get_stock("filter")==1)
	# Tutorial state machine.
	shift=1; tutorial_complete=false; tutorial_step=0; player.set_held_item("food"); _update_tutorial(); assert(tutorial_step==1); total_feeds=1; _update_tutorial(); assert(tutorial_step==2); unlock_log("care_scan",false); _update_tutorial(); assert(tutorial_step==3); total_waste_cleaned=1; _update_tutorial(); assert(tutorial_step==4); tutorial_log_seen=true; _update_tutorial(); assert(tutorial_complete)
	shift=20; mutation_path="social"; _show_ea_ending(); assert(ea_complete and ending_panel.visible); _hide_modals(); menu_open=false
	assert(pet.food_power >= 35.0 and pet.med_power >= 35.0 and pet.sample_value >= 14); assert(root.bowl.max_portions == 5)
	stock["medicine"] = 2; stock["vial"] = 2; stock["filter"] = 2; stock["toy_chew"] = 2
	var med = root.get_node_or_null("MedCabinet"); var samples = root.get_node_or_null("SampleStation"); var filters = root.get_node_or_null("FilterRack")
	var hatch = root.get_node_or_null("BiofilterHatch"); var toys = root.get_node_or_null("ToyLocker"); var scanner = root.get_node_or_null("ScannerDock")
	assert(med and samples and filters and hatch and toys and scanner)
	# Fever: obtain medicine from the actual cabinet, then administer it.
	active_incident = "fever"; incident_timer = 30.0; pet.health = 45.0; player.set_held_item(""); med.on_cogito_interact(player)
	assert(player.held_item == "medicine" and get_stock("medicine") == 1); pet.on_cogito_interact(player)
	assert(active_incident == "" and pet.health >= 79.0 and player.held_item == "")
	# Tantrum: actual toy locker -> Gloop.
	active_incident = "tantrum"; incident_timer = 30.0; pet.boredom = 95.0; toys.on_cogito_interact(player)
	assert(player.held_item == "toy" and get_stock("toy_chew") == 1); pet.on_cogito_interact(player); assert(active_incident == "" and pet.boredom <= 55.0)
	# Sample request: actual sterile-vial station -> Gloop.
	active_incident = "sample_request"; incident_timer = 30.0; pet.behavior_state = "curious"; var samples_before = total_samples; var credits_before = credits
	samples.on_cogito_interact(player); assert(player.held_item == "sample_vial"); pet.on_cogito_interact(player)
	assert(total_samples == samples_before + 1 and credits > credits_before and "care_sample" in log_unlocked and active_incident == "")
	# Biofilter: actual rack -> actual hatch.
	active_incident = "biofilter"; incident_timer = 30.0; filters.on_cogito_interact(player); assert(player.held_item == "filter"); hatch.on_cogito_interact(player); assert(active_incident == "" and player.held_item == "")
	# Sensor fault: actual scanner dock -> scan Gloop.
	active_incident = "sensor_fault"; incident_timer = 30.0; scanner.on_cogito_interact(player); assert(player.held_item == "scanner"); pet.on_cogito_interact(player); assert(active_incident == ""); player.set_held_item("")
	unlock_log("state_playful",false); unlock_log("incident_blackout",false)
	open_specimen_log(); _refresh_log(); assert(log_text.text.length() > 0); _close_all_menus()
	_open_shop(); _refresh_shop(); assert(shop_buttons.size() == SHOP_PAGE_SIZE); _close_all_menus()
	active_incident = "power"; root.power_multiplier = 0.18; resolve_incident_from_world(); assert(active_incident == "" and root.power_multiplier == 1.0)
	pet.hunger = 30.0; pet.grime = 20.0; pet.happiness = 80.0; pet.health = 77.0; pet.trust = 42.0
	shift = 9; credits = 321; stock["medicine"] = 4; total_samples = 3; unlock_log("care_scan",false)
	save_game(); pet.health = 1.0; credits = 0; stock["medicine"] = 0; total_samples = 0; log_unlocked.clear()
	assert(load_game()); assert(int(pet.health) == 77 and credits == 321 and shift == 9 and get_stock("medicine") == 4 and total_samples == 3 and "care_scan" in log_unlocked)
	shift_time = SHIFT_LENGTH; stable_time = SHIFT_LENGTH * 0.8; shift_complete = false; _complete_shift(); assert(last_score >= 79)
	print("PASS_B_TEST_PASS shop=%d log=%d med=%d filter=%d vial=%d score=%d pay=%d credits=%d" % [shop_items.size(),log_unlocked.size(),get_stock("medicine"),get_stock("filter"),get_stock("vial"),last_score,last_pay,credits])
	if FileAccess.file_exists(save_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	get_tree().quit()

