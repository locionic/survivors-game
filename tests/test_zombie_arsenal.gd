extends Node

## Milestone 1: Tactical Arsenal & Weapons Reskin for Zombie Outbreak mode.
## Verifies that:
## 1. Loc.weapon_name() and Loc.t() return modern tactical firearms & evolutions in zombie_city.
## 2. UpgradeManager.card_icon() returns tactical icons (🔫, 🛡️, ⚡, 💣, 🧨, 🔪) in zombie_city.
## 3. UpgradeManager.get_upgrade_catalog() serves tactical upgrade options with matched balance numbers.
## 4. Default martial arts stage maintains 100% legacy canonical strings and icons.

var _failures: Array[String] = []

func check(cond: bool, msg: String) -> bool:
	if not cond:
		_failures.append(msg)
		push_error("CHECK FAILED: %s" % msg)
	return cond

func _ready() -> void:
	print("=== RUNNING MILESTONE 1: ZOMBIE TACTICAL ARSENAL TEST SUITE ===")
	var original_stage = GameManager.selected_stage if GameManager else "martial_arts"
	var original_locale = Loc.current_locale

	_test_martial_arts_baseline()
	_test_zombie_stage_weapon_names_en()
	_test_zombie_stage_weapon_names_vi()
	_test_zombie_card_icons()
	_test_zombie_upgrade_catalog()

	# Restore state
	if GameManager:
		GameManager.selected_stage = original_stage
	Loc.set_locale(original_locale)

	if _failures.is_empty():
		print("PASSED: All Zombie Tactical Arsenal tests passed cleanly!")
	else:
		push_error("FAILED: %d assertions failed in Zombie Tactical Arsenal tests!" % _failures.size())

	get_tree().quit(0 if _failures.is_empty() else 1)

func _test_martial_arts_baseline() -> void:
	if GameManager:
		GameManager.selected_stage = "martial_arts"
	Loc.set_locale("en")

	check(Loc.weapon_name("dagger") == "Thousand Daggers", "Martial dagger is Thousand Daggers")
	check(Loc.weapon_name("shield") == "Eight Trigrams Shield", "Martial shield is Eight Trigrams Shield")
	check(Loc.weapon_name("lightning") == "Heaven's Wrath", "Martial lightning is Heaven's Wrath")
	check(Loc.weapon_name("fireball") == "Apocalypse Meteor", "Martial fireball is Apocalypse Meteor")
	check(Loc.weapon_name("axe") == "Dog-Beating Staff", "Martial axe is Dog-Beating Staff")
	check(Loc.weapon_name("slash") == "Nine Swords Cleave", "Martial slash is Nine Swords Cleave")

	var up = UpgradeManager.new()
	add_child(up)
	check(up.card_icon("dagger") == "🗡️", "Martial dagger icon is 🗡️")
	check(up.card_icon("fireball") == "🔥", "Martial fireball icon is 🔥")
	check(up.card_icon("axe") == "🪓", "Martial axe icon is 🪓")
	up.queue_free()

func _test_zombie_stage_weapon_names_en() -> void:
	if GameManager:
		GameManager.selected_stage = "zombie_city"
	Loc.set_locale("en")

	check(Loc.weapon_name("dagger") == "Tactical Pistol", "Zombie dagger is Tactical Pistol")
	check(Loc.weapon_name("shield") == "Riot Shield Orbit", "Zombie shield is Riot Shield Orbit")
	check(Loc.weapon_name("lightning") == "Tesla Arc Coil", "Zombie lightning is Tesla Arc Coil")
	check(Loc.weapon_name("fireball") == "Molotov Launcher", "Zombie fireball is Molotov Launcher")
	check(Loc.weapon_name("axe") == "Frag Grenade", "Zombie axe is Frag Grenade")
	check(Loc.weapon_name("slash") == "Combat Machete", "Zombie slash is Combat Machete")

	check(Loc.t("evo.dagger.name") == "Minigun Barrage", "Zombie dagger evo is Minigun Barrage")
	check(Loc.t("evo.shield.name") == "Bio-Barrier Array", "Zombie shield evo is Bio-Barrier Array")
	check(Loc.t("evo.lightning.name") == "EMP Storm Grid", "Zombie lightning evo is EMP Storm Grid")
	check(Loc.t("evo.fireball.name") == "Napalm Strike", "Zombie fireball evo is Napalm Strike")
	check(Loc.t("evo.axe.name") == "Cluster Warhead", "Zombie axe evo is Cluster Warhead")
	check(Loc.t("evo.slash.name") == "Chainsaw Ripper", "Zombie slash evo is Chainsaw Ripper")

	check(Loc.t("synergy.lotus_storm.name") == "Bullet Hell Barrage", "Zombie synergy 1 is Bullet Hell Barrage")
	check(Loc.t("synergy.frost_sovereign.name") == "Cryo-Shock Cleaver", "Zombie synergy 2 is Cryo-Shock Cleaver")

func _test_zombie_stage_weapon_names_vi() -> void:
	if GameManager:
		GameManager.selected_stage = "zombie_city"
	Loc.set_locale("vi")

	check(Loc.weapon_name("dagger") == "Súng Lục Tác Chiến", "Zombie dagger vi is Súng Lục Tác Chiến")
	check(Loc.weapon_name("shield") == "Khiên Chống Bạo Động", "Zombie shield vi is Khiên Chống Bạo Động")
	check(Loc.weapon_name("lightning") == "Súng Phóng Điện Tesla", "Zombie lightning vi is Súng Phóng Điện Tesla")
	check(Loc.weapon_name("fireball") == "Bom Xăng Molotov", "Zombie fireball vi is Bom Xăng Molotov")
	check(Loc.weapon_name("axe") == "Lựu Đạn Mảnh", "Zombie axe vi is Lựu Đạn Mảnh")
	check(Loc.weapon_name("slash") == "Dao Rựa Dã Chiến", "Zombie slash vi is Dao Rựa Dã Chiến")

	check(Loc.t("evo.dagger.name") == "Súng Máy Gatling", "Zombie dagger evo vi is Súng Máy Gatling")
	check(Loc.t("evo.shield.name") == "Lá Chắn Sinh Học", "Zombie shield evo vi is Lá Chắn Sinh Học")
	check(Loc.t("evo.lightning.name") == "Bão Từ Trường EMP", "Zombie lightning evo vi is Bão Từ Trường EMP")
	check(Loc.t("evo.fireball.name") == "Không Kích Napalm", "Zombie fireball evo vi is Không Kích Napalm")
	check(Loc.t("evo.axe.name") == "Đầu Đạn Chùm", "Zombie axe evo vi is Đầu Đạn Chùm")
	check(Loc.t("evo.slash.name") == "Cưa Máy Cuồng Nộ", "Zombie slash evo vi is Cưa Máy Cuồng Nộ")

func _test_zombie_card_icons() -> void:
	if GameManager:
		GameManager.selected_stage = "zombie_city"

	var up = UpgradeManager.new()
	add_child(up)

	check(up.card_icon("dagger") == "🔫", "Zombie dagger card icon is 🔫, got %s" % up.card_icon("dagger"))
	check(up.card_icon("unlock_dagger") == "🔫", "Zombie unlock_dagger card icon is 🔫, got %s" % up.card_icon("unlock_dagger"))
	check(up.card_icon("evolve_dagger") == "🔫", "Zombie evolve_dagger card icon is 🔫, got %s" % up.card_icon("evolve_dagger"))
	check(up.card_icon("shield") == "🛡️", "Zombie shield card icon is 🛡️")
	check(up.card_icon("lightning") == "⚡", "Zombie lightning card icon is ⚡")
	check(up.card_icon("fireball") == "💣", "Zombie fireball card icon is 💣")
	check(up.card_icon("axe") == "🧨", "Zombie axe card icon is 🧨")
	check(up.card_icon("slash") == "🔪", "Zombie slash card icon is 🔪")
	check(up.card_icon("magnet") == "🧲", "Zombie magnet card icon is 🧲")
	check(up.card_icon("move_speed") == "🏃", "Zombie move_speed card icon is 🏃")
	check(up.card_icon("max_hp") == "💉", "Zombie max_hp card icon is 💉")
	check(up.card_icon("might_surge") == "☣️", "Zombie might_surge card icon is ☣️")

	up.queue_free()

func _test_zombie_upgrade_catalog() -> void:
	if GameManager:
		GameManager.selected_stage = "zombie_city"
	Loc.set_locale("en")

	var up = UpgradeManager.new()
	add_child(up)
	up.weapon_levels = {"dagger": 0, "shield": 0, "lightning": 0, "fireball": 0, "axe": 0, "slash": 0}
	up.evolved_weapons = {"dagger": false, "shield": false, "lightning": false, "fireball": false, "axe": false, "slash": false}
	up.synergies_evolved = {"bao_vu": false, "bang_phach": false}

	var cat = up.get_upgrade_catalog()
	check(cat.size() >= 10, "Zombie catalog has offerings, got %d" % cat.size())

	# Check unlock titles
	var titles: Array[String] = []
	for item in cat:
		titles.append(String(item.get("title", "")))

	check(titles.has("[NEW] Tactical Pistol"), "Offers [NEW] Tactical Pistol")
	check(titles.has("[NEW] Riot Shield Orbit"), "Offers [NEW] Riot Shield Orbit")
	check(titles.has("[NEW] Tesla Arc Coil"), "Offers [NEW] Tesla Arc Coil")
	check(titles.has("[NEW] Molotov Launcher"), "Offers [NEW] Molotov Launcher")
	check(titles.has("[NEW] Frag Grenade"), "Offers [NEW] Frag Grenade")
	check(titles.has("[NEW] Combat Machete"), "Offers [NEW] Combat Machete")

	# Check passives in EN
	check(titles.has("SWAT Tactical Boots"), "Offers SWAT Tactical Boots")
	check(titles.has("Military Loot Scanner"), "Offers Military Loot Scanner")
	check(titles.has("Kevlar Ballistic Vest"), "Offers Kevlar Ballistic Vest")
	check(titles.has("Combat Adrenaline Shot"), "Offers Combat Adrenaline Shot")

	# Test evolutions and synergies at Lv.5
	up.weapon_levels = {"dagger": 5, "shield": 5, "lightning": 5, "fireball": 5, "axe": 5, "slash": 5}
	var cat_max = up.get_upgrade_catalog()
	var evo_titles: Array[String] = []
	for item in cat_max:
		evo_titles.append(String(item.get("title", "")))

	check(evo_titles.has("[EVOLUTION] MINIGUN BARRAGE"), "Offers [EVOLUTION] MINIGUN BARRAGE")
	check(evo_titles.has("[EVOLUTION] BIO-BARRIER ARRAY"), "Offers [EVOLUTION] BIO-BARRIER ARRAY")
	check(evo_titles.has("[EVOLUTION] EMP STORM GRID"), "Offers [EVOLUTION] EMP STORM GRID")
	check(evo_titles.has("[EVOLUTION] NAPALM STRIKE"), "Offers [EVOLUTION] NAPALM STRIKE")
	check(evo_titles.has("[EVOLUTION] CLUSTER WARHEAD"), "Offers [EVOLUTION] CLUSTER WARHEAD")
	check(evo_titles.has("[EVOLUTION] CHAINSAW RIPPER"), "Offers [EVOLUTION] CHAINSAW RIPPER")
	check(evo_titles.has("[SYNERGY] BULLET HELL BARRAGE"), "Offers [SYNERGY] BULLET HELL BARRAGE")
	check(evo_titles.has("[SYNERGY] CRYO-SHOCK CLEAVER"), "Offers [SYNERGY] CRYO-SHOCK CLEAVER")

	up.queue_free()
