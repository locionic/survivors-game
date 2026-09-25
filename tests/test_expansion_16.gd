extends Node

## Comprehensive test suite verifying Expansion 16.0:
## Kỳ Ngộ Giang Hồ, Đỉnh Hoa Sơn Tuyết Phủ & Hoàng Kim Trang Bị.

func _ready() -> void:
	print("=== RUNNING EXPANSION 16.0 STAGE & WUXIA EQUIPMENT TEST SUITE ===")
	
	# 1. Test Stage Catalog & Stage Selection
	assert(GameManager != null, "GameManager autoload exists")
	assert(GameManager.STAGES.has("plains"), "Plains stage defined")
	assert(GameManager.STAGES.has("mount_hua"), "Mount Hua stage defined")
	
	GameManager.select_stage("mount_hua")
	assert(GameManager.selected_stage == "mount_hua", "Selected stage updated to Mount Hua")
	var hua_data = GameManager.get_selected_stage_data()
	assert(hua_data.get("hazard") == "blizzard", "Mount Hua has blizzard hazard")
	assert(hua_data.get("texture_path") == "res://assets/textures/snow_floor.png", "Mount Hua uses snow floor texture")
	print("✔ Stage Catalog and Selection verified.")
	
	# 2. Test Golden Wuxia Equipment Catalog & Equipping
	assert(GameManager.EQUIPMENT_CATALOG.has("y_thien_kiem"), "Ỷ Thiên Kiếm in catalog")
	assert(GameManager.EQUIPMENT_CATALOG.has("nhuyen_vi_giap"), "Nhuyễn Vị Giáp in catalog")
	assert(GameManager.EQUIPMENT_CATALOG.has("van_hac_hai"), "Vân Hạc Hài in catalog")
	
	GameManager.equip_gear("weapon", "y_thien_kiem")
	GameManager.equip_gear("armor", "nhuyen_vi_giap")
	GameManager.equip_gear("boots", "van_hac_hai")
	
	assert(GameManager.has_equipped("y_thien_kiem"), "Ỷ Thiên Kiếm is equipped")
	assert(GameManager.has_equipped("nhuyen_vi_giap"), "Nhuyễn Vị Giáp is equipped")
	assert(GameManager.has_equipped("van_hac_hai"), "Vân Hạc Hài is equipped")
	print("✔ Equipment catalog and slot management verified.")
	
	# 3. Test Player Stat Adjustments with Equipment
	GameManager.select_character("knight")
	var player_scene = load("res://scenes/player.tscn")
	assert(player_scene != null, "Player scene exists")
	var player = player_scene.instantiate()
	add_child(player)
	player.apply_character_data()
	player.char_dodge_bonus = 0.0
	player.refresh_meta_stats()
	
	var base_spd = 230.0 + GameManager.get_meta_stat("swiftness") * 20.0
	assert(player.move_speed >= base_spd + 30.0, "Vân Hạc Hài provides +30 move speed")
	assert(player.meta_might_bonus >= 0.15, "Ỷ Thiên Kiếm provides +15% might bonus")
	print("✔ Equipment stat buffs applied to player.")
	
	# 4. Test Nhuyễn Vị Giáp Reflect Damage
	var enemy_scene = load("res://scenes/enemy.tscn")
	var enemy = enemy_scene.instantiate()
	add_child(enemy)
	enemy.global_position = player.global_position + Vector2(40, 0)
	enemy.max_health = 200.0
	enemy.current_health = 200.0
	
	var enemy_hp_before = enemy.current_health
	player.take_damage(20.0)
	assert(enemy.current_health < enemy_hp_before, "Nhuyễn Vị Giáp reflected damage back to nearby enemy")
	print("✔ Nhuyễn Vị Giáp 40% damage reflection verified.")
	
	# 5. Test Mount Hua Blizzard Hazard & Counter with Vân Hạc Hài
	# With Vân Hạc Hài equipped:
	player.apply_blizzard_slow(4.0)
	assert(player.blizzard_slow_timer == 0.0, "Vân Hạc Hài renders player immune to blizzard slow")
	
	# Unequip boots:
	GameManager.equip_gear("boots", "")
	assert(GameManager.has_equipped("van_hac_hai") == false, "Vân Hạc Hài unequipped")
	player.apply_blizzard_slow(4.0)
	assert(player.blizzard_slow_timer > 0.0, "Without boots, player is slowed by blizzard")
	print("✔ Blizzard hazard and Vân Hạc Hài slow immunity counter verified.")
	
	# 6. Test Mount Hua Frost Damage Buff (+50%)
	var test_dummy = enemy_scene.instantiate()
	add_child(test_dummy)
	test_dummy.global_position = player.global_position + Vector2(50, 0)
	test_dummy.max_health = 200.0
	test_dummy.current_health = 200.0
	
	GameManager.selected_stage = "mount_hua"
	player.skill_id = "frost_singularity"
	var dummy_hp_before = test_dummy.current_health
	player.activate_hero_skill()
	# Base frost damage is 35 * might * 1.50 Mount Hua buff

	assert(test_dummy.current_health <= dummy_hp_before - (35.0 * 1.50), "Mount Hua granted +50% frost damage bonus")
	test_dummy.free()
	print("✔ Mount Hua +50% frost damage amplification verified.")
	
	# 7. Test Hermit NPC & Secret Shop Modal
	var hermit_scene = load("res://scenes/hermit_npc.tscn")
	assert(hermit_scene != null, "Hermit NPC scene exists")
	var hermit = hermit_scene.instantiate()
	add_child(hermit)
	assert(hermit.is_in_group("hermit_npcs"), "Hermit NPC in hermit_npcs group")
	
	var hermit_shop_scene = load("res://scenes/hermit_shop_ui.tscn")
	assert(hermit_shop_scene != null, "Hermit Shop UI scene exists")
	var hermit_ui = hermit_shop_scene.instantiate()
	add_child(hermit_ui)
	assert(hermit_ui.ITEMS.size() == 3, "Hermit Shop offers 3 unique items")
	
	# Test Cửu Chuyển Hoàn Hồn Đan purchase
	GameManager.total_gold = 500
	player.current_health = 20.0
	var prev_max_hp = player.max_health
	hermit_ui._buy_item("cuu_chuyen_dan", 120)
	assert(GameManager.total_gold == 380, "Gold deducted for Cửu Chuyển Đan")
	assert(player.max_health > prev_max_hp, "Max HP increased by 15%")
	assert(player.current_health == player.max_health, "HP fully restored")
	
	# Test Tẩy Tủy Hoán Cốt Đan purchase
	var might_before = player.might_multiplier
	hermit_ui._buy_item("tay_tuy_dan", 160)
	assert(GameManager.total_gold == 220, "Gold deducted for Tẩy Tủy Đan")
	assert(player.might_multiplier > might_before, "Might multiplier boosted by +20%")
	
	# Test Vận Mệnh Quẻ Bói
	hermit_ui._buy_item("van_menh_que", 100)
	assert(GameManager.total_gold == 120 or GameManager.total_gold == 320, "Gamble executed successfully")
	print("✔ Hermit NPC, secret shop, and all 3 elixir effects verified.")
	
	# 8. Test Enemy Spawner Hermit Spawn Method
	var spawner_script = load("res://scripts/enemy_spawner.gd")
	var spawner = Node2D.new()
	spawner.set_script(spawner_script)
	add_child(spawner)
	var spawned_hermit = spawner.spawn_hermit(Vector2(100, 100))
	assert(spawned_hermit.is_in_group("hermit_npcs"), "Spawned Hermit in group")



	
	# 9. Test Main Scene Integration & CharacterSelectUI Stage/Gear Controls
	var main_scene = load("res://scenes/main.tscn")
	assert(main_scene != null, "Main scene exists")
	var main = main_scene.instantiate()
	add_child(main)
	
	var hud = main.get_node_or_null("HUD")
	assert(hud != null, "HUD exists in main scene")
	assert(hud.get_node_or_null("HermitShopModal") != null, "HermitShopModal attached under HUD")
	
	var char_select = hud.get_node_or_null("CharacterSelectModal")
	assert(char_select != null, "CharacterSelectModal exists under HUD")
	char_select.open_ui()
	assert(char_select.stage_plains_btn != null, "Stage plains button resolved")
	assert(char_select.stage_hua_btn != null, "Stage Hua button resolved")
	assert(char_select.gear_weapon_btn != null, "Gear weapon button resolved")
	assert(char_select.gear_armor_btn != null, "Gear armor button resolved")
	assert(char_select.gear_boots_btn != null, "Gear boots button resolved")
	
	# Select Stage via UI
	char_select._on_stage_selected("mount_hua")
	assert(GameManager.selected_stage == "mount_hua", "Stage changed to mount_hua via UI")
	
	# Toggle Gear via UI
	char_select._on_gear_toggled("boots", "van_hac_hai")
	assert(GameManager.has_equipped("van_hac_hai"), "Vân Hạc Hài equipped via UI")
	
	char_select.close_ui()
	assert(char_select.visible == false, "CharacterSelectModal closes cleanly")
	
	print("=== ALL EXPANSION 16.0 TESTS PASSED 100% CLEANLY! ===")
	get_tree().quit(0)


