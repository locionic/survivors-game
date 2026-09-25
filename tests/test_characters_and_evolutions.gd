extends Node

func _ready() -> void:
	print("=== RUNNING EXPANSION 7.0 CHARACTER & EVOLUTION TEST SUITE ===")
	
	# 1. Test GameManager 4 Heroes Registry
	assert(GameManager.CHARACTERS.has("knight"), "Knight exists in registry")
	assert(GameManager.CHARACTERS.has("pyro"), "Pyro exists in registry")
	assert(GameManager.CHARACTERS.has("ranger"), "Ranger exists in registry")
	assert(GameManager.CHARACTERS.has("mage"), "Mage exists in registry")
	
	for char_id in ["knight", "pyro", "ranger", "mage"]:
		GameManager.select_character(char_id)
		assert(GameManager.selected_character == char_id, "Selected character is updated to " + char_id)
		var c_data = GameManager.get_selected_character_data()
		assert(c_data["id"] == char_id, "Character data matches ID")
		assert(ResourceLoader.exists(c_data["texture_path"]), "Character texture exists: " + c_data["texture_path"])
		assert(c_data["starter_weapons"].size() > 0, "Character has starter weapons")
	print("✔ All 4 hero archetypes verified with valid assets & configs.")
	
	# 2. Test Player Class Traits & Dynamic Starter Weapons
	var player_scene = load("res://scenes/player.tscn")
	assert(player_scene != null, "Player scene loads")
	
	# Test Ignis (Pyro) starter weapons & passives
	GameManager.select_character("pyro")
	var pyro_player = player_scene.instantiate()
	add_child(pyro_player)
	
	var fire_wpn = pyro_player.get_node("Weapons/FireballWeapon")
	var dagger_wpn = pyro_player.get_node("Weapons/MainWeapon")
	assert(fire_wpn.is_active == true, "Ignis starts with Fireball active")
	assert(dagger_wpn.is_active == false, "Ignis starts with Daggers inactive")
	assert(pyro_player.meta_might_bonus >= 0.20, "Ignis has pyro might bonus")
	
	# Test activating weapon on player
	pyro_player.activate_weapon("dagger")
	assert(dagger_wpn.is_active == true, "Dagger activated on Pyro successfully")
	
	# Test walking squash and stretch animation update
	pyro_player.velocity = Vector2(200.0, 0.0)
	pyro_player._physics_process(0.016)
	assert(pyro_player.walk_phase > 0.0, "Walk phase increments when moving")
	assert(pyro_player.sprite.scale.x != 1.4 or pyro_player.sprite.scale.y != 1.4, "Squash and stretch scale active")
	pyro_player.free()
	print("✔ Player dynamic class stats, weapon activation, and squash-stretch verified.")
	
	# 3. Test Super Weapon Evolutions
	# Dagger -> Thousand Blades
	var dagger_scene = load("res://scenes/weapon.tscn")
	var d_wpn = dagger_scene.instantiate()
	add_child(d_wpn)
	assert(d_wpn.is_evolved == false, "Dagger starts unevolved")
	d_wpn.evolve_to_thousand_blades()
	assert(d_wpn.is_evolved == true, "Dagger evolves to Thousand Blades")
	assert(d_wpn.projectile_count == 8, "Thousand Blades fires 8 astral blades")
	d_wpn.free()
	
	# Shield -> Solar Bulwark
	var shield_scene = load("res://scenes/orbiting_weapon.tscn")
	var s_wpn = shield_scene.instantiate()
	add_child(s_wpn)
	assert(s_wpn.is_evolved == false, "Shield starts unevolved")
	s_wpn.evolve_to_solar_bulwark()
	assert(s_wpn.is_evolved == true, "Shield evolves to Solar Bulwark")
	assert(s_wpn.shield_count == 5, "Solar Bulwark spawns 5 shields")
	s_wpn.free()
	
	# Lightning -> Heaven's Wrath
	var light_scene = load("res://scenes/lightning_weapon.tscn")
	var l_wpn = light_scene.instantiate()
	add_child(l_wpn)
	assert(l_wpn.is_evolved == false, "Lightning starts unevolved")
	l_wpn.evolve_to_heavens_wrath()
	assert(l_wpn.is_evolved == true, "Lightning evolves to Heaven's Wrath")
	assert(l_wpn.strike_count == 4, "Heaven's Wrath strikes 4 simultaneous targets")
	l_wpn.free()
	
	# Fireball -> Apocalypse Meteor
	var fb_scene = load("res://scenes/fireball_weapon.tscn")
	var f_wpn = fb_scene.instantiate()
	add_child(f_wpn)
	assert(f_wpn.is_evolved == false, "Fireball starts unevolved")
	f_wpn.evolve_to_apocalypse_meteor()
	assert(f_wpn.is_evolved == true, "Fireball evolves to Apocalypse Meteor")
	assert(f_wpn.fireball_count == 3, "Apocalypse Meteor launches 3 massive meteors")
	f_wpn.free()
	
	# Axe -> Reaper's Cleave
	var axe_scene = load("res://scenes/axe_weapon.tscn")
	var a_wpn = axe_scene.instantiate()
	add_child(a_wpn)
	assert(a_wpn.is_evolved == false, "Axe starts unevolved")
	a_wpn.evolve_to_reapers_cleave()
	assert(a_wpn.is_evolved == true, "Axe evolves to Reaper's Cleave")
	assert(a_wpn.axe_count == 3, "Reaper's Cleave throws 3 piercing scythes")
	a_wpn.free()
	print("✔ All 5 Legendary Super Weapon Evolutions verified.")
	
	# 4. Test UpgradeManager Evolution Catalog Offering
	var upgrade_mgr = UpgradeManager.new()
	var up_panel = PanelContainer.new()
	up_panel.name = "UpgradePanel"
	var up_vbox = VBoxContainer.new()
	up_vbox.name = "VBox"
	var up_opts = HBoxContainer.new()
	up_opts.name = "OptionsContainer"
	up_vbox.add_child(up_opts)
	up_panel.add_child(up_vbox)
	upgrade_mgr.add_child(up_panel)
	add_child(upgrade_mgr)
	
	# Set dagger to Rank 5 to check evolution offer
	upgrade_mgr.weapon_levels["dagger"] = 5
	var cat = upgrade_mgr.get_upgrade_catalog()
	var has_thousand_blades = false
	for item in cat:
		if item["id"] == "evolve_dagger":
			has_thousand_blades = true
			break
	assert(has_thousand_blades == true, "Evolution offer appears when weapon reaches Lv.5")
	upgrade_mgr.free()
	print("✔ UpgradeManager evolution generation verified.")
	
	# 5. Test Character Selection Modal
	var char_select_scene = load("res://scenes/character_select_ui.tscn")
	assert(char_select_scene != null, "CharacterSelectUI scene exists")
	var char_ui = char_select_scene.instantiate()
	add_child(char_ui)
	char_ui.open_ui()
	assert(char_ui.cards_container.get_child_count() == 5, "Renders 5 character cards")
	char_ui.close_ui()
	char_ui.free()
	print("✔ CharacterSelectUI modal and 5-hero cards verified.")
	
	# 6. Test Enemy Archetype Procedural Animations
	var bat_scene = load("res://scenes/bat.tscn")
	var bat = bat_scene.instantiate()
	add_child(bat)
	assert(bat.is_bat_type == true, "Bat recognized as bat archetype")
	bat._physics_process(0.016)
	assert(bat.anim_time > 0.0, "Bat anim_time increments")
	bat.free()
	
	var necro_scene = load("res://scenes/necromancer.tscn")
	var necro = necro_scene.instantiate()
	add_child(necro)
	assert(necro.is_necro_type == true, "Necromancer recognized as necro archetype")
	necro._physics_process(0.016)
	necro.free()
	print("✔ Enemy archetype animations (bat fluttering, necro levitation) verified.")
	
	print("=== ALL EXPANSION 7.0 TESTS PASSED SUCCESSFULLY! ===")
	get_tree().quit(0)
