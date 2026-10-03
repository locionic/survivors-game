extends "res://tests/suite_base.gd"

## Automated Test Suite for Expansion 20.0:
## "Tinh Võ Hợp Nhất & Tinh Anh Lệnh"
## Verifies dual-weapon synergy fusions (Lotus Storm / Frost Sovereign) and
## telegraphed Elite Champions (scaling, shockwave telegraph, guaranteed loot).

const TAU_STEP_16: float = TAU / 16.0

func _ready() -> void:
	print("=== RUNNING EXPANSION 20.0 TINH VÕ HỢP NHẤT & TINH ANH LỆNH TEST SUITE ===")

	_test_synergy_card_availability()
	_test_lotus_storm_evolution()
	_test_frost_sovereign_evolution()
	_test_elite_champion_behaviour()
	_test_elite_champion_spawner()

	if _failures.is_empty():
		print("=== ALL EXPANSION 20.0 TESTS PASSED 100% CLEANLY! ===")
	get_tree().quit(_exit_code())

# --- 1. Synergy card offering rules -----------------------------------------

func _catalog_has(catalog: Array, id: String) -> bool:
	for item in catalog:
		if item.get("id") == id:
			return true
	return false

func _catalog_get(catalog: Array, id: String) -> Dictionary:
	for item in catalog:
		if item.get("id") == id:
			return item
	return {}

func _test_synergy_card_availability() -> void:
	var up_mgr = UpgradeManager.new()
	add_child(up_mgr)
	up_mgr.weapon_levels = {"dagger": 0, "shield": 0, "lightning": 0, "fireball": 0, "axe": 0, "slash": 0}
	up_mgr.evolved_weapons = {"dagger": false, "shield": false, "lightning": false, "fireball": false, "axe": false, "slash": false}
	up_mgr.synergies_evolved = {"bao_vu": false, "bang_phach": false}

	# --- Lotus Storm: Dagger Lv.5 + Axe Lv.5 ---
	up_mgr.weapon_levels["dagger"] = 5
	up_mgr.weapon_levels["axe"] = 4
	check(not _catalog_has(up_mgr.get_upgrade_catalog(), "synergy_bao_vu"),
		"Lotus Storm NOT offered while Axe is only Lv.4")
	up_mgr.weapon_levels["axe"] = 5
	var bao_card = _catalog_get(up_mgr.get_upgrade_catalog(), "synergy_bao_vu")
	check(not bao_card.is_empty(), "Lotus Storm synergy offered at Dagger Lv.5 + Axe Lv.5")
	check(bao_card.get("is_synergy", false) == true, "Lotus Storm card flagged is_synergy = true")
	# The emoji star was replaced by the [HỢP NHẤT] tag in d71418c ("de-slop
	# visual UI cards"). An assert() aborts the rest of _ready(), so while this
	# one was stale the Frost Sovereign assertion below never even ran.
	check(bao_card.get("title", "") == "[HỢP NHẤT] BÃO VŨ LÊ HOA CHÂM (Lotus Storm)", "Lotus Storm card title matches spec")
	check((bao_card.get("desc", "") as String).contains("TIỆT KỸ HỢP NHẤT"), "Lotus Storm card advertises the fusion")

	# Not offered again once the fusion has been consumed
	up_mgr.synergies_evolved["bao_vu"] = true
	check(not _catalog_has(up_mgr.get_upgrade_catalog(), "synergy_bao_vu"),
		"Lotus Storm NOT offered again after it has been fused")
	up_mgr.synergies_evolved["bao_vu"] = false

	# --- Frost Sovereign: Slash Lv.5 + Shield Lv.5 ---
	up_mgr.weapon_levels["slash"] = 4
	up_mgr.weapon_levels["shield"] = 5
	check(not _catalog_has(up_mgr.get_upgrade_catalog(), "synergy_bang_phach"),
		"Frost Sovereign NOT offered while Slash is only Lv.4")
	up_mgr.weapon_levels["slash"] = 5
	var phach_card = _catalog_get(up_mgr.get_upgrade_catalog(), "synergy_bang_phach")
	check(not phach_card.is_empty(), "Frost Sovereign synergy offered at Slash Lv.5 + Shield Lv.5")
	check(phach_card.get("is_synergy", false) == true, "Frost Sovereign card flagged is_synergy = true")
	check(phach_card.get("title", "") == "[HỢP NHẤT] BĂNG PHÁCH THẦN KIẾM (Frost Sovereign)", "Frost Sovereign card title matches spec")
	check((phach_card.get("desc", "") as String).contains("TIỆT KỸ HỢP NHẤT"), "Frost Sovereign card advertises the fusion")

	up_mgr.synergies_evolved["bang_phach"] = true
	check(not _catalog_has(up_mgr.get_upgrade_catalog(), "synergy_bang_phach"),
		"Frost Sovereign NOT offered again after it has been fused")

	# --- Selecting the card drives the weapon node ---
	up_mgr.synergies_evolved["bang_phach"] = false
	var dagger_scene = load("res://scenes/weapon.tscn")
	var slash_scene = load("res://scenes/slash_weapon.tscn")
	var dagger = dagger_scene.instantiate()
	var slash = slash_scene.instantiate()
	add_child(dagger)
	add_child(slash)
	up_mgr.weapon = dagger
	up_mgr.slash_weapon = slash

	up_mgr.select_upgrade(_catalog_get(up_mgr.get_upgrade_catalog(), "synergy_bang_phach"))
	check(dagger.is_lotus_storm == false, "Selecting Frost Sovereign does not touch the Dagger")
	check(slash.is_frost_sovereign == true, "Selecting Frost Sovereign calls evolve_to_frost_sovereign() on the SlashWeapon")
	check(up_mgr.synergies_evolved["bang_phach"] == true, "Synergy marked consumed in synergies_evolved")

	get_tree().paused = false
	up_mgr.queue_free()
	dagger.queue_free()
	slash.queue_free()
	print("✔ Synergy card availability rules (both partners Lv.5, one-shot, wired to weapon nodes) verified.")

# --- 2. Bão Vũ Lê Hoa Châm (Lotus Storm) -------------------------------------

func _test_lotus_storm_evolution() -> void:
	var dagger_scene = load("res://scenes/weapon.tscn")
	check(dagger_scene != null, "Dagger weapon scene loaded")
	var dagger = dagger_scene.instantiate()
	add_child(dagger)
	dagger.global_position = Vector2.ZERO
	dagger.is_active = false # keep _process from auto-firing mid-test

	check(dagger.is_lotus_storm == false, "Dagger starts without the Lotus Storm fusion")
	dagger.evolve_to_lotus_storm()

	check(dagger.is_lotus_storm == true, "is_lotus_storm flag activated by evolve_to_lotus_storm()")
	check(dagger.is_evolved == true, "Lotus Storm marks the weapon as evolved")
	check(dagger.projectile_count == 16, "Lotus Storm fires exactly 16 needles per volley")
	check(dagger.base_damage >= 90.0, "Lotus Storm damage boosted to at least 90.0")

	# Fire a real volley and confirm the needles cover a full 360-degree circle
	dagger.fire_at(Vector2(300, 0))
	var spawned: Array = get_tree().get_nodes_in_group("projectiles")
	check(spawned.size() == 16, "A single Lotus Storm volley spawns 16 projectiles (got %d)" % spawned.size())

	var angles: Array[float] = []
	for p in spawned:
		angles.append(p.direction.angle())
		check(p.pierce >= 999, "Lotus Storm needles pierce the whole screen")
	angles.sort()
	# Evenly spaced by 2*PI/16, and the wrap-around closes the circle
	for i in range(angles.size()):
		var next_angle = angles[(i + 1) % angles.size()]
		var gap = next_angle - angles[i] if i < angles.size() - 1 else (angles[0] + TAU) - angles[i]
		check(absf(gap - TAU_STEP_16) < 0.001,
			"Needle %d spaced by exactly 2*PI/16 (got %.6f)" % [i, gap])

	for p in spawned:
		p.queue_free()
	dagger.queue_free()
	print("✔ Lotus Storm evolution (16 needles, full 360° ring, 90+ damage, piercing) verified.")

# --- 3. Băng Phách Thần Kiếm (Frost Sovereign) -------------------------------

func _test_frost_sovereign_evolution() -> void:
	var enemy_scene = load("res://scenes/enemy.tscn")
	var boss_scene = load("res://scenes/boss.tscn")
	var slash_scene = load("res://scenes/slash_weapon.tscn")
	check(enemy_scene != null and boss_scene != null and slash_scene != null, "Slash, enemy and boss scenes loaded")

	var slash = slash_scene.instantiate()
	add_child(slash)
	slash.global_position = Vector2.ZERO
	slash.is_active = false

	check(slash.is_frost_sovereign == false, "Slash starts without the Frost Sovereign fusion")
	slash.evolve_to_frost_sovereign()

	check(slash.is_frost_sovereign == true, "is_frost_sovereign flag activated by evolve_to_frost_sovereign()")
	check(slash.slash_damage >= 110.0, "Frost Sovereign slash damage boosted to at least 110.0")
	check(slash.slash_arc >= PI * 1.25, "Frost Sovereign arc widened to at least PI * 1.25 radians")

	# Non-boss target: struck and flash-frozen for 1.5s
	var victim = enemy_scene.instantiate()
	add_child(victim)
	victim.global_position = Vector2(60, 0)
	victim.max_health = 9999.0
	victim.current_health = 9999.0
	check(victim.freeze_timer == 0.0, "Target is unfrozen before the cleave")

	var hits = slash.perform_slash(Vector2.RIGHT)
	check(hits.has(victim), "Frost Sovereign cleave connects with the target")
	check(victim.current_health < 9999.0, "Target takes Frost Sovereign damage")
	check(victim.freeze_timer == 1.5, "Non-boss target is flash-frozen for exactly 1.5s")

	# Boss target: takes damage but bosses are immune to the freeze
	var boss = boss_scene.instantiate()
	add_child(boss)
	boss.global_position = Vector2(60, 0)
	boss.max_health = 99999.0
	boss.current_health = 99999.0
	var boss_hits = slash.perform_slash(Vector2.RIGHT)
	check(boss_hits.has(boss), "Frost Sovereign cleave also connects with bosses")
	check(boss.freeze_timer == 0.0, "Bosses are NOT frozen by Frost Sovereign")

	victim.queue_free()
	boss.queue_free()
	slash.queue_free()
	print("✔ Frost Sovereign evolution (110+ damage, >PI*1.25 arc, 1.5s non-boss freeze) verified.")

# --- 4. Tinh Anh Lệnh (Elite Champions) --------------------------------------

func _test_elite_champion_behaviour() -> void:
	var skeleton_scene = load("res://scenes/skeleton.tscn")
	check(skeleton_scene != null, "Skeleton scene loaded")

	# --- Scaling + health ---
	var plain = skeleton_scene.instantiate()
	add_child(plain)
	var plain_node_scale = plain.scale.x
	var plain_sprite_scale = plain.sprite.scale.x
	var plain_hp = plain.max_health
	check(plain.is_elite_champion == false, "Skeleton starts as an ordinary enemy")

	plain.is_elite_champion = true
	plain.make_elite_champion()
	check(plain.is_elite_champion == true, "is_elite_champion flag is set by make_elite_champion()")
	check(is_equal_approx(plain.scale.x, plain_node_scale * 1.6), "Elite Champion body scales to 1.6x the base sprite")
	check(is_equal_approx(plain.sprite.scale.x, plain_sprite_scale * 1.6), "Elite Champion sprite scales to 1.6x")
	check(is_equal_approx(plain.max_health, plain_hp * 3.5), "Elite Champion max_health multiplied by 3.5x")
	check(is_equal_approx(plain.current_health, plain.max_health), "Elite Champion current_health tracks the boosted max_health")
	check(plain.is_in_group("elite_champions"), "Elite Champion joins the elite_champions group")
	plain.queue_free()

	# --- Telegraph -> burst ---
	var player_scene = load("res://scenes/player.tscn")
	var player = player_scene.instantiate() as Player
	add_child(player)
	player.apply_character_data()
	player.global_position = Vector2.ZERO

	var elite = skeleton_scene.instantiate()
	add_child(elite)
	elite.global_position = Vector2(300, 0)
	elite.make_elite_champion()
	check(elite.is_telegraphing_burst == false, "Elite Champion is not telegraphing on spawn")

	# Wind the internal timer down to the burst window
	elite.elite_telegraph_timer = 0.05
	elite._physics_process(0.1)
	check(elite.is_telegraphing_burst == true, "Elite Champion enters the 0.8s telegraph warning")
	check(is_equal_approx(elite.elite_telegraph_timer, elite.elite_telegraph_duration), "Telegraph lasts the full 0.8s warning window")

	# The player is 300px away — outside the 190px burst ring — so this must be a clean miss
	var hp_before_burst = player.current_health
	elite._physics_process(0.9)
	check(elite.is_telegraphing_burst == false, "Telegraph clears and the shockwave unleashes")
	check(is_equal_approx(elite.elite_telegraph_timer, elite.elite_burst_interval), "Burst cooldown resets after the shockwave")
	check(player.current_health == hp_before_burst, "Shockwave misses a player outside the burst radius")

	# Player inside the ring takes the contact damage.
	# Expansion 48.0: shield pinned out, for the reason in test_expansion_19.gd --
	# every suite inherits the developer's real save, and a saved Nhâm Mạch rank puts
	# a 30-point Qi Shield between this burst and the HP the assert is watching.
	player.qi_shield_max = 0.0
	player.qi_shield_current = 0.0
	player.global_position = elite.global_position + Vector2(60, 0)
	var hp_inside = player.current_health
	elite.elite_telegraph_timer = 0.05
	elite._physics_process(0.1)
	elite._physics_process(0.9)
	check(player.current_health < hp_inside, "Shockwave deals contact damage to a player inside the burst radius")

	# --- Guaranteed death loot ---
	var loot = skeleton_scene.instantiate()
	add_child(loot)
	loot.global_position = Vector2(500, 0)
	loot.coin_drop_chance = 0.0 # isolate the guaranteed elite payout
	loot.make_elite_champion()
	var coins_before = get_tree().get_nodes_in_group("coins").size()
	loot.die()
	var new_coins := get_tree().get_nodes_in_group("coins")
	check(new_coins.size() - coins_before == 10, "Elite Champion death drops 10 guaranteed gold coins (got %d)" % (new_coins.size() - coins_before))
	var gold_total := 0
	for i in range(coins_before, new_coins.size()):
		gold_total += new_coins[i].gold_value
	check(gold_total == 50, "Elite Champion guaranteed payout totals 50 gold (got %d)" % gold_total)
	for c in new_coins:
		c.queue_free()

	player.queue_free()
	elite.queue_free()
	print("✔ Elite Champion scaling, telegraphed shockwave burst, and 50-gold guaranteed death loot verified.")

# --- 5. Elite Champion spawner -----------------------------------------------

func _test_elite_champion_spawner() -> void:
	var spawner = EnemySpawner.new()
	add_child(spawner)
	spawner.skeleton_scene = load("res://scenes/skeleton.tscn")
	spawner.necromancer_scene = load("res://scenes/necromancer.tscn")
	spawner.bat_scene = load("res://scenes/bat.tscn")

	var before := get_tree().get_nodes_in_group("elite_champions").size()

	var elite = spawner.spawn_elite_champion(Vector2(900, 900))
	check(elite != null, "spawn_elite_champion() returns a spawned enemy")
	check(elite.is_elite_champion == true, "Spawned enemy is flagged as an Elite Champion")
	check(elite.get_parent() != null, "Spawned Elite Champion is parented into the scene tree")
	check(get_tree().get_nodes_in_group("elite_champions").size() == before + 1, "Elite Champion registers in the elite_champions group")
	check(elite.max_health > 50.0, "Spawned Elite Champion carries the boosted health pool")

	# A bare spawner with no elite-capable scenes must degrade instead of crashing
	var bare = EnemySpawner.new()
	add_child(bare)
	bare.skeleton_scene = null
	bare.necromancer_scene = null
	bare.bat_scene = load("res://scenes/bat.tscn")
	var fallback = bare.spawn_elite_champion(Vector2(1200, 1200))
	check(fallback != null and fallback.is_elite_champion == true, "Spawner falls back to a bat when skeleton/necromancer are unavailable")

	var announced := [false]
	spawner.wave_event_announced.connect(func(_m: String, _b: bool): announced[0] = true)
	spawner.spawn_elite_champion(Vector2(1400, 1400))
	check(announced[0] == true, "Elite Champion spawn announces itself on the wave event signal")

	elite.queue_free()
	fallback.queue_free()
	bare.queue_free()
	spawner.queue_free()
	print("✔ Elite Champion spawner (skeleton/necromancer promotion + wave announcement) verified.")
