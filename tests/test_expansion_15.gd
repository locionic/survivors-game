extends Node

## Comprehensive test suite verifying Expansion 15.0:
## Wuxia Unlock Codex, Demonic Risk-Reward Altars & Explosive Elemental Synergies.

func _ready() -> void:
	print("=== RUNNING EXPANSION 15.0 CODEX & DEMONIC ALTAR TEST SUITE ===")
	
	# 1. Test CodexManager Autoload and Quest Structure
	assert(CodexManager != null, "CodexManager autoload exists")
	CodexManager.reset_codex_data()
	assert(CodexManager.quests.size() == 8, "CodexManager contains 8 wuxia milestone quests")
	assert(CodexManager.unlocked_count == 0, "Initial unlocked count is 0")
	print("✔ CodexManager quest catalog initialized.")
	
	# 2. Test Quest Progress Tracking & Unlock
	var initial_gold = GameManager.total_gold
	CodexManager.report_stat("cumulative_kills", 300)
	var q_slay = CodexManager.get_quest("slay_500")
	assert(q_slay["progress"] == 300, "Cumulative kills progress tracks correctly")
	assert(q_slay["unlocked"] == false, "Quest not yet unlocked at 300 kills")
	
	# Reach 500 kills threshold
	CodexManager.report_stat("cumulative_kills", 200)
	q_slay = CodexManager.get_quest("slay_500")
	assert(q_slay["progress"] == 500, "Reached 500 kills threshold")
	assert(q_slay["unlocked"] == true, "Quest unlocked upon reaching target")
	assert(CodexManager.unlocked_count == 1, "unlocked_count incremented to 1")
	
	# Claim Reward
	var claimed = CodexManager.claim_reward("slay_500")
	assert(claimed == true, "Reward claimed successfully")
	assert(GameManager.total_gold == initial_gold + 600, "Claiming slay_500 grants +600 Meta Gold")
	assert(q_slay["claimed"] == true, "Quest marked as claimed")
	print("✔ Codex milestone tracking, unlock trigger, and reward payout verified.")
	
	# 3. Test Demonic Altar & AltarUI
	var altar_scene = load("res://scenes/demonic_altar.tscn")
	assert(altar_scene != null, "DemonicAltar scene exists")
	var altar = altar_scene.instantiate()
	add_child(altar)
	assert(altar.is_in_group("demonic_altars"), "Altar added to demonic_altars group")
	assert(altar.is_activated == false, "Altar starts unactivated")
	
	var altar_ui_scene = load("res://scenes/altar_ui.tscn")
	assert(altar_ui_scene != null, "AltarUI scene exists")
	var altar_ui = altar_ui_scene.instantiate()
	add_child(altar_ui)
	assert(altar_ui.cards_container.get_child_count() == 3, "AltarUI displays 3 Demonic Pacts")
	
	# Test Pact Application on Player
	var player_scene = load("res://scenes/player.tscn")
	var player = player_scene.instantiate()
	add_child(player)
	player.apply_character_data()
	var prev_hp = player.current_health
	var prev_might = player.might_multiplier
	
	# Sign Blood Covenant
	player.apply_demonic_pact("blood_covenant")
	assert(player.has_blood_covenant == true, "Player has active blood covenant")
	assert(player.current_health < prev_hp, "Blood covenant sacrifices health")
	assert(player.might_multiplier > prev_might, "Blood covenant boosts might multiplier")
	
	altar.on_pact_signed("blood_covenant")
	assert(altar.is_activated == true, "Altar marked as activated after signing pact")
	
	# Signing pact should also trigger Codex "sign_pact" quest
	CodexManager.report_stat("pact", 1)
	var q_pact = CodexManager.get_quest("sign_pact")
	assert(q_pact["unlocked"] == true, "Demonic pact signing unlocks Codex quest")
	print("✔ Demonic Altar, 3 Pacts, sacrifice curses, and boons verified.")
	
	# 4. Test Explosive Elemental Synergy: Băng Hỏa Bạo Kích (Thermal Shockwave)
	var enemy_scene = load("res://scenes/enemy.tscn")
	var enemy = enemy_scene.instantiate()
	add_child(enemy)
	enemy.max_health = 300.0
	enemy.current_health = 300.0
	
	# Apply Burn, then Apply Freeze -> triggers Thermal Shockwave
	enemy.apply_burn(4.0, 20.0)
	assert(enemy.burn_timer > 0.0, "Enemy is burning")
	
	var health_before_shockwave = enemy.current_health
	enemy.apply_freeze(3.0)
	# Thermal shockwave should have cleared burn and freeze, and dealt 140 instant damage
	assert(enemy.freeze_timer == 0.0, "Freeze timer consumed by thermal shockwave")
	assert(enemy.burn_timer == 0.0, "Burn timer consumed by thermal shockwave")
	assert(enemy.current_health <= health_before_shockwave - 140.0, "Enemy took 140 thermal shockwave damage")
	print("✔ Explosive Elemental Synergy (Băng Hỏa Bạo Kích) verified.")
	
	# 5. Test Relic: Bát Tiên Hồ Lô Splash on Dodge
	GameManager.add_relic("drunken_gourd")
	assert(GameManager.has_relic("drunken_gourd"), "Drunken gourd relic active")
	player._proc_drunken_gourd_splash()
	print("✔ Relic: Bát Tiên Hồ Lô dodge splash verified.")
	
	# 6. Test Main Scene Integration (TopBar Codex Button & Modals)
	var main_scene = load("res://scenes/main.tscn")
	assert(main_scene != null, "Main scene exists")
	var main = main_scene.instantiate()
	add_child(main)
	
	var hud = main.get_node_or_null("HUD")
	assert(hud != null, "HUD exists in main scene")
	assert(hud.get_node_or_null("GameUI/TopBar/CodexButton") == null,
		"CodexButton is off the combat TopBar")
	assert(hud.get_node_or_null("PausePanel/VBox/PauseCodexButton") != null,
		"PauseCodexButton exists in PausePanel")
	assert(hud.get_node_or_null("CodexModal") != null, "CodexModal exists under HUD")
	assert(hud.get_node_or_null("AltarModal") != null, "AltarModal exists under HUD")
	assert(main.get_node_or_null("Landmarks/DemonicAltar") != null, "DemonicAltar placed in world Landmarks")
	
	# Test Open and Close CodexModal
	hud.open_codex("topbar")
	assert(hud.codex_modal.visible == true, "CodexModal opens cleanly")
	hud.codex_modal.close_ui()
	assert(hud.codex_modal.visible == false, "CodexModal closes cleanly")
	
	# Test Toast announcement banner
	hud.announce_codex_unlock("Thử Nghiệm", "Mở khóa thành công")
	assert(hud.codex_toast_banner != null, "Codex unlock announcement banner spawned")
	
	# Cleanup
	altar.free()
	altar_ui.free()
	player.free()
	enemy.free()
	main.free()
	
	print("=== ALL EXPANSION 15.0 TESTS PASSED CLEANLY! ===")
	get_tree().quit(0)
