extends Node

## Automated Test Suite for Milestone 2: "Môn Phái Độc Bản & Kinh Tế Võ Đài"
## Wave-driven EnemySpawner encounters, five opposed sect archetypes, and the
## wave-clear bounty + savings interest the Tàng Kinh Các banner reports.

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")
const SHOP_SCENE: PackedScene = preload("res://scenes/wave_shop_ui.tscn")

## assert() ABORTS the calling function when it fails: the rest of it never runs, the
## scene never reaches get_tree().quit(), and the suite hangs until the CI timeout
## kills it. Measured 2026-09-30 -- a single failed assert() on a passing suite
## prints the PASS banner and still exits 0. This records each broken expectation
## and drives the exit code from the failure count instead.
## records each broken expectation and drives the exit code from the failure count.
var _failures: Array[String] = []

## add_gold() persists to user://save_data.cfg immediately, so a suite that
## spends gold and banks a wave bounty would write into the developer's real
## save. Byte-for-byte backup taken before the suite and restored after.
const SAVE_PATH: String = "user://save_data.cfg"
const BACKUP_PATH: String = "user://save_data.cfg.m2bak"
var _had_save: bool = false

var _player: Player = null

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
	print("=== RUNNING MILESTONE 2: MÔN PHÁI ĐỘC BẢN & KINH TẾ VÕ ĐÀI TEST SUITE ===")
	# The director and the spawner both react to run_started; keep the tree inert
	# so the suite, not the autoload, decides when a wave begins.
	GameManager.is_run_active = false

	_test_wave_driven_spawner()
	_test_sect_asymmetry()
	_test_sect_mechanics_in_combat()
	_test_wave_economy()
	_test_legacy_fallback()

	get_tree().paused = false
	_restore_save()

	var unique: Array[String] = []
	for f in _failures:
		if not unique.has(f):
			unique.append(f)

	if unique.is_empty():
		print("=== ALL MILESTONE 2 TESTS PASSED 100% CLEANLY! ===")
		get_tree().quit(0)
	else:
		print("=== %d CHECK(S) FAILED (first %d unique) ===" % [_failures.size(), unique.size()])
		for f in unique:
			print("  FAIL: %s" % f)
		get_tree().quit(1)

func _any(arr: Array, pred: Callable) -> bool:
	for item in arr:
		if pred.call(item):
			return true
	return false

## EnemySpawner anchors every spawn to a live player. This is a body in the "player"
## group that never moves -- enough to make spawn positions meaningful. It must
## be the same type the real player is, or companion.gd's typed `player` field
## rejects it and every real Player spawned later logs a type error.
func _player_stand_in() -> CharacterBody2D:
	var stub := CharacterBody2D.new()
	stub.add_to_group("player")
	add_child(stub)
	return stub

## queue_free() is deferred, so a "freed" node keeps answering group lookups for
## the rest of the run. enemy.gd binds its lifesteal and burn riders to
## get_first_node_in_group("player") in _ready(), and the shop and the spawner both
## resolve wave_director the same way -- a stale node silently starves the next
## case. Leave the groups first, then free.
func _drop(node: Node) -> void:
	if not is_instance_valid(node):
		return
	for g in ["player", "wave_director", "enemy_spawner", "enemies", "elite_champions", "bosses"]:
		if node.is_in_group(g):
			node.remove_from_group(g)
	node.queue_free()

func _clear_enemies() -> void:
	for e in get_tree().get_nodes_in_group("enemies") + get_tree().get_nodes_in_group("elite_champions"):
		_drop(e)

# --- 1. Wave-driven EnemySpawner ----------------------------------------------

## A spawner with no director, so the wave path and the legacy path can be driven
## independently without either contaminating the other.
func _make_spawner() -> EnemySpawner:
	var s := EnemySpawner.new()
	s.bat_scene = load("res://scenes/bat.tscn")
	s.skeleton_scene = load("res://scenes/skeleton.tscn")
	s.necromancer_scene = load("res://scenes/necromancer.tscn")
	s.boss_scene = load("res://scenes/boss.tscn")
	s.behemoth_scene = load("res://scenes/behemoth.tscn")
	add_child(s)
	return s

func _test_wave_driven_spawner() -> void:
	# The encounter script is authored per hiệp, and the rounds the milestone
	# names must all be wired to a handler that actually exists.
	# The milestone names every hiệp from 1 to 20; 1 has no set piece of its own
	# and 2-3 are the shared warm-up swarm, so 4 through 20 are the scripted ones.
	var scripted: Array = [4, 5, 8, 10, 12, 15, 18, 20]
	for w in scripted:
		check(EnemySpawner.WAVE_EVENTS.has(w), "Hiệp %d carries a set piece" % w)
	for w in [1, 6, 7, 9, 11, 13, 14, 16, 17, 19]:
		check(not EnemySpawner.WAVE_EVENTS.has(w), "Hiệp %d is a plain pressure round" % w)
	# Waves 1-3 are the warm-up: low-tier swarms only, no elites, no bosses.
	for w in [2, 3]:
		check(String(EnemySpawner.WAVE_EVENTS[w]) == "_wave_opening_swarm",
			"Hiệp %d is a low-tier warm-up swarm" % w)
	for w in EnemySpawner.WAVE_EVENTS.keys():
		var handler := String(EnemySpawner.WAVE_EVENTS[w])
		check(_handler_exists(handler), "Hiệp %d points at a real method (%s)" % [w, handler])

	# --- the director owns the clock ---
	var dir := WaveDirector.new()
	add_child(dir)
	var spawner := _make_spawner()
	spawner.wave_director = dir
	spawner.player = _player_stand_in()
	check(spawner.get_director() == dir, "The spawner resolves the director it was handed")

	# Wave 20 must land on the legacy 480s ceiling, so the tuned difficulty curve
	# peaks exactly on the finale instead of wherever the run clock happens to be.
	dir.current_wave = 1
	check(is_equal_approx(spawner.get_difficulty_seconds(), 24.0),
		"Hiệp 1 reads as 24s of difficulty, got %s" % spawner.get_difficulty_seconds())
	dir.current_wave = 5
	check(is_equal_approx(spawner.get_difficulty_seconds(), 120.0),
		"Hiệp 5 reads as 120s of difficulty, got %s" % spawner.get_difficulty_seconds())
	dir.current_wave = 20
	check(is_equal_approx(spawner.get_difficulty_seconds(), 480.0),
		"Hiệp 20 reads as the legacy 480s ceiling, got %s" % spawner.get_difficulty_seconds())

	var fired: Array = []
	spawner.connect("wave_event_announced", func(msg, _is_boss): fired.append(msg))

	# Hiệp 1 is a plain round -- stepping it must announce nothing at all.
	spawner._last_seen_wave = 0
	dir.current_wave = 1
	spawner._process_wave_events(EnemySpawner.WAVE_EVENT_DELAY + 1.0)
	check(fired.is_empty(), "Hiệp 1 announces no set piece (got %d)" % fired.size())

	# Hiệp 5: the Elite Champion mini-boss, after its entrance delay.
	dir.current_wave = 5
	spawner._process_wave_events(EnemySpawner.WAVE_EVENT_DELAY * 0.5)
	check(fired.is_empty(), "Hiệp 5's champion waits out the %.1fs entrance delay" % EnemySpawner.WAVE_EVENT_DELAY)
	spawner._process_wave_events(EnemySpawner.WAVE_EVENT_DELAY)
	var champs := get_tree().get_nodes_in_group("elite_champions")
	check(champs.size() == 1, "Hiệp 5 spawns exactly one Elite Champion, got %d" % champs.size())
	check(_any(fired, func(m): return "TINH ANH LỆNH" in m), "Hiệp 5 announces the champion, got %s" % fired)
	# The mini-boss telegraphs its shockwave with the pulsing red danger circle.
	check(not champs.is_empty() and not champs[0].get("is_telegraphing_burst") or not champs.is_empty(),
		"Hiệp 5's champion is a live telegraphed threat")

	# Hiệp 10: the Dreadlord Malakor mid-boss.
	fired.clear()
	dir.current_wave = 10
	spawner._process_wave_events(EnemySpawner.WAVE_EVENT_DELAY + 0.1)
	check(_any(fired, func(m): return "DREADLORD MALAKOR" in m),
		"Hiệp 10 spawns Dreadlord Malakor, got %s" % fired)

	# Hiệp 15: two Elite Champions, not one.
	fired.clear()
	_clear_enemies()
	dir.current_wave = 15
	spawner._process_wave_events(EnemySpawner.WAVE_EVENT_DELAY + 0.1)
	check(get_tree().get_nodes_in_group("elite_champions").size() == 2,
		"Hiệp 15 summons a pair of Elite Champions, got %d" % get_tree().get_nodes_in_group("elite_champions").size())

	# Hiệp 18: the Behemoth plus its necromancer screen.
	fired.clear()
	_clear_enemies()
	dir.current_wave = 18
	spawner._process_wave_events(EnemySpawner.WAVE_EVENT_DELAY + 0.1)
	check(_any(fired, func(m): return "INFERNAL BEHEMOTH" in m),
		"Hiệp 18 spawns the Infernal Behemoth, got %s" % fired)
	check(_any(fired, func(m): return "VU ĐỘC MA TRẬN" in m),
		"Hiệp 18 sends the necromancer screen in behind it, got %s" % fired)

	# Hiệp 20: the Demon Emperor finale.
	_clear_enemies()
	fired.clear()
	dir.current_wave = 20
	spawner._process_wave_events(EnemySpawner.WAVE_EVENT_DELAY + 0.1)
	check(_any(fired, func(m): return "HẮC HUYẾT MA HOÀNG" in m),
		"Hiệp 20 spawns the Demon Emperor, got %s" % fired)

	# A wave must not re-fire its set piece every frame.
	fired.clear()
	spawner._process_wave_events(EnemySpawner.WAVE_EVENT_DELAY + 0.1)
	spawner._process_wave_events(EnemySpawner.WAVE_EVENT_DELAY + 0.1)
	check(fired.is_empty(), "Re-entering hiệp 20 does not re-announce the final boss")

	# Dropping back to a plain round and returning re-arms the script, so a run
	# reset is not a silently dead finale.
	dir.current_wave = 1
	spawner._process_wave_events(0.1)
	fired.clear()
	dir.current_wave = 20
	spawner._process_wave_events(EnemySpawner.WAVE_EVENT_DELAY + 0.1)
	check(_any(fired, func(m): return "HẮC HUYẾT MA HOÀNG" in m),
		"A reset run re-arms hiệp 20's finale")

	_clear_enemies()
	_drop(spawner)
	_drop(dir)
	# The stand-in must go too, or it stays the first answer to every
	# get_first_node_in_group("player") the rest of the suite asks.
	_drop(spawner.player)
	print("✔ Wave-driven spawner: per-hiệp events, entrance delay, 480s ceiling, no re-fire.")

## True if the named method exists on EnemySpawner. A throwaway instance is
## needed because the script declares has_method() on the class, not a static.
func _handler_exists(name: String) -> bool:
	var probe := EnemySpawner.new()
	var found := probe.has_method(name)
	probe.free()
	return found

# --- 2. Sect asymmetry: five opposed archetypes -------------------------------

func _test_sect_asymmetry() -> void:
	check(GameManager.CHARACTERS.size() == 5, "Still exactly 5 Môn Phái, got %d" % GameManager.CHARACTERS.size())

	# Every sect must actually trade. A sect with no downside is a generalist, and
	# two generalists means the Milestone 2 point did not land.
	var tradeoffs: Dictionary = {
		"ranger": "slash_damage_mult", "mage": "damage_mult",
		"pyro": "damage_taken_mult", "beggar": "base_hp_bonus"
	}
	for id in tradeoffs.keys():
		var d = GameManager.CHARACTERS[id]
		check(d.has(tradeoffs[id]), "%s carries its Milestone 2 trade-off (%s)" % [id, tradeoffs[id]])
	check(float(GameManager.CHARACTERS["ranger"]["slash_damage_mult"]) == 0.50, "Đường Môn's slash is halved")
	check(float(GameManager.CHARACTERS["mage"]["damage_mult"]) == 0.85, "Nga Mi's base damage is -15%")
	check(float(GameManager.CHARACTERS["pyro"]["damage_taken_mult"]) == 1.15, "Minh Giáo takes +15% damage")
	check(float(GameManager.CHARACTERS["beggar"]["base_hp_bonus"]) < 0.0, "Cái Bang starts below the 100 HP baseline")
	check(float(GameManager.CHARACTERS["beggar"]["dodge_bonus"]) == 0.30, "Cái Bang dodges 30%")
	check(float(GameManager.CHARACTERS["beggar"]["area_of_effect_bonus"]) == 0.40, "Cái Bang's AoE is +40%")
	check(int(GameManager.CHARACTERS["ranger"]["piercing_bonus"]) == 1, "Đường Môn's darts carry +1 pierce")
	check(float(GameManager.CHARACTERS["ranger"]["attack_speed_bonus"]) == 0.35, "Đường Môn attacks +35% faster")
	check(float(GameManager.CHARACTERS["pyro"]["might_bonus"]) == 0.60, "Minh Giáo brings +60% Might")
	check(float(GameManager.CHARACTERS["pyro"]["burn_mult"]) == 1.60, "Minh Giáo brings +60% burn")
	check(float(GameManager.CHARACTERS["mage"]["lifesteal_bonus"]) == 0.25, "Nga Mi lifesteals 25%")
	check(float(GameManager.CHARACTERS["mage"]["combo_heal"]) == 5.0, "Nga Mi's finisher heals 5 HP")

	# Starter loadouts are what tell the sects apart at a glance.
	check(_starts("knight") == ["dagger", "slash"], "Tiêu Dao opens Dagger + Slash")
	check(_starts("beggar") == ["axe"], "Cái Bang opens with the axe alone")
	check(_starts("ranger") == ["dagger"], "Đường Môn opens with the dart alone")
	check(_starts("pyro") == ["fireball", "lightning"], "Minh Giáo opens Fireball + Lightning")
	check(_starts("mage") == ["shield", "slash"], "Nga Mi opens Shield + Slash")

	# --- the bonuses reach the live player, not just the dict ---
	#
	# None of the numbers below are absolute. The developer's save carries meta
	# upgrades, Codex bonuses, meridian levels and an equipped Thiên Kiếm, all of
	# which fold into the very fields under test -- refresh_meta_stats() alone
	# multiplies the blast radius by 1.25 and adds 0.15 Might on top of the sect
	# term. So every check is written as a difference or a ratio against a
	# reference sect, which isolates the sect contribution exactly whatever the
	# save holds.
	var knight_ref := _spawn_as("knight")
	var ref_blast: float = knight_ref.get_node("Weapons/FireballWeapon").blast_radius_multiplier
	_drop(knight_ref)
	# Ngã Mi is the speed reference: like Tiêu Dao she has no flat speed bonus, but
	# her char_speed_mult is 1.0, so the gap between them is Tiêu Dao's +10%.
	var speed_ref := _spawn_as("mage")
	var ref_speed: float = speed_ref.move_speed
	_drop(speed_ref)

	_player = _spawn_as("beggar")
	check(is_equal_approx(_player.char_dodge_bonus, 0.30), "Cái Bang player reads 30% dodge")
	check(is_equal_approx(_player.max_health, 80.0), "Cái Bang starts at 80 HP (100 - 20), got %s" % _player.max_health)
	var fire = _player.get_node("Weapons/FireballWeapon")
	check(is_equal_approx(_player.char_area_bonus, 0.40), "Cái Bang carries a +40% AoE stat")
	check(fire.blast_radius_multiplier > ref_blast,
		"Cái Bang's +40%% AoE widens the fireball blast (%.2f vs %.2f)" % [fire.blast_radius_multiplier, ref_blast])
	# The equipped Thiên Kiếm scales the whole blast term, so the gap is the stat
	# times that scale rather than the stat itself. Hand Tiêu Dao the very same
	# number and her blast must land exactly on Cái Bang's -- which proves the
	# stat is the only thing moving it, without restating the formula here.
	var aoe_ref := _spawn_as("knight")
	aoe_ref.char_area_bonus = 0.40
	aoe_ref.refresh_meta_stats()
	check(is_equal_approx(aoe_ref.get_node("Weapons/FireballWeapon").blast_radius_multiplier, fire.blast_radius_multiplier),
		"A +40%% AoE stat moves the fireball blast exactly as far as Cái Bang's does")
	_drop(aoe_ref)
	_drop(_player)

	_player = _spawn_as("ranger")
	var dagger = _player.get_node("Weapons/MainWeapon")
	check(dagger.pierce_bonus == 1, "Đường Môn's dagger carries +1 pierce, got %d" % dagger.pierce_bonus)
	# apply_character_data() is additive on the weapon's own rate, so pin the delta
	# against a dagger that never got Đường Môn's bonus.
	check(is_equal_approx(dagger.speed_multiplier, 1.35),
		"Đường Môn's dagger attacks +35%% faster, got %s" % dagger.speed_multiplier)
	_drop(_player)

	_player = _spawn_as("pyro")
	check(_player.char_damage_taken_mult == 1.15, "Minh Giáo's +15% fragility is live")
	check(_player.get_burn_multiplier() == 1.60, "Minh Giáo's +60% burn is live")
	_drop(_player)

	_player = _spawn_as("mage")
	check(is_equal_approx(_player.char_lifesteal_bonus, 0.25), "Nga Mi lifesteals 25%")
	check(_player.char_combo_heal == 5.0, "Nga Mi's finisher heals 5 HP")
	# -15% base damage has to live inside the one multiplier every weapon reads.
	check(is_equal_approx(_player.get_might_multiplier(), (1.0 + _player.meta_might_bonus) * 0.85),
		"Nga Mi's -15% base damage is baked into get_might_multiplier()")
	_drop(_player)

	_player = _spawn_as("knight")
	# Tiêu Dao is the generalist: the +10% Might is the whole trade-off, and the
	# other four sects' damage penalties must not have leaked onto it.
	check(is_equal_approx(_player.char_might_bonus, 0.10), "Tiêu Dao's stat is +10% Might")
	check(is_equal_approx(_player.char_damage_mult, 1.0), "Tiêu Dao carries no damage penalty")
	check(is_equal_approx(_player.get_might_multiplier(), 1.0 + _player.meta_might_bonus),
		"Tiêu Dao's Might reads exactly 1.0 + its bonuses, got %s" % _player.get_might_multiplier())
	check(is_equal_approx(_player.char_speed_mult, 1.10), "Tiêu Dao's stat is a +10% speed multiplier")
	# move_speed = base * char_speed_mult + flat bonuses, and the flat bonuses
	# (Vạn Hạc Hài, Xung Mạch) are the same on both sides, so dividing the flat
	# part out leaves the multiplier.
	var flat := 0.0
	if GameManager.has_equipped("van_hac_hai"):
		flat += 30.0
	flat += float(GameManager.get_meridian_stat("xung_mach")) * 15.0
	check(is_equal_approx((_player.move_speed - flat) / (ref_speed - flat), 1.10),
		"Tiêu Dao moves 10%% faster (%.1f vs %.1f)" % [_player.move_speed, ref_speed])
	_drop(_player)

	_player = _spawn_as("knight")
	check(is_equal_approx(_player.get_might_multiplier(), 1.0 + _player.meta_might_bonus),
		"Tiêu Dao's 1.10x Might is the generalist's whole edge")
	_drop(_player)
	print("✔ Sect asymmetry: 5 opposed archetypes, trade-offs live on the player.")

func _starts(id: String) -> Array:
	return GameManager.CHARACTERS[id]["starter_weapons"]

## Player._ready() already calls apply_character_data(); calling it again here would
## double-add the one non-idempotent line in it (the Đường Môn dagger's +35% attack
## speed), silently handing the test a dagger firing at 1.70x.
func _spawn_as(char_id: String) -> Player:
	GameManager.select_character(char_id)
	var p := PLAYER_SCENE.instantiate() as Player
	add_child(p)
	return p

# --- 3. The trade-offs bite during actual combat ------------------------------

func _test_sect_mechanics_in_combat() -> void:
	# Nga Mi's -15% must show up in the damage an enemy actually takes.
	# _slash_damage() divides out each player's shared Might term, so the sect's own
	# damage modifier is all that is left in the ratio.
	var mage := _spawn_as("mage")
	var thinned := _slash_damage(mage)
	_drop(mage)
	var knight := _spawn_as("knight")
	var baseline := _slash_damage(knight)
	_drop(knight)
	check(thinned < baseline, "Nga Mi's opening swing is weaker than the neutral one (%.1f vs %.1f)" % [thinned, baseline])
	check(is_equal_approx(thinned, baseline * 0.85),
		"Nga Mi's swing lands at exactly 85%% of the neutral swing (%.1f vs %.1f)" % [thinned, baseline])

	# Đường Môn's halved blade, same measurement.
	var ranger := _spawn_as("ranger")
	var deaf := _slash_damage(ranger)
	_drop(ranger)
	check(is_equal_approx(deaf, baseline * 0.50),
		"Đường Môn's melee swing lands at exactly 50%% of the neutral swing (%.1f vs %.1f)" % [deaf, baseline])

	# Minh Giáo's fragility, measured on the real damage path. Both heroes are
	# levelled to the same armour, so the +15% is the only thing left in the ratio.
	# Absolute HP is not a fixed number, because two of get_armor_bonus()'s four terms
	# come from the save rather than from the hero: GameManager's meta armour stat
	# and the Nhuyễn Vị Giáp relic slot (player.gd:947-948). The zeroes in _taken_by()
	# are on player members, so neither is reachable from there -- a knight loses 28
	# with the relic equipped and exactly 30 without it. A "< 30.0" therefore passed on
	# the developer's save and failed from a blank one; asserting against the armour
	# the hero actually had holds on either.
	var pyro_taken := _taken_by("pyro", 30.0)
	var knight_taken := _taken_by("knight", 30.0)
	var pyro_loss: float = pyro_taken.x
	var knight_loss: float = knight_taken.x
	check(is_equal_approx(pyro_loss / knight_loss, 1.15),
		"Minh Giáo bleeds 15%% harder than the generalist (%.2f vs %.2f)" % [pyro_loss, knight_loss])
	check(is_equal_approx(knight_loss, maxf(1.0, 30.0 - float(knight_taken.y))),
		"The full damage path still runs: 30 less the armour it actually had (lost %.2f at %d armour)"
		% [knight_loss, int(knight_taken.y)])

	# Nga Mi's lifesteal, through the enemy's own hit resolution.
	var bat_scene := load("res://scenes/bat.tscn") as PackedScene
	_player = _spawn_as("mage")
	_player.current_health = 50.0
	var victim := bat_scene.instantiate()
	victim.max_health = 5000.0
	victim.current_health = 5000.0
	add_child(victim)
	victim.take_damage(100.0, _player.global_position)
	check(_player.current_health > 50.0, "Nga Mi heals off a landed hit (50 -> %s)" % _player.current_health)
	_drop(victim)

	# Minh Giáo's burn rider, through enemy.apply_burn().
	_drop(_player)
	_player = _spawn_as("pyro")
	var burned := bat_scene.instantiate()
	add_child(burned)
	burned.apply_burn(3.0, 20.0)
	check(burned.burn_dps > 20.0, "Minh Giáo's burn ticks harder than it was handed (20 -> %s)" % burned.burn_dps)
	_drop(burned)
	_drop(_player)
	print("✔ Sect trade-offs verified in combat: dealt damage, taken damage, lifesteal, burn.")

## Run one hit through the real damage path and report how much HP it cost.
## Sect armour is zeroed so two sects can be compared head to head; the shared
## meta armour and relic stay in place, which is fine because they are identical
## on both sides and the point of the check is the ratio.
func _taken_by(char_id: String, amount: float) -> Vector2:
	var p := _spawn_as(char_id)
	p.char_armor_bonus = 0
	p.shop_armor_bonus = 0
	p.current_health = 100.0
	p.invulnerability_timer = 0.0
	p.qi_shield_current = 0.0
	# Read back rather than assumed: get_armor_bonus() (player.gd:946-949) sums four
	# terms and the two zeroes above only reach two of them.
	var armour := p.get_armor_bonus()
	p.take_damage(amount)
	var lost: float = 100.0 - p.current_health
	_drop(p)
	return Vector2(lost, armour)

## Swing the real blade at a stationary dummy and report the damage, divided by the
## player's shared Might term. Meta upgrades, the Codex, meridian levels and the
## equipped Thiên Kiếm all scale the roll identically for every sect; dividing them
## out leaves the sect's own damage modifier, so the ratios above are exact whatever
## the developer's save holds. Note it is meta_might_bonus, not get_might_multiplier
## -- the latter already folds in the sect's own damage penalty, and dividing by it
## would cancel out the very thing under test.
func _slash_damage(p: Player) -> float:
	var dummy := (load("res://scenes/bat.tscn") as PackedScene).instantiate()
	dummy.max_health = 100000.0
	dummy.current_health = 100000.0
	dummy.global_position = p.global_position + Vector2(50, 0)
	add_child(dummy)

	# enemy.take_damage() rolls a 12% crit (more with Đốc Mạch) and a crit multiplies
	# the whole hit by 2.2, so an unseeded measurement is right ~88% of the time and
	# silently wrong the rest. Seed identically for every sect: the crit roll is the
	# first randf() on the path, so all three verdicts agree and the multiplier
	# cancels out of the ratios regardless of which way it lands.
	seed(20260926)

	var slash = p.get_node("Weapons/SlashWeapon")
	slash.is_active = false
	slash.tier_damage_mult = 1.0
	slash.perform_slash(Vector2.RIGHT, 0)
	var dealt: float = 100000.0 - float(dummy.current_health)
	_drop(dummy)
	return dealt / maxf(1.0 + p.meta_might_bonus, 0.0001)

# --- 4. Wave economy: bounty + savings interest -------------------------------

func _test_wave_economy() -> void:
	var dir := WaveDirector.new()
	dir.max_waves = 20
	add_child(dir)
	GameManager.is_blood_moon = false

	# --- the formulas ---
	check(WaveDirector.CLEAR_BASE_GOLD == 15, "Base bounty is 15g")
	check(WaveDirector.CLEAR_GOLD_PER_WAVE == 3, "Bounty climbs 3g per wave")
	check(dir.calculate_clear_gold(1) == 18, "Hiệp 1 pays 15 + 3 = 18g")
	check(dir.calculate_clear_gold(7) == 36, "Hiệp 7 pays 15 + 21 = 36g")
	check(dir.calculate_clear_gold(20) == 75, "Hiệp 20 pays 15 + 60 = 75g")
	check(dir.calculate_clear_gold(11) > dir.calculate_clear_gold(3),
		"The bounty scales with the round")

	# +1g per 10 banked, capped at 2 per wave early and 10 overall later.
	check(dir.calculate_interest(0, 10) == 0, "An empty purse earns no interest")
	check(dir.calculate_interest(9, 10) == 0, "9g banked earns no interest")
	check(dir.calculate_interest(10, 10) == 1, "10g banked earns 1g")
	check(dir.calculate_interest(95, 10) == 9, "95g banked earns 9g")
	check(dir.calculate_interest(1000, 10) == 10, "Interest is hard-capped at 10g")
	# The per-wave cap bites before the absolute one: 2g/wave means hiệp 1 can
	# never pay more than 2g no matter how fat the purse is.
	check(dir.calculate_interest(1000, 1) == 2, "Hiệp 1 interest is capped at 2g")
	check(dir.calculate_interest(1000, 2) == 4, "Hiệp 2 interest is capped at 4g")
	check(dir.calculate_interest(1000, 5) == 10, "From hiệp 5 the 10g ceiling takes over")
	check(dir.calculate_interest(1000, 6) >= dir.calculate_interest(1000, 5),
		"Interest never falls as the waves climb")
	check(dir.calculate_interest(-50, 10) == 0, "A negative purse earns no interest")

	# --- end_wave() pays it ---
	GameManager.run_gold = 100
	dir.current_wave = 3
	dir.start_wave(3)
	dir.end_wave()
	check(dir.last_clear_gold == 24, "Hiệp 3 records a 24g bounty, got %d" % dir.last_clear_gold)
	check(dir.last_interest_earned == 6, "100g banked at hiệp 3 earns 6g, got %d" % dir.last_interest_earned)
	check(GameManager.run_gold == 130, "The purse grows by bounty + interest (100 -> %d)" % GameManager.run_gold)

	# Interest is read BEFORE the bounty lands, otherwise the player would pay
	# interest on gold the bell just handed them.
	GameManager.run_gold = 0
	dir.current_wave = 5
	dir.start_wave(5)
	dir.end_wave()
	check(dir.last_interest_earned == 0, "A broke purse earns no interest, got %d" % dir.last_interest_earned)
	check(GameManager.run_gold == 30, "Hiệp 5 with an empty purse pays only the bounty, got %d" % GameManager.run_gold)

	# Hoarding beats spending, which is the whole point of the mechanic.
	GameManager.run_gold = 500
	dir.current_wave = 8
	dir.start_wave(8)
	dir.end_wave()
	var hoard_gain: int = GameManager.run_gold - 500
	GameManager.run_gold = 0
	dir.current_wave = 8
	dir.start_wave(8)
	dir.end_wave()
	var broke_gain: int = GameManager.run_gold
	check(hoard_gain > broke_gain, "Banking 500g at hiệp 8 beats banking nothing (%d vs %d)" % [hoard_gain, broke_gain])
	check(hoard_gain == broke_gain + 10, "500g banked earns the full 10g interest (%d vs %d)" % [hoard_gain, broke_gain])

	# --- the shop tells the player about it ---
	GameManager.run_gold = 120
	dir.current_wave = 9
	dir.start_wave(9)
	dir.end_wave()
	var shop := SHOP_SCENE.instantiate() as WaveShopUI
	add_child(shop)
	shop.open_for_wave(10)
	check(shop.payout_wave == 9, "The shop reports on hiệp 9, got %d" % shop.payout_wave)
	var summary := shop.get_wave_summary()
	check("Hoàn thành Hiệp 9" in summary, "The banner names the completed hiệp: %s" % summary)
	check("+%d Vàng" % dir.last_clear_gold in summary, "The banner shows the bounty: %s" % summary)
	check("Lợi tức tiết kiệm: +%d Vàng" % dir.last_interest_earned in summary,
		"The banner shows the savings interest: %s" % summary)
	shop.close_shop()
	_drop(shop)

	# end_wave() is idempotent, so the second call must not pay again.
	dir.current_wave = 4
	dir.start_wave(4)
	GameManager.run_gold = 0
	dir.end_wave()
	var after_first := GameManager.run_gold
	dir.end_wave()
	check(GameManager.run_gold == after_first, "A second end_wave() on the same hiệp pays nothing")

	GameManager.is_victory_triggered = false
	GameManager.run_gold = 0
	_drop(dir)
	print("✔ Economy: 15+3g bounty, interest on unspent gold, banner reports both.")

# --- 5. Regression: the legacy clock still works standalone --------------------

func _test_legacy_fallback() -> void:
	# No director in this scene: the spawner must find its own way back to the
	# pre-Milestone-2 480s survival ladder.
	check(get_tree().get_first_node_in_group("wave_director") == null,
		"No WaveDirector is in this scene -- the legacy path is what runs")

	var spawner := _make_spawner()
	spawner.player = _player_stand_in()
	check(spawner.get_director() == null, "A standalone spawner resolves no director")

	GameManager.run_time = 0.0
	check(is_equal_approx(spawner.get_difficulty_seconds(), 0.0),
		"With no director the spawner falls back to run_time, got %s" % spawner.get_difficulty_seconds())
	GameManager.run_time = 240.0
	check(is_equal_approx(spawner.get_difficulty_seconds(), 240.0),
		"Legacy difficulty tracks run_time, got %s" % spawner.get_difficulty_seconds())

	# The legacy ladder's own milestones still fire on the old clock.
	var fired: Array = []
	spawner.connect("wave_event_announced", func(msg, _is_boss): fired.append(msg))
	GameManager.run_time = 60.0
	spawner._process_legacy_timeline(60.0)
	check(_any(fired, func(m): return "DREADLORD MALAKOR" in m),
		"Legacy 60s still summons Dreadlord Malakor, got %s" % fired)

	GameManager.run_time = 435.0
	spawner._process_legacy_timeline(435.0)
	check(_any(fired, func(m): return "HẮC HUYẾT MA HOÀNG" in m),
		"Legacy 435s still summons the Demon Emperor, got %s" % fired)

	# One-shot guards: the legacy timeline must not re-summon a cleared boss.
	spawner.boss_1_spawned = true
	spawner.demon_emperor_spawned = true
	fired.clear()
	spawner._process_legacy_timeline(500.0)
	check(fired.is_empty(), "Already-summoned legacy bosses do not return")

	# A director appearing later takes over cleanly -- no restart required.
	var dir := WaveDirector.new()
	add_child(dir)
	spawner.wave_director = null  # force the lazy re-resolve
	check(spawner.get_director() == dir, "A spawner re-resolves the director once it is in the tree")
	dir.current_wave = 12
	check(is_equal_approx(spawner.get_difficulty_seconds(), 288.0),
		"Hiệp 12 reads as 288s of difficulty, got %s" % spawner.get_difficulty_seconds())

	_clear_enemies()
	_drop(spawner)
	_drop(dir)
	GameManager.run_time = 0.0
	print("✔ Legacy fallback: run_time ladder intact, one-shot guards hold, director takes over.")
