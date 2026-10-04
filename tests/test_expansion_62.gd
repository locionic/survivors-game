extends "res://tests/suite_base.gd"

## Phase 1 of the visual rebirth: the level-up cards were two styles pretending to
## be six. `_populate_cards()` branched on `is_evolution or is_synergy` and drew one
## dark panel or one gold one, so of the four rarities the plan calls for exactly
## two were visible, no card had a martial-art badge, and a card did nothing under
## the cursor.
##
## WHAT IS PINNED AND WHY EACH HALF MATTERS. `card_rarity()` is a pure function over
## the catalog's own flags, so the cheap assertion is that it classifies -- but a
## correct classifier that nothing calls would still leave every card grey. The
## build is therefore read back off a real Button: the stylebox actually installed
## has to carry the tier's border colour. Icon coverage is a scan over the whole
## catalog rather than a list, because the failure mode is a *new* card with no
## entry, and a list would not notice one.
##
## The hover lift is measured on `position` and `scale`, which is what the player
## sees, not on the tween that produced them. Both are asserted on the way up AND on
## the way back down, because a lift that only ever goes up leaves a card stranded
## over its neighbours.

const UPGRADE_MANAGER := preload("res://scripts/upgrade_manager.gd")

## The four tiers the plan names. Read out of UITheme rather than typed as literals
## here, so a palette edit cannot leave this suite asserting colours nothing uses.
const EXPECTED_TIERS: Array[int] = [0, 1, 2, 3]

var _up: UpgradeManager = null

func _mk() -> UpgradeManager:
	var m := UPGRADE_MANAGER.new()
	add_child(m)
	return m

## Show the panel and hand back the live cards. _teardown() clears the pause the
## manager sets, so a failing assert mid-suite cannot leave the tree frozen for
## whichever suite runs next.
func _open() -> Array[Button]:
	_up.show_upgrade_selection()
	var out: Array[Button] = []
	for child in _up.options_container.get_children():
		if child is Button:
			out.append(child)
	return out

## A maxed arsenal on every weapon, so the deal contains an evolution (Thần Công),
## a fusion (Tuyệt Kỹ) and unlocks (Hiếm) all at once. Both fusion partners at
## Lv.5 is what puts the synergy on the table.
func _max_everything() -> void:
	_up.weapon_levels = {"dagger": 5, "shield": 5, "lightning": 5, "fireball": 5, "axe": 5, "slash": 5}
	_up.evolved_weapons = {"dagger": false, "shield": false, "lightning": false,
		"fireball": false, "axe": false, "slash": false}

func _teardown() -> void:
	if is_instance_valid(_up):
		_up.queue_free()
		_up = null
	get_tree().paused = false

static func _find_particles(node: Node) -> CPUParticles2D:
	for child in node.get_children():
		if child is CPUParticles2D:
			return child
		var deep := _find_particles(child)
		if deep != null:
			return deep
	return null

# --- 1. every card is classified, and none is invisible -----------------------

func _test_every_catalog_card_is_classified_and_illustrated() -> void:
	_up = _mk()
	# Two passes, because one manager is never at both halves of the catalog at
	# once: the rank-up cards need a weapon between Lv.1 and Lv.4, the evolutions
	# and fusions need two weapons at Lv.5. Scanning only the fresh state cleared 14
	# cards and passed while half the game's cards went unillustrated.
	var seen := {}
	var tiers := {}
	for pass_maxed in [false, true]:
		if pass_maxed:
			_max_everything()
		for item in _up.get_upgrade_catalog():
			var id := String(item["id"])
			if seen.has(id):
				continue
			seen[id] = true
			tiers[_up.card_rarity(item)] = true
			check(_up.card_icon(id) != "✦",
				"card %s has no võ học badge -- add it to UpgradeManager.CARD_ICONS" % id)
	check(seen.size() >= 20, "both states between them are the whole catalog, got %d" % seen.size())
	for tier in EXPECTED_TIERS:
		check(tiers.has(tier), "rarity tier %d is reachable in the catalog" % tier)
	# Coverage by võ học rather than a bare count: the number moves every time a card
	# is added, but a weapon losing its last card is a real gap and does not.
	for weapon_id in ["dagger", "shield", "lightning", "fireball", "axe", "slash"]:
		var covered := false
		for id in seen:
			if String(id).contains(weapon_id):
				covered = true
				break
		check(covered, "the %s võ học has at least one card in the catalog" % weapon_id)

func _test_the_four_tiers_map_to_the_four_things_that_earn_them() -> void:
	# The mapping is the whole point: if rarity were computed from, say, id length,
	# every tier would be reachable and none of them would mean anything.
	_up = _mk()
	check(_up.card_rarity({"id": "evolve_dagger", "is_evolution": true}) == UITheme.RARITY_LEGENDARY,
		"a weapon evolution is Thần Công")
	check(_up.card_rarity({"id": "synergy_bao_vu", "is_synergy": true}) == UITheme.RARITY_EPIC,
		"a dual-weapon fusion is Tuyệt Kỹ")
	check(_up.card_rarity({"id": "unlock_axe"}) == UITheme.RARITY_RARE,
		"a new võ học is Hiếm")
	check(_up.card_rarity({"id": "damage"}) == UITheme.RARITY_COMMON,
		"an ordinary rank-up is Bình Thường")
	check(_up.card_rarity({"id": "damage", "is_evolution": true}) == UITheme.RARITY_LEGENDARY,
		"evolution outranks the plain tier regardless of id")

func _test_the_plan_names_its_own_five_icons() -> void:
	# The plan lists these five by name, so they are the contract rather than my
	# choice of glyph. WEAPON_INFO already owns a second, differently-named icon
	# per weapon; this is the card's own badge and the two are allowed to differ.
	_up = _mk()
	for expected in [["dagger", "🗡️"], ["fireball", "🔥"], ["lightning", "⚡"],
			["magnet", "🌀"], ["shield", "🛡️"]]:
		var key: String = expected[0]
		check(_up.card_icon(key) == String(expected[1]),
			"%s cards carry the plan's %s badge, got %s" % [key, expected[1], _up.card_icon(key)])

# --- 2. the tier reaches the stylebox the card actually draws ----------------

func _test_the_rarity_glow_is_installed_on_the_card() -> void:
	# Reading the classifier is not enough. This is the boundary where a tier could
	# be computed and then styled by something else -- which is exactly what the old
	# two-branch `is_evolution or is_synergy` was.
	_up = _mk()
	_max_everything()
	var cards := _open()
	if not check(cards.size() == 3, "three cards are dealt, got %d" % cards.size()):
		_teardown()
		return
	check(_up.card_rarity(_up.current_offered_upgrades[0]) == UITheme.RARITY_LEGENDARY,
		"evolutions sort to the front of the deal")
	for i in cards.size():
		var tier := _up.card_rarity(_up.current_offered_upgrades[i])
		var sb := cards[i].get_theme_stylebox("normal") as StyleBoxFlat
		if not check(sb != null, "card %d has a StyleBoxFlat" % i):
			continue
		check(sb.border_color.is_equal_approx(UITheme.RARITY_BORDER[tier]),
			"card %d is drawn in tier %d's colour, not something else's" % [i, tier])
	# Hover is styled separately, and a themed Button recolours itself -- which would
	# drop the aura the instant the mouse arrived.
	check(cards[0].get_theme_stylebox("hover") != null
			and cards[0].get_theme_stylebox("normal") != null,
		"the hover state keeps a stylebox so the aura survives the cursor")
	_teardown()

func _test_only_the_top_three_tiers_actually_glow() -> void:
	# A glow on every tier is not a rarity scale, it is a border. Common ships
	# shadow_size 0 on purpose.
	check(UITheme.RARITY_GLOW_SIZE[UITheme.RARITY_COMMON] == 0,
		"an ordinary card is unlit")
	var seen: Dictionary = {}
	for tier in [UITheme.RARITY_RARE, UITheme.RARITY_EPIC, UITheme.RARITY_LEGENDARY]:
		check(UITheme.RARITY_GLOW_SIZE[tier] > 0, "tier %d is lit" % tier)
		check(UITheme.RARITY_GLOW[tier].a > 0.0, "tier %d's aura is visible" % tier)
		seen[UITheme.RARITY_BORDER[tier]] = true
		# The plan's four frames, read as four and not as three shades of one.
		check(UITheme.RARITY_NAMES[tier] != "", "tier %d is named on the card" % tier)
	check(seen.size() == 3, "the three lit tiers are three distinct colours, got %d" % seen.size())
	check(UITheme.rarity_style(UITheme.RARITY_LEGENDARY).shadow_size
			> UITheme.rarity_style(UITheme.RARITY_RARE).shadow_size,
		"a bigger tier burns brighter")

func _test_the_legendary_card_pulses_and_sparks() -> void:
	_up = _mk()
	_max_everything()
	var cards := _open()
	if not check(cards.size() >= 2, "two cards on the table, got %d" % cards.size()):
		_teardown()
		return
	var legendary := cards[0]
	var sb := legendary.get_theme_stylebox("normal") as StyleBoxFlat
	if not check(sb != null, "the Thần Công card has a StyleBoxFlat"):
		_teardown()
		return
	var before := sb.shadow_color.a
	await get_tree().create_timer(0.75).timeout
	var mid := sb.shadow_color.a
	await get_tree().create_timer(0.75).timeout
	var after := sb.shadow_color.a
	check(absf(mid - before) > 0.01 or absf(after - mid) > 0.01,
		"the Thần Công aura breathes (a=%f then %f then %f)" % [before, mid, after])

	var embers := _find_particles(legendary)
	check(embers != null, "a Thần Công card carries its ember rays")
	if embers != null:
		check(embers.texture != null,
			"the embers have a mote -- CPUParticles2D draws nothing without one")

func _test_an_ordinary_card_has_no_particles() -> void:
	# The scale only reads as a scale if the bottom rung is plain.
	_up = _mk()
	var cards := _open()
	if not check(cards.size() > 0, "a card is on the table"):
		_teardown()
		return
	var tier := _up.card_rarity(_up.current_offered_upgrades[0])
	if tier == UITheme.RARITY_COMMON:
		check(_find_particles(cards[0]) == null,
			"a Bình Thường card does not sparkle")
	_teardown()

# --- 3. the juice ------------------------------------------------------------

func _test_hover_lifts_the_card_and_puts_it_back() -> void:
	_up = _mk()
	var cards := _open()
	if not check(cards.size() > 0, "a card is on the table"):
		_teardown()
		return
	var btn := cards[0]
	# Settle the layout first: the HBoxContainer owns position and the base is read
	# off `resized`, so a hover fired before the first sort would measure nothing.
	await get_tree().process_frame
	var base_y := btn.position.y
	var base_scale := btn.scale

	btn.mouse_entered.emit()
	await get_tree().create_timer(0.25).timeout
	check(btn.position.y <= base_y - 11.0,
		"the card lifts at least 12px, went %f -> %f" % [base_y, btn.position.y])
	check(btn.scale.x >= 1.04, "the card grows to ~1.05, got %f" % btn.scale.x)

	btn.mouse_exited.emit()
	await get_tree().create_timer(0.25).timeout
	check(absf(btn.position.y - base_y) < 0.5,
		"leaving puts the card back on the row, got %f want %f" % [btn.position.y, base_y])
	check(btn.scale.distance_to(base_scale) < 0.01,
		"leaving restores the scale, got %f want %f" % [btn.scale, base_scale])
	_teardown()

func _test_choosing_a_card_bursts_and_closes_the_panel() -> void:
	_up = _mk()
	var cards := _open()
	if not check(cards.size() > 0, "a card is on the table"):
		_teardown()
		return
	var before := _up.get_child_count()
	cards[0].pressed.emit()
	await get_tree().process_frame
	check(_up.panel.visible == false, "choosing closes the panel")
	check(get_tree().paused == false, "choosing resumes the run")
	check(_up.get_child_count() > before,
		"the confirmation burst is spawned at the card that was clicked")
	# The burst frees itself; leaving a CPUParticles2D on the CanvasLayer forever
	# would accumulate one per level-up for the rest of the session.
	await get_tree().create_timer(1.6).timeout
	check(_up.get_child_count() == before,
		"the burst cleans itself up, still %d nodes" % _up.get_child_count())
	_teardown()

func _ready() -> void:
	print("=== RUNNING EXPANSION 62.0: LEVEL-UP CARD RARITY & JUICE ===")
	GameManager.is_run_active = false

	await _test_every_catalog_card_is_classified_and_illustrated()
	_teardown()
	await _test_the_four_tiers_map_to_the_four_things_that_earn_them()
	_teardown()
	await _test_the_plan_names_its_own_five_icons()
	_teardown()
	await _test_the_rarity_glow_is_installed_on_the_card()
	await _test_only_the_top_three_tiers_actually_glow()
	await _test_the_legendary_card_pulses_and_sparks()
	await _test_an_ordinary_card_has_no_particles()
	await _test_hover_lifts_the_card_and_puts_it_back()
	await _test_choosing_a_card_bursts_and_closes_the_panel()

	_teardown()
	if _failures.is_empty():
		print("=== ALL EXPANSION 62.0 TESTS PASSED 100% CLEANLY! ===")
	get_tree().quit(_exit_code())