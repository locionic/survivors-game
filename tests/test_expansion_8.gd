extends "res://tests/suite_base.gd"

## Comprehensive test suite verifying Expansion 8.0:
## Champions, Affixes, Telegraphed Boss Mechanics, Ancient Relics, and In-Run Bounties.

func _ready() -> void:
	print("=== RUNNING EXPANSION 8.0 CHAMPIONS, BOSS MECHANICS & RELICS TEST SUITE ===")
	
	# 1. Test GameManager Relic System
	GameManager.collected_relics.clear()
	check(GameManager.RELICS.size() >= 6, "At least 6 Relics defined in catalog")
	check(GameManager.has_relic("vampire_fang") == false, "Starts without vampire fang")
	
	GameManager.add_relic("vampire_fang")
	check(GameManager.has_relic("vampire_fang") == true, "Vampire fang successfully added")
	
	# Test Golden Horseshoe (+50% gold bonus)
	var prev_total = GameManager.total_gold
	GameManager.add_relic("golden_horseshoe")
	check(GameManager.has_relic("golden_horseshoe") == true, "Golden horseshoe added")
	GameManager.add_gold(100)
	check(GameManager.total_gold == prev_total + 150, "Golden horseshoe grants 1.5x gold on collection")
	print("✔ GameManager Relics catalog and passive bonuses verified.")
	
	# 2. Test RelicPickup Scene
	var relic_scene = load("res://scenes/relic_pickup.tscn")
	check(relic_scene != null, "RelicPickup scene exists")
	var relic_node = relic_scene.instantiate()
	relic_node.set_relic("chrono_hourglass")
	add_child(relic_node)
	check(relic_node.relic_id == "chrono_hourglass", "Relic ID correctly set on pickup")
	check(relic_node.is_in_group("relics"), "Relic added to relics group")
	relic_node.free()
	print("✔ RelicPickup scene and dynamic configuration verified.")
	
	# 3. Test Player Relic Synergies (Phoenix Feather & Berserker Brand)
	var player_scene = load("res://scenes/player.tscn")
	check(player_scene != null, "Player scene exists")
	var player = player_scene.instantiate()
	add_child(player)
	player.current_health = 100.0
	
	# Test Berserker Brand
	GameManager.add_relic("berserker_brand")
	player.current_health = 30.0 # 30% HP (below 40%)
	player._physics_process(0.016)
	# get_might_multiplier(), not might_multiplier: since Expansion 23.0 the Brand
	# is a getter folded into the composed read, so it lifts the player to at
	# least 1.5x on top of whatever else they had instead of max()-ing one shared
	# field -- and it hands that back the frame they heal past the threshold.
	check(player.get_might_multiplier() >= 1.50, "Berserker Brand boosts might when below 40% HP")
	
	# Test Phoenix Feather Revive
	GameManager.add_relic("phoenix_feather")
	player.char_dodge_bonus = 0.0
	player.drunken_buff_timer = 0.0
	player.current_health = 20.0
	player.take_damage(200.0) # Fatal hit

	check(player.current_health > 0.0, "Phoenix Feather prevents death")
	check(player.phoenix_feather_used == true, "Phoenix Feather marked as used")
	check(player.invulnerability_timer > 1.0, "Phoenix Feather grants invulnerability window")
	player.free()
	print("✔ Player Relic synergies (Phoenix Feather & Berserker Brand) verified.")
	
	# 4. Test In-Run Bounties System
	GameManager.init_run_bounties()
	check(GameManager.active_bounties.size() >= 3, "At least 3 Active bounties initialized")
	
	var initial_gold = GameManager.total_gold
	# Slay 25 bats
	for i in range(25):
		GameManager.record_bounty_event("kill_bat", 1)
		
	var bat_bounty = GameManager.active_bounties[0]
	check(bat_bounty["completed"] == true, "Bat Hunter bounty completes upon 25 bat kills")
	check(GameManager.total_gold >= initial_gold + 40, "Bounty completion grants gold reward")
	print("✔ In-Run Bounties tracking and reward payout verified.")
	
	# 5. Test Elite Champions and Affixes
	var enemy_scene = load("res://scenes/enemy.tscn")
	check(enemy_scene != null, "Enemy scene exists")
	
	# Vampiric Champion
	var champ_vamp = enemy_scene.instantiate()
	add_child(champ_vamp)
	champ_vamp.make_champion("vampiric")
	check(champ_vamp.is_champion == true, "Marked as champion")
	check(champ_vamp.champion_affix == "vampiric", "Vampiric affix applied")
	check(champ_vamp.max_health > 25.0, "Champion has increased max health")
	check(champ_vamp.champ_nameplate != null, "Champion has overhead affix badge")
	champ_vamp.free()
	
	# Glacial Champion
	var champ_glac = enemy_scene.instantiate()
	add_child(champ_glac)
	champ_glac.make_champion("glacial")
	check(champ_glac.champion_affix == "glacial", "Glacial affix applied")
	champ_glac.free()
	
	# Volatile Champion
	var champ_vol = enemy_scene.instantiate()
	add_child(champ_vol)
	champ_vol.make_champion("volatile")
	check(champ_vol.champion_affix == "volatile", "Volatile affix applied")
	champ_vol.free()
	
	# Swift Champion
	var champ_swift = enemy_scene.instantiate()
	add_child(champ_swift)
	var base_spd = champ_swift.move_speed
	champ_swift.make_champion("swift")
	check(champ_swift.champion_affix == "swift", "Swift affix applied")
	check(champ_swift.move_speed > base_spd, "Swift champion has boosted movement speed")
	champ_swift.free()
	print("✔ All 4 Champion affixes (Vampiric, Glacial, Volatile, Swift) verified.")
	
	# 6. Test Boss Telegraphed Moves
	var boss_scene = load("res://scenes/boss.tscn")
	check(boss_scene != null, "Boss scene exists")
	var boss = boss_scene.instantiate()
	add_child(boss)
	check(boss.is_boss == true, "Boss recognized as boss unit")
	check(boss.boss_slam_timer > 0.0, "Boss slam timer initialized")
	check(boss.boss_charge_timer > 0.0, "Boss charge timer initialized")
	
	# Test Slam execution
	boss.is_telegraphing = true
	boss.telegraph_type = "slam"
	boss._execute_boss_telegraph()
	check(boss.is_telegraphing == false, "Telegraph state finishes after execution")
	check(boss.boss_slam_timer > 5.0, "Boss slam timer resets to full cooldown")
	
	# Test Charge execution
	boss.is_telegraphing = true
	boss.telegraph_type = "charge"
	boss._execute_boss_telegraph()
	check(boss.charge_duration_remaining > 0.0, "Boss enters charge forward phase")
	check(boss.boss_charge_timer > 5.0, "Boss charge timer resets to full cooldown")
	boss.free()
	print("✔ Telegraphed Boss Ground Slam and Bull Rush verified.")
	
	if _failures.is_empty():
		print("=== ALL EXPANSION 8.0 TESTS PASSED SUCCESSFULLY! ===")
	get_tree().quit(_exit_code())
