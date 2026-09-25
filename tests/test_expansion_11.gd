extends Node

## Comprehensive test suite verifying Expansion 11.0:
## Linh Thú Companions & Hệ Thống Kinh Mạch (Meridian Cultivation).

func _ready() -> void:
	print("=== RUNNING EXPANSION 11.0 COMPANIONS & MERIDIAN CULTIVATION TEST SUITE ===")
	
	# 1. Setup Player & Test Companion Spawning
	GameManager.meridian_upgrades = {
		"nham_mach": 0,
		"doc_mach": 0,
		"xung_mach": 0,
		"dan_dien": 0
	}
	GameManager.select_companion("dragon_whelp")
	var player_scene = load("res://scenes/player.tscn")
	assert(player_scene != null, "Player scene exists")
	var player = player_scene.instantiate()
	add_child(player)
	player.apply_character_data()
	player.refresh_meta_stats()
	await get_tree().process_frame
	
	# Verify Companion auto-spawned alongside Player
	var companions = get_tree().get_nodes_in_group("companions")
	assert(companions.size() == 1, "Companion is spawned into scene")
	var companion = companions[0]
	assert(companion.companion_id == "dragon_whelp", "Companion starts as dragon_whelp")
	assert(companion.companion_name == "Tiểu Kim Long", "Companion has proper wuxia name")
	assert(companion.sprite.texture.resource_path.contains("companion_dragon"), "Dragon sprite assigned")
	print("✔ Companion auto-spawning and initial dragon whelp configuration verified.")
	
	# 2. Test Dynamic Companion Switching (Bạch Hổ Thần Thú)
	GameManager.select_companion("white_tiger")
	assert(companion.companion_id == "white_tiger", "Companion switches to white_tiger dynamically")
	assert(companion.companion_name == "Bạch Hổ Thần Thú", "Companion name updated")
	assert(companion.sprite.texture.resource_path.contains("companion_tiger"), "Tiger sprite assigned")
	assert(companion.attack_damage == 36.0, "Tiger has high melee attack damage")
	print("✔ Dynamic companion switching to Bạch Hổ Thần Thú verified.")
	
	# 3. Test Companion Autonomous Combat Attack
	var bat_scene = load("res://scenes/bat.tscn")
	assert(bat_scene != null, "Bat scene exists")
	var enemy = bat_scene.instantiate()
	enemy.max_health = 150.0
	enemy.current_health = 150.0
	enemy.global_position = companion.global_position + Vector2(60, 0)
	add_child(enemy)
	
	companion.attack_timer = 0.0
	companion._physics_process(0.1)
	assert(enemy.current_health < 150.0, "Companion automatically targeted and damaged enemy")
	enemy.free()
	print("✔ Companion autonomous enemy tracking and attack verified.")
	
	# 4. Test Companion Loot Vacuum (Gems & Coins)
	var gem_scene = load("res://scenes/gem.tscn")
	assert(gem_scene != null, "Gem scene exists")
	var gem = gem_scene.instantiate()
	gem.global_position = companion.global_position + Vector2(50, 0)
	add_child(gem)
	
	companion.vacuum_timer = 0.0
	companion._physics_process(0.1)
	assert(gem.target != null, "Companion vacuum magnetized nearby XP gem to player")
	gem.free()
	print("✔ Companion magnetic loot vacuum verified.")
	
	# 5. Test Hệ Thống Kinh Mạch (Meridian Cultivation & Qi Shield)
	GameManager.total_gold = 5000 # Grant test gold for cultivation
	
	# Test Nhâm Mạch (Qi Shield & Regen)
	assert(player.qi_shield_current == 0.0, "Qi shield starts at 0 without cultivation")
	var bought_nham = GameManager.buy_meridian_upgrade("nham_mach")
	assert(bought_nham == true, "Successfully unlocked Nhâm Mạch Tầng 1")
	assert(GameManager.get_meridian_stat("nham_mach") == 1, "Nhâm Mạch rank is 1")
	player.refresh_meta_stats()
	assert(player.qi_shield_max == 30.0, "Player has 30 Qi Shield capacity")
	assert(player.qi_shield_current == 30.0, "Qi Shield is fully charged")
	
	# Test Qi Shield Damage Absorption
	var full_hp = player.current_health
	var meta_arm = GameManager.get_meta_stat("armor") if GameManager else 0
	var equip_arm = 2 if (GameManager and GameManager.has_equipped("nhuyen_vi_giap")) else 0
	var total_arm = meta_arm + player.char_armor_bonus + equip_arm
	var expected_absorbed = max(1.0, 20.0 - float(total_arm))

	player.take_damage(20.0)
	assert(player.current_health == full_hp, "Player HP unharmed; Qi Shield absorbed the damage")
	assert(player.qi_shield_current == (30.0 - expected_absorbed), "Qi Shield depleted appropriately accounting for armor")
	
	# Test Xung Mạch (Thân Pháp & Speed)
	var speed_before = player.move_speed
	GameManager.buy_meridian_upgrade("xung_mach")
	player.refresh_meta_stats()
	assert(player.move_speed > speed_before, "Xung Mạch increased hero movement swiftness")
	
	# Test Đan Điền (Chi Gathering & Dragon Soul Harvest)
	assert(player.dragon_soul_harvest_mult == 1.0, "Base soul harvest mult is 1.0")
	GameManager.buy_meridian_upgrade("dan_dien")
	player.refresh_meta_stats()
	assert(player.dragon_soul_harvest_mult >= 1.30, "Đan Điền increased Dragon Soul harvest rate by 30%")
	print("✔ Hệ Thống Kinh Mạch (Nhâm Mạch Qi Shield absorption, Xung Mạch speed, Đan Điền harvest) verified.")
	
	# 6. Test Meta Shop Meridian & Companion UI Integration
	var main_scene = load("res://scenes/main.tscn")
	assert(main_scene != null, "Main scene exists")
	var main = main_scene.instantiate()
	add_child(main)
	var hud: HUD = main.get_node("HUD")
	assert(hud != null, "HUD exists in main scene")
	
	hud._open_shop(false)
	assert(hud.shop_panel.visible == true, "Shop panel opens")
	var shop_children = hud.shop_items_container.get_children()
	assert(shop_children.size() >= 10, "Shop displays Meta Upgrades, Kinh Mạch, and Linh Thú sections")
	hud._close_shop()
	
	main.free()
	companion.free()
	player.free()
	print("✔ Meta Shop Meridian Cultivation and Companion UI rendering verified.")
	
	print("=== ALL EXPANSION 11.0 TESTS PASSED CLEANLY! ===")
	get_tree().quit(0)
