class_name EnemySpawner
extends Node2D

## Spawns dynamic waves of Bats, Skeletons, Necromancers, swarms, and Boss encounters.

signal wave_event_announced(message: String, is_boss: bool)

@export var bat_scene: PackedScene
@export var skeleton_scene: PackedScene
@export var necromancer_scene: PackedScene
@export var boss_scene: PackedScene
@export var behemoth_scene: PackedScene
@export var powerup_scene: PackedScene
@export var goblin_scene: PackedScene = preload("res://scenes/goblin.tscn")

@export var demon_emperor_scene: PackedScene = preload("res://scenes/demon_emperor.tscn")

@export var spawn_interval: float = 0.70
@export var spawn_distance: float = 460.0

var timer: float = 0.0
var powerup_timer: float = 12.0
var boss_1_spawned: bool = false
var boss_2_spawned: bool = false
var swarm_1_triggered: bool = false
var swarm_2_triggered: bool = false
var goblin_1_spawned: bool = false
var goblin_2_spawned: bool = false
var blood_moon_triggered: bool = false
var hermit_spawned: bool = false
var swarm_3_triggered: bool = false
var goblin_3_spawned: bool = false
var swarm_4_triggered: bool = false
var blood_moon_2_triggered: bool = false
var boss_3_spawned: bool = false
var hermit_2_spawned: bool = false
var swarm_5_triggered: bool = false
var demon_emperor_spawned: bool = false
var elite_champion_1_spawned: bool = false
var elite_champion_2_spawned: bool = false
var player: Node2D = null

## Milestone 2 — set pieces are authored per hiệp, not per second. Keyed by
## WaveDirector.current_wave; each entry names the method that runs the encounter.
## Waves 2 and 3 share one handler.
const WAVE_EVENTS: Dictionary = {
	2: "_wave_opening_swarm",
	3: "_wave_opening_swarm",
	4: "spawn_treasure_goblin",
	5: "spawn_elite_champion",
	8: "_wave_ambush_swarm",
	10: "spawn_boss_1",
	12: "_wave_blood_hermit",
	15: "_wave_dual_elites",
	18: "_wave_behemoth_duo",
	20: "spawn_demon_emperor"
}
## Seconds into a wave before its set piece lands, so the hiệp banner gets read
## before a boss is standing on top of the player.
const WAVE_EVENT_DELAY: float = 2.5
## Seconds-equivalent difficulty per hiệp. Wave 20 lands exactly on the legacy
## 480s ceiling, so one already-tuned difficulty curve serves both a Võ Đài run
## and a standalone survival test.
const WAVE_DIFFICULTY_SECONDS: float = 24.0

var wave_director: Node = null
var _last_seen_wave: int = 0
var _pending_wave: int = 0
var _pending_timer: float = 0.0


func _ready() -> void:
	add_to_group("enemy_spawner")
	player = get_tree().get_first_node_in_group("player")
	# Either node may enter the tree first, so this only primes the cache; the
	# real resolution happens lazily in get_director() on the first _process.
	wave_director = get_tree().get_first_node_in_group("wave_director")
	if GameManager:
		GameManager.connect("run_started", Callable(self, "_on_run_started"))
	call_deferred("spawn_intro_ambush")

func _on_run_started() -> void:
	# Both _ready and the run_started signal defer a ring, so the guard has to
	# come back up here or only the first run of a persistent node gets one.
	_intro_ring_spawned = false
	call_deferred("spawn_intro_ambush")

## Milestone 3b: one ring per run, never two. Guarded rather than left to luck
## because _ready and _on_run_started both ask for one.
var _intro_ring_spawned: bool = false

func spawn_intro_ambush() -> void:
	if _intro_ring_spawned or not is_instance_valid(player) or not bat_scene:
		return
	_intro_ring_spawned = true
	# Milestone 3b: 9 bats in a full 360 ring, 300px out, on frame one. Wave 1
	# used to dribble in one bat every 0.7s, so the first seconds of a run had
	# nothing in reach and the 3-hit combo had no time to be discovered. A closed
	# ring also lets you swing INTO the swarm instead of chasing it.
	for i in range(9):
		var angle = TAU * (float(i) / 9.0)
		var spawn_pos = player.global_position + Vector2(cos(angle), sin(angle)) * 300.0
		var bat = bat_scene.instantiate()
		if bat:
			_scale_for_wave(bat)
			bat.global_position = spawn_pos
			get_tree().current_scene.call_deferred("add_child", bat)

func _process(delta: float) -> void:
	if not GameManager.is_run_active or not is_instance_valid(player):
		return

	timer += delta
	powerup_timer += delta

	# Random periodic floor item drop (~22s)
	if powerup_timer >= 22.0:
		powerup_timer = 0.0
		spawn_floor_powerup()

	# One pacing curve, two clocks: a Võ Đài run is driven by the hiệp number,
	# a standalone run by the legacy survival clock.
	var difficulty := get_difficulty_seconds()
	if get_director() != null:
		_process_wave_events(delta)
	else:
		_process_legacy_timeline(difficulty)

	var current_interval = max(0.18, spawn_interval - (difficulty * 0.005))

	if timer >= current_interval:
		timer = 0.0
		spawn_enemy_wave()

## Cached lookup so the two nodes may enter the tree in either order. Returns
## null whenever no WaveDirector is present, which is the signal to stay on the
## legacy timeline.
func get_director() -> Node:
	if not is_instance_valid(wave_director) and is_inside_tree():
		wave_director = get_tree().get_first_node_in_group("wave_director")
	return wave_director

## The scalar every spawn curve reads. Wave 20 == 480s, the legacy ceiling, so
## enemy counts, HP inflation and champion odds hit their tuned top tier exactly
## on the final hiệp instead of wherever the run clock happened to be.
func get_difficulty_seconds() -> float:
	var dir := get_director()
	if dir != null:
		return float(clampi(int(dir.current_wave), 1, 20)) * WAVE_DIFFICULTY_SECONDS
	return GameManager.run_time

func _process_wave_events(delta: float) -> void:
	var wave := int(wave_director.current_wave)
	if wave != _last_seen_wave:
		_last_seen_wave = wave
		_pending_wave = wave if WAVE_EVENTS.has(wave) else 0
		_pending_timer = WAVE_EVENT_DELAY

	if _pending_wave <= 0:
		return
	_pending_timer -= delta
	if _pending_timer > 0.0:
		return
	var event := String(WAVE_EVENTS[_pending_wave])
	_pending_wave = 0
	if has_method(event):
		call(event)

## The pre-Milestone-2 survival ladder. Only reached when no WaveDirector is in
## the scene, so standalone tests that instantiate the spawner on their own keep
## working against the 480s clock.
func _process_legacy_timeline(r_time: float) -> void:
	
	# 30s: First Treasure Goblin Appears!
	if r_time >= 30.0 and not goblin_1_spawned:
		goblin_1_spawned = true
		spawn_treasure_goblin()
	
	# 45s: Swarm Warning 1
	if r_time >= 45.0 and not swarm_1_triggered:
		swarm_1_triggered = true
		trigger_swarm("⚠️ BAT SWARM DETECTED! ⚠️", bat_scene, 28)
		
	# 60s: Boss 1 (Dreadlord Malakor)
	if r_time >= 60.0 and not boss_1_spawned:
		boss_1_spawned = true
		spawn_boss_1()
		
	# 90s (1:30): First Tinh Anh Lệnh Elite Champion
	if r_time >= 90.0 and not elite_champion_1_spawned:
		elite_champion_1_spawned = true
		spawn_elite_champion()

	# 75s: Blood Moon Eclipse (30s duration - 2x XP & Gold)
	if r_time >= 75.0 and not blood_moon_triggered:
		blood_moon_triggered = true
		trigger_blood_moon_event()
		
	# 100s: Swarm Warning 2 (Armored Skeletons)
	if r_time >= 100.0 and not swarm_2_triggered:
		swarm_2_triggered = true
		trigger_swarm("💀 UNDEAD SIEGE INCOMING! 💀", skeleton_scene, 22)
		
	# 110s: Second Treasure Goblin Appears!
	if r_time >= 110.0 and not goblin_2_spawned:
		goblin_2_spawned = true
		spawn_treasure_goblin()
		
	# 120s (2:00): Boss 2 (Infernal Behemoth)
	if r_time >= 120.0 and not boss_2_spawned:
		boss_2_spawned = true
		spawn_boss_2()
		
	# 150s (2:30): Wandering Hermit "Lão Ngoan Đồng" Lucky Encounter!
	if r_time >= 150.0 and not hermit_spawned:
		hermit_spawned = true
		spawn_hermit()

	# 180s (3:00): Second Tinh Anh Lệnh Elite Champion
	if r_time >= 180.0 and not elite_champion_2_spawned:
		elite_champion_2_spawned = true
		spawn_elite_champion()

	# 180s (3:00): Swarm 3 (Thi Ma Trận - Skeletal Legion)
	if r_time >= 180.0 and not swarm_3_triggered:
		swarm_3_triggered = true
		trigger_swarm("💀 VẠN QUỶ XUẤT ĐỘNG: THI MA TRẬN! 💀", skeleton_scene, 28)
		
	# 210s (3:30): Third Treasure Goblin
	if r_time >= 210.0 and not goblin_3_spawned:
		goblin_3_spawned = true
		spawn_treasure_goblin()
		
	# 240s (4:00): Swarm 4 (Vu Độc Ma Trận - Necromancers)
	if r_time >= 240.0 and not swarm_4_triggered:
		swarm_4_triggered = true
		trigger_swarm("🔮 VU ĐỘC MA TRẬN BAO VÂY! CẨN THẬN MA PHÁP! 🔮", necromancer_scene, 18)
		
	# 270s (4:30): Blood Moon Eclipse 2 (30s duration - 2x XP & Gold)
	if r_time >= 270.0 and not blood_moon_2_triggered:
		blood_moon_2_triggered = true
		trigger_blood_moon_event()
		
	# 300s (5:00): Boss 3 (Song Thủ Ma Tướng)
	if r_time >= 300.0 and not boss_3_spawned:
		boss_3_spawned = true
		spawn_boss_3()
		
	# 360s (6:00): Second Hermit "Lão Ngoan Đồng" Lucky Encounter
	if r_time >= 360.0 and not hermit_2_spawned:
		hermit_2_spawned = true
		spawn_hermit()
		
	# 390s (6:30): Apocalypse Swarm (Vạn Ma Vây Hãm)
	if r_time >= 390.0 and not swarm_5_triggered:
		swarm_5_triggered = true
		trigger_swarm("⚡ ĐẠI KIẾP NẠN: VẠN MA VÂY HÃM! ĐỈNH CAO SINH TỒN! ⚡", skeleton_scene, 32)
		
	# 435s (7:15): Final Boss (Hắc Huyết Ma Hoàng)
	if r_time >= 435.0 and not demon_emperor_spawned:
		demon_emperor_spawned = true
		spawn_demon_emperor()

# --- Milestone 2: per-hiệp encounters ------------------------------------------

## Hiệp 2-3 are the warm-up: cheap fodder so the player banks opening gold to
## spend in the Tàng Kinh Các. The base cadence already leans bats this early
## (see get_difficulty_seconds), so this only adds a visible burst.
func _wave_opening_swarm() -> void:
	trigger_swarm("🦇 BẦY CUA MỘ ĐANG BAY VỀ! 🦇", bat_scene, 10)

## Hiệp 8: the pinned-down ambush -- skeletons from every angle at once.
func _wave_ambush_swarm() -> void:
	trigger_swarm("⚠️ PHỤC KÍCH! BỐN MẶT THI MA TRẬN! ⚠️", skeleton_scene, 24)

## Hiệp 12: the Blood Moon pays double while a wandering hermit turns up to sell
## a reprieve. Greed and safety in the same round.
func _wave_blood_hermit() -> void:
	trigger_blood_moon_event()
	spawn_hermit()

## Hiệp 15: two Elite Champions, each carrying a different rider. The frozen one
## is easy to burst down but slow to start; the venom one keeps its distance
## while the poison ticks.
func _wave_dual_elites() -> void:
	var frost := spawn_elite_champion()
	var venom := spawn_elite_champion()
	if is_instance_valid(frost) and "freeze_timer" in frost:
		frost.freeze_timer = 6.0
	if is_instance_valid(venom) and venom.has_method("apply_poison"):
		venom.apply_poison(999.0, 16.0)
	emit_signal("wave_event_announced", "⚜️ HAI VỊ TINH ANH LỆNH: BĂNG SƯ & ĐỘC SƯ! ⚜️", true)
	SoundManager.play("boss_alarm", 0.12)

## Hiệp 18: the Behemoth anchors the floor while a necromancer screen keeps the
## player from closing on it.
func _wave_behemoth_duo() -> void:
	spawn_boss_2()
	trigger_swarm("🔮 VU ĐỘC MA TRẬN BAO VÂY! CẨN THẬN MA PHÁP! 🔮", necromancer_scene, 12)

const MAX_ACTIVE_ENEMIES: int = 180

## WaveDirector lowers this to 80 during a Võ Đài run so the single-threaded WASM
## web build holds 60 FPS. Unset spawners keep the legacy 180 ceiling.
var enemy_cap: int = MAX_ACTIVE_ENEMIES

func spawn_enemy_wave() -> void:
	if not is_instance_valid(player):
		return

	# Performance Governor: Cap active concurrent enemies to prevent WebGL/HTML5 frame drops
	var active_enemies = get_tree().get_nodes_in_group("enemies").size()
	if active_enemies >= enemy_cap:
		return

	var r_time = get_difficulty_seconds()
	var count = 3 + int(r_time / 14.0)
	for i in range(count):
		var angle = randf() * TAU
		var spawn_pos = player.global_position + Vector2(cos(angle), sin(angle)) * spawn_distance

		# Dynamic enemy composition by time (0 to 480s):
		var chosen_scene: PackedScene = bat_scene
		
		if r_time > 180.0:
			var roll = randf()
			if roll < 0.35 and necromancer_scene:
				chosen_scene = necromancer_scene
			elif roll < 0.75 and skeleton_scene:
				chosen_scene = skeleton_scene
			else:
				chosen_scene = bat_scene
		elif r_time > 35.0 and necromancer_scene and randf() < 0.22:
			chosen_scene = necromancer_scene
		elif r_time > 25.0 and skeleton_scene and randf() < 0.45:
			chosen_scene = skeleton_scene
				
		if not chosen_scene:
			chosen_scene = bat_scene
			
		if chosen_scene:
			var enemy = chosen_scene.instantiate()
			if enemy:
				_scale_for_wave(enemy)
				enemy.global_position = spawn_pos

				# Champion chance: scales up to 26% late game, plus one step per
				# elite affix the danger tier grants.
				var champ_chance = 0.26 if r_time > 360.0 else (0.20 if r_time > 180.0 else (0.18 if r_time > 60.0 else (0.12 if r_time > 20.0 else 0.0)))
				champ_chance += 0.03 * float(GameManager.get_danger_data()["elite"])
				if randf() < champ_chance and enemy.has_method("make_champion"):
					enemy.make_champion()

				get_tree().current_scene.add_child(enemy)

## Milestone 3a: the danger tier scales HP and speed together. Applied to the
## instance BEFORE it enters the tree, because enemy.gd's _ready() seeds
## current_health from max_health -- scaling afterwards would leave a tier-5 bat
## at full health on a bar sized for a tier-0 one.
## The hiệp HP curve plus the danger tier, applied to an instance BEFORE it enters
## the tree. Every spawn path routes through here -- and "every" is load-bearing, so
## it is worth saying what it took: trigger_swarm() and the hermit's Hạ Hạ Quẻ summons
## did neither and dropped a tier-0 bat into a tier-5 hiệp; then all four boss spawns,
## the treasure goblin and the opening ambush did neither, which left a hiệp-20 boss
## the same size as a hiệp-1 one. A new spawn path that skips this is silent, so the
## assertion belongs in tests/test_expansion_35.gd rather than in a comment here.
##
## spawn_hermit() is the one enemy-ish spawn still outside it, deliberately: the Lão
## Ngọan Đồng is the pact NPC, and putting the combat HP curve on a non-combatant
## would be a new bug.
func _scale_for_wave(node: Node2D) -> void:
	var hp = node.get("max_health")
	if hp != null:
		node.set("max_health", float(hp) + floor(get_difficulty_seconds() * 0.22))
	_apply_danger(node)

## Spawn one named enemy at an exact position. The ids are a map rather than a
## bare string because every caller that needs this can only see the spawner
## through its group -- it has no handle on the exported PackedScenes.
const NAMED_ENEMIES: Dictionary = {
	"skeleton_brute": "skeleton_scene",
	"bat": "bat_scene",
	"necromancer": "necromancer_scene",
}

func spawn_specific_enemy(enemy_id: String, pos: Vector2) -> void:
	if not is_instance_valid(player) or not is_inside_tree():
		return
	var prop: String = NAMED_ENEMIES.get(enemy_id, "")
	if prop.is_empty() or not (prop in self):
		push_warning("spawn_specific_enemy: unknown id '%s'" % enemy_id)
		return
	var scene: PackedScene = get(prop)
	if not scene:
		return
	var enemy = scene.instantiate()
	if not enemy:
		return
	_scale_for_wave(enemy)
	enemy.global_position = pos
	get_tree().current_scene.add_child(enemy)

func _apply_danger(node: Node2D) -> void:
	var d := GameManager.get_danger_data()
	var hp = node.get("max_health")
	if hp != null:
		node.set("max_health", float(hp) * float(d["hp"]))
	var spd = node.get("move_speed")
	if spd != null:
		node.set("move_speed", float(spd) * float(d["speed"]))

func trigger_swarm(msg: String, enemy_scene: PackedScene, swarm_count: int) -> void:
	emit_signal("wave_event_announced", msg, false)
	SoundManager.play("boss_alarm", 0.1)
	
	var cam = get_tree().get_first_node_in_group("camera")
	if cam and cam.has_method("shake"):
		cam.shake(12.0)
		
	if not enemy_scene or not is_instance_valid(player):
		return
		
	for i in range(swarm_count):
		var angle = (float(i) / float(swarm_count)) * TAU
		var spawn_pos = player.global_position + Vector2(cos(angle), sin(angle)) * 520.0
		var enemy = enemy_scene.instantiate()
		if enemy:
			_scale_for_wave(enemy)
			enemy.global_position = spawn_pos
			# 1 in 8 swarm enemies is a champion leader
			if i % 8 == 0 and enemy.has_method("make_champion"):
				enemy.make_champion()
			get_tree().current_scene.call_deferred("add_child", enemy)

## Everything a freshly spawned boss owes the player: its health bar and the
## entrance alert. All four boss spawners ended in the same eight lines, so the
## banner would have had to be re-added by hand at each one; here it cannot be
## forgotten, and the four call sites stop drifting apart.
##
## Deliberately fire-and-forget -- the alert is a HUD tween and the fight is
## already underway by the time this returns, which is the point.
func _on_boss_spawned(boss: Node) -> void:
	var hud = get_tree().get_first_node_in_group("hud")
	if not hud:
		return
	if hud.has_method("attach_boss_bar"):
		hud.attach_boss_bar(boss)
	if hud.has_method("announce_boss_entrance"):
		hud.announce_boss_entrance(boss)

func spawn_boss_1() -> void:
	emit_signal("wave_event_announced", "☠️ DREADLORD MALAKOR EMERGES! ☠️", true)
	SoundManager.play("boss_alarm", 0.05)
	
	var cam = get_tree().get_first_node_in_group("camera")
	if cam and cam.has_method("shake"):
		cam.shake(18.0)
		
	if boss_scene and is_instance_valid(player):
		var angle = randf() * TAU
		var spawn_pos = player.global_position + Vector2(cos(angle), sin(angle)) * 620.0
		var boss = boss_scene.instantiate()
		if boss:
			_scale_for_wave(boss)
			boss.global_position = spawn_pos
			get_tree().current_scene.add_child(boss)
			
			_on_boss_spawned(boss)

func spawn_boss_2() -> void:
	emit_signal("wave_event_announced", "👑 INFERNAL BEHEMOTH AWAKENS! 👑", true)
	SoundManager.play("boss_alarm", 0.05)
	
	var cam = get_tree().get_first_node_in_group("camera")
	if cam and cam.has_method("shake"):
		cam.shake(22.0)
		
	var b_scene = behemoth_scene if behemoth_scene else boss_scene
	if b_scene and is_instance_valid(player):
		var angle = randf() * TAU
		var spawn_pos = player.global_position + Vector2(cos(angle), sin(angle)) * 640.0
		var boss = b_scene.instantiate()
		if boss:
			_scale_for_wave(boss)
			boss.global_position = spawn_pos
			get_tree().current_scene.add_child(boss)

			_on_boss_spawned(boss)

func spawn_boss_3() -> void:
	emit_signal("wave_event_announced", "👑 SONG THỦ MA TƯỚNG GIÁNG LÂM! 👑", true)
	SoundManager.play("boss_alarm", 0.05)
	
	var cam = get_tree().get_first_node_in_group("camera")
	if cam and cam.has_method("shake"):
		cam.shake(22.0)
		
	var b_scene = behemoth_scene if behemoth_scene else boss_scene
	if b_scene and is_instance_valid(player):
		var angle = randf() * TAU
		var spawn_pos = player.global_position + Vector2(cos(angle), sin(angle)) * 640.0
		var boss = b_scene.instantiate()
		if boss:
			# Scaling first, then the boss's own bonus: the 1.8 is 80% on top of a
			# Behemoth that has already been put through the hiệp curve and the tier.
			# It read max_health and wrote cur_hp * 1.8 off a flat scene value, so
			# Sòng Thủ was the same fight on hiệp 20 as on hiệp 1.
			_scale_for_wave(boss)
			boss.global_position = spawn_pos
			boss.set("boss_name", "👑 SONG THỦ MA TƯỚNG")
			var cur_hp = boss.get("max_health")
			if cur_hp != null:
				boss.set("max_health", cur_hp * 1.8)
			get_tree().current_scene.add_child(boss)
			
			_on_boss_spawned(boss)

func spawn_demon_emperor() -> void:
	emit_signal("wave_event_announced", "🔥 TRÙM CUỐI: HẮC HUYẾT MA HOÀNG ĐÃ THỨC TỈNH! 🔥", true)
	SoundManager.play("boss_alarm", 0.03)
	
	var cam = get_tree().get_first_node_in_group("camera")
	if cam and cam.has_method("shake"):
		cam.shake(28.0)
		
	var de_scene = demon_emperor_scene if demon_emperor_scene else behemoth_scene
	if de_scene and is_instance_valid(player):
		var angle = randf() * TAU
		var spawn_pos = player.global_position + Vector2(cos(angle), sin(angle)) * 650.0
		var boss = de_scene.instantiate()
		if boss:
			# The final boss, the one wired to trigger_victory(). It was 2400 on every
			# wave of the run: (2400 + 105) * 3.0 = 7515 is what hiệp 20 at Hắc Ám asks
			# for, so the fight that decides the run arrived at a third of its size.
			_scale_for_wave(boss)
			boss.global_position = spawn_pos
			get_tree().current_scene.add_child(boss)
			
			_on_boss_spawned(boss)
				
			if boss.has_signal("boss_defeated"):
				boss.boss_defeated.connect(func():
					if GameManager and not GameManager.is_victory_triggered:
						GameManager.trigger_victory()
				)

func spawn_floor_powerup() -> void:
	if not powerup_scene or not is_instance_valid(player):
		return
	var angle = randf() * TAU
	var pos = player.global_position + Vector2(cos(angle), sin(angle)) * randf_range(180, 360)
	var pup = powerup_scene.instantiate()
	if pup:
		var types = ["meat", "meat", "magnet", "nuke"]
		pup.set_type(types.pick_random())
		pup.global_position = pos
		get_tree().current_scene.call_deferred("add_child", pup)

func spawn_treasure_goblin() -> void:
	emit_signal("wave_event_announced", "💰 TREASURE GOBLIN SPOTTED! CATCH IT! 💰", false)
	SoundManager.play("powerup", 0.2)
	var cam = get_tree().get_first_node_in_group("camera")
	if cam and cam.has_method("shake"):
		cam.shake(10.0)
		
	if goblin_scene and is_instance_valid(player):
		var angle = randf() * TAU
		var spawn_pos = player.global_position + Vector2(cos(angle), sin(angle)) * 380.0
		var gob = goblin_scene.instantiate()
		if gob:
			_scale_for_wave(gob)
			gob.global_position = spawn_pos
			get_tree().current_scene.call_deferred("add_child", gob)

func trigger_blood_moon_event() -> void:
	emit_signal("wave_event_announced", "🩸 BLOOD MOON ECLIPSE! 2X XP & GOLD FOR 30s! 🩸", true)
	SoundManager.play("boss_alarm", 0.08)
	var cam = get_tree().get_first_node_in_group("camera")
	if cam and cam.has_method("shake"):
		cam.shake(16.0)
	if GameManager:
		GameManager.trigger_blood_moon(30.0)

## Expansion 20.0: Tinh Anh Lệnh — spawns a Skeleton or Necromancer promoted to an
## Elite Champion (1.6x scale, 3.5x health, telegraphed shockwave, guaranteed loot).
## Falls back to bats only if neither elite-capable scene is wired up.
func spawn_elite_champion(pos: Vector2 = Vector2.ZERO) -> Node2D:
	var pool: Array = []
	if skeleton_scene:
		pool.append(skeleton_scene)
	if necromancer_scene:
		pool.append(necromancer_scene)
	if pool.is_empty():
		pool.append(bat_scene)
	if pool.is_empty():
		return null

	var elite = pool.pick_random().instantiate()
	if elite == null:
		return null

	elite.set("is_elite_champion", true)
	# _scale_for_wave() rather than _apply_danger(), and not both: it already calls
	# _apply_danger() itself, so adding it here as well would square the tier -- a
	# tier-5 elite at 9x HP, which is a worse bug than the curve this adds.
	_scale_for_wave(elite)
	if pos != Vector2.ZERO:
		elite.global_position = pos
	elif is_instance_valid(player):
		var angle = randf() * TAU
		elite.global_position = player.global_position + Vector2(cos(angle), sin(angle)) * 340.0
	else:
		elite.global_position = Vector2(300, 300)

	get_tree().current_scene.add_child(elite)
	emit_signal("wave_event_announced", "⚜️ TINH ANH LỆNH GIÁ THỔNG GIANG! ⚜️", false)
	SoundManager.play("boss_alarm", 0.15)
	var cam = get_tree().get_first_node_in_group("camera")
	if cam and cam.has_method("shake"):
		cam.shake(12.0)
	return elite

func spawn_hermit(pos: Vector2 = Vector2.ZERO) -> Node2D:
	var hermit_res = load("res://scenes/hermit_npc.tscn")
	if not hermit_res:
		return null
	var hermit = hermit_res.instantiate()
	if pos != Vector2.ZERO:
		hermit.global_position = pos
	elif is_instance_valid(player):
		var angle = randf() * TAU
		hermit.global_position = player.global_position + Vector2(cos(angle), sin(angle)) * 220.0
	else:
		hermit.global_position = Vector2(300, 300)
	get_tree().current_scene.call_deferred("add_child", hermit)
	emit_signal("wave_event_announced", "🧙‍♂️ KỲ NGỘ: LÃO NGOAN ĐỒNG XUẤT HIỆN! 🧙‍♂️", false)
	SoundManager.play("powerup")
	if GameManager:
		GameManager.emit_signal("hermit_spawned")
	return hermit

