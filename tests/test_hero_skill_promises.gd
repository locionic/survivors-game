extends "res://tests/suite_base.gd"

## Expansion 57.0: half of Cái Bang's ultimate was a promise with no code behind it.
##
## The skill card reads "+40% Né Đòn & +50% Tốc Đánh trong 6.0s". The dodge was
## real -- player.gd:759 folds `+0.40` into `total_dodge` whenever
## `drunken_buff_timer > 0.0`. The attack speed was not, and could not have been:
## `get_attack_speed_multiplier()` was the *only* attack-speed hook in the game,
## and its entire body was
##
##     return RELIC_RAGE_ATTACK_SPEED if is_demonic_rage_active() else 1.0
##
## -- no reference to the timer. Measured 2026-10-01 with the beggar applied:
##
##     attack speed, before = 1
##     attack speed, during = 1
##
## Six seconds of a 6.0s buff that changed nothing about how fast you attack. All
## five weapons route their fire rate through that one function, so the fix is one
## term in the composition rather than five call sites.
##
## The suite asserts against `get_attack_speed_multiplier()` itself, not against a
## weapon's measured fire rate, because that function is what every weapon reads
## and it is where the promise is made. `test_expansion_14.gd:45` already tries to
## cover the dodge half and does not: it computes `char_dodge_bonus + 0.40` as a
## local and checks the sum is >= 0.55, which is arithmetic performed by the test
## rather than a roll performed by the game. This suite calls the real thing.

func _beggar() -> Player:
	# selected_character is written directly rather than through select_character(),
	# which calls save_game_data() and would leave the developer's real save on a
	# hero they did not pick. apply_character_data() reads the field, so the player
	# is configured exactly as the game's own selection would configure it.
	GameManager.selected_character = "beggar"
	var p = load("res://scenes/player.tscn").instantiate() as Player
	add_child(p)
	p.apply_character_data()
	return p

func _test_buff_grants_the_advertised_attack_speed() -> void:
	var p = _beggar()
	if not check(p != null, "player instantiates"):
		return
	check(p.skill_id == "drunken_brew", "Cái Bang's signature skill is drunken_brew")

	p.drunken_buff_timer = 0.0
	var before := p.get_attack_speed_multiplier()
	p.drunken_buff_timer = 6.0
	var during := p.get_attack_speed_multiplier()

	check(before == 1.0, "attack speed is unmodified before the skill, got %f" % before)
	check(is_equal_approx(during, 1.5),
		"Say Rượu Bát Tiên advertises +50%% Tốc Đánh; attack speed during the buff is %f" % during)

func _test_buff_expires_with_its_timer() -> void:
	# A buff that outlived its own duration would be worse than the missing half:
	# the player drinks once and is permanently 50% faster.
	var p = _beggar()
	if not check(p != null, "player instantiates"):
		return
	p.drunken_buff_timer = 0.05
	p._physics_process(0.1)
	check(p.drunken_buff_timer <= 0.0, "the 6.0s timer is consumed by _physics_process")
	check(is_equal_approx(p.get_attack_speed_multiplier(), 1.0),
		"attack speed returns to baseline once the buff expires, got %f"
		% p.get_attack_speed_multiplier())

func _test_buff_stacks_with_the_rage_relic_rather_than_replacing_it() -> void:
	# The relic used to be an either/or ternary, so the moment a second source
	# existed the old one had to become a composition or the new one would silently
	# delete it. 1.15 * 1.50 is +72.5%, and the relic alone must still read 1.15.
	var p = _beggar()
	if not check(p != null, "player instantiates"):
		return
	p.drunken_buff_timer = 0.0
	# Raging is demonic_token owned AND at or below half health -- both halves,
	# because a half-written setup here is a test that asserts nothing.
	GameManager.add_relic("demonic_token")
	p.current_health = p.max_health
	check(not p.is_demonic_rage_active(), "demonic_token at full health is not rage")
	check(is_equal_approx(p.get_attack_speed_multiplier(), 1.0),
		"no rage and no buff is baseline, got %f" % p.get_attack_speed_multiplier())

	p.current_health = p.max_health * 0.4
	check(p.is_demonic_rage_active(), "demonic_token below 50%% health rages")
	check(is_equal_approx(p.get_attack_speed_multiplier(), 1.15),
		"the rage relic alone is still +15%%, got %f" % p.get_attack_speed_multiplier())

	p.drunken_buff_timer = 6.0
	check(is_equal_approx(p.get_attack_speed_multiplier(), 1.15 * 1.5),
		"rage and the buff compose to 1.725, got %f" % p.get_attack_speed_multiplier())

func _ready() -> void:
	print("=== RUNNING EXPANSION 57.0: HERO SKILL PROMISE TEST SUITE ===")
	GameManager.is_run_active = false

	_test_buff_grants_the_advertised_attack_speed()
	_test_buff_expires_with_its_timer()
	_test_buff_stacks_with_the_rage_relic_rather_than_replacing_it()

	GameManager.selected_character = "knight"
	if _failures.is_empty():
		print("=== ALL EXPANSION 57.0 TESTS PASSED 100% CLEANLY! ===")
	get_tree().quit(_exit_code())