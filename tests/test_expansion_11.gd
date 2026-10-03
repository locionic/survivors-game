extends "res://tests/suite_base.gd"

## Comprehensive test suite verifying Expansion 11.0:
## Linh Thú Companions & Hệ Thống Kinh Mạch (Meridian Cultivation).

## Expansion 48.0: this suite was the one leaking into the rest of the gate. Every
## suite shares one user://save_data.cfg, this one runs early in the alphabetical
## order, and it both buys a meridian and hands itself 5000 gold -- and
## buy_meridian_upgrade() calls save_game_data() on its way out. The nham_mach rank
## it bought survived into later runs, so a player spawned with a 30-point Qi Shield,
## and the three suites that deal exactly 30 damage to check that HP drops (19, 20 and
## hit_stop) then watched the shield absorb it and reported a false failure. The
## shield was right; the suites that could not see it were wrong.
const SAVE_PATH: String = "user://save_data.cfg"
const BACKUP_PATH: String = "user://save_data.cfg.e11bak"
var _had_save: bool = false

func _backup_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
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
	print("=== RUNNING EXPANSION 11.0 COMPANIONS & MERIDIAN CULTIVATION TEST SUITE ===")
	_backup_save()
	
	# 1. Setup Player & Test Companion Spawning
	GameManager.meridian_upgrades = {
		"nham_mach": 0,
		"doc_mach": 0,
		"xung_mach": 0,
		"dan_dien": 0
	}
	# The character is deliberately NOT pinned here, and the expectation below is
	# derived from the player rather than from a hand-rebuilt formula precisely so it
	# does not need to be. This suite has no save backup/restore sidecar, so a
	# select_character() would persist to the one save every suite shares and reach
	# the twenty-odd suites that run after it alphabetically.
	GameManager.select_companion("dragon_whelp")
	var player_scene = load("res://scenes/player.tscn")
	check(player_scene != null, "Player scene exists")
	var player = player_scene.instantiate()
	add_child(player)
	player.apply_character_data()
	player.refresh_meta_stats()
	await get_tree().process_frame
	
	# Verify Companion auto-spawned alongside Player
	var companions = get_tree().get_nodes_in_group("companions")
	check(companions.size() == 1, "Companion is spawned into scene")
	var companion = companions[0]
	check(companion.companion_id == "dragon_whelp", "Companion starts as dragon_whelp")
	check(companion.companion_name == "Tiểu Kim Long", "Companion has proper wuxia name")
	check(companion.sprite.texture.resource_path.contains("companion_dragon"), "Dragon sprite assigned")
	print("✔ Companion auto-spawning and initial dragon whelp configuration verified.")
	
	# 2. Test Dynamic Companion Switching (Bạch Hổ Thần Thú)
	GameManager.select_companion("white_tiger")
	check(companion.companion_id == "white_tiger", "Companion switches to white_tiger dynamically")
	check(companion.companion_name == "Bạch Hổ Thần Thú", "Companion name updated")
	check(companion.sprite.texture.resource_path.contains("companion_tiger"), "Tiger sprite assigned")
	check(companion.attack_damage == 36.0, "Tiger has high melee attack damage")
	print("✔ Dynamic companion switching to Bạch Hổ Thần Thú verified.")
	
	# 3. Test Companion Autonomous Combat Attack
	var bat_scene = load("res://scenes/bat.tscn")
	check(bat_scene != null, "Bat scene exists")
	var enemy = bat_scene.instantiate()
	enemy.max_health = 150.0
	enemy.current_health = 150.0
	enemy.global_position = companion.global_position + Vector2(60, 0)
	add_child(enemy)
	
	companion.attack_timer = 0.0
	companion._physics_process(0.1)
	check(enemy.current_health < 150.0, "Companion automatically targeted and damaged enemy")
	enemy.free()
	print("✔ Companion autonomous enemy tracking and attack verified.")
	
	# 4. Test Companion Loot Vacuum (Gems & Coins)
	var gem_scene = load("res://scenes/gem.tscn")
	check(gem_scene != null, "Gem scene exists")
	var gem = gem_scene.instantiate()
	gem.global_position = companion.global_position + Vector2(50, 0)
	add_child(gem)
	
	companion.vacuum_timer = 0.0
	companion._physics_process(0.1)
	check(gem.target != null, "Companion vacuum magnetized nearby XP gem to player")
	gem.free()
	print("✔ Companion magnetic loot vacuum verified.")
	
	# 5. Test Hệ Thống Kinh Mạch (Meridian Cultivation & Qi Shield)
	GameManager.total_gold = 5000 # Grant test gold for cultivation
	
	# Test Nhâm Mạch (Qi Shield & Regen)
	check(player.qi_shield_current == 0.0, "Qi shield starts at 0 without cultivation")
	var bought_nham = GameManager.buy_meridian_upgrade("nham_mach")
	check(bought_nham == true, "Successfully unlocked Nhâm Mạch Tầng 1")
	check(GameManager.get_meridian_stat("nham_mach") == 1, "Nhâm Mạch rank is 1")
	player.refresh_meta_stats()
	check(player.qi_shield_max == 30.0, "Player has 30 Qi Shield capacity")
	check(player.qi_shield_current == 30.0, "Qi Shield is fully charged")
	
	# Test Qi Shield Damage Absorption
	var full_hp = player.current_health
	# Ask the player rather than restate the formula, which is what Expansion 46.0
	# did to the HUD's two ARMOR readouts for the same reason. take_damage() applies
	# max(1, amount - get_armor_bonus()) * char_damage_taken_mult, and this block
	# rebuilt the first half by hand: it missed shop_armor_bonus, the fourth term
	# get_armor_bonus() grew in 46.0, and it dropped the character multiplier
	# altogether. The suite inherits its character from the save rather than pinning
	# one, so whenever that save held Ignis (damage_taken_mult 1.15) the shield was
	# correctly drained 15% deeper than this expectation and the assert below failed.
	var expected_absorbed = max(1.0, 20.0 - float(player.get_armor_bonus())) * player.char_damage_taken_mult

	player.take_damage(20.0)
	check(player.current_health == full_hp, "Player HP unharmed; Qi Shield absorbed the damage")
	check(player.qi_shield_current == (30.0 - expected_absorbed), "Qi Shield depleted appropriately accounting for armor")
	
	# Test Xung Mạch (Thân Pháp & Speed)
	var speed_before = player.move_speed
	GameManager.buy_meridian_upgrade("xung_mach")
	player.refresh_meta_stats()
	check(player.move_speed > speed_before, "Xung Mạch increased hero movement swiftness")
	
	# Test Đan Điền (Chi Gathering & Dragon Soul Harvest)
	check(player.dragon_soul_harvest_mult == 1.0, "Base soul harvest mult is 1.0")
	GameManager.buy_meridian_upgrade("dan_dien")
	player.refresh_meta_stats()
	check(player.dragon_soul_harvest_mult >= 1.30, "Đan Điền increased Dragon Soul harvest rate by 30%")
	print("✔ Hệ Thống Kinh Mạch (Nhâm Mạch Qi Shield absorption, Xung Mạch speed, Đan Điền harvest) verified.")
	
	# 6. Test Meta Shop Meridian & Companion UI Integration
	var main_scene = load("res://scenes/main.tscn")
	check(main_scene != null, "Main scene exists")
	var main = main_scene.instantiate()
	add_child(main)
	var hud: HUD = main.get_node("HUD")
	check(hud != null, "HUD exists in main scene")
	
	hud._open_shop(false)
	check(hud.shop_panel.visible == true, "Shop panel opens")
	var shop_children = hud.shop_items_container.get_children()
	check(shop_children.size() >= 10, "Shop displays Meta Upgrades, Kinh Mạch, and Linh Thú sections")
	hud._close_shop()
	
	main.free()
	companion.free()
	player.free()
	print("✔ Meta Shop Meridian Cultivation and Companion UI rendering verified.")
	
	if _failures.is_empty():
		print("=== ALL EXPANSION 11.0 TESTS PASSED CLEANLY! ===")
	_restore_save()
	get_tree().quit(_exit_code())
