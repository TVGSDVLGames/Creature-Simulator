extends Node
class_name GloopReleaseManager

var game
var root
var player
var pet
var canvas: CanvasLayer

var steam = null
var steam_ready := false
var steam_stats_ready := false
var last_input_gamepad := false
var autosave_timer := 0.0
var autosave_interval := 45.0

var release_settings_path := "user://gloop_release_settings.cfg"
var achievements_path := "user://gloop_achievements.cfg"
var backup_path := "user://gloop_save.bak.cfg"
var temp_save_path := "user://gloop_save.tmp.cfg"

var fullscreen := false
var master_volume := 0.86
var controller_sensitivity := 1.0
var controller_deadzone := 0.18
var performance_profile := "balanced"

var advanced_panel: Control
var bind_panel: Control
var achievements_panel: Control
var volume_label: Label
var volume_slider: HSlider
var sensitivity_label: Label
var sensitivity_slider: HSlider
var deadzone_label: Label
var deadzone_slider: HSlider
var fullscreen_button: Button
var performance_button: Button
var binding_status: Label
var binding_buttons := {}
var achievement_text: Label
var achievements_back_button: Button

var rebinding_action := ""
var rebinding_device := ""
var achievement_defs := {
	"FIRST_SHIFT":["Clocked In","Complete your first care shift."],
	"PERFECT_SHIFT":["Clinical Precision","Finish a shift with a 95%+ care score."],
	"WEEK_ONE":["One Week With Gloop","Complete seven shifts."],
	"ANNEX_ACCESS":["Research Clearance","Unlock the Research Annex."],
	"TRUST_50":["Recognized Handler","Reach 50% trust."],
	"SAMPLES_5":["Research Contributor","Collect five viable samples."],
	"CLEAN_25":["Biohazard Professional","Clean twenty-five biological incidents."],
	"INCIDENTS_10":["Nothing Is Routine","Encounter ten different incident types."],
	"LOG_25":["Field Notes","Unlock twenty-five Specimen Log entries."],
	"AUTOMATED":["Mostly Hands-Off","Install all four care automation systems."],
	"SOCIAL_MUTATION":["Social Adaptation","Develop Gloop's social mutation path."],
	"DEFENSIVE_MUTATION":["Defensive Adaptation","Develop Gloop's defensive mutation path."],
	"CONTRACT_COMPLETE":["Permanent Staff","Complete the current twenty-shift contract."]
}
var unlocked_achievements := {}

var bind_actions := [
	["move_forward","MOVE FORWARD"], ["move_back","MOVE BACK"], ["move_left","MOVE LEFT"], ["move_right","MOVE RIGHT"],
	["interact","USE / INTERACT"], ["drop_item","DROP ITEM"], ["jump","JUMP"], ["sprint","SPRINT"], ["pause_game","PAUSE"]
]

func setup(game_node, root_node, player_node, pet_node, canvas_node: CanvasLayer) -> void:
	game = game_node
	root = root_node
	player = player_node
	pet = pet_node
	canvas = canvas_node
	process_mode = Node.PROCESS_MODE_ALWAYS
	_migrate_legacy_user_data()
	_load_release_settings()
	_load_achievements()
	_init_steam()
	_build_advanced_ui()
	_build_bind_ui()
	_build_achievements_ui()
	_inject_options_button()
	_apply_release_settings()
	_refresh_all()

func _migrate_legacy_user_data() -> void:
	var current_dir=OS.get_user_data_dir()
	var parent=current_dir.get_base_dir()
	var old_dirs=[parent.path_join("Weird Pet Simulator - Full Game Slice"),parent.path_join("Specimen Care- Gloop"),parent.path_join("Specimen Care: Gloop")]
	for old_dir in old_dirs:
		if old_dir==current_dir or not DirAccess.dir_exists_absolute(old_dir): continue
		for file_name in ["gloop_save.cfg","gloop_save.cfg.bak","gloop_settings.cfg","gloop_achievements.cfg","gloop_release_settings.cfg"]:
			var dst=current_dir.path_join(file_name)
			var src=old_dir.path_join(file_name)
			if not FileAccess.file_exists(dst) and FileAccess.file_exists(src):
				DirAccess.copy_absolute(src,dst)
				print("SAVE_MIGRATION: ",file_name," from ",old_dir.get_file())

func _process(delta: float) -> void:
	if steam_ready and steam != null and steam.has_method("run_callbacks"):
		steam.call("run_callbacks")
	if game != null and game.simulation_active and not game.menu_open and not game.dialogue_open:
		autosave_timer += delta
		if autosave_timer >= autosave_interval:
			autosave_timer = 0.0
			game.save_game()
	_check_achievements()

func _input(event: InputEvent) -> void:
	if rebinding_action != "":
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_ESCAPE:
				_cancel_rebind()
				get_viewport().set_input_as_handled()
				return
			if rebinding_device == "keyboard":
				_apply_binding_event(rebinding_action,event,"keyboard")
				get_viewport().set_input_as_handled()
				return
		if event is InputEventJoypadButton and event.pressed and rebinding_device == "gamepad":
			_apply_binding_event(rebinding_action,event,"gamepad")
			get_viewport().set_input_as_handled()
			return
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		last_input_gamepad = true
	elif event is InputEventKey or event is InputEventMouseMotion or event is InputEventMouseButton:
		last_input_gamepad = false

func _init_steam() -> void:
	steam_ready = false
	steam_stats_ready = false
	if not Engine.has_singleton("Steam"):
		print("STEAM_BRIDGE: extension not present; local achievement mirror active.")
		return
	steam = Engine.get_singleton("Steam")
	if steam == null:
		return
	var init_ok := true
	if steam.has_method("steamInitEx"):
		var result = steam.call("steamInitEx")
		init_ok = int(result) == 0
	elif steam.has_method("steamInit"):
		init_ok = bool(steam.call("steamInit"))
	steam_ready = init_ok
	if steam_ready and steam.has_method("requestCurrentStats"):
		steam.call("requestCurrentStats")
		steam_stats_ready = true
	print("STEAM_BRIDGE: %s" % ("READY" if steam_ready else "INITIALIZATION FAILED"))

func _check_achievements() -> void:
	if game == null or pet == null:
		return
	if game.shift > 1 or game.shift_complete:
		_unlock("FIRST_SHIFT")
	if game.last_score >= 95:
		_unlock("PERFECT_SHIFT")
	if game.shift >= 8:
		_unlock("WEEK_ONE")
		_unlock("ANNEX_ACCESS")
	if pet.trust >= 50.0:
		_unlock("TRUST_50")
	if game.total_samples >= 5:
		_unlock("SAMPLES_5")
	if game.total_waste_cleaned >= 25:
		_unlock("CLEAN_25")
	if game.incidents_seen.size() >= 10:
		_unlock("INCIDENTS_10")
	if game.log_unlocked.size() >= 25:
		_unlock("LOG_25")
	if game.upgrades.get("auto_feeder",false) and game.upgrades.get("auto_scrubber",false) and game.upgrades.get("auto_enrichment",false) and game.upgrades.get("auto_filter",false):
		_unlock("AUTOMATED")
	if game.mutation_path == "social" and game.growth_stage >= 2:
		_unlock("SOCIAL_MUTATION")
	if game.mutation_path == "defensive" and game.growth_stage >= 2:
		_unlock("DEFENSIVE_MUTATION")
	if game.ea_complete:
		_unlock("CONTRACT_COMPLETE")

func _unlock(id: String) -> void:
	if unlocked_achievements.get(id,false):
		return
	unlocked_achievements[id] = true
	_save_achievements()
	print("ACHIEVEMENT_UNLOCKED: %s" % id)
	if game != null and not game.test_mode:
		game._toast("ACHIEVEMENT: %s" % achievement_defs[id][0],3.5)
	if steam_ready and steam != null and steam.has_method("setAchievement"):
		steam.call("setAchievement",id)
		if steam.has_method("storeStats"):
			steam.call("storeStats")
	_refresh_achievements()

func _load_achievements() -> void:
	unlocked_achievements.clear()
	var cfg = ConfigFile.new()
	if cfg.load(achievements_path) == OK:
		for id in achievement_defs.keys():
			unlocked_achievements[id] = bool(cfg.get_value("achievements",id,false))

func _save_achievements() -> void:
	var cfg = ConfigFile.new()
	for id in achievement_defs.keys():
		cfg.set_value("achievements",id,bool(unlocked_achievements.get(id,false)))
	cfg.save(achievements_path)

func _inject_options_button() -> void:
	if game.options_panel == null:
		return
	var content: Control = null
	for c in game.options_panel.get_children():
		if c is ColorRect and c.size.x < 800:
			content = c
	if content == null:
		return
	content.size.y = 505
	var back: Button = null
	for b in content.find_children("","Button",true,false):
		if b.text == "BACK": back = b
	if back:
		back.position.y = 445
	var advanced = game._button(content,Vector2(90,390),"RELEASE / INPUT SETTINGS",320)
	advanced.pressed.connect(open_advanced)

func _build_advanced_ui() -> void:
	advanced_panel = game._make_modal()
	var p = game._panel(advanced_panel,Rect2(345,68,590,590),Color(0.008,0.014,0.018,0.99))
	var t = game._label(p,Vector2(35,22),"RELEASE / INPUT SETTINGS",26,Vector2(520,40)); t.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	fullscreen_button = game._button(p,Vector2(105,80),"DISPLAY: WINDOWED",380); fullscreen_button.pressed.connect(_toggle_fullscreen)
	volume_label = game._label(p,Vector2(105,138),"MASTER VOLUME: 86%",15,Vector2(380,24)); volume_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	volume_slider = HSlider.new(); volume_slider.position=Vector2(105,164); volume_slider.size=Vector2(380,28); volume_slider.min_value=0; volume_slider.max_value=1; volume_slider.step=0.05; volume_slider.value=master_volume; volume_slider.value_changed.connect(_set_volume); p.add_child(volume_slider)
	sensitivity_label = game._label(p,Vector2(105,205),"CONTROLLER LOOK: 1.0x",15,Vector2(380,24)); sensitivity_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	sensitivity_slider=HSlider.new(); sensitivity_slider.position=Vector2(105,230); sensitivity_slider.size=Vector2(380,28); sensitivity_slider.min_value=0.5; sensitivity_slider.max_value=3.0; sensitivity_slider.step=0.1; sensitivity_slider.value=controller_sensitivity; sensitivity_slider.value_changed.connect(_set_controller_sensitivity); p.add_child(sensitivity_slider)
	deadzone_label = game._label(p,Vector2(105,271),"STICK DEADZONE: 0.18",15,Vector2(380,24)); deadzone_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	deadzone_slider=HSlider.new(); deadzone_slider.position=Vector2(105,296); deadzone_slider.size=Vector2(380,28); deadzone_slider.min_value=0.0; deadzone_slider.max_value=0.4; deadzone_slider.step=0.02; deadzone_slider.value=controller_deadzone; deadzone_slider.value_changed.connect(_set_controller_deadzone); p.add_child(deadzone_slider)
	performance_button=game._button(p,Vector2(105,342),"PERFORMANCE: BALANCED",380); performance_button.pressed.connect(_cycle_performance)
	var rebind=game._button(p,Vector2(105,398),"REBIND CONTROLS",380); rebind.pressed.connect(open_bindings)
	var ach=game._button(p,Vector2(105,454),"ACHIEVEMENTS / STEAM TEST",380); ach.pressed.connect(open_achievements)
	var back=game._button(p,Vector2(105,510),"BACK TO OPTIONS",380); back.pressed.connect(_back_to_options)

func _build_bind_ui() -> void:
	bind_panel = game._make_modal()
	var p=game._panel(bind_panel,Rect2(225,42,830,635),Color(0.008,0.014,0.018,0.99))
	var t=game._label(p,Vector2(35,18),"CONTROL BINDINGS",26,Vector2(760,38)); t.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	binding_status=game._label(p,Vector2(60,60),"Select a keyboard or gamepad binding.",14,Vector2(710,32)); binding_status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	binding_buttons.clear()
	for i in range(bind_actions.size()):
		var action=bind_actions[i][0]; var label=bind_actions[i][1]
		game._label(p,Vector2(50,112+i*48),label,14,Vector2(235,38))
		var kb=game._button(p,Vector2(285,105+i*48),"KEY",205); kb.size.y=38; kb.pressed.connect(_begin_rebind.bind(action,"keyboard"))
		binding_buttons[action+"_keyboard"]=kb
		if action in ["interact","drop_item","jump","sprint","pause_game"]:
			var gp=game._button(p,Vector2(510,105+i*48),"PAD",205); gp.size.y=38; gp.pressed.connect(_begin_rebind.bind(action,"gamepad")); binding_buttons[action+"_gamepad"]=gp
	var reset=game._button(p,Vector2(165,555),"RESET DEFAULTS",235); reset.pressed.connect(_reset_bindings)
	var back=game._button(p,Vector2(430,555),"BACK",235); back.pressed.connect(open_advanced)

func _build_achievements_ui() -> void:
	achievements_panel=game._make_modal()
	var p=game._panel(achievements_panel,Rect2(250,70,780,585),Color(0.008,0.014,0.018,0.99))
	var t=game._label(p,Vector2(35,20),"ACHIEVEMENTS / STEAM TEST",26,Vector2(710,38)); t.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	achievement_text=game._label(p,Vector2(55,70),"",14,Vector2(670,420)); achievement_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	achievements_back_button=game._button(p,Vector2(230,500),"BACK",320); achievements_back_button.pressed.connect(open_advanced)

func hide_panels() -> void:
	for panel in [advanced_panel,bind_panel,achievements_panel]:
		if panel: panel.hide()

func has_open_panel() -> bool:
	for panel in [advanced_panel,bind_panel,achievements_panel]:
		if panel and panel.visible: return true
	return false

func handle_back() -> void:
	if bind_panel and bind_panel.visible:
		open_advanced(); return
	if achievements_panel and achievements_panel.visible:
		open_advanced(); return
	if advanced_panel and advanced_panel.visible:
		_back_to_options(); return

func open_advanced() -> void:
	game._hide_modals(); hide_panels(); game.menu_open=true; game.simulation_active=false; game._set_gameplay_enabled(false); advanced_panel.show(); _refresh_all(); fullscreen_button.grab_focus()

func open_bindings() -> void:
	game._hide_modals(); hide_panels(); game.menu_open=true; game.simulation_active=false; game._set_gameplay_enabled(false); bind_panel.show(); _refresh_bindings()
	var first=binding_buttons.get("move_forward_keyboard"); if first: first.grab_focus()

func open_achievements() -> void:
	game._hide_modals(); hide_panels(); game.menu_open=true; game.simulation_active=false; game._set_gameplay_enabled(false); achievements_panel.show(); _refresh_achievements()
	if achievements_back_button: achievements_back_button.grab_focus()

func _back_to_options() -> void:
	# Preserve whether Options was entered from title or pause. Calling _open_options()
	# here would recalculate that after the title panel had already been hidden.
	hide_panels(); game._hide_modals(); game.menu_open=true; game.simulation_active=false; game._set_gameplay_enabled(false)
	game.options_panel.show(); game._refresh_options(); game.invert_button.grab_focus()

func _toggle_fullscreen() -> void:
	fullscreen=not fullscreen; _apply_display(); _save_release_settings(); _refresh_all()
func _set_volume(v: float) -> void:
	master_volume=v; _apply_audio(); _save_release_settings(); _refresh_all()
func _set_controller_sensitivity(v: float) -> void:
	controller_sensitivity=v; _apply_controller(); _save_release_settings(); _refresh_all()
func _set_controller_deadzone(v: float) -> void:
	controller_deadzone=v; _apply_controller(); _save_release_settings(); _refresh_all()
func _cycle_performance() -> void:
	performance_profile = "quality" if performance_profile=="balanced" else ("low" if performance_profile=="quality" else "balanced")
	_apply_performance(); _save_release_settings(); _refresh_all()

func _refresh_all() -> void:
	if fullscreen_button: fullscreen_button.text="DISPLAY: %s" % ("FULLSCREEN" if fullscreen else "WINDOWED")
	if volume_label: volume_label.text="MASTER VOLUME: %d%%" % int(master_volume*100.0)
	if volume_slider and abs(volume_slider.value-master_volume)>0.01: volume_slider.value=master_volume
	if sensitivity_label: sensitivity_label.text="CONTROLLER LOOK: %.1fx" % controller_sensitivity
	if sensitivity_slider and abs(sensitivity_slider.value-controller_sensitivity)>0.01: sensitivity_slider.value=controller_sensitivity
	if deadzone_label: deadzone_label.text="STICK DEADZONE: %.2f" % controller_deadzone
	if deadzone_slider and abs(deadzone_slider.value-controller_deadzone)>0.01: deadzone_slider.value=controller_deadzone
	if performance_button: performance_button.text="PERFORMANCE: %s" % performance_profile.to_upper()
	_refresh_bindings(); _refresh_achievements()

func _refresh_achievements() -> void:
	if achievement_text == null: return
	var lines=["STEAM STATUS: %s" % ("CONNECTED" if steam_ready else "LOCAL TEST MODE"),""]
	for id in achievement_defs.keys():
		var d=achievement_defs[id]; lines.append("%s  %s — %s" % [("[X]" if unlocked_achievements.get(id,false) else "[ ]"),d[0],d[1]])
	achievement_text.text="\n".join(lines)

func _begin_rebind(action: String, device: String) -> void:
	rebinding_action=action; rebinding_device=device; binding_status.text="PRESS A NEW %s INPUT FOR %s — ESC CANCELS" % [device.to_upper(),action.to_upper()]

func _cancel_rebind() -> void:
	rebinding_action=""; rebinding_device=""; binding_status.text="Binding cancelled."; _refresh_bindings()

func _apply_binding_event(action: String, event: InputEvent, device: String) -> void:
	for existing in InputMap.action_get_events(action):
		if device=="keyboard" and existing is InputEventKey: InputMap.action_erase_event(action,existing)
		elif device=="gamepad" and existing is InputEventJoypadButton: InputMap.action_erase_event(action,existing)
	InputMap.action_add_event(action,event)
	rebinding_action=""; rebinding_device=""; binding_status.text="Binding updated."; _save_release_settings(); _refresh_bindings()

func _binding_text(action: String, device: String) -> String:
	for e in InputMap.action_get_events(action):
		if device=="keyboard" and e is InputEventKey:
			var code=e.physical_keycode if e.physical_keycode != 0 else e.keycode
			return OS.get_keycode_string(code)
		if device=="gamepad" and e is InputEventJoypadButton:
			return _joy_button_name(e.button_index)
	return "UNBOUND"

func _refresh_bindings() -> void:
	for d in bind_actions:
		var action=d[0]
		if binding_buttons.has(action+"_keyboard"): binding_buttons[action+"_keyboard"].text=_binding_text(action,"keyboard")
		if binding_buttons.has(action+"_gamepad"): binding_buttons[action+"_gamepad"].text=_binding_text(action,"gamepad")

func _joy_button_name(i: int) -> String:
	var names={0:"A / CROSS",1:"B / CIRCLE",2:"X / SQUARE",3:"Y / TRIANGLE",4:"BACK",5:"GUIDE",6:"START",7:"L3",8:"R3",9:"LB",10:"RB",11:"DPAD UP",12:"DPAD DOWN",13:"DPAD LEFT",14:"DPAD RIGHT"}
	return names.get(i,"BUTTON %d" % i)

func _reset_bindings() -> void:
	var defaults={
		"move_forward":[KEY_W,-1],"move_back":[KEY_S,-1],"move_left":[KEY_A,-1],"move_right":[KEY_D,-1],
		"interact":[KEY_E,JOY_BUTTON_A],"drop_item":[KEY_Q,JOY_BUTTON_B],"jump":[KEY_SPACE,JOY_BUTTON_X],"sprint":[KEY_SHIFT,JOY_BUTTON_LEFT_STICK],"pause_game":[KEY_ESCAPE,JOY_BUTTON_START]
	}
	for action in defaults.keys():
		for e in InputMap.action_get_events(action):
			if e is InputEventKey or e is InputEventJoypadButton: InputMap.action_erase_event(action,e)
		var k=InputEventKey.new(); k.physical_keycode=defaults[action][0]; InputMap.action_add_event(action,k)
		if defaults[action][1]>=0:
			var p=InputEventJoypadButton.new(); p.button_index=defaults[action][1]; InputMap.action_add_event(action,p)
	binding_status.text="Defaults restored."; _save_release_settings(); _refresh_bindings()

func _apply_release_settings() -> void:
	_apply_display(); _apply_audio(); _apply_controller(); _apply_performance()
func _apply_display() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
func _apply_audio() -> void:
	AudioServer.set_bus_mute(0,master_volume<=0.001)
	if master_volume>0.001: AudioServer.set_bus_volume_db(0,linear_to_db(master_volume))
func _apply_controller() -> void:
	for action in ["look_left","look_right","look_up","look_down","move_forward","move_back","move_left","move_right"]:
		if InputMap.has_action(action): InputMap.action_set_deadzone(action,controller_deadzone)
	if is_instance_valid(player):
		var head=player.get_node_or_null("Head")
		if head:
			head.set("controller_sensitivity",controller_sensitivity)
			head.set("controller_deadzone",controller_deadzone)
func _apply_performance() -> void:
	if is_instance_valid(root) and root.has_method("apply_performance_profile"): root.apply_performance_profile(performance_profile)

func _save_release_settings() -> void:
	var cfg=ConfigFile.new()
	cfg.set_value("release","fullscreen",fullscreen); cfg.set_value("release","master_volume",master_volume); cfg.set_value("release","controller_sensitivity",controller_sensitivity); cfg.set_value("release","controller_deadzone",controller_deadzone); cfg.set_value("release","performance_profile",performance_profile)
	for d in bind_actions:
		var action=d[0]
		for e in InputMap.action_get_events(action):
			if e is InputEventKey:
				cfg.set_value("keyboard",action,int(e.physical_keycode if e.physical_keycode!=0 else e.keycode)); break
		for e in InputMap.action_get_events(action):
			if e is InputEventJoypadButton:
				cfg.set_value("gamepad",action,int(e.button_index)); break
	cfg.save(release_settings_path)

func _load_release_settings() -> void:
	var cfg=ConfigFile.new()
	if cfg.load(release_settings_path)!=OK: return
	fullscreen=bool(cfg.get_value("release","fullscreen",false)); master_volume=float(cfg.get_value("release","master_volume",0.86)); controller_sensitivity=float(cfg.get_value("release","controller_sensitivity",1.0)); controller_deadzone=float(cfg.get_value("release","controller_deadzone",0.18)); performance_profile=String(cfg.get_value("release","performance_profile","balanced"))
	for d in bind_actions:
		var action=d[0]
		if cfg.has_section_key("keyboard",action):
			var code=int(cfg.get_value("keyboard",action,0)); if code!=0:
				for e in InputMap.action_get_events(action):
					if e is InputEventKey: InputMap.action_erase_event(action,e)
				var k=InputEventKey.new(); k.physical_keycode=code; InputMap.action_add_event(action,k)
		if cfg.has_section_key("gamepad",action):
			var btn=int(cfg.get_value("gamepad",action,-1)); if btn>=0:
				for e in InputMap.action_get_events(action):
					if e is InputEventJoypadButton: InputMap.action_erase_event(action,e)
				var p=InputEventJoypadButton.new(); p.button_index=btn; InputMap.action_add_event(action,p)

func interact_hint() -> String:
	return "[%s]" % _binding_text("interact","gamepad" if last_input_gamepad else "keyboard")
func drop_hint() -> String:
	return "[%s]" % _binding_text("drop_item","gamepad" if last_input_gamepad else "keyboard")

func safe_save_config(cfg: ConfigFile, path: String) -> int:
	cfg.set_value("meta","save_version",3)
	cfg.set_value("meta","signature","GLOOP_RC_SAVE")
	cfg.set_value("meta","written_unix",int(Time.get_unix_time_from_system()))
	var temp=path+".tmp"
	var backup=path+".bak"
	var err=cfg.save(temp)
	if err!=OK: return err
	var abs_path=ProjectSettings.globalize_path(path); var abs_temp=ProjectSettings.globalize_path(temp); var abs_backup=ProjectSettings.globalize_path(backup)
	if FileAccess.file_exists(path): DirAccess.copy_absolute(abs_path,abs_backup)
	err=DirAccess.copy_absolute(abs_temp,abs_path)
	DirAccess.remove_absolute(abs_temp)
	return err

func load_with_recovery(path: String) -> ConfigFile:
	var cfg=ConfigFile.new()
	var primary_err=cfg.load(path)
	if primary_err==OK and _valid_config(cfg): return cfg
	var backup=path+".bak"
	var b=ConfigFile.new()
	var backup_err=b.load(backup)
	if backup_err==OK and _valid_config(b):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(backup),ProjectSettings.globalize_path(path))
		print("SAVE_RECOVERY: restored backup")
		return b
	print("SAVE_RECOVERY_FAILED primary=%s backup=%s exists=%s" % [primary_err,backup_err,FileAccess.file_exists(backup)])
	return null

func _valid_config(cfg: ConfigFile) -> bool:
	if not cfg.has_section("game") or not cfg.has_section("pet"):
		print("SAVE_INVALID missing required sections"); return false
	var sig=String(cfg.get_value("meta","signature",""))
	if sig not in ["","GLOOP_RC_SAVE"]:
		print("SAVE_INVALID signature=",sig); return false
	var s=int(cfg.get_value("game","shift",1)); var c=int(cfg.get_value("game","credits",0))
	if s<1 or s>20 or c<0 or c>10000000:
		print("SAVE_INVALID range shift=",s," credits=",c); return false
	for k in ["hunger","grime","happiness","health","trust","boredom","sleepiness"]:
		var v=float(cfg.get_value("pet",k,50.0))
		if is_nan(v) or is_inf(v) or v < -0.1 or v > 100.1:
			print("SAVE_INVALID pet ",k,"=",v); return false
	return true
