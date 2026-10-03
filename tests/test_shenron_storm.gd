extends Node

## Expansion 49.0: Vạn Kiếm Quy Tông -- the Shenron sword storm.
##
## The wish advertised "tiêu diệt toàn bộ ma vật trên bản đồ" -- destroy every
## monster on the map -- and the only test that touched it (test_expansion_12)
## asserted nothing more than `van_kiem_timer == 20.0`, i.e. that a timer got
## set. Nothing had ever established that a single enemy took a single point of
## damage, so the promise was unfalsifiable.
##
## Measured, on a screen of 40 enemies at 3000 HP each, over the full promised
## 20s: 60,446 of 120,000 HP delivered, and 1 of 40 killed. The storm is
## enormously powerful -- it is the copy that was wrong, not the balance -- so
## the description now states what the code does. These tests hold both halves:
## the mechanism keeps working, and the description cannot drift back into
## promising something the code does not do.

const TAU_FULL: float = TAU

var _failures: Array[String] = []

func check(cond: bool, msg: String) -> bool:
	if not cond:
		_failures.append(msg)
		push_error("CHECK FAILED: %s" % msg)
	return cond

## These are REAL physics frames on purpose. The blade is an Area2D that deals
## its damage from body_entered, so hand-driving _physics_process() moves it
## without ever running the physics server: measured as a clean 0 damage, which
## is how the first version of this suite came to "proving" the storm was dead.
func _run_frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame

## A clean slate, so a damage number here is the storm's and not the save's.
func _pin_clean_state() -> void:
	GameManager.collected_relics.erase("storm_amulet")
	GameManager.meta_upgrades["might"] = 0
	GameManager.meta_upgrades["armor"] = 0
	GameManager.meta_upgrades["pyro"] = 0
	GameManager.meta_upgrades["vitality"] = 0
	GameManager.meta_upgrades["swiftness"] = 0
	GameManager.meta_upgrades["magnetism"] = 0
	GameManager.meridian_upgrades = {"nham_mach": 0, "doc_mach": 0, "xung_mach": 0, "dan_dien": 0}

func _spawn_cluster(player: Node2D, count: int, hp: float, offset: Vector2, spread: float = 6.0) -> Array:
	var out: Array = []
	for i in count:
		var e = load("res://scenes/enemy.tscn").instantiate()
		add_child(e)
		e.max_health = hp
		e.current_health = hp
		var ang := TAU_FULL * float(i) / float(count)
		e.global_position = player.global_position + offset + Vector2(cos(ang), sin(ang)) * spread
		# Frozen in place. These are live CharacterBody2Ds with a 12px collision
		# circle: left running, they chase the player and shove each other apart
		# while the blade is still in flight, and the pile the pierce check is
		# about is a different shape by the time the blade arrives. Collision
		# detection is independent of the body's own process, so they stay
		# hittable while stationary.
		e.set_physics_process(false)
		out.append(e)
	return out

func _total_hp(enemies: Array) -> float:
	var t := 0.0
	for e in enemies:
		if is_instance_valid(e):
			t += float(e.current_health)
	return t

func _ready() -> void:
	print("=== RUNNING EXPANSION 49.0: VẠN KIẾM QUY TÔNG TEST SUITE ===")
	GameManager.is_run_active = false

	var player = load("res://scenes/player.tscn").instantiate()
	add_child(player)
	player.apply_character_data()
	_pin_clean_state()

	await _test_the_storm_actually_damages_something(player)
	await _test_the_blade_carries_the_pierce_the_copy_promises(player)
	_test_the_description_stops_overpromising()

	get_tree().paused = false
	var unique: Array[String] = []
	for f in _failures:
		if not unique.has(f):
			unique.append(f)
	if unique.is_empty():
		print("=== ALL SHENRON SWORD STORM TESTS PASSED 100% CLEANLY! ===")
		get_tree().quit(0)
	else:
		print("=== %d CHECK(S) FAILED (first %d unique) ===" % [_failures.size(), unique.size()])
		for f in unique:
			print("  FAIL: %s" % f)
		get_tree().quit(1)

# --- 1. The storm deals damage -----------------------------------------------

func _test_the_storm_actually_damages_something(player) -> void:
	var enemies := _spawn_cluster(player, 4, 99999.0, Vector2(0, -250))
	var before := _total_hp(enemies)

	player.apply_shenron_wish("wish_swords")
	check(is_equal_approx(player.van_kiem_timer, 20.0),
		"Wish arms the storm for its advertised 20s, got %f" % player.van_kiem_timer)

	# Only the 20s timer summons blades -- park it so this is one summon's work.
	player.van_kiem_timer = 0.0
	player._summon_van_kiem_sword()
	await _run_frames(45)

	var dealt := before - _total_hp(enemies)
	check(dealt > 0.0,
		"A summoned Thần Kiếm damages the enemies it flies through (got 0 damage across 4 targets)")

	for e in enemies:
		e.queue_free()
	print("OK The storm puts real damage on the field.")

# --- 2. A blade pierces ------------------------------------------------------

## The copy promises "mỗi kiếm xuyên 5 mục tiêu". The number is read out of the
## description and compared against the blade the wish actually spawns, so this
## goes red if EITHER the copy drifts or the code is retuned away from it.
##
## It deliberately does not try to prove this by shooting blades into a packed
## formation. That version was built and measured: one blade into 12 packed
## enemies scored 5, 5, 5, 1 across four runs, because the aim point and spawn
## offset are both randomised and the blade's flight varies with them. A check
## that green two times out of three is worse than no check -- it trains people
## to ignore the gate. The formation count is also capped by deferred
## queue_free(): bodies report body_entered in the same tick the blade dies, so
## even pierce=1 lands three.
func _test_the_blade_carries_the_pierce_the_copy_promises(player) -> void:
	var desc: String = GameManager.SHENRON_WISHES["wish_swords"].get("desc", "")
	var promised := _parse_promised_pierce(desc)
	check(promised > 0, "The description still states how many targets a blade pierces: %s" % desc)

	# The player's own weapons are also firing into this group, and the earlier
	# test's blade is still alive -- so "the last SpiritSwordProjectile" picks
	# up a stale one. Only an instance that did not exist a frame ago counts.
	var already: Dictionary = {}
	for p in get_tree().get_nodes_in_group("projectiles"):
		if p is SpiritSwordProjectile:
			already[p.get_instance_id()] = true

	player.van_kiem_timer = 0.0
	player._summon_van_kiem_sword()
	await get_tree().physics_frame

	var blade: SpiritSwordProjectile = null
	for p in get_tree().get_nodes_in_group("projectiles"):
		if p is SpiritSwordProjectile and not already.has(p.get_instance_id()):
			blade = p
			break
	check(blade != null, "The wish spawns a Thần Kiếm blade")
	if blade != null and promised > 0:
		check(blade.pierce == promised,
			"The spawned blade pierces %d targets, which is the number the description advertises" % promised)
		check(blade.damage > 0.0, "The spawned blade carries a real damage value, got %f" % blade.damage)

	print("OK The blade's pierce matches the number the description advertises.")

## "mỗi kiếm xuyên 5 mục tiêu" -> 5
func _parse_promised_pierce(desc: String) -> int:
	var re := RegEx.new()
	if re.compile("xuyên\\s*(\\d+)\\s*mục tiêu") != OK:
		return 0
	var m := re.search(desc)
	if m == null:
		return 0
	return int(m.get_string(1))

# --- 3. The copy matches the code -------------------------------------------

## The defect this suite exists for was in a string. Left unchecked, the next
## balance pass has no reason to prefer an honest description over a good one.
func _test_the_description_stops_overpromising() -> void:
	var desc: String = GameManager.SHENRON_WISHES["wish_swords"].get("desc", "")
	check(not desc.contains("toàn bộ ma vật"),
		"The Shenron description no longer promises to destroy every monster on the map: %s" % desc)
	check(desc.contains("20s"),
		"The Shenron description still states the 20s duration it actually gets: %s" % desc)
	print("OK The Shenron description states the storm, not a map clear.")