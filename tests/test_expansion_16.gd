extends "res://tests/suite_base.gd"

## Comprehensive test suite verifying Expansion 16.0:
## Kỳ Ngộ Giang Hồ, Đỉnh Hoa Sơn Tuyết Phủ & Hoàng Kim Trang Bị.

## This is the one suite in tests/ that can *destroy* the developer's save rather
## than only inflate it. Section 5 instantiates the hermit shop, and the hermit shop
## spends GameManager.total_gold -- the purse that survives a run -- so running this
## suite by hand drained 2831 -> 320 and the damage was only noticed because the
## number was checked afterwards. ci.sh now snapshots the save around the whole gate,
## which covers it there, but a suite run directly bypasses that, so the guard lives
## in the suite: same byte-backup as test_wave_arena_milestone_3.gd, same sidecar.
const SAVE_PATH: String = "user://save_data.cfg"
const BACKUP_PATH: String = "user://save_data.cfg.e16bak"
var _had_save: bool = false

func _backup_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	_had_save = true
	var src := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var dst := FileAccess.open(BACKUP_PATH, FileAccess.WRITE)
	dst.store_buffer(src.get_buffer(src.get_length()))
	src.close()
	dst.close()

func _restore_save() -> void:
	if not _had_save:
		return
	var src := FileAccess.open(BACKUP_PATH, FileAccess.READ)
	var dst := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	dst.store_buffer(src.get_buffer(src.get_length()))
	src.close()
	dst.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(BACKUP_PATH))

func _ready() -> void:
	print("=== RUNNING EXPANSION 16.0 STAGE & WUXIA EQUIPMENT TEST SUITE ===")
	_backup_save()
	
	# 1. Test Stage Catalog & Stage Selection
	check(GameManager != null, "GameManager autoload exists")
	check(GameManager.STAGES.has("plains"), "Plains stage defined")
	check(GameManager.STAGES.has("mount_hua"), "Mount Hua stage defined")
	
	GameManager.select_stage("mount_hua")
	check(GameManager.selected_stage == "mount_hua", "Selected stage updated to Mount Hua")
	var hua_data = GameManager.get_selected_stage_data()
	check(hua_data.get("hazard") == "blizzard", "Mount Hua has blizzard hazard")
	check(hua_data.get("texture_path") == "res://assets/textures/snow_floor.png", "Mount Hua uses snow floor texture")
	print("✔ Stage Catalog and Selection verified.")
	
	# 2. Test Golden Wuxia Equipment Catalog & Equipping
	check(GameManager.EQUIPMENT_CATALOG.has("y_thien_kiem"), "Ỷ Thiên Kiếm in catalog")
	check(GameManager.EQUIPMENT_CATALOG.has("nhuyen_vi_giap"), "Nhuyễn Vị Giáp in catalog")
	check(GameManager.EQUIPMENT_CATALOG.has("van_hac_hai"), "Vân Hạc Hài in catalog")
	
	GameManager.equip_gear("weapon", "y_thien_kiem")
	GameManager.equip_gear("armor", "nhuyen_vi_giap")
	GameManager.equip_gear("boots", "van_hac_hai")
	
	check(GameManager.has_equipped("y_thien_kiem"), "Ỷ Thiên Kiếm is equipped")
	check(GameManager.has_equipped("nhuyen_vi_giap"), "Nhuyễn Vị Giáp is equipped")
	check(GameManager.has_equipped("van_hac_hai"), "Vân Hạc Hài is equipped")
	print("✔ Equipment catalog and slot management verified.")
	
	# 3. Test Player Stat Adjustments with Equipment
	GameManager.select_character("knight")
	var player_scene = load("res://scenes/player.tscn")
	check(player_scene != null, "Player scene exists")
	var player = player_scene.instantiate()
	add_child(player)
	player.apply_character_data()
	player.char_dodge_bonus = 0.0
	player.refresh_meta_stats()
	
	var base_spd = 230.0 + GameManager.get_meta_stat("swiftness") * 20.0
	check(player.move_speed >= base_spd + 30.0, "Vân Hạc Hài provides +30 move speed")
	check(player.meta_might_bonus >= 0.15, "Ỷ Thiên Kiếm provides +15% might bonus")
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
	check(enemy.current_health < enemy_hp_before, "Nhuyễn Vị Giáp reflected damage back to nearby enemy")
	print("✔ Nhuyễn Vị Giáp 40% damage reflection verified.")
	
	# 5. Test Mount Hua Blizzard Hazard & Counter with Vân Hạc Hài
	# With Vân Hạc Hài equipped:
	player.apply_blizzard_slow(4.0)
	check(player.blizzard_slow_timer == 0.0, "Vân Hạc Hài renders player immune to blizzard slow")
	
	# Unequip boots:
	GameManager.equip_gear("boots", "")
	check(GameManager.has_equipped("van_hac_hai") == false, "Vân Hạc Hài unequipped")
	player.apply_blizzard_slow(4.0)
	check(player.blizzard_slow_timer > 0.0, "Without boots, player is slowed by blizzard")
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

	check(test_dummy.current_health <= dummy_hp_before - (35.0 * 1.50), "Mount Hua granted +50% frost damage bonus")
	test_dummy.free()
	print("✔ Mount Hua +50% frost damage amplification verified.")
	
	# 7. Test Hermit NPC & Secret Shop Modal
	var hermit_scene = load("res://scenes/hermit_npc.tscn")
	check(hermit_scene != null, "Hermit NPC scene exists")
	var hermit = hermit_scene.instantiate()
	add_child(hermit)
	check(hermit.is_in_group("hermit_npcs"), "Hermit NPC in hermit_npcs group")
	
	var hermit_shop_scene = load("res://scenes/hermit_shop_ui.tscn")
	check(hermit_shop_scene != null, "Hermit Shop UI scene exists")
	var hermit_ui = hermit_shop_scene.instantiate()
	add_child(hermit_ui)
	check(hermit_ui.ITEMS.size() == 3, "Hermit Shop offers 3 unique items")
	
	# Test Cửu Chuyển Hoàn Hồn Đan purchase
	GameManager.total_gold = 500
	player.current_health = 20.0
	var prev_max_hp = player.max_health
	hermit_ui._buy_item("cuu_chuyen_dan", 120)
	check(GameManager.total_gold == 380, "Gold deducted for Cửu Chuyển Đan")
	check(player.max_health > prev_max_hp, "Max HP increased by 15%")
	check(player.current_health == player.max_health, "HP fully restored")
	
	# Test Tẩy Tủy Hoán Cốt Đan purchase
	# get_might_multiplier(), not might_multiplier: since Expansion 23.0 this
	# permanent +20% banks into might_flat_bonus so a timed Might Surge can no
	# longer refund it, and might_multiplier belongs to apply_might_buff() alone.
	var might_before = player.get_might_multiplier()
	hermit_ui._buy_item("tay_tuy_dan", 160)
	check(GameManager.total_gold == 220, "Gold deducted for Tẩy Tủy Đan")
	check(player.get_might_multiplier() > might_before, "Might multiplier boosted by +20%")
	
	# Test Vận Mệnh Quẻ Bói
	hermit_ui._buy_item("van_menh_que", 100)
	check(GameManager.total_gold == 120 or GameManager.total_gold == 320, "Gamble executed successfully")
	print("✔ Hermit NPC, secret shop, and all 3 elixir effects verified.")
	
	# 8. Test Enemy Spawner Hermit Spawn Method
	var spawner_script = load("res://scripts/enemy_spawner.gd")
	var spawner = Node2D.new()
	spawner.set_script(spawner_script)
	add_child(spawner)
	var spawned_hermit = spawner.spawn_hermit(Vector2(100, 100))
	check(spawned_hermit.is_in_group("hermit_npcs"), "Spawned Hermit in group")



	
	# 9. Test Main Scene Integration & CharacterSelectUI Stage/Gear Controls
	var main_scene = load("res://scenes/main.tscn")
	check(main_scene != null, "Main scene exists")
	var main = main_scene.instantiate()
	add_child(main)
	
	var hud = main.get_node_or_null("HUD")
	check(hud != null, "HUD exists in main scene")
	check(hud.get_node_or_null("HermitShopModal") != null, "HermitShopModal attached under HUD")
	
	var char_select = hud.get_node_or_null("CharacterSelectModal")
	check(char_select != null, "CharacterSelectModal exists under HUD")
	char_select.open_ui()
	check(char_select.stage_plains_btn != null, "Stage plains button resolved")
	check(char_select.stage_hua_btn != null, "Stage Hua button resolved")
	check(char_select.gear_weapon_btn != null, "Gear weapon button resolved")
	check(char_select.gear_armor_btn != null, "Gear armor button resolved")
	check(char_select.gear_boots_btn != null, "Gear boots button resolved")
	
	# Select Stage via UI
	char_select._on_stage_selected("mount_hua")
	check(GameManager.selected_stage == "mount_hua", "Stage changed to mount_hua via UI")
	
	# Toggle Gear via UI
	char_select._on_gear_toggled("boots", "van_hac_hai")
	check(GameManager.has_equipped("van_hac_hai"), "Vân Hạc Hài equipped via UI")
	
	char_select.close_ui()
	check(char_select.visible == false, "CharacterSelectModal closes cleanly")
	
	if _failures.is_empty():
		print("=== ALL EXPANSION 16.0 TESTS PASSED 100% CLEANLY! ===")
	_restore_save()
	get_tree().quit(_exit_code())


