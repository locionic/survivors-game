extends Node

## Comprehensive test suite verifying Expansion 12.0:
## Võ Học Bí Tịch & Thất Long Châu (Martial Arts Scrolls & Seven Dragon Pearls).

func _ready() -> void:
	print("=== RUNNING EXPANSION 12.0 MARTIAL SCROLLS & SEVEN DRAGON PEARLS TEST SUITE ===")
	
	# Reset state hermetically
	GameManager.dragon_pearls_collected = 0
	GameManager.collected_scrolls.clear()
	GameManager.shenron_wishes_used = 0
	GameManager.meridian_upgrades = {"nham_mach": 0, "doc_mach": 0, "xung_mach": 0, "dan_dien": 0}
	
	# 1. Setup Player
	GameManager.select_character("knight")
	var player_scene = load("res://scenes/player.tscn")
	assert(player_scene != null, "Player scene exists")
	var player = player_scene.instantiate()
	add_child(player)
	player.apply_character_data()
	player.refresh_meta_stats()
	await get_tree().process_frame
	
	# 2. Test Dragon Pearls Collection & Signals
	assert(GameManager.dragon_pearls_collected == 0, "Starts with 0 Dragon Pearls")
	var pearl_signal_state = {"collected_count": 0, "last_index": 0}
	GameManager.dragon_pearl_collected.connect(func(idx, _tot):
		pearl_signal_state["collected_count"] += 1
		pearl_signal_state["last_index"] = idx
	)
	
	var summon_ready_state = {"fired": false}
	GameManager.shenron_summon_ready.connect(func():
		summon_ready_state["fired"] = true
	)
	
	# Collect 6 pearls
	for i in range(1, 7):
		var success = GameManager.collect_dragon_pearl()
		assert(success == true, "Successfully collected pearl %d" % i)
		assert(GameManager.dragon_pearls_collected == i, "Dragon pearls count is %d" % i)
	assert(summon_ready_state["fired"] == false, "Shenron summon not ready before 7th pearl")
	
	# Collect 7th pearl
	var success_7 = GameManager.collect_dragon_pearl()
	assert(success_7 == true, "Collected 7th dragon pearl")
	assert(GameManager.dragon_pearls_collected == 7, "All 7 Dragon Pearls collected")
	assert(summon_ready_state["fired"] == true, "shenron_summon_ready signal fired on 7th pearl")
	print("✔ Thất Long Châu (Seven Dragon Pearls) accumulation & Shenron summon trigger verified.")
	
	# 3. Test PearlPickup Scene & Magnetic Attraction
	var pearl_scene = load("res://scenes/pearl_pickup.tscn")
	assert(pearl_scene != null, "PearlPickup scene exists")
	var pearl_pickup = pearl_scene.instantiate()
	pearl_pickup.global_position = player.global_position + Vector2(40, 0)
	add_child(pearl_pickup)
	pearl_pickup.target_player(player)
	assert(pearl_pickup.target == player, "Pearl pickup targets player on magnetic vacuum")
	pearl_pickup.free()
	print("✔ PearlPickup scene & vacuum targeting verified.")
	
	# 4. Test Shenron Wish Choices
	var initial_gold = GameManager.total_gold
	player.apply_shenron_wish("wish_wealth")
	assert(GameManager.total_gold == initial_gold + 1500, "Wish 1 (Kim Sơn Bạc Hải) grants +1500 gold")
	assert(player.golden_frenzy_timer > 0.0, "Golden Frenzy timer active")
	
	var base_max_hp = player.max_health
	player.apply_shenron_wish("wish_immortality")
	assert(player.max_health == base_max_hp + 100.0, "Wish 2 (Bất Tử Chân Thân) adds +100 Max HP")
	assert(player.current_health == player.max_health, "Restores HP to 100%")
	assert(player.qi_shield_max >= 50.0, "Boosts Qi Shield capacity")
	assert(player.phoenix_feather_used == false, "Resets Phoenix Rebirth availability")
	
	player.apply_shenron_wish("wish_swords")
	assert(player.van_kiem_timer == 20.0, "Wish 3 (Vạn Kiếm Quy Tông) activates 20s sword storm")
	print("✔ Thần Long (Shenron) 3 Wishes (Wealth, Immortality, Ten Thousand Swords) verified.")
	
	# 5. Test Martial Arts Scrolls (Võ Học Bí Tịch) System
	assert(GameManager.MARTIAL_SCROLLS.size() == 3, "3 Martial Scrolls defined in catalog")
	assert(GameManager.has_scroll("yijinjing") == false, "Player starts without Dịch Cân Kinh")
	
	# Test ScrollPickup Scene
	var scroll_scene = load("res://scenes/scroll_pickup.tscn")
	assert(scroll_scene != null, "ScrollPickup scene exists")
	var scroll_pickup = scroll_scene.instantiate()
	scroll_pickup.set_scroll("yijinjing")
	add_child(scroll_pickup)
	assert(scroll_pickup.scroll_id == "yijinjing", "Scroll ID set correctly")
	scroll_pickup.free()
	print("✔ ScrollPickup scene & dynamic setup verified.")
	
	# 6. Test Dịch Cân Kinh (Sư Tử Hống Shockwave)
	var bat_scene = load("res://scenes/bat.tscn")
	assert(bat_scene != null, "Bat scene exists")
	var enemy1 = bat_scene.instantiate()
	enemy1.max_health = 200.0
	enemy1.current_health = 200.0
	enemy1.global_position = player.global_position + Vector2(100, 0)
	add_child(enemy1)
	
	GameManager.add_scroll("yijinjing")
	assert(GameManager.has_scroll("yijinjing") == true, "Dịch Cân Kinh added to player scrolls")
	player._trigger_yijinjing_pulse()
	assert(enemy1.current_health < 200.0, "Lion's Roar shockwave damaged enemy")
	assert(enemy1.knockback.x > 0.0, "Lion's Roar knocked enemy backwards")
	enemy1.free()
	print("✔ Bí Tịch: Dịch Cân Kinh (Sư Tử Hống shockwave & knockback) verified.")
	
	# 7. Test Lục Mạch Thần Kiếm (Qi Laser Swords)
	var enemy2 = bat_scene.instantiate()
	enemy2.max_health = 100.0
	enemy2.current_health = 100.0
	enemy2.global_position = player.global_position + Vector2(120, 0)
	add_child(enemy2)
	
	GameManager.add_scroll("lucmach")
	assert(GameManager.has_scroll("lucmach") == true, "Lục Mạch Thần Kiếm added")
	player._fire_lucmach_beam()
	var spirit_swords = get_tree().get_nodes_in_group("projectiles")
	assert(spirit_swords.size() > 0, "Flying Spirit Sword projectile spawned")
	enemy2.free()
	print("✔ Bí Tịch: Lục Mạch Thần Kiếm (Finger Qi spirit sword projectile) verified.")
	
	# 8. Test Thái Cực Kiếm Trận (Taoist Yin-Yang Aura Slowing)
	var enemy3 = bat_scene.instantiate()
	enemy3.global_position = player.global_position + Vector2(60, 0)
	add_child(enemy3)
	
	GameManager.add_scroll("thaicuc")
	player._process_thaicuc_aura(0.1)
	assert(enemy3.slow_multiplier <= 0.55, "Thái Cực Đồ aura slows enemy movement by 50%")
	enemy3.free()
	print("✔ Bí Tịch: Thái Cực Kiếm Trận (Taoist aura mob slowing) verified.")
	
	# 9. Test HUD Dragon Pearl Tray & Shenron Modal Integration
	var main_scene = load("res://scenes/main.tscn")
	assert(main_scene != null, "Main scene exists")
	var main = main_scene.instantiate()
	add_child(main)
	var hud: HUD = main.get_node("HUD")
	assert(hud != null, "HUD exists in main scene")
	assert(hud.pearl_tray != null, "Dragon Pearl Tray initialized on TopBar")
	assert(hud.pearl_labels.size() == 7, "7 Star slots in pearl tray")
	
	# Simulate collecting 3 pearls and check labels
	hud._on_dragon_pearl_collected(3, 7)
	assert(hud.pearl_labels[0].text == "⭐", "Slot 1 is active star")
	assert(hud.pearl_labels[1].text == "⭐", "Slot 2 is active star")
	assert(hud.pearl_labels[2].text == "⭐", "Slot 3 is active star")
	assert(hud.pearl_labels[3].text == "⚪", "Slot 4 is empty")
	
	# Test Shenron Wish Modal opening and card population
	assert(hud.shenron_modal != null, "ShenronWishModal initialized")
	hud._open_shenron_modal()
	assert(hud.shenron_modal.visible == true, "Shenron Wish Modal opens")
	var cards = hud.shenron_cards_container.get_children()
	assert(cards.size() == 3, "3 Wish cards populated in modal")
	
	# Choose a wish through UI
	hud._choose_shenron_wish("wish_wealth")
	assert(hud.shenron_modal.visible == false, "Modal closes upon wish selection")
	assert(get_tree().paused == false, "Game unpaused after choosing wish")
	print("✔ HUD Dragon Pearl Tray & Shenron Wish Modal interactive UI verified.")
	
	main.free()
	player.free()
	
	print("=== ALL EXPANSION 12.0 TESTS PASSED CLEANLY! ===")
	get_tree().quit(0)
