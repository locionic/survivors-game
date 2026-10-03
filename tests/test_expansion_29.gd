extends Node

## Automated Test Suite for Expansion 29.0:
## "Chiến Tích Lệnh" -- the bounty aimed at the wrong enemy.
##
## init_run_bounties() offers four bounties, each keyed by a hand-typed target_type that
## record_bounty_event() matches on. One of them is:
##
##     "id": "defeat_champion", "title": "Champion Slayer",
##     "desc": "Slay an Elite Champion", "target_type": "kill_champion"
##
## and the only thing that fed "kill_champion" was add_kill()'s second argument. That
## argument was called is_champ and was fed is_champion -- but is_champion and
## is_elite_champion are siblings, not a nesting. make_champion() sets is_champion;
## make_elite_champion() sets is_elite_champion and never touches the other. So the
## bounty the game advertises as "Slay an Elite Champion" was credited to:
##
##   * ordinary affix champions, which are not what it says, and
##   * not one Elite Champion, which is,
##
## and a third caller, goblin.gd, passed a hardcoded true for a Treasure Goblin that is no
## kind of champion at all. A goblin therefore completed "Champion Slayer" (80 gold) on
## top of "Greed Hunter" (90 gold) -- 170 gold of bounty for one kill, from the enemy a
## player is least likely to read as a champion.
##
## The fix makes the flag mean what the bounty advertises: add_kill()'s parameter is
## now is_elite_champ, enemy.gd passes is_elite_champion, and the goblin passes false.
## Elites spawn on a fixed schedule (90s, 180s, and twice in wave 5) against a target of
## one, so the bounty is still comfortably completable.
##
## No claim is made here that the old design was "intended". The advertised text is the
## contract the player reads, and the elite is what it names.

const GOBLIN_SCENE: PackedScene = preload("res://scenes/goblin.tscn")

## goblin.die() calls add_gold(80), which calls save_game_data() and rewrites the
## developer's save. Backed up and restored, per the same idiom test_expansion_23 uses.
const SAVE_PATH: String = "user://save_data.cfg"
const BACKUP_PATH: String = "user://save_data.cfg.m29bak"
var _had_save: bool = false

## assert() ABORTS the calling function when it fails: the rest of it never runs, the
## scene never reaches get_tree().quit(), and the suite hangs until the CI timeout
## kills it. Measured 2026-09-30 -- a single failed assert() on a passing suite
## prints the PASS banner and still exits 0. This records each broken expectation
## and drives the exit code from the failure count instead.
var _failures: Array[String] = []

var _bounties_backup: Array[Dictionary] = []
var _kills_backup: int = 0

func check(cond: bool, msg: String) -> bool:
	if not cond:
		_failures.append(msg)
		push_error("CHECK FAILED: %s" % msg)
	return cond

func _ready() -> void:
	print("=== RUNNING EXPANSION 29.0 TEST SUITE ===")
	GameManager.is_run_active = false
	_backup_save()
	_bounties_backup = GameManager.active_bounties.duplicate(true)
	_kills_backup = GameManager.kills

	_test_the_advertised_bounty_names_an_elite_champion()
	_test_only_an_elite_champion_credits_it()
	_test_a_goblin_does_not_credit_it_but_still_credits_its_own()
	_test_enemy_death_passes_the_elite_flag_not_the_champion_one()

	_restore_bounties()
	GameManager.kills = _kills_backup
	_restore_save()

	if _failures.is_empty():
		print("=== ALL EXPANSION 29.0 TESTS PASSED 100% CLEANLY! ===")
		get_tree().quit(0)
	else:
		print("=== %d CHECK(S) FAILED ===" % _failures.size())
		for f in _failures:
			print("  FAIL: %s" % f)
		get_tree().quit(1)

# --- 1. the contract, taken from the data the player reads ---------------------

func _test_the_advertised_bounty_names_an_elite_champion() -> void:
	GameManager.init_run_bounties()
	var champ := _bounty("kill_champion")
	if not check(not champ.is_empty(), "Precondition: a bounty watches for kill_champion"):
		return
	check(str(champ.get("desc", "")).to_lower().contains("elite"),
		"The kill_champion bounty still advertises an Elite Champion, got '%s'"
			% champ.get("desc", ""))
	check(int(champ.get("target", 0)) == 1,
		"Champion Slayer is a single-target kill, got %s" % champ.get("target", 0))
	# Every target_type in the data must be one something can actually feed, or that
	# bounty is uncompletable for the same silent reason the Codex reward was.
	for b in GameManager.active_bounties:
		check(FEEDABLE_TYPES.has(str(b.get("target_type", ""))),
			"Bounty %s has a target_type something reports: %s"
				% [b.get("id", "?"), b.get("target_type", "?")])

# --- 2. the flag, on the one function whose contract changed --------------------

## Targets are raised first so no increment can reach a completion: completing a bounty
## calls add_gold(), which calls save_game_data(). This checks which bounties *moved*,
## which is the whole of the contract, without writing the developer's save.
func _test_only_an_elite_champion_credits_it() -> void:
	GameManager.init_run_bounties()
	for b in GameManager.active_bounties:
		b["current"] = 0
		b["target"] = 99
		b["completed"] = false

	# An ordinary affix champion. enemy.gd used to pass is_champion for these.
	GameManager.add_kill("skeleton", false)
	check(is_equal_approx(float(_bounty("kill_champion").get("current", -1)), 0.0),
		"An ordinary champion does not satisfy 'Slay an Elite Champion', got %s"
			% _bounty("kill_champion").get("current", -1))

	# A real Elite Champion, which is what enemy.gd passes now.
	GameManager.add_kill("skeleton", true)
	check(is_equal_approx(float(_bounty("kill_champion").get("current", -1)), 1.0),
		"An Elite Champion does satisfy the bounty, got %s"
			% _bounty("kill_champion").get("current", -1))

	# The bat branch is untouched by this fix; a bat must still feed only its own bounty.
	var bat_before := float(_bounty("kill_bat").get("current", 0))
	GameManager.add_kill("bat", false)
	check(is_equal_approx(float(_bounty("kill_bat").get("current", 0)), bat_before + 1.0),
		"A bat still feeds Bat Hunter, got %s" % _bounty("kill_bat").get("current", -1))
	check(is_equal_approx(float(_bounty("kill_champion").get("current", -1)), 1.0),
		"A bat does not feed Champion Slayer, got %s"
			% _bounty("kill_champion").get("current", -1))

# --- 3. the goblin, end to end -------------------------------------------------

## The real defect as the player meets it: a Treasure Goblin completing a bounty it is
## not named for. Driven through the scene's own die() rather than by calling add_kill,
## so the argument in goblin.gd is genuinely under test.
func _test_a_goblin_does_not_credit_it_but_still_credits_its_own() -> void:
	GameManager.init_run_bounties()
	var goblin := GOBLIN_SCENE.instantiate()
	add_child(goblin)

	goblin.die()

	check(_bounty("kill_champion").get("completed", true) == false,
		"A Treasure Goblin does not complete 'Slay an Elite Champion' (champion bounty current %s of %s)"
			% [_bounty("kill_champion").get("current", -1), _bounty("kill_champion").get("target", -1)])
	check(_bounty("kill_goblin").get("completed", false) == true,
		"...but it does still complete Greed Hunter, its own bounty")

	_drop(goblin)

# --- 4. the caller the runtime cannot reach cheaply ----------------------------

## enemy.gd has exactly one call into add_kill() and it happens deep in die(), behind
## hitstop, particles and a FloatingText spawn -- driving it would stall the suite on
## Engine.time_scale to test one argument. The argument is read at the source instead.
## This is a string check on purpose and is labelled as one: it exists because the bug
## it guards was itself a single hand-typed argument, and nothing else would catch that
## token being reverted.
func _test_enemy_death_passes_the_elite_flag_not_the_champion_one() -> void:
	var f := FileAccess.open("res://scripts/enemy.gd", FileAccess.READ)
	if not check(f != null, "Precondition: res://scripts/enemy.gd is readable"):
		return
	var src := f.get_as_text()
	f.close()

	var passed := ""
	for line in src.split("\n"):
		if line.contains("add_kill("):
			passed = line.strip_edges()
			break
	if not check(passed != "", "Precondition: enemy.gd calls add_kill somewhere"):
		return
	check(passed.contains("is_elite_champion"),
		"enemy.gd credits the elite flag when recording a kill, got: %s" % passed)
	check(not passed.contains(", is_champion)"),
		"enemy.gd no longer passes is_champion to add_kill, got: %s" % passed)

# --- helpers ------------------------------------------------------------------

## The target_types init_run_bounties() can declare. Duplicated deliberately: this is
## the half that cannot notice a rename, so the contract is stated rather than inferred.
const FEEDABLE_TYPES: Array[String] = ["kill_bat", "kill_goblin", "kill_champion", "time"]

func _bounty(target_type: String) -> Dictionary:
	for b in GameManager.active_bounties:
		if str(b.get("target_type", "")) == target_type:
			return b
	return {}

func _restore_bounties() -> void:
	GameManager.active_bounties = _bounties_backup

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

func _drop(node: Node) -> void:
	if is_instance_valid(node):
		remove_child(node)
		node.queue_free()
