extends Node

## Expansion 51.0: two upgrades the player could buy in the same run, wearing the
## same name.
##
##   Lăng Ba Vi Bộ       level-up card    +15% move speed
##   Lăng Ba Vi Bộ       wave-shop scroll +25% speed, -4 armor
##
##   Hấp Tinh Đại Pháp   level-up card    +30% pickup radius
##   Hấp Tinh Đại Pháp   wave-shop scroll +8% lifesteal, -15% max HP
##
## Not just the same word: different magnitudes and, worse, a *downside on one
## and not the other*. A player who took the card and then saw the scroll had
## no way to tell they were buying a different thing -- and the scroll's real
## cost (-4 armor) is invisible in its title. Both scrolls have been renamed.
##
## This suite makes the whole class unreintroducible, and the normalisation is
## the point of it. The raw strings were never equal: the scroll titles carry a
## leading emoji ("🥋 Lăng Ba Vi Bộ") and the card titles do not. A plain
## set-intersection over the two catalogs found zero collisions while two were
## sitting right there. Titles are compared with the decoration stripped.

var _failures: Array[String] = []

func check(cond: bool, msg: String) -> bool:
	if not cond:
		_failures.append(msg)
		push_error("CHECK FAILED: %s" % msg)
	return cond

## A letter is the one character class that changes case under to_upper(). Emoji,
## digits and punctuation all return themselves, and Vietnamese diacritics are
## ordinary letters, so the first character that differs is the first real one.
func _normalize(title: String) -> String:
	var t := title.strip_edges()
	for i in t.length():
		var c := t[i]
		if c.to_upper() != c.to_lower():
			return t.substr(i).strip_edges()
	return t

## Titles the player can be shown during a single run. Kept deliberately narrow:
## the daily trials in leaderboard_manager.gd reuse two of these names too, but
## they live on the leaderboard screen and are never offered beside a level-up
## card, so demanding global uniqueness would fail for a reason no player can hit.
func _in_run_titles(mgr: UpgradeManager) -> Dictionary:
	var out: Dictionary = {}
	for card in mgr.get_upgrade_catalog():
		var t := _normalize(String(card.get("title", "")))
		if not t.is_empty():
			out[t] = "level-up card '%s'" % card.get("id", "?")
	return out

func _scroll_titles() -> Dictionary:
	var out: Dictionary = {}
	for s in WaveShopUI.SCROLL_POOL:
		var t := _normalize(String(s.get("title", "")))
		if not t.is_empty():
			out[t] = "wave-shop scroll '%s'" % s.get("id", "?")
	return out

func _ready() -> void:
	print("=== RUNNING EXPANSION 51.0: CATALOG TITLE UNIQUENESS TEST SUITE ===")
	GameManager.is_run_active = false

	var mgr := UpgradeManager.new()
	add_child(mgr)
	mgr.weapon_levels = {"dagger": 0, "shield": 0, "lightning": 0, "fireball": 0, "axe": 0, "slash": 0}
	mgr.evolved_weapons = {"dagger": false, "shield": false, "lightning": false, "fireball": false, "axe": false, "slash": false}
	mgr.synergies_evolved = {"bao_vu": false, "bang_phach": false}

	var cards := _in_run_titles(mgr)
	var scrolls := _scroll_titles()

	check(not cards.is_empty(), "The level-up catalog offered at least one card to compare")
	check(not scrolls.is_empty(), "The wave shop offered at least one scroll to compare")

	# Both halves of the normalisation, asserted directly. Without these the
	# uniqueness check below could pass for the wrong reason -- a helper that
	# returned "" for everything would also find no collisions.
	var probe := _normalize("🥋 Lăng Ba Vi Bộ")
	check(probe == "Lăng Ba Vi Bộ", "A decorated scroll title normalises to its bare name, got '%s'" % probe)
	check(_normalize("Hấp Tinh Đại Pháp") == "Hấp Tinh Đại Pháp",
		"An undecorated card title survives normalisation unchanged")

	var clashes: Array[String] = []
	for t in cards.keys():
		if scrolls.has(t):
			clashes.append("'%s' is both %s and %s" % [t, cards[t], scrolls[t]])
	check(clashes.is_empty(),
		"No name is offered as both a level-up card and a wave-shop scroll: %s" % "; ".join(clashes))

	# Report what the scan actually saw, so a future failure is diagnosable
	# without re-running a probe.
	print("  compared %d card titles against %d scroll titles" % [cards.size(), scrolls.size()])
	print("OK No level-up card and wave-shop scroll share a name.")

	get_tree().paused = false
	var unique: Array[String] = []
	for f in _failures:
		if not unique.has(f):
			unique.append(f)
	if unique.is_empty():
		print("=== ALL CATALOG TITLE TESTS PASSED 100% CLEANLY! ===")
		get_tree().quit(0)
	else:
		print("=== %d CHECK(S) FAILED (first %d unique) ===" % [_failures.size(), unique.size()])
		for f in unique:
			print("  FAIL: %s" % f)
		get_tree().quit(1)