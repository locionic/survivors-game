extends Node

## Automated Test Suite for Expansion 21.0:
## "Bảo Rương Kim Quy & Vạn Nhân Trảm"
## Verifies per-weapon damage tracking + DPS breakdown/combat rank (Chiến Tích Bảng),
## the cinematic jackpot chest ceremony, and kill-streak Blood Rush rampage buffs.

const WEAPON_IDS: Array[String] = ["dagger", "shield", "lightning", "fireball", "axe", "slash"]

## assert() ABORTS the calling function when it fails: the rest of it never runs, the
## scene never reaches get_tree().quit(), and the suite hangs until the CI timeout
## kills it. Measured 2026-09-30 -- a single failed assert() on a passing suite
## prints the PASS banner and still exits 0. This records each broken expectation
## and drives the exit code from the failure count instead.
## each broken expectation and drives the exit code from the failure count.
var _failures: Array[String] = []

## add_gold()/start_new_run() persist to user://save_data.cfg immediately, so a test
## that rolls 300 jackpots would otherwise write ~90k fake gold into the developer's
## real save. Byte-for-byte backup taken before the suite and restored after.
const SAVE_PATH: String = "user://save_data.cfg"
const BACKUP_PATH: String = "user://save_data.cfg.testbak"
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

func check(cond: bool, msg: String) -> bool:
	if not cond:
		_failures.append(msg)
		push_error("CHECK FAILED: %s" % msg)
	return cond

func _ready() -> void:
	_backup_save()
	print("=== RUNNING EXPANSION 21.0 BẢO RƯƠNG KIM QUY & VẠN NHÂN TRẢM TEST SUITE ===")

	_test_weapon_damage_ledger()
	_test_damage_pipeline_feeds_ledger()
	_test_dps_breakdown_and_rank()
	_test_treasure_chest_jackpots()
	_test_kill_milestone_rampage()

	get_tree().paused = false
	_restore_save()

	# Deduped so a per-iteration failure inside a 300-roll loop reads once.
	var unique: Array[String] = []
	for f in _failures:
		if not unique.has(f):
			unique.append(f)

	if unique.is_empty():
		print("=== ALL EXPANSION 21.0 TESTS PASSED 100% CLEANLY! ===")
		get_tree().quit(0)
	else:
		print("=== %d CHECK(S) FAILED (first %d unique) ===" % [_failures.size(), unique.size()])
		for f in unique:
			print("  FAIL: %s" % f)
		get_tree().quit(1)

# --- 1a. record_weapon_damage ledger -----------------------------------------

func _reset_ledger() -> void:
	GameManager.start_new_run()
	for wid in WEAPON_IDS:
		GameManager.weapon_damage_stats[wid] = 0.0

func _test_weapon_damage_ledger() -> void:
	_reset_ledger()

	for wid in WEAPON_IDS:
		check(GameManager.weapon_damage_stats[wid] == 0.0,
			"'%s' starts at 0.0 damage after start_new_run()" % wid)

	# Two hits per weapon, so accumulation (not assignment) is what gets tested.
	var expected: Dictionary = {
		"dagger": 30.0, "shield": 60.0, "lightning": 90.0,
		"fireball": 120.0, "axe": 150.0, "slash": 180.0
	}
	for wid in WEAPON_IDS:
		var amount: float = expected[wid]
		GameManager.record_weapon_damage(wid, amount)
		GameManager.record_weapon_damage(wid, amount)
		check(is_equal_approx(GameManager.weapon_damage_stats[wid], amount * 2.0),
			"record_weapon_damage('%s') accumulates additively (got %.1f, want %.1f)"
			% [wid, GameManager.weapon_damage_stats[wid], amount * 2.0])

	var total: float = 0.0
	for wid in WEAPON_IDS:
		total += expected[wid] * 2.0
	check(is_equal_approx(GameManager.get_total_weapon_damage(), total),
		"get_total_weapon_damage() sums every weapon (got %.1f, want %.1f)"
		% [GameManager.get_total_weapon_damage(), total])

	# An untracked weapon id must not crash and must still be counted.
	GameManager.record_weapon_damage("spirit_sword", 25.0)
	check(is_equal_approx(GameManager.weapon_damage_stats["spirit_sword"], 25.0),
		"record_weapon_damage() creates the bucket for an unknown weapon id")
	check(is_equal_approx(GameManager.get_total_weapon_damage(), total + 25.0),
		"An unknown weapon id still contributes to the run total")

	# start_new_run() zeroes the ledger again.
	GameManager.start_new_run()
	for wid in WEAPON_IDS:
		check(GameManager.weapon_damage_stats[wid] == 0.0,
			"start_new_run() resets '%s' damage back to 0.0" % wid)
	check(is_equal_approx(GameManager.get_total_weapon_damage(), 0.0),
		"start_new_run() empties the whole damage ledger")

	print("OK record_weapon_damage() accumulates per weapon and start_new_run() resets it.")

# --- 1b. Real weapons feed the ledger at the point they deal damage ----------

func _spawn_victim(at: Vector2) -> Node2D:
	var enemy = load("res://scenes/enemy.tscn").instantiate()
	add_child(enemy)
	enemy.global_position = at
	enemy.max_health = 999999.0
	enemy.current_health = 999999.0
	return enemy

func _despawn(nodes: Array) -> void:
	for n in nodes:
		if is_instance_valid(n):
			# queue_free() is deferred to end-of-frame, but this suite runs entirely
			# inside _ready(), so leaving the node in "enemies" would let the next
			# sub-test's AoE scan splash onto a corpse. Leave the group immediately.
			if n.is_in_group("enemies"):
				n.remove_from_group("enemies")
			n.queue_free()

func _test_damage_pipeline_feeds_ledger() -> void:
	_reset_ledger()
	# No player exists in this test, so every weapon's Might multiplier is a flat 1.0
	# and raw damage numbers are directly comparable. Each sub-test despawns its own
	# targets so AoE weapons cannot splash onto a previous sub-test's leftovers.
	#
	# Loaded gear is the one save-derived modifier these weapons read (SlashWeapon
	# grants +15% damage and +25% range for y_thien_kiem), so clear it -- otherwise
	# these exact-value checks depend on whatever the developer last saved.
	GameManager.equipment_slots = {"weapon": "", "armor": "", "boots": ""}

	# Dagger -- Projectile.on_body_entered
	var victim = _spawn_victim(Vector2.ZERO)
	var proj = load("res://scenes/projectile.tscn").instantiate()
	add_child(proj)
	proj.damage = 25.0
	proj.weapon_id = "dagger"
	proj._on_body_entered(victim)
	check(is_equal_approx(GameManager.weapon_damage_stats["dagger"], 25.0),
		"A Dagger projectile hit books 25.0 damage on the dagger ledger")
	_despawn([victim, proj])

	# Axe -- AxeProjectile.on_body_entered
	victim = _spawn_victim(Vector2.ZERO)
	var axe = load("res://scenes/axe_projectile.tscn").instantiate()
	add_child(axe)
	axe.base_damage = 50.0
	axe.damage_multiplier = 1.5
	axe._on_body_entered(victim)
	check(is_equal_approx(GameManager.weapon_damage_stats["axe"], 75.0),
		"An Axe hit books base_damage * multiplier on the axe ledger (got %.1f, want 75.0)"
		% GameManager.weapon_damage_stats["axe"])
	_despawn([victim, axe])

	# Shield -- OrbitingShield.on_body_entered
	victim = _spawn_victim(Vector2.ZERO)
	var shield = load("res://scenes/orbiting_shield.tscn").instantiate()
	add_child(shield)
	shield.damage = 14.0
	shield._on_body_entered(victim)
	check(is_equal_approx(GameManager.weapon_damage_stats["shield"], 14.0),
		"An orbiting Shield contact books damage on the shield ledger")
	_despawn([victim, shield])

	# Fireball -- FireballProjectile.explode splashes every enemy in the blast
	victim = _spawn_victim(Vector2.ZERO)
	var fireball = load("res://scenes/fireball_projectile.tscn").instantiate()
	add_child(fireball)
	fireball.global_position = Vector2.ZERO
	fireball.blast_radius = 100.0
	fireball.damage_multiplier = 1.0
	fireball.explode()
	check(is_equal_approx(GameManager.weapon_damage_stats["fireball"], 32.0),
		"A Fireball explosion books 32.0 splash damage on the fireball ledger (got %.1f)"
		% GameManager.weapon_damage_stats["fireball"])
	_despawn([victim, fireball])

	# Slash -- SlashWeapon.perform_slash
	victim = _spawn_victim(Vector2(60, 0))
	var slash = load("res://scenes/slash_weapon.tscn").instantiate()
	add_child(slash)
	slash.global_position = Vector2.ZERO
	slash.is_active = false
	slash.base_damage = 40.0
	var hits: Array[Node2D] = slash.perform_slash(Vector2.RIGHT)
	check(hits.has(victim), "The cleave connects with the target")
	check(is_equal_approx(GameManager.weapon_damage_stats["slash"], 40.0),
		"A Slash cleave books 40.0 damage on the slash ledger (got %.1f)"
		% GameManager.weapon_damage_stats["slash"])
	_despawn([victim, slash])

	# Lightning -- LightningWeapon.strike_target (direct hit + evolved 60% splash)
	victim = _spawn_victim(Vector2.ZERO)
	var splash_victim = _spawn_victim(Vector2(40, 0))
	var lightning = load("res://scenes/lightning_weapon.tscn").instantiate()
	add_child(lightning)
	lightning.global_position = Vector2.ZERO
	lightning.base_damage = 45.0
	lightning.is_evolved = true
	lightning.strike_target(Vector2.ZERO, victim)
	var lightning_damage: float = GameManager.weapon_damage_stats["lightning"]
	check(is_equal_approx(lightning_damage, 45.0 + 45.0 * 0.6),
		"Lightning books the full direct strike plus one 60%% evolved splash (got %.1f, want %.1f)"
		% [lightning_damage, 45.0 + 45.0 * 0.6])
	_despawn([victim, splash_victim, lightning])

	# Every one of the six weapons must now be represented in the ledger.
	for wid in WEAPON_IDS:
		check(GameManager.weapon_damage_stats[wid] > 0.0,
			"Weapon '%s' landed real damage and is tracked in the ledger" % wid)

	print("OK All six weapons book damage through the real hit pipeline.")

# --- 1c. Breakdown rows & combat rank ----------------------------------------

func _test_dps_breakdown_and_rank() -> void:
	_reset_ledger()
	check(GameManager.get_weapon_dps_breakdown().is_empty(),
		"A fresh run reports an empty Chien Tich Bang rather than six 0% rows")

	GameManager.run_time = 10.0
	GameManager.record_weapon_damage("dagger", 100.0)
	GameManager.record_weapon_damage("fireball", 300.0)
	GameManager.record_weapon_damage("slash", 200.0)

	var rows: Array[Dictionary] = GameManager.get_weapon_dps_breakdown()
	check(rows.size() == 3, "Only weapons that dealt damage get a row (got %d)" % rows.size())
	check(rows[0]["id"] == "fireball" and rows[1]["id"] == "slash" and rows[2]["id"] == "dagger",
		"Rows are sorted by damage descending")

	for row in rows:
		check(row.has("id") and row.has("name") and row.has("damage")
			and row.has("percent") and row.has("dps"),
			"Every row carries id/name/damage/percent/dps")
		check(str(row["name"]) != "" and str(row["name"]) != str(row["id"]),
			"Weapon '%s' resolves to a display name (%s)" % [row["id"], row["name"]])

	var total: float = GameManager.get_total_weapon_damage()
	var pct_sum: float = 0.0
	for row in rows:
		var expected_pct: float = float(row["damage"]) / total * 100.0
		check(is_equal_approx(float(row["percent"]), expected_pct),
			"'%s' percent is damage/total (got %.2f%%, want %.2f%%)"
			% [row["id"], row["percent"], expected_pct])
		check(is_equal_approx(float(row["dps"]), float(row["damage"]) / max(1.0, GameManager.run_time)),
			"'%s' DPS is damage / run_time" % row["id"])
		pct_sum += float(row["percent"])
	check(is_equal_approx(pct_sum, 100.0), "Percentages sum to 100%% (got %.2f)" % pct_sum)

	# run_time below 1s must not divide by zero.
	GameManager.run_time = 0.0
	for row in GameManager.get_weapon_dps_breakdown():
		check(is_equal_approx(float(row["dps"]), float(row["damage"])),
			"DPS is clamped to a 1s floor instead of dividing by zero")

	# --- Combat rank thresholds ---
	GameManager.run_time = 100.0
	GameManager.kills = 0
	GameManager.record_weapon_damage("dagger", 100.0) # 1.0 DPS
	check(GameManager.get_combat_rank() == "C", "1 DPS with 0 kills is rank C")

	GameManager.record_weapon_damage("dagger", 19900.0) # 200 DPS total
	check(GameManager.get_combat_rank() == "B", "200 DPS is the B threshold")

	GameManager.record_weapon_damage("dagger", 25000.0) # 450 DPS total
	check(GameManager.get_combat_rank() == "A", "450 DPS is the A threshold")

	GameManager.record_weapon_damage("dagger", 35000.0) # 800 DPS total
	check(GameManager.get_combat_rank() == "S", "800 DPS is the S threshold")

	# The kill-count path promotes independently of DPS.
	GameManager.start_new_run()
	GameManager.run_time = 100.0
	GameManager.kills = 0
	GameManager.record_weapon_damage("dagger", 1.0)
	check(GameManager.get_combat_rank() == "C", "Baseline is rank C")
	GameManager.kills = 60
	check(GameManager.get_combat_rank() == "B", "60 kills promotes to B on kill count alone")
	GameManager.kills = 150
	check(GameManager.get_combat_rank() == "A", "150 kills promotes to A on kill count alone")
	GameManager.kills = 300
	check(GameManager.get_combat_rank() == "S", "300 kills promotes to S on kill count alone")

	print("OK Chien Tich Bang breakdown (sort/percent/dps clamp) and the S/A/B/C rank ladder.")

# --- 2. Bao Ruong Kim Quy (Cinematic Jackpot Chest) ---------------------------

func _test_treasure_chest_jackpots() -> void:
	# The tier table itself must match the designed odds.
	check(GameManager.CHEST_JACKPOTS.size() == 3, "Three jackpot tiers are configured")
	var chance_sum: float = 0.0
	for entry in GameManager.CHEST_JACKPOTS:
		chance_sum += float(entry["chance"])
	check(is_equal_approx(chance_sum, 1.0), "Jackpot chances sum to 1.0 (got %.2f)" % chance_sum)
	check(int(GameManager.CHEST_JACKPOTS[0]["gold"]) == 100
		and int(GameManager.CHEST_JACKPOTS[1]["gold"]) == 250
		and int(GameManager.CHEST_JACKPOTS[2]["gold"]) == 500,
		"Tier gold payouts are 100 / 250 / 500")
	check(int(GameManager.CHEST_JACKPOTS[0]["upgrades"]) == 1
		and int(GameManager.CHEST_JACKPOTS[1]["upgrades"]) == 3
		and int(GameManager.CHEST_JACKPOTS[2]["upgrades"]) == 5,
		"Tiers award 1 / 3 / 5 upgrades")

	var up_mgr = UpgradeManager.new()
	add_child(up_mgr)
	up_mgr.player = null
	up_mgr.weapon_levels = {"dagger": 0, "shield": 0, "lightning": 0, "fireball": 0, "axe": 0, "slash": 0}
	up_mgr.evolved_weapons = {"dagger": false, "shield": false, "lightning": false, "fireball": false, "axe": false, "slash": false}
	up_mgr.synergies_evolved = {"bao_vu": false, "bang_phach": false}

	var catalog_size: int = up_mgr.get_upgrade_catalog().size()
	check(catalog_size > 0, "A level-0 arsenal still offers a catalog to draw from")

	# A chest draws from the same catalog the level-up modal shows, so arm a
	# realistic mid-run arsenal rather than an empty one. This also pins the fact
	# the jackpot tiers rely on: a live catalog always has at least 5 entries, so
	# the tier-3 payout is never silently clamped.
	up_mgr.weapon_levels = {"dagger": 3, "shield": 3, "lightning": 5, "fireball": 0, "axe": 0, "slash": 0}
	up_mgr.evolved_weapons = {"dagger": false, "shield": false, "lightning": false, "fireball": false, "axe": false, "slash": false}
	catalog_size = up_mgr.get_upgrade_catalog().size()
	check(catalog_size >= 5,
		"A live mid-run catalog always offers at least 5 cards, so tier 3 is never clamped (got %d)"
		% catalog_size)

	GameManager.start_new_run()
	GameManager.collected_relics.clear()
	GameManager.is_blood_moon = false

	# The signal must fire with the same payload the method returns.
	var seen: Array[Dictionary] = []
	GameManager.chest_opened.connect(func(tier: int, upgrades: Array, gold: int):
		seen.append({"tier": tier, "upgrades": upgrades, "gold": gold}))

	# Roll enough times that all three tiers are certain to appear.
	var tiers_seen: Dictionary = {}
	seed(20260925)
	for i in range(300):
		# select_upgrade() consumes the card it was handed, so re-arm the arsenal
		# every roll. 300 chests in one run is synthetic -- without this the catalog
		# drains and the loop would measure depletion instead of the tier contract.
		up_mgr.weapon_levels = {"dagger": 3, "shield": 3, "lightning": 5, "fireball": 0, "axe": 0, "slash": 0}
		up_mgr.evolved_weapons = {"dagger": false, "shield": false, "lightning": false, "fireball": false, "axe": false, "slash": false}
		var gold_before: int = GameManager.run_gold
		var result: Dictionary = GameManager.open_treasure_chest()
		var tier: int = int(result["tier"])
		var granted: Array = result["upgrades"]
		var gold: int = int(result["gold"])

		var want_upgrades: int = int(GameManager.CHEST_JACKPOTS[tier - 1]["upgrades"])
		var want_gold: int = int(GameManager.CHEST_JACKPOTS[tier - 1]["gold"])
		check(granted.size() == want_upgrades,
			"Tier %d awards exactly %d upgrades (got %d)" % [tier, want_upgrades, granted.size()])
		check(gold == want_gold, "Tier %d awards exactly %d gold (got %d)" % [tier, want_gold, gold])
		check(GameManager.run_gold - gold_before == gold,
			"Tier %d gold actually lands in run_gold" % tier)
		check(get_tree().paused == true,
			"The ceremony keeps the tree frozen so the modal can play")

		# Upgrades come from the live catalog and are unique.
		var ids: Array[String] = []
		for item in granted:
			var id: String = str(item.get("id", ""))
			check(id != "", "Every granted upgrade is a real catalog entry with an id")
			check(not ids.has(id), "A single chest never hands out '%s' twice" % id)
			ids.append(id)

		tiers_seen[tier] = true

	check(tiers_seen.has(1) and tiers_seen.has(2) and tiers_seen.has(3),
		"All three jackpot tiers were rolled during the distribution check (saw %s)" % str(tiers_seen.keys()))
	check(seen.size() == 300, "chest_opened fires once per opening")
	check(int(seen[0]["gold"]) == int(GameManager.CHEST_JACKPOTS[int(seen[0]["tier"]) - 1]["gold"]),
		"chest_opened carries the same tier/gold payload as the return value")

	# Applying an upgrade must actually move the manager's state.
	GameManager.start_new_run()
	up_mgr.weapon_levels = {"dagger": 0, "shield": 0, "lightning": 0, "fireball": 0, "axe": 0, "slash": 0}
	up_mgr.weapon_levels["dagger"] = 3
	up_mgr.evolved_weapons["dagger"] = false
	var dagger = load("res://scenes/weapon.tscn").instantiate()
	add_child(dagger)
	up_mgr.weapon = dagger
	dagger.is_active = false
	var dmg_before: float = dagger.damage_multiplier

	var dmg_card: Dictionary = {}
	for item in up_mgr.get_upgrade_catalog():
		if item.get("id") == "damage":
			dmg_card = item
			break
	check(not dmg_card.is_empty(), "A Lv.3 Dagger offers the 'damage' upgrade card")
	up_mgr.select_upgrade(dmg_card)
	check(up_mgr.weapon_levels["dagger"] == 4, "Applying a card advances the Dagger to Lv.4")
	check(dagger.damage_multiplier > dmg_before, "Applying the card drives the live weapon node")

	# The chest node itself: collecting pauses the run and fires the ceremony.
	GameManager.start_new_run()
	GameManager.collected_relics.clear()
	var fired: Array = []
	GameManager.chest_opened.connect(func(tier: int, _u: Array, _g: int): fired.append(tier))
	var chest = load("res://scenes/chest.tscn").instantiate()
	add_child(chest)
	chest.collect(null)
	check(fired.size() == 1, "Collecting a TreasureChest triggers exactly one jackpot ceremony")
	check(get_tree().paused == true, "Collecting a TreasureChest pauses the game for the modal")
	check(GameManager.run_gold > 0, "Collecting a TreasureChest paid out gold")

	up_mgr.queue_free()
	dagger.queue_free()
	chest.queue_free()
	get_tree().paused = false
	print("OK Bao Ruong Kim Quy: 75/20/5 tiers pay 1/3/5 upgrades + 100/250/500 gold and freeze the run.")

# --- 3. Van Nhan Tram (Kill Streak Rampage) -----------------------------------

func _test_kill_milestone_rampage() -> void:
	GameManager.start_new_run()
	check(GameManager.reached_kill_milestones.is_empty(),
		"A new run has not reached any kill milestone yet")

	var player = load("res://scenes/player.tscn").instantiate() as Player
	add_child(player)
	player.apply_character_data()
	player.global_position = Vector2.ZERO
	check(player.blood_rush_timer == 0.0, "Blood Rush is inactive before the first milestone")

	# --- Blood Rush stat contract, independent of GameManager ---
	player.activate_blood_rush(5.0)
	check(is_equal_approx(player.blood_rush_timer, 5.0),
		"activate_blood_rush(5.0) arms a 5 second Blood Rush")
	check(is_equal_approx(player.get_blood_rush_speed_multiplier(), 1.20),
		"Blood Rush grants +20% move speed")
	check(is_equal_approx(player.get_blood_rush_cooldown_rate(), 1.25),
		"Blood Rush drains skill cooldown 25% faster")

	# The cooldown boost must show up as a real tick, not just a constant.
	player.skill_cooldown_timer = 10.0
	player._physics_process(1.0)
	check(player.skill_cooldown_timer < 9.0,
		"A 1s frame burns more than 1s of cooldown during Blood Rush (left %.3f)"
		% player.skill_cooldown_timer)

	player.blood_rush_timer = 0.0
	check(is_equal_approx(player.get_blood_rush_speed_multiplier(), 1.0),
		"Move speed multiplier reverts when Blood Rush expires")
	check(is_equal_approx(player.get_blood_rush_cooldown_rate(), 1.0),
		"Cooldown rate reverts when Blood Rush expires")
	player.skill_cooldown_timer = 10.0
	player._physics_process(1.0)
	check(is_equal_approx(player.skill_cooldown_timer, 9.0),
		"Cooldown ticks at plain speed once Blood Rush expires (left %.3f)"
		% player.skill_cooldown_timer)

	# --- Milestone crossing ---
	var fired: Array = []
	GameManager.kill_milestone_reached.connect(func(milestone: int, title: String):
		fired.append({"milestone": milestone, "title": title}))

	# Milestone 3a moved the banner copy behind Loc, so what the banner says now
	# follows the active language -- comparing it to a fixed literal would only
	# pass for one of the two. The Vietnamese text is still pinned exactly, in two
	# places, so a translator drifting it fails here instead of shipping silently.
	var expected_titles: Dictionary = {
		50: "⚔️ TRẢM TƯỚNG ĐOẠT KỲ! (+25% CUỒNG BẠO)",
		100: "🔥 BÁCH NHÂN ĐỊCH! (+25% CUỒNG BẠO)",
		250: "⚡ CUỒNG MA XUẤT THẾ! (+25% CUỒNG BẠO)",
		500: "👑 VẠN QUÂN BẤT ĐỊCH! (+25% CUỒNG BẠO)",
		1000: "🌌 ĐỘC BỘ THIÊN HẠ! (+25% CUỒNG BẠO)"
	}
	for target: int in expected_titles:
		var vi_row: String = str(Loc.STRINGS.get("hud.streak_%d" % target, {}).get("vi", ""))
		check(vi_row == expected_titles[target],
			"The Vietnamese %d milestone banner is unchanged (got '%s')" % [target, vi_row])
		check(vi_row == str(GameManager.KILL_MILESTONE_TITLES.get(target, "")),
			"Loc's Vietnamese %d banner agrees with the GameManager fallback" % target)
	var expected_milestones: Array[int] = [50, 100, 250, 500, 1000]
	check(GameManager.KILL_MILESTONES == expected_milestones,
		"Milestones are 50 / 100 / 250 / 500 / 1000")

	for idx in range(expected_milestones.size()):
		var target: int = expected_milestones[idx]
		while GameManager.kills < target:
			GameManager.add_kill()

		check(fired.size() == idx + 1,
			"Exactly %d milestone signal(s) have fired by %d kills (got %d)"
			% [idx + 1, target, fired.size()])
		var event: Dictionary = fired[fired.size() - 1]
		check(int(event["milestone"]) == target,
			"Crossing %d kills announces the %d milestone (announced %d)"
			% [target, target, event["milestone"]])
		check(event["title"] == Loc.t("hud.streak_%d" % target, expected_titles[target]),
			"The %d milestone banner says what the %s locale publishes"
			% [target, Loc.current_locale])
		check(player.blood_rush_timer > 0.0,
			"Crossing %d kicks off a 5 second Blood Rush on the player" % target)
		check(is_equal_approx(player.blood_rush_timer, 5.0),
			"Crossing %d grants the full 5 second Blood Rush" % target)
		check(GameManager.reached_kill_milestones.has(target),
			"%d is recorded in reached_kill_milestones" % target)

		# Clear the buff so the next crossing is observed from a cold timer.
		player.blood_rush_timer = 0.0

	check(GameManager.reached_kill_milestones == expected_milestones,
		"Every milestone is recorded exactly once, in order")

	# A milestone must never re-fire while the run keeps going.
	for i in range(50):
		GameManager.add_kill()
	check(fired.size() == 5, "Milestones never re-fire after being reached (got %d events)" % fired.size())
	check(GameManager.reached_kill_milestones.size() == 5,
		"reached_kill_milestones holds no duplicates")

	player.queue_free()
	print("OK Van Nhan Tram: 50/100/250/500/1000 announce once and grant a +20%/+25% Blood Rush.")
