extends Node

## Automated Test Suite for Expansion 38.0:
## "TÀNG KINH CÁC" -- the wave shop's gold header showed a number the shop would not
## spend.
##
## There are two shops, and they were written to two different rules.
##
## The hermit shop displays, checks and spends the same currency, three times over:
##
##     hermit_shop_ui.gd:72   gold_label.text = "Túi Tiền: %d" % GameManager.total_gold
##     hermit_shop_ui.gd:130  var can_afford = GameManager.total_gold >= cost
##     hermit_shop_ui.gd:150  GameManager.total_gold -= cost
##
## The wave shop checks and spends run gold:
##
##     wave_shop_ui.gd:89   func get_gold() -> int: return GameManager.run_gold
##     wave_shop_ui.gd:93   GameManager.run_gold -= amount
##
## ...and its header displayed the sum of the two:
##
##     wave_shop_ui.gd:399  _gold_label.text = "VÀNG: %d" % (run_gold + total_gold)
##
## Which is a value that is neither currency. It is not total_gold (the shop would
## never spend it) and it is not run_gold (the only thing it does spend), so the
## number on screen is not a number the player has, in the shop's terms, at all.
##
## The consequence is not a cosmetic mismatch. Every card's buy button is gated on
##
##     var can_afford: bool = get_gold() >= price      # :630
##     buy_btn.disabled = not can_afford
##
## ...so a player carrying 100 run gold and 2831 banked sees
##
##     VÀNG: 2931
##
## above a shop where the 300-gold card is greyed out, the 800-gold card is greyed
## out, and pressing one anyway plays ui_deny. The header is the number the player
## reasons with when deciding what to buy; the game is counting a different one.
##
## The fix is one expression: the header reports the purse the shop spends from. It
## is emphatically NOT the other direction -- making the wave shop spend total_gold
## would let a player burn a run's persistent earnings on run-scoped upgrades and
## leave run_gold meaningless. Case 3 exists to hold that door shut.

const SHOP_SCENE: PackedScene = preload("res://scenes/wave_shop_ui.tscn")
const HERMIT_SHOP_SCENE: PackedScene = preload("res://scenes/hermit_shop_ui.tscn")

## Deliberately far apart, so "the header shows a different number from the purse" is
## unmistakable and no tolerance is needed anywhere.
const RUN_GOLD: int = 100
const TOTAL_GOLD: int = 2831
## Priced inside the gap: the header says the player can afford it, the shop says
## they cannot.
const MID_PRICE: int = 300

var _failures: Array[String] = []
var _shop: Node = null
var _run_gold_backup: int = 0
var _total_gold_backup: int = 0

func check(cond: bool, msg: String) -> bool:
	if not cond:
		_failures.append(msg)
		push_error("CHECK FAILED: %s" % msg)
	return cond

func _ready() -> void:
	print("=== RUNNING EXPANSION 38.0 TEST SUITE ===")
	GameManager.is_run_active = false
	# Read and write only -- nothing here calls add_gold() or buy_*(), so this suite
	# never persists and the developer's save is not involved. The values are still
	# put back at teardown, because a suite that leaves global state moved is how the
	# next suite in the gate inherits something it did not set up.
	_run_gold_backup = GameManager.run_gold
	_total_gold_backup = GameManager.total_gold

	_shop = SHOP_SCENE.instantiate()
	add_child(_shop)
	await get_tree().process_frame
	# roll_items() is what deals the four slots, and the shop does not call it until
	# it is opened for a wave the suite never starts. The suite writes its own cards,
	# so the slots are laid out here in the same shape roll_items() uses at :104 --
	# otherwise the purchase cases would be indexing into an empty array.
	_shop.cards.clear()
	for _slot in range(4):
		_shop.cards.append({"data": {}, "locked": false})
	GameManager.run_gold = RUN_GOLD
	GameManager.total_gold = TOTAL_GOLD

	_test_the_header_is_the_purse_the_shop_spends_from()
	_test_the_gap_the_player_can_see()
	await _test_the_wrong_fix_does_not_get_in()

	_finish()

# --- 1. the invariant -----------------------------------------------------------

## One assertion, and it subsumes the whole bug: if the number on the header is the
## number in get_gold(), then no price can be affordable on screen and unaffordable in
## the shop, because the shop is comparing against the thing the player is reading.
func _test_the_header_is_the_purse_the_shop_spends_from() -> void:
	_shop._refresh_gold()
	var shown := _shown_gold()
	if not check(shown >= 0, "The shop header carries a number: \"%s\"" % _label_text()):
		return
	check(shown == _shop.get_gold(),
		"The header shows the purse the shop spends from: %d where get_gold() is %d" % [shown, _shop.get_gold()])

# --- 2. the contradiction, stated as arithmetic ---------------------------------

## Not a UI snapshot. This is the sentence the player would have to say out loud:
## "it says I have 2931 and it won't sell me anything under 2931."
func _test_the_gap_the_player_can_see() -> void:
	_shop._refresh_gold()
	var shown := _shown_gold()
	# Stated as agreement between the header and the shop's verdict, not as the
	# existence of the gap. Asserting "the header is above the purse" would be a
	# precondition that only holds while the bug is present -- the suite would then
	# pass on broken code and fail on the fix, which is backwards. This form holds on
	# correct code and fails on the defect: a header that claims the card is
	# affordable while the shop refuses it.
	_shop.cards[0]["data"] = {"kind": "scroll", "id": "probe", "price": MID_PRICE,
		"apply": "max_hp", "value": 5.0}
	var bought: bool = _shop.purchase_card(0)
	check(bought == (shown >= MID_PRICE),
		"The shop's verdict matches its own header for a %d-gold card: header shows %d, purchase %s"
			% [MID_PRICE, shown, "allowed" if bought else "refused"])
	check(GameManager.run_gold == RUN_GOLD,
		"The refused purchase left the purse alone: %d" % GameManager.run_gold)

# --- 3. the wrong fix, and the model of what right looks like -------------------

## "Make the shop spend total_gold, then the header is correct" is the other way to
## make case 1 pass, and it is a serious balance change: total_gold is the purse that
## survives a run, so a player could bank gold, die, and spend the bank on run-scoped
## upgrades, making run_gold -- the currency every wave payout and every in-run
## purchase is denominated in -- decorative. So the wave shop's spend is pinned, and
## the hermit shop is pinned beside it as the worked example of what consistent looks
## like: it displays one currency, checks it, and spends it.
func _test_the_wrong_fix_does_not_get_in() -> void:
	GameManager.run_gold = RUN_GOLD
	GameManager.total_gold = TOTAL_GOLD
	_shop.cards[0]["data"] = {"kind": "scroll", "id": "probe", "price": 50,
		"apply": "max_hp", "value": 5.0}
	var bought: bool = _shop.purchase_card(0)
	check(bought, "A 50-gold card within the purse buys")
	check(GameManager.run_gold == RUN_GOLD - 50,
		"The wave shop spends run_gold: %d where %d is expected" % [GameManager.run_gold, RUN_GOLD - 50])
	check(GameManager.total_gold == TOTAL_GOLD,
		"The wave shop did not touch the persistent purse: %d" % GameManager.total_gold)

	var hermit := HERMIT_SHOP_SCENE.instantiate()
	add_child(hermit)
	await get_tree().process_frame
	if check(hermit != null, "The hermit shop instantiated"):
		# It has no get_gold() -- it reads total_gold inline at :130 and :150 -- so the
		# comparison is made against the label it actually renders, through the same
		# _refresh_ui() that open_ui() calls.
		hermit._refresh_ui()
		var shown: int = _number_in(String(hermit.gold_label.text))
		check(shown == GameManager.total_gold,
			"The hermit shop spends what its label shows: label %d, purse %d"
				% [shown, GameManager.total_gold])
		remove_child(hermit)
		hermit.queue_free()

# --- helpers -------------------------------------------------------------------

func _label_text() -> String:
	return String(_shop.get("_gold_label").text)

## The number out of "VÀNG: 2931". Parsed rather than reformatted, so the test reads
## the player-facing string instead of restating it.
func _shown_gold() -> int:
	return _number_in(_label_text())

## The first run of digits in a label. A digit scan rather than a split on the last
## space, because the two shops write different suffixes: the wave header is
## "VÀNG: 2931" and the hermit's is "Túi Tiền: 2831 <coin>", so splitting on the last
## space yields the emoji and int() reads that as 0. That is a bug this suite made
## and fixed before it found a real one.
func _number_in(text: String) -> int:
	var digits := ""
	for i in text.length():
		var c := text[i]
		if c >= "0" and c <= "9":
			digits += c
		elif not digits.is_empty():
			break
	return int(digits) if not digits.is_empty() else -1

func _finish() -> void:
	GameManager.run_gold = _run_gold_backup
	GameManager.total_gold = _total_gold_backup
	if is_instance_valid(_shop):
		remove_child(_shop)
		_shop.queue_free()

	if _failures.is_empty():
		print("=== ALL EXPANSION 38.0 TESTS PASSED 100% CLEANLY! ===")
		get_tree().quit(0)
	else:
		print("=== %d CHECK(S) FAILED ===" % _failures.size())
		for f in _failures:
			print("  FAIL: %s" % f)
		get_tree().quit(1)
