class_name WaveDirector
extends Node

## Võ Đài Sóng 1 — autonomous round controller for the contained martial arena.
##
## Drives 20 discrete hiệp (waves) of 20s-60s each. On timer zero the floor is
## cleared, surviving non-boss enemies are purged (their gold/XP vacuumed to the
## player) and the Tàng Kinh Các intermission shop opens. Clearing wave 20 wins
## the run.
##
## Deliberately NOT process_mode = ALWAYS: the shop pauses the tree, and the
## countdown must not tick down behind the pause screen.

signal wave_started(wave_num: int, duration: float)
signal wave_timer_updated(time_left: float, duration: float)
signal wave_completed(wave_num: int)
signal shop_opened
signal wave_paid_out(wave_num: int, clear_gold: int, interest: int)

const WAVE_SHOP_SCENE: PackedScene = preload("res://scenes/wave_shop_ui.tscn")

## Wave 1 lasts 20s; every later wave adds 2.5s, capped at 60s (reached by wave 17).
const BASE_WAVE_DURATION: float = 20.0
const WAVE_DURATION_STEP: float = 2.5
const MAX_WAVE_DURATION: float = 60.0

## Milestone 2: savings interest (Tích Lũy). Clearing a hiệp pays a flat bounty
## that scales with the round, and the gold still sitting in the purse at the
## bell pays interest of its own -- so hoarding through the early waves is a real
## strategy rather than a rounding error.
const CLEAR_BASE_GOLD: int = 15
const CLEAR_GOLD_PER_WAVE: int = 3
const INTEREST_GOLD_DIVISOR: int = 10
const INTEREST_CAP: int = 10

var current_wave: int = 1
var max_waves: int = 20
var wave_duration: float = BASE_WAVE_DURATION
var wave_time_left: float = BASE_WAVE_DURATION
var is_wave_active: bool = false

## Read by WaveShopUI so the intermission can show the player exactly what the
## bell paid out. Reset by the next end_wave(), not by start_wave().
var last_clear_gold: int = 0
var last_interest_earned: int = 0

## Performance governor. The single-threaded WASM web build cannot hold 60 FPS at
## the legacy 180-enemy ceiling, so the director clamps concurrent spawns to 80.
var max_enemies_alive: int = 80

var spawner: Node = null
var shop: CanvasLayer = null

func _ready() -> void:
	add_to_group("wave_director")
	if GameManager and not GameManager.run_started.is_connected(_on_run_started):
		GameManager.run_started.connect(_on_run_started)
	spawner = get_tree().get_first_node_in_group("enemy_spawner")
	# A test or a late-added scene can instantiate this after the run already began.
	if GameManager and GameManager.is_run_active:
		call_deferred("start_wave", current_wave)

func _on_run_started() -> void:
	current_wave = 1
	start_wave(current_wave)

func calculate_wave_duration(wave_num: int) -> float:
	return min(MAX_WAVE_DURATION, BASE_WAVE_DURATION + float(wave_num - 1) * WAVE_DURATION_STEP)

func start_wave(wave_num: int) -> void:
	current_wave = wave_num
	wave_duration = calculate_wave_duration(wave_num)
	wave_time_left = wave_duration
	is_wave_active = true
	var tree = get_tree()
	if tree and tree.paused:
		tree.paused = false

	if not spawner:
		spawner = get_tree().get_first_node_in_group("enemy_spawner")
	# Hand the performance cap to the spawner, which gates spawn_enemy_wave() on it.
	if spawner and "enemy_cap" in spawner:
		spawner.set("enemy_cap", max_enemies_alive)

	emit_signal("wave_started", wave_num, wave_duration)
	_announce("🏯 HIỆP %d / %d — VÕ ĐÀI MỞ!" % [wave_num, max_waves], wave_num == max_waves)
	SoundManager.play("buddha_gong", 0.05)

func _process(delta: float) -> void:
	if not is_wave_active:
		return
	wave_time_left -= delta
	emit_signal("wave_timer_updated", maxf(0.0, wave_time_left), wave_duration)
	if wave_time_left <= 0.0:
		end_wave()

func end_wave() -> void:
	if not is_wave_active:
		return
	is_wave_active = false
	wave_time_left = 0.0

	_purge_remaining_enemies()
	_award_wave_payout()
	SoundManager.play("fanfare", 0.05)
	emit_signal("wave_completed", current_wave)

	if current_wave >= max_waves:
		_announce("🏆 TOÀN THẮNG! VÕ ĐÀI CHIẾN THẮNG %d HIỆP!" % max_waves, true)
		GameManager.trigger_victory()
		return

	var tree = get_tree()
	if tree:
		tree.paused = true
	_open_shop()
	emit_signal("shop_opened")

func advance_to_next_wave() -> void:
	current_wave += 1
	var tree = get_tree()
	if tree:
		tree.paused = false
	start_wave(current_wave)

# --- internals ----------------------------------------------------------------

## Flat bounty for surviving a hiệp, independent of the purse.
func calculate_clear_gold(wave_num: int) -> int:
	return CLEAR_BASE_GOLD + wave_num * CLEAR_GOLD_PER_WAVE

## Interest on unspent gold: +1 per 10 banked, capped at 10 overall and at 2 per
## wave so the first few rounds cannot fund a full arsenal from thin air.
func calculate_interest(unspent_gold: int, wave_num: int) -> int:
	var raw := floori(float(maxi(unspent_gold, 0)) / float(INTEREST_GOLD_DIVISOR))
	return mini(raw, mini(INTEREST_CAP, wave_num * 2))

## Interest is read off the purse BEFORE the bounty lands, otherwise the player
## would bank interest on gold they just earned instead of on gold they chose
## not to spend -- which is the entire point of the mechanic.
func _award_wave_payout() -> void:
	last_interest_earned = calculate_interest(GameManager.run_gold, current_wave)
	last_clear_gold = calculate_clear_gold(current_wave)
	GameManager.add_gold(last_clear_gold + last_interest_earned)
	emit_signal("wave_paid_out", current_wave, last_clear_gold, last_interest_earned)

func _announce(message: String, is_boss: bool = false) -> void:
	if spawner and spawner.has_signal("wave_event_announced"):
		spawner.emit_signal("wave_event_announced", message, is_boss)

## Clear the floor between waves. Bosses survive the intermission; every other
## enemy dies through its own die() so gold, XP gems, kills and Dragon Soul all
## flow through the normal payout path, then every loose pickup is handed to the
## player so nothing is stranded across a paused tree.
func _purge_remaining_enemies() -> void:
	var tree = get_tree()
	if not tree:
		return
	var player = tree.get_first_node_in_group("player")
	for e in tree.get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or e.get("is_dead"):
			continue
		if e.get("is_boss"):
			continue
		if e.has_method("die"):
			e.die()
	_vacuum_pickups(player)

func _vacuum_pickups(player: Node2D) -> void:
	if not is_instance_valid(player):
		return
	for group in ["coins", "gems"]:
		for pickup in get_tree().get_nodes_in_group(group):
			if is_instance_valid(pickup) and pickup.has_method("target_player"):
				pickup.target_player(player)

func _open_shop() -> void:
	if is_instance_valid(shop):
		return
	shop = WAVE_SHOP_SCENE.instantiate() as CanvasLayer
	add_child(shop)
	if shop.has_method("open_for_wave"):
		shop.open_for_wave(current_wave)
