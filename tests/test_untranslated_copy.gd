extends "res://tests/suite_base.gd"

## Expansion 55.0: twenty-one of the game's twenty-seven card descriptions were in
## English while the UI around them was in Vietnamese.
##
## The panel that holds them makes it unmissable rather than subtle.
## `render_shop_items()` (hud.gd:1205) builds ONE scroll list with three sections,
## and until this suite the first was English and the other two Vietnamese:
##
##   section 1  meta upgrades    "⚔️ Might" / "+10% Weapon Damage" / "MAXED" / "Buy"
##   section 2  meridians        "Đả Thông" / "Tầng %d/%d" / "ĐẠI THÀNH"
##   section 3  companions       "✓ XUẤT TRẬN" / "Đổi Linh Thú"
##
## Twelve relics, companions and meridians were the same: Vietnamese `title`,
## icon, English `desc`. A player reads "+2 Armor & Reflect 40% of damage taken"
## while every other word on the card is Vietnamese.
##
## So what this suite guards is not "the game is in Vietnamese" -- it is not, and
## the run bounties below are the honest counterexample -- it is that a card row
## is not allowed to be half-translated while its neighbours are not. The
## discriminator is structural rather than a list of strings: a dict literal that
## carries an `"icon"` key is a card the player reads, and every card `desc` must
## contain a Vietnamese letter. That is the exact shape relics, companions,
## meridians and Shenron wishes all have, and it is why the four run bounties are
## exempt without being named: they carry `title` but no `icon`, because they are
## announced as a line of HUD text rather than drawn as a card.
##
## The exemption test is what keeps that from becoming a loophole. "No icon" is a
## reason, not permission -- dropping an `"icon"` off a relic to slip past this
## suite fails there instead. Nothing else in the codebase keys off `icon`, so it
## is free to use as the marker precisely because nothing depends on it.

## Sources of player-facing card copy. `hud.gd` is here because its meta-upgrade
## table is the one card list that lives in a UI file rather than in GameManager
## -- and it is the section that was entirely English.
const CARD_SOURCES: Array[String] = [
	"res://scripts/game_manager.gd",
	"res://scripts/hud.gd",
]

## The rows the structural rule does not reach, and why there are six of them
## rather than four. Two are the world-map biome descriptions (game_manager.gd:119
## and :127), which are keyed by `texture_path` rather than `icon` and are already
## Vietnamese. Four are `init_run_bounties()`, which announce themselves as a line
## of HUD text and are still English as of this commit -- translating those is a
## product call, not a defect with one right answer. Pinned as a count so that an
## icon dropped off a real card to dodge the rule below fails here instead.
const NON_CARD_DESCS: int = 6

## No escape handling on purpose: `[^"]*` is enough because no card desc in
## either file contains a backslash or an embedded quote (checked, not assumed --
## the first version of this pattern spelled the class `[^"\\]`, which GDScript
## unescapes to a single backslash and PCRE then reads as an unterminated
## `[` class, so the whole suite silently matched nothing).
const DESC_RE := '"desc"[ \t]*:[ \t]*"([^"]*)"'

## Vietnamese writes its diacritics as precomposed codepoints, so the test is
## "is this a lowercase letter", not "is this a combining mark" -- unicode_at/
## combining() returns 0 for every character in "Vàng", which is how the first
## version of this helper reported six translated rows as untranslated. Lowercase
## is the reliable signal because it is the one class that `to_upper()` moves
## without `to_lower()` moving back: "HP" and "AoE" are not letters, digits are
## not either, and every accented vowel in "Vàng" or "đ" is.
static func _is_vietnamese(s: String) -> bool:
	for i in s.length():
		var c := s[i]
		if c == c.to_lower() and c != c.to_upper() and c.unicode_at(0) > 127:
			return true
	return false

## True when the dict literal the `desc` on line `idx` sits in carries an `"icon"`
## key. Walks back to the line that opens the block -- the nearest line ending in
## `{` at a lower indent -- and scans forward to its matching close.
static func _block_has_icon(lines: PackedStringArray, idx: int) -> bool:
	var indent := _indent_of(lines[idx])
	var start := -1
	var j := idx - 1
	while j >= 0:
		var l: String = lines[j]
		if l.strip_edges() != "" and l.rstrip("\t ").ends_with("{"):
			if _indent_of(l) < indent:
				start = j
				break
		j -= 1
	if start < 0:
		return false
	var k := start
	while k < lines.size():
		if lines[k].contains('"icon"'):
			return true
		if lines[k].strip_edges().begins_with("}") and _indent_of(lines[k]) <= _indent_of(lines[start]):
			return false
		k += 1
	return false

static func _indent_of(l: String) -> int:
	return l.length() - l.lstrip("\t").length()

## The desc literals on every line of `lines`, as [{line_index, text}].
static func _descs(lines: PackedStringArray) -> Array[Dictionary]:
	var re := RegEx.new()
	re.compile(DESC_RE)
	var out: Array[Dictionary] = []
	for i in lines.size():
		var m := re.search(lines[i])
		if m != null:
			out.append({"i": i, "text": m.get_string(1)})
	return out

static func _read(path: String) -> PackedStringArray:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return PackedStringArray()
	return f.get_as_text().split("\n")

func _test_card_descs_are_vietnamese() -> void:
	var found := 0
	for path in CARD_SOURCES:
		var lines := _read(path)
		if not check(lines.size() > 0, "could not read %s" % path):
			continue
		for d in _descs(lines):
			found += 1
			if _block_has_icon(lines, d["i"]):
				check(_is_vietnamese(d["text"]),
					"%s:%d card desc is not Vietnamese: \"%s\"" % [path, d["i"] + 1, d["text"]])
	# A number near zero means the regex stopped matching -- a green run that
	# checks nothing, which is the failure mode this repo keeps having.
	check(found >= 30, "expected 30+ desc literals across the card sources, found %d" % found)

func _test_exemption_stays_exactly_six_rows() -> void:
	# "No icon" exempts a desc, and that is a reason rather than permission: an
	# icon dropped off a relic to dodge the rule above has to fail here.
	var iconless := 0
	var lines := _read("res://scripts/game_manager.gd")
	if not check(lines.size() > 0, "could not read res://scripts/game_manager.gd"):
		return
	for d in _descs(lines):
		if not _block_has_icon(lines, d["i"]):
			iconless += 1
	check(iconless == NON_CARD_DESCS,
		"expected %d icon-less descs (2 world-map biomes + 4 run bounties), found %d -- "
		% [NON_CARD_DESCS, iconless] + "a new icon-less card table has appeared and needs a verdict")

func _test_meta_shop_section_is_translated() -> void:
	# The panel-level strings, which no dict-literal rule can reach: the rank
	# label, the gold label and the two button states. Meridian and companion rows
	# below them were already Vietnamese, so these were the only English words
	# left in a list the player scrolls through as one screen.
	var src := "\n".join(_read("res://scripts/hud.gd"))
	if not check(src != "", "could not read res://scripts/hud.gd"):
		return
	for s in ['"MAXED"', '"Buy (%d 💰)"', '"Total Gold: %d"', '"Total Gold: %d 💰"',
			'"⚔️ Might"', '"💖 Vitality"', '"👢 Swiftness"',
			'"🧲 Magnetism"', '"🔥 Pyro Power"', '"🛡️ Armor Plating"']:
		check(not src.contains(s), "hud.gd still ships untranslated meta-shop copy: %s" % s)
	# The rank label is checked as a bare fragment, not as a quoted literal. The
	# source is "%s (Cấp %d/%d)\n%s", so '"(Rank %d/%d)"' -- with a closing quote --
	# matches nothing at all and the check would have passed on the English string
	# too. A negative string check is only evidence if it can fail.
	check(not src.contains("(Rank %d/%d)"), "hud.gd still ships (Rank %d/%d) in the meta shop")
	check(src.contains("(Cấp %d/%d)"), "hud.gd: meta rank label should read Cấp, not Rank")
	check(src.contains('"ĐẠI THÀNH"'), "hud.gd: meta max button should match the meridian one")

func _test_bounty_copy_is_still_the_known_exception() -> void:
	# Not a translation check -- a canary. If someone does translate the bounties
	# this fails, and then the sentence in this function's name and the exemption
	# above both get deleted rather than the row quietly passing through the
	# structural exemption with nothing to say about it.
	var src := "\n".join(_read("res://scripts/game_manager.gd"))
	if not check(src != "", "could not read res://scripts/game_manager.gd"):
		return
	check(src.contains('"Slay 25 Bats"'),
		"the run bounties appear to have been translated -- update NON_CARD_DESCS' "
		+ "comment, delete this canary, and this test")

func _ready() -> void:
	print("=== RUNNING EXPANSION 55.0: UNTRANSLATED CARD COPY TEST SUITE ===")
	GameManager.is_run_active = false

	_test_card_descs_are_vietnamese()
	_test_exemption_stays_exactly_six_rows()
	_test_meta_shop_section_is_translated()
	_test_bounty_copy_is_still_the_known_exception()

	if _failures.is_empty():
		print("=== ALL EXPANSION 55.0 TESTS PASSED 100% CLEANLY! ===")
	get_tree().quit(_exit_code())