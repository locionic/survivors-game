extends Node

## Automated Test Suite for Milestone 1: "Võ Đài Sóng 1"
## Contained martial arena, 20-wave WaveDirector, 6-weapon arsenal with tier
## fusing, the Tàng Kinh Các intermission shop, and the manual 3-Hit combo.

const SHOP_SCENE: PackedScene = preload("res://scenes/wave_shop_ui.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")
const SLASH_SCENE: PackedScene = preload("res://scenes/slash_weapon.tscn")

## Godot's assert() only logs a SCRIPT ERROR and keeps running -- the process
## still exits 0, so a suite built on it can never fail a regression run. This
## records each broken expectation and drives the exit code from the failure count.
var _failures: Array[String] = []

## add_gold()/trigger_victory() persist to user://save_data.cfg immediately, so a
## suite that spends gold and banks a win payout would write into the developer's
## real save. Byte-for-byte backup taken before the suite and restored after.
const SAVE_PATH: String = "user://save_data.cfg"
const BACKUP_PATH: String = "user://save_data.cfg.wavebak"
var _had_save: bool = false

var _up_mgr: UpgradeManager = null
var _player: Player = null
var _shop: WaveShopUI = null

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
	print("=== RUNNING MILESTONE 1: VÕ ĐÀI SÓNG 1 TEST SUITE ===")
	# The director auto-starts on run_started; keep the tree inert so the suite,
	# not the autoload, decides when a wave begins.
	GameManager.is_run_active = false

	_test_wave_director_rounds()
	_test_six_weapon_cap()
	_test_weapon_fusing()
	_test_wave_shop_economy()
	_test_signature_combo()

	get_tree().paused = false
	_restore_save()

	var unique: Array[String] = []
	for f in _failures:
		if not unique.has(f):
			unique.append(f)

	if unique.is_empty():
		print("=== ALL VÕ ĐÀI SÓNG 1 TESTS PASSED 100% CLEANLY! ===")
		get_tree().quit(0)
	else:
		print("=== %d CHECK(S) FAILED (first %d unique) ===" % [_failures.size(), unique.size()])
		for f in unique:
			print("  FAIL: %s" % f)
		get_tree().quit(1)

# --- 1. WaveDirector: wave 1 duration, countdown, completion -----------------

func _test_wave_director_rounds() -> void:
	var dir := WaveDirector.new()
	dir.max_waves = 20
	add_child(dir)

	check(dir.current_wave == 1, "WaveDirector starts on wave 1, got %d" % dir.current_wave)
	check(dir.max_waves == 20, "WaveDirector is configured for 20 waves, got %d" % dir.max_waves)
	check(dir.max_enemies_alive == 80, "WaveDirector clamps to 80 live enemies, got %d" % dir.max_enemies_alive)
	check(not dir.is_wave_active, "WaveDirector is idle before the first start_wave()")

	dir.start_wave(1)
	check(dir.is_wave_active, "start_wave(1) puts the director in an active wave")
	check(is_equal_approx(dir.wave_duration, 20.0), "Wave 1 lasts 20s, got %s" % dir.wave_duration)
	check(is_equal_approx(dir.wave_time_left, 20.0), "Wave 1 opens with a full 20s on the clock")

	# Duration curve: +2.5s per wave, hard-capped at 60s.
	check(is_equal_approx(dir.calculate_wave_duration(2), 22.5), "Wave 2 lasts 22.5s")
	check(is_equal_approx(dir.calculate_wave_duration(17), 60.0), "Wave 17 is the first 60s cap")
	check(is_equal_approx(dir.calculate_wave_duration(20), 60.0), "Wave 20 stays at the 60s cap")

	var started: Array = []
	var completed: Array = []
	dir.connect("wave_started", func(n, d): started.append([n, d]))
	dir.connect("wave_completed", func(n): completed.append(n))

	dir.start_wave(2)
	check(started.size() == 1, "wave_started fired once after an explicit start_wave")
	check(int(started[0][0]) == 2, "wave_started reports the wave it opened")
	check(is_equal_approx(float(started[0][1]), 22.5), "wave_started carries the wave duration")

	# Tick the clock down by hand rather than sleeping: _process is the only thing
	# that ends a wave, so driving it is the real path.
	dir._process(10.0)
	check(is_equal_approx(dir.wave_time_left, 12.5), "Countdown ticked 10s off the 22.5s clock")
	check(dir.is_wave_active, "Wave still active with 12.5s left")
	check(completed.is_empty(), "No completion signal before the timer hits zero")

	dir._process(12.5)
	check(completed.size() == 1, "wave_completed fires when the timer reaches zero")
	check(int(completed[0]) == 2, "wave_completed reports the wave that just ended")
	check(not dir.is_wave_active, "end_wave() clears is_wave_active")
	check(is_equal_approx(dir.wave_time_left, 0.0), "Clock reads 0.0 after completion")
	check(get_tree().paused, "end_wave() pauses the tree and opens the intermission")

	# end_wave() is idempotent -- a double call must not double-pay or re-open.
	var shop_node := dir.get_node_or_null("WaveShopUI")
	check(shop_node != null, "end_wave() opened the Tàng Kinh Các shop")
	completed.clear()
	dir.end_wave()
	check(completed.is_empty(), "A second end_wave() on the same wave is a no-op")

	get_tree().paused = false
	dir.advance_to_next_wave()
	check(dir.current_wave == 3, "advance_to_next_wave() steps 2 -> 3")
	check(dir.is_wave_active, "advance_to_next_wave() opens the next wave")
	check(is_equal_approx(dir.wave_duration, 25.0), "Wave 3 lasts 25s")
	check(not get_tree().paused, "advance_to_next_wave() unpauses the tree")

	# Victory: clearing the final wave ends the run rather than opening a shop.
	dir.current_wave = dir.max_waves
	dir.end_wave()
	check(GameManager.is_victory_triggered, "Clearing wave 20 triggers victory")
	check(not get_tree().paused, "Victory leaves the tree running, not paused")
	GameManager.is_victory_triggered = false

	dir.queue_free()
	print("✔ WaveDirector: 20 rounds, escalating duration, completion, shop gate, victory.")

# --- 2. Six-weapon arsenal ----------------------------------------------------

func _test_six_weapon_cap() -> void:
	_up_mgr = UpgradeManager.new()
	add_child(_up_mgr)

	check(UpgradeManager.MAX_WEAPONS == 6, "MAX_WEAPONS is 6, got %d" % UpgradeManager.MAX_WEAPONS)
	check(_up_mgr.get_arsenal_count() == 0, "Arsenal starts empty")

	var all_ids: Array[String] = ["dagger", "shield", "lightning", "fireball", "axe", "slash"]
	for id in all_ids:
		check(_up_mgr.add_weapon(id), "Equipped %s into slot %d" % [id, _up_mgr.get_arsenal_count() + 1])
	check(_up_mgr.get_arsenal_count() == 6, "All 6 võ học equip together, got %d" % _up_mgr.get_arsenal_count())

	# The 7th has nowhere to go: the tray is still full, so this must be refused.
	check(not _up_mgr.add_weapon("dagger"), "A 7th weapon is refused at the 6-slot cap")
	check(_up_mgr.get_arsenal_count() == 6, "Arsenal holds exactly 6 after the refused add")

	for id in all_ids:
		check(_up_mgr.get_weapon_tier(id) == 1, "%s reports Tier 1" % id)
	_up_mgr.arsenal.clear()
	check(_up_mgr.get_weapon_tier("dagger") == 0, "An unowned weapon reports tier 0")

	# The level-up catalog is the other half of the cap: it must stop offering
	# "VÕ HỌC MỚI" unlock cards once all six slots are taken. (test_expansion_18
	# asserts this too, but assert() cannot fail a headless run.)
	_up_mgr.weapon_levels = {"dagger": 1, "shield": 1, "lightning": 0, "fireball": 0, "axe": 0, "slash": 0}
	var unlocks_at_2 := _count_unlock_cards(_up_mgr)
	check(unlocks_at_2 > 0, "Unlock cards are offered at 2/6 weapons, got %d" % unlocks_at_2)
	_up_mgr.weapon_levels = {"dagger": 1, "shield": 1, "lightning": 1, "fireball": 1, "axe": 1, "slash": 1}
	var unlocks_at_6 := _count_unlock_cards(_up_mgr)
	check(unlocks_at_6 == 0, "No unlock cards are offered at 6/6 weapons, got %d" % unlocks_at_6)
	print("✔ Arsenal: 6 slots, tier queries, cap enforced, unlock gate closes at 6.")

func _count_unlock_cards(up: UpgradeManager) -> int:
	var n := 0
	for item in up.get_upgrade_catalog():
		if str(item["id"]).begins_with("unlock_"):
			n += 1
	return n

# --- 3. Weapon fusing ---------------------------------------------------------

func _test_weapon_fusing() -> void:
	_up_mgr.arsenal.clear()
	var base_mult := _up_mgr.get_arsenal_damage_mult()
	check(is_equal_approx(base_mult, 1.0), "An empty arsenal grants no damage bonus, got %s" % base_mult)

	_up_mgr.add_weapon("dagger")
	var one_t1 := _up_mgr.get_arsenal_damage_mult()
	check(not _up_mgr.can_fuse("dagger", 1), "One Tier 1 dagger cannot fuse -- it needs a pair")
	check(is_equal_approx(_up_mgr.get_weapon_tier("dagger"), 1), "First dagger lands at Tier 1")
	# Tier 1 IS the baseline -- the bonus only starts at Tier 2.
	check(is_equal_approx(one_t1, base_mult), "Tier 1 is the baseline multiplier, got %s" % one_t1)

	_up_mgr.add_weapon("dagger")
	check(_up_mgr.count_at_tier("dagger", 1) == 2, "Two Tier 1 daggers are on the tray")
	check(_up_mgr.can_fuse("dagger", 1), "Two same-type same-tier daggers offer GHÉP")

	var before_count := _up_mgr.get_arsenal_count()
	var before_mult := _up_mgr.get_arsenal_damage_mult()
	check(_up_mgr.fuse_weapons("dagger", 1), "fuse_weapons consumes the pair")
	check(_up_mgr.get_arsenal_count() == before_count - 1, "Fusing freed a weapon slot (%d -> %d)" % [before_count, _up_mgr.get_arsenal_count()])
	check(_up_mgr.get_weapon_tier("dagger") == 2, "The fused dagger is Tier 2")
	check(_up_mgr.count_at_tier("dagger", 1) == 0, "No Tier 1 dagger remains")
	check(_up_mgr.count_at_tier("dagger", 2) == 1, "Exactly one Tier 2 dagger remains")

	var after_mult := _up_mgr.get_arsenal_damage_mult()
	check(after_mult > before_mult, "A Tier 2 weapon hits harder than two Tier 1: %s -> %s" % [before_mult, after_mult])
	check(is_equal_approx(after_mult, 1.0 + UpgradeManager.TIER_DAMAGE_BONUS),
		"A lone Tier 2 is worth exactly one TIER_DAMAGE_BONUS step")

	# A lone Tier 2 has no partner, so the fuse button must go dead.
	check(not _up_mgr.can_fuse("dagger", 2), "A single Tier 2 dagger cannot fuse again")
	check(not _up_mgr.fuse_weapons("dagger", 2), "fuse_weapons refuses a single Tier 2 dagger")
	check(_up_mgr.get_arsenal_count() == 1, "The refused fuse left the arsenal alone")

	# Tier 4 is the ceiling: nothing to fuse into.
	_up_mgr.arsenal = [{"id": "dagger", "tier": 4}, {"id": "dagger", "tier": 4}]
	check(not _up_mgr.can_fuse("dagger", 4), "A maxed Tier 4 offers no further fusion")
	print("✔ Fusing: two Tier 1 -> one Tier 2, slot freed, damage up, ceiling respected.")

# --- 4. Tàng Kinh Các shop: roll, buy, lock, reroll --------------------------

func _test_wave_shop_economy() -> void:
	_up_mgr.arsenal.clear()

	_player = PLAYER_SCENE.instantiate()
	add_child(_player)
	GameManager.run_gold = 500

	_shop = SHOP_SCENE.instantiate() as WaveShopUI
	add_child(_shop)
	_shop.open_for_wave(1)

	# --- roll ---
	check(_shop.cards.size() == WaveShopUI.CARD_COUNT, "Shop offers exactly 4 cards, got %d" % _shop.cards.size())
	for i in range(_shop.cards.size()):
		check(not _shop.cards[i]["data"].is_empty(), "Card %d rolled a real item" % i)
	check(_shop.visible, "Opening the shop shows it")

	# --- reroll cost escalates ---
	check(_shop.get_reroll_cost() == 15, "First reroll costs 15g, got %d" % _shop.get_reroll_cost())
	var gold_before_reroll := GameManager.run_gold
	check(_shop.reroll(), "Reroll succeeds with gold in hand")
	check(GameManager.run_gold == gold_before_reroll - 15, "Reroll deducted exactly 15g")
	check(_shop.get_reroll_cost() == 20, "Second reroll costs 20g (15 + 5/use), got %d" % _shop.get_reroll_cost())
	check(_shop.reroll(), "Second reroll succeeds")
	check(GameManager.run_gold == gold_before_reroll - 35, "Two rerolls deducted 15 + 20 = 35g")
	check(_shop.get_reroll_cost() == 25, "Third reroll costs 25g, got %d" % _shop.get_reroll_cost())

	# --- a locked card survives a reroll ---
	var lock_index := 0
	var locked_id: String = _shop.cards[lock_index]["data"]["id"]
	_shop.toggle_lock(lock_index)
	check(_shop.cards[lock_index]["locked"], "Card %d is now locked" % lock_index)
	_shop.reroll()
	_shop.reroll()
	_shop.reroll()
	check(String(_shop.cards[lock_index]["data"]["id"]) == locked_id,
		"Locked card survived 3 rerolls (%s held)" % locked_id)
	check(_shop.cards[lock_index]["locked"], "Card %d is still locked afterwards" % lock_index)
	_shop.toggle_lock(lock_index)
	check(not _shop.cards[lock_index]["locked"], "Toggling again unlocks card %d" % lock_index)

	# --- purchasing a weapon deducts gold and fills a slot ---
	_up_mgr.arsenal.clear()
	GameManager.run_gold = 100
	_shop.cards[1]["data"] = _shop.WEAPON_POOL[0].duplicate()  # Ám Khí Phi Đao, 40g
	var gold_before_buy := GameManager.run_gold
	check(_shop.purchase_card(1), "Buying a 40g dagger succeeds with 100g")
	check(GameManager.run_gold == gold_before_buy - 40, "Purchase deducted exactly 40g")
	check(_up_mgr.get_arsenal_count() == 1, "The bought dagger took slot 1")
	check(String(_up_mgr.arsenal[0]["id"]) == "dagger", "Slot 1 holds a dagger")
	check(_shop.cards[1]["data"].is_empty(), "The spent slot is now empty")

	# --- unaffordable purchase is refused ---
	GameManager.run_gold = 5
	var gold_before_refuse := GameManager.run_gold
	check(not _shop.purchase_card(1), "A 40g dagger is refused with 5g in hand")
	check(GameManager.run_gold == gold_before_refuse, "The refused purchase cost nothing")

	# --- purchasing a scroll rewrites the player's stats in place ---
	var might_before := _player.meta_might_bonus
	var hp_before := _player.max_health
	GameManager.run_gold = 100
	_shop.cards[2]["data"] = _scroll("cuu_am_chan_kinh")  # +30% Might, -20 Max HP
	check(_shop.purchase_card(2), "Buying Cửu Âm Chân Kinh succeeds")
	check(is_equal_approx(_player.meta_might_bonus, might_before + 0.30),
		"Cửu Âm Chân Kinh granted +30%% Might (%s -> %s)" % [might_before, _player.meta_might_bonus])
	check(is_equal_approx(_player.max_health, hp_before - 20.0),
		"...and charged 20 Max HP (%s -> %s)" % [hp_before, _player.max_health])

	var armor_before := _player.shop_armor_bonus
	var speed_before := _player.move_speed
	GameManager.run_gold = 100
	_shop.cards[3]["data"] = _scroll("kim_cuong_bat_hoai")  # +8 Armor, -15% Move Speed
	check(_shop.purchase_card(3), "Buying Kim Cương Bất Hoại succeeds")
	check(_player.shop_armor_bonus == armor_before + 8, "Kim Cương Bất Hoại granted +8 Armor")
	check(_player.move_speed < speed_before, "...and slowed the player down (%s -> %s)" % [speed_before, _player.move_speed])

	# --- a full arsenal refunds instead of eating the gold ---
	_up_mgr.arsenal.clear()
	for id in ["dagger", "shield", "lightning", "fireball", "axe", "slash"]:
		_up_mgr.add_weapon(id)
	GameManager.run_gold = 100
	_shop.cards[0]["data"] = _shop.WEAPON_POOL[0].duplicate()
	var gold_before_full := GameManager.run_gold
	check(not _shop.purchase_card(0), "Buying a 7th weapon is refused at the cap")
	check(GameManager.run_gold == gold_before_full, "The refused 7th weapon refunded its 40g")
	check(_up_mgr.get_arsenal_count() == 6, "Arsenal still holds 6 after the refusal")

	# --- selling refunds 60% and frees the slot ---
	GameManager.run_gold = 0
	var sell_refund := int(float(_shop.WEAPON_POOL[0]["price"]) * WaveShopUI.SELL_REFUND)
	_shop._sell(_up_mgr, 0)
	check(_up_mgr.get_arsenal_count() == 5, "Selling freed a slot")
	check(GameManager.run_gold == sell_refund, "Selling refunded %d%% of 40g = %d" % [int(WaveShopUI.SELL_REFUND * 100.0), sell_refund])

	_shop.queue_free()
	_player.queue_free()
	_up_mgr.queue_free()
	_shop = null
	_player = null
	_up_mgr = null
	print("✔ Shop: 4 cards, escalating reroll, lock persistence, purchases, sell, cap refund.")

func _scroll(id: String) -> Dictionary:
	for s in WaveShopUI.SCROLL_POOL:
		if s["id"] == id:
			return s.duplicate()
	return {}

# --- 5. Manual 3-Hit Signature Combo ------------------------------------------

func _test_signature_combo() -> void:
	var slash := SLASH_SCENE.instantiate() as SlashWeapon
	add_child(slash)

	# The per-step numbers the blade actually swings with.
	check(slash.combo_damage_mult_for(0) == 1.0, "Step 0 (Nhất Kiếm) deals 1.0x")
	check(slash.combo_damage_mult_for(1) == 1.35, "Step 1 (Song Phong) deals 1.35x")
	check(slash.combo_damage_mult_for(2) == 2.2, "Step 2 (Cửu Kiếm Quy Tông) deals 2.2x")
	check(slash.combo_arc_for(0) == 120.0, "Step 0 sweeps 120°")
	check(slash.combo_arc_for(1) == 150.0, "Step 1 sweeps 150°")
	check(slash.combo_arc_for(2) == 220.0, "Step 2 shockwaves 220°")
	# Milestone 3b retune: the finisher is the payoff, so it kicks the camera
	# harder (8.0) and throws mobs along the blade rather than off the player.
	check(SlashWeapon.COMBO_SHAKE[2] == 8.0, "The finisher shakes the camera 8.0")
	check(SlashWeapon.COMBO_KNOCKBACK[0] == 240.0, "Step 0 knocks back 240 along the blade")
	check(SlashWeapon.COMBO_KNOCKBACK[1] == 240.0, "Step 1 knocks back 240 along the blade")
	check(SlashWeapon.COMBO_KNOCKBACK[2] == 450.0, "The finisher knocks back 450 along the blade")
	check(SlashWeapon.COMBO_KNOCKBACK[2] > SlashWeapon.COMBO_KNOCKBACK[0],
		"The finisher throws harder than the opener")
	check(is_equal_approx(SlashWeapon.COMBO_RESET_TIME, 0.8), "Combo lapses after 0.8s")

	# The multipliers have to be genuinely distinct, not three copies of one.
	check(slash.combo_damage_mult_for(0) < slash.combo_damage_mult_for(1),
		"Hit 2 hits harder than hit 1")
	check(slash.combo_damage_mult_for(1) < slash.combo_damage_mult_for(2),
		"Hit 3 hits harder than hit 2")

	# --- 0 -> 1 -> 2 on successive manual presses ---
	check(slash.combo_step == 0, "Combo opens at step 0, got %d" % slash.combo_step)
	check(slash.trigger_combo_attack(), "Manual attack 1 lands (Nhất Kiếm)")
	check(slash.combo_step == 1, "Attack 1 advances the combo to step 1, got %d" % slash.combo_step)

	# Recovery windows gate the chain -- a swing during recovery is refused.
	check(not slash.trigger_combo_attack(), "A second attack inside the 0.2s recovery is refused")

	slash.cooldown_timer = 0.0
	check(slash.trigger_combo_attack(), "Manual attack 2 lands (Song Phong)")
	check(slash.combo_step == 2, "Attack 2 advances the combo to step 2, got %d" % slash.combo_step)

	slash.cooldown_timer = 0.0
	check(slash.trigger_combo_attack(), "Manual attack 3 lands (Cửu Kiếm Quy Tông)")
	check(slash.combo_step == 0, "The chain wraps back to step 0 after the finisher, got %d" % slash.combo_step)
	check(is_equal_approx(slash.combo_reset_timer, SlashWeapon.COMBO_RESET_TIME),
		"Each swing rearms the 0.8s combo window")

	# --- the chain lapses if the player stops clicking ---
	# A live window is what decays here: _process only reopens the chain when the
	# timer is running down, so start it armed rather than already expired.
	slash.combo_step = 1
	slash.combo_reset_timer = SlashWeapon.COMBO_RESET_TIME
	slash._process(SlashWeapon.COMBO_RESET_TIME + 0.05)
	check(slash.combo_step == 0, "An elapsed 0.8s window resets the combo to step 0")
	check(is_equal_approx(slash.combo_reset_timer, 0.0), "The timer clears on reset, got %s" % slash.combo_reset_timer)

	slash.queue_free()
	print("✔ Combo: 0->1->2 with distinct multipliers, recovery gate, 0.8s reset.")
