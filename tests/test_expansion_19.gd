extends Node

## Automated Test Suite for Expansion 19.0:
## "Cửu Kiếm Quy Tông & Tẩy Tủy Quyết"
## Verifies Directional Slash Arc weapon, Reroll & Skip agency, and Dash I-Frames.

func _ready() -> void:
	print("=== RUNNING EXPANSION 19.0 COMBAT SKILL & LEVEL-UP MASTERY TEST SUITE ===")
	
	_test_directional_slash_weapon()
	_test_upgrade_reroll_agency()
	_test_upgrade_skip_agency()
	_test_dash_invulnerability_window()
	_test_player_arsenal_slash_integration()
	
	print("=== ALL EXPANSION 19.0 TESTS PASSED 100% CLEANLY! ===")
	get_tree().quit(0)

func _test_directional_slash_weapon() -> void:
	var enemy_scene = load("res://scenes/enemy.tscn")
	assert(enemy_scene != null, "Enemy scene loaded")
	
	var slash_scene = load("res://scenes/slash_weapon.tscn")
	assert(slash_scene != null, "SlashWeapon scene loaded")
	var slash = slash_scene.instantiate()
	add_child(slash)
	slash.global_position = Vector2.ZERO
	slash.is_active = true
	
	# Spawn 3 enemies: Front (in arc), Cleave (in cone), and Behind (outside arc)
	var e_front = enemy_scene.instantiate()
	add_child(e_front)
	e_front.global_position = Vector2(50, 0)
	var front_hp_init = e_front.current_health
	
	var e_cleave = enemy_scene.instantiate()
	add_child(e_cleave)
	e_cleave.global_position = Vector2(45, 25) # within 120-degree forward cone
	var cleave_hp_init = e_cleave.current_health
	
	var e_behind = enemy_scene.instantiate()
	add_child(e_behind)
	e_behind.global_position = Vector2(-50, 0) # directly behind the slash
	var behind_hp_init = e_behind.current_health
	
	# Perform directional slash facing RIGHT
	var hits_right = slash.perform_slash(Vector2.RIGHT)
	assert(slash.last_slash_direction == Vector2.RIGHT, "Last slash direction recorded as Vector2.RIGHT")
	assert(hits_right.has(e_front), "Enemy in front is hit by directional slash")
	assert(hits_right.has(e_cleave), "Enemy in forward cleave cone is hit by directional slash")
	assert(not hits_right.has(e_behind), "Enemy behind player is NOT hit by directional slash")
	assert(e_front.current_health < front_hp_init, "Enemy in front took damage")
	assert(e_cleave.current_health < cleave_hp_init, "Enemy in cleave cone took damage")
	assert(e_behind.current_health == behind_hp_init, "Enemy behind took zero damage")
	
	# Test facing UP
	var e_up = enemy_scene.instantiate()
	add_child(e_up)
	e_up.global_position = Vector2(0, -55)
	var up_hp_init = e_up.current_health
	
	var e_down = enemy_scene.instantiate()
	add_child(e_down)
	e_down.global_position = Vector2(0, 55)
	var down_hp_init = e_down.current_health
	
	var hits_up = slash.perform_slash(Vector2.UP)
	assert(slash.last_slash_direction == Vector2.UP, "Last slash direction recorded as Vector2.UP")
	assert(hits_up.has(e_up), "Enemy in UP direction is hit when facing UP")
	assert(not hits_up.has(e_down), "Enemy in DOWN direction is NOT hit when facing UP")
	assert(e_up.current_health < up_hp_init, "Enemy above took damage")
	assert(e_down.current_health == down_hp_init, "Enemy below took zero damage")
	
	# Test Evolution to Nine Swords
	slash.evolve_to_nine_swords()
	assert(slash.is_evolved == true, "SlashWeapon evolved state active")
	assert(slash.base_damage >= 75.0, "Evolved slash damage boosted to at least 75.0")
	assert(slash.slash_angle_deg >= 180.0, "Evolved slash sweeping arc expanded to at least 180 degrees")
	
	# Cleanup
	e_front.queue_free()
	e_cleave.queue_free()
	e_behind.queue_free()
	e_up.queue_free()
	e_down.queue_free()
	slash.queue_free()
	print("✔ Directional slash damage, facing vector, and multi-target cleave verified.")

func _test_upgrade_reroll_agency() -> void:
	var up_mgr = UpgradeManager.new()
	add_child(up_mgr)
	
	assert(up_mgr.max_rerolls == 2, "UpgradeManager provides 2 default rerolls per run")
	assert(up_mgr.rerolls_remaining == 2, "Starts with 2 rerolls remaining")
	
	up_mgr.show_upgrade_selection()
	assert(up_mgr.panel.visible == true, "UpgradePanel is visible upon level up")
	assert(get_tree().paused == true, "Game pauses during upgrade selection")
	assert(up_mgr.current_offered_upgrades.size() > 0, "Cards offered to player")
	
	# First Reroll
	var success1 = up_mgr.reroll_upgrades()
	assert(success1 == true, "First reroll successful")
	assert(up_mgr.rerolls_remaining == 1, "Rerolls remaining decremented to 1")
	assert(up_mgr.current_offered_upgrades.size() > 0, "New cards generated after reroll")
	
	# Second Reroll
	var success2 = up_mgr.reroll_upgrades()
	assert(success2 == true, "Second reroll successful")
	assert(up_mgr.rerolls_remaining == 0, "Rerolls remaining decremented to 0")
	
	# Third Reroll (should fail since exhausted)
	var success3 = up_mgr.reroll_upgrades()
	assert(success3 == false, "Third reroll rejected when rerolls_remaining == 0")
	assert(up_mgr.rerolls_remaining == 0, "Rerolls counter stays at 0")
	
	# Test Reset Rerolls
	up_mgr.reset_rerolls()
	assert(up_mgr.rerolls_remaining == 2, "Rerolls reset back to max_rerolls")
	
	up_mgr.queue_free()
	get_tree().paused = false
	print("✔ Reroll functionality (deck refresh, count decrement, exhaustion) verified.")

func _test_upgrade_skip_agency() -> void:
	var up_mgr = UpgradeManager.new()
	add_child(up_mgr)
	
	var initial_gold = GameManager.total_gold if GameManager else 0
	up_mgr.show_upgrade_selection()
	assert(up_mgr.panel.visible == true, "UpgradePanel open before skip")
	assert(get_tree().paused == true, "Tree paused before skip")
	
	# Execute Skip
	up_mgr.skip_upgrade()
	
	if GameManager:
		assert(GameManager.total_gold >= initial_gold + 30, "+30 Gold bonus awarded on Skip")
	assert(up_mgr.panel.visible == false, "UpgradePanel cleanly closed after skip")
	assert(get_tree().paused == false, "Game unpaused and gameplay resumes after skip")
	
	up_mgr.queue_free()
	print("✔ Skip functionality (+30 gold bonus, panel closed, game unpaused) verified.")

func _test_dash_invulnerability_window() -> void:
	var player_scene = load("res://scenes/player.tscn")
	assert(player_scene != null, "Player scene loaded")
	var player = player_scene.instantiate() as Player
	add_child(player)
	player.apply_character_data()
	
	assert(player.is_invulnerable == false, "Player is not invulnerable initially")
	
	# Trigger Tactical Dash / Thân Pháp
	player.perform_dash(Vector2.RIGHT)
	assert(player.is_dashing == true, "Player is in dashing state")
	assert(player.is_invulnerable == true, "Player enters invulnerable state during dash")
	assert(player.invulnerability_timer >= 0.25, "Dash grants at least 0.25s i-frame window")
	
	# Test incoming damage nullification during i-frames
	var hp_before = player.current_health
	player.take_damage(50.0)
	assert(player.current_health == hp_before, "Incoming damage completely nullified during dash i-frame window")
	
	# Advance physics time past the 0.25s window
	player._physics_process(0.26)
	assert(player.is_dashing == false, "Dash ends after duration")
	assert(player.is_invulnerable == false, "Invulnerability expires after i-frame window")
	
	# Take damage outside window
	player.take_damage(30.0)
	assert(player.current_health < hp_before, "Player takes damage normally once i-frame window expires")
	
	# Test setter for is_invulnerable
	player.is_invulnerable = true
	assert(player.is_invulnerable == true, "Setter turns on invulnerability")
	player.is_invulnerable = false
	assert(player.is_invulnerable == false, "Setter turns off invulnerability")
	
	player.queue_free()
	print("✔ Dash invulnerability window (0.25s i-frames and collision damage nullification) verified.")

func _test_player_arsenal_slash_integration() -> void:
	var player_scene = load("res://scenes/player.tscn")
	var player = player_scene.instantiate() as Player
	add_child(player)
	player.apply_character_data()
	
	# Check SlashWeapon node exists in Player tree
	var slash_node = player.get_node_or_null("Weapons/SlashWeapon")
	assert(slash_node != null, "SlashWeapon node exists in Player weapons container")
	
	# Activate weapon
	player.activate_weapon("slash")
	assert(slash_node.is_active == true, "SlashWeapon active after activate_weapon('slash')")
	
	# Test perform_slash helper
	var hits = player.perform_slash(Vector2.RIGHT)
	assert(hits is Array, "perform_slash returns hit array")
	
	# Test UpgradeManager catalog inclusion
	var up_mgr = UpgradeManager.new()
	add_child(up_mgr)
	up_mgr.weapon_levels = {"dagger": 1, "shield": 1, "lightning": 0, "fireball": 0, "axe": 0, "slash": 0}
	var cat = up_mgr.get_upgrade_catalog()
	var has_unlock_slash = false
	for item in cat:
		if item.get("id") == "unlock_slash":
			has_unlock_slash = true
			break
	assert(has_unlock_slash == true, "unlock_slash is offered in catalog when active weapons < 3")
	
	# Test Slash Evolution offer at Lv.5
	up_mgr.weapon_levels["slash"] = 5
	up_mgr.evolved_weapons["slash"] = false
	var evol_cat = up_mgr.get_upgrade_catalog()
	var has_evolve_slash = false
	for item in evol_cat:
		if item.get("id") == "evolve_slash":
			has_evolve_slash = true
			break
	assert(has_evolve_slash == true, "evolve_slash offered when slash reaches Lv.5")
	
	up_mgr.queue_free()
	player.queue_free()
	print("✔ Player arsenal SlashWeapon integration and upgrade catalog verified.")
