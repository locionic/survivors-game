extends Node

## GameManager: Autoload singleton managing game state, currency, scoring, and run flow.

signal run_started
signal run_ended(victory: bool)
signal score_updated(kills: int, time: float)
signal gold_updated(current_gold: int)
signal meta_upgraded(stat: String, level: int)
signal landmark_discovered(landmark_id: String, landmark_name: String)
signal character_selected(char_id: String)
signal relic_collected(relic_id: String, relic_data: Dictionary)
signal bounty_updated(bounties: Array)
signal bounty_completed(bounty: Dictionary)
signal blood_moon_started(duration: float)
signal blood_moon_ended
signal meridian_upgraded(meridian_id: String, level: int)
signal companion_changed(companion_id: String)
signal dragon_pearl_collected(pearl_index: int, total_collected: int)
signal shenron_summon_ready
signal shenron_wish_selected(wish_id: String)
signal scroll_collected(scroll_id: String)
signal stage_selected(stage_id: String)
signal equipment_updated(slot: String, gear_id: String)
signal hermit_spawned
signal victory_achieved(stats: Dictionary)
signal chest_opened(jackpot_tier: int, upgrades: Array, gold_awarded: int)
signal kill_milestone_reached(milestone: int, title: String)

const MAX_RUN_TIME: float = 480.0 # 8-Minute Web Run
var is_endless_mode: bool = false
var is_victory_triggered: bool = false

var run_time: float = 0.0
var kills: int = 0
var run_gold: int = 0
var total_gold: int = 0
var discovered_landmarks: Dictionary = {}
var selected_character: String = "knight"
var selected_stage: String = "plains"
var equipment_slots: Dictionary = {"weapon": "", "armor": "", "boots": ""}
var collected_relics: Array[String] = []
var active_bounties: Array[Dictionary] = []
var dragon_pearls_collected: int = 0
var shenron_wishes_used: int = 0
var collected_scrolls: Array[String] = []
var is_first_run: bool = true

# Expansion 21.0: Chiến Tích Bảng — per-weapon damage ledger feeding the DPS breakdown.
var weapon_damage_stats: Dictionary = {
	"dagger": 0.0, "shield": 0.0, "lightning": 0.0,
	"fireball": 0.0, "axe": 0.0, "slash": 0.0
}
# Expansion 21.0: Vạn Nhân Trảm — kill-streak rampage milestones already fired this run.
var reached_kill_milestones: Array[int] = []

const WEAPON_DISPLAY_NAMES: Dictionary = {
	"dagger": "🗡️ Độc Cô Phi Đao",
	"shield": "🛡️ Khiên Bát Quái",
	"lightning": "⚡ Cửu Thiên Lôi",
	"fireball": "🔥 Liệt Hỏa Chưởng Cầu",
	"axe": "🪓 Đả Cẩu Trận",
	"slash": "⚔️ Độc Cô Cửu Kiếm"
}

const KILL_MILESTONES: Array[int] = [50, 100, 250, 500, 1000]
const KILL_MILESTONE_TITLES: Dictionary = {
	50: "⚔️ TRẢM TƯỚNG ĐOẠT KỲ! (+25% CUỒNG BẠO)",
	100: "🔥 BÁCH NHÂN ĐỊCH! (+25% CUỒNG BẠO)",
	250: "⚡ CUỒNG MA XUẤT THẾ! (+25% CUỒNG BẠO)",
	500: "👑 VẠN QUÂN BẤT ĐỊCH! (+25% CUỒNG BẠO)",
	1000: "🌌 ĐỘC BỘ THIÊN HẠ! (+25% CUỒNG BẠO)"
}

# Expansion 21.0: Bảo Rương Kim Quy — jackpot tiers. Chances must sum to 1.0.
const CHEST_JACKPOTS: Array[Dictionary] = [
	{"tier": 1, "chance": 0.75, "upgrades": 1, "gold": 100},
	{"tier": 2, "chance": 0.20, "upgrades": 3, "gold": 250},
	{"tier": 3, "chance": 0.05, "upgrades": 5, "gold": 500}
]

const STAGES: Dictionary = {
	"plains": {
		"id": "plains",
		"name": "Ba Lăng Huyện",
		"desc": "Đồng cỏ thanh bình, nơi khởi đầu của vạn dặm hành hiệp trượng nghĩa.",
		"texture_path": "res://assets/textures/dungeon_floor.png",
		"hazard": "none",
		"color": Color(0.35, 0.85, 0.45)
	},
	"mount_hua": {
		"id": "mount_hua",
		"name": "Đỉnh Hoa Sơn Tuyết Phủ",
		"desc": "Hàn băng buốt giá. Định kỳ bão tuyết quét qua làm chậm 25% nhưng tăng +50% Sát thương Băng!",
		"texture_path": "res://assets/textures/snow_floor.png",
		"hazard": "blizzard",
		"color": Color(0.4, 0.85, 1.0)
	}
}

const EQUIPMENT_CATALOG: Dictionary = {
	"y_thien_kiem": {
		"id": "y_thien_kiem",
		"slot": "weapon",
		"name": "Ỷ Thiên Kiếm",
		"icon": "⚔️",
		"desc": "+25% Bán kính tầm đánh & +15% Sát thương",
		"color": Color(0.3, 0.85, 1.0)
	},
	"nhuyen_vi_giap": {
		"id": "nhuyen_vi_giap",
		"slot": "armor",
		"name": "Nhuyễn Vị Giáp",
		"icon": "🛡️",
		"desc": "+2 Giáp cơ bản & Phản hồi 40% sát thương nhận vào",
		"color": Color(1.0, 0.8, 0.25)
	},
	"van_hac_hai": {
		"id": "van_hac_hai",
		"slot": "boots",
		"name": "Vân Hạc Hài",
		"icon": "🥾",
		"desc": "+30 Tốc độ di chuyển & Miễn nhiễm hiệu ứng làm chậm",
		"color": Color(0.4, 0.95, 0.6)
	}
}

var RELICS: Dictionary = {
	"vampire_fang": {
		"id": "vampire_fang",
		"name": "Vampire Fang",
		"icon": "🩸",
		"desc": "+3 HP every 10 kills",
		"color": Color(0.9, 0.2, 0.25)
	},
	"storm_amulet": {
		"id": "storm_amulet",
		"name": "Storm Amulet",
		"icon": "⚡",
		"desc": "25% chance on hit to call bonus lightning",
		"color": Color(0.2, 0.85, 1.0)
	},
	"phoenix_feather": {
		"id": "phoenix_feather",
		"name": "Phoenix Feather",
		"icon": "🪶",
		"desc": "Revive with 40% HP & blast enemies (1x/run)",
		"color": Color(1.0, 0.5, 0.1)
	},
	"golden_horseshoe": {
		"id": "golden_horseshoe",
		"name": "Golden Horseshoe",
		"icon": "👑",
		"desc": "+50% Gold drops & +60 Magnet Radius",
		"color": Color(1.0, 0.85, 0.2)
	},
	"berserker_brand": {
		"id": "berserker_brand",
		"name": "Berserker Brand",
		"icon": "🔥",
		"desc": "+50% Damage when below 40% HP",
		"color": Color(1.0, 0.3, 0.15)
	},
	"chrono_hourglass": {
		"id": "chrono_hourglass",
		"name": "Chrono Hourglass",
		"icon": "⏳",
		"desc": "-20% Weapon Cooldowns",
		"color": Color(0.4, 0.95, 0.7)
	}
}

const MARTIAL_SCROLLS: Dictionary = {
	"yijinjing": {
		"id": "yijinjing",
		"name": "Dịch Cân Kinh",
		"icon": "📜",
		"texture_path": "res://assets/textures/scroll_gold.png",
		"sect": "Thiếu Lâm Tự",
		"desc": "Mỗi 7.5s bộc phát Sư Tử Hống đẩy lùi & làm choáng toàn bộ quái vật 1.5s (80 ST)",
		"color": Color(1.0, 0.85, 0.2)
	},
	"lucmach": {
		"id": "lucmach",
		"name": "Lục Mạch Thần Kiếm",
		"icon": "🗡️",
		"texture_path": "res://assets/textures/scroll_sword.png",
		"sect": "Đại Lý Đoàn Thị",
		"desc": "Bắn chỉ kiếm laser xuyên thấu liên tục mỗi 0.65s (35 ST, xuyên 3 mục tiêu)",
		"color": Color(0.2, 0.85, 1.0)
	},
	"thaicuc": {
		"id": "thaicuc",
		"name": "Thái Cực Kiếm Trận",
		"icon": "☯️",
		"texture_path": "res://assets/textures/scroll_taichi.png",
		"sect": "Võ Đang Phái",
		"desc": "Tạo vòng xoáy Thái Cực Đồ giảm 50% tốc độ quái vật xung quanh & gây 15 ST/s",
		"color": Color(0.7, 0.5, 1.0)
	}
}

const SHENRON_WISHES: Dictionary = {
	"wish_wealth": {
		"id": "wish_wealth",
		"title": "Kim Sơn Bạc Hải",
		"icon": "💰",
		"desc": "Nhận ngay +1,500 Vàng & kích hoạt Mưa Vàng 30 giây (quái rơi x2 Vàng)!",
		"color": Color(1.0, 0.85, 0.2)
	},
	"wish_immortality": {
		"id": "wish_immortality",
		"title": "Bất Tử Chân Thân",
		"icon": "☯️",
		"desc": "Hồi đầy Máu & Khí Thuẫn, +100 Máu Tối Đa, nhận thêm 1 lần Hồi Sinh Phượng Hoàng!",
		"color": Color(0.2, 0.9, 0.6)
	},
	"wish_swords": {
		"id": "wish_swords",
		"title": "Vạn Kiếm Quy Tông",
		"icon": "⚔️",
		"desc": "Triệu hồi bão Thần Kiếm thiên hà trong 20s tiêu diệt toàn bộ ma vật trên bản đồ!",
		"color": Color(0.3, 0.8, 1.0)
	}
}

var is_blood_moon: bool = false
var blood_moon_timer: float = 0.0

## Milestone 2: five deliberately opposed Môn Phái. Every entry trades something
## real for something real, so the sect you pick decides which of the six weapon
## slots is worth buying rather than just a starting palette.
##   knight  Tiêu Dao   generalist  - no upside and no downside
##   pyro    Minh Giáo  glass cannon- +60% burn & might, eats 15% more damage
##   ranger  Đường Môn  darter      - +100% pierce & +35% attack speed, slash -50%
##   mage    Nga Mi     vampiric    - +25% lifesteal & a healing finisher, -15% damage
##   beggar  Cái Bang   brawler     - +40% AoE & +30% dodge, -20 Max HP
##
## The ids stay ranger/mage rather than the spec's tang/emei: selected_character
## and every leaderboard "hero" row on disk use these strings.
const CHARACTERS: Dictionary = {
	"knight": {
		"id": "knight",
		"name": "Đoàn Kiếm (Sir Kaelen)",
		"title": "Tiêu Dao Kiếm Hiệp",
		"texture_path": "res://assets/textures/player.png",
		"starter_weapons": ["dagger", "slash"],
		"base_hp_bonus": 25.0,
		"armor_bonus": 2,
		"speed_bonus": 0.0,
		"magnet_bonus": 0.0,
		"might_bonus": 0.10,
		"speed_mult": 1.10,
		"xp_mult": 1.0,
		"skill_id": "shield_charge",
		"skill_name": "Ngự Kiếm Trùng Kích",
		"skill_icon": "🛡️",
		"skill_desc": "Lướt tới húc văng quái gây 45 ST kèm 0.9s hộ thể bất tử",
		"description": "Truyền nhân Tiêu Dao phái ngự khí hộ thân.\n⚔️ Khởi đầu: Độc Cô Cửu Kiếm & Phi Đao\n🛡️ Tuyệt kỹ: Ngự Kiếm Trùng Kích (SPACE)\n⚖️ Thiên phú: +10% Sức Mạnh, +10% Tốc Độ — vạn võ đều dùng được"
	},
	"pyro": {
		"id": "pyro",
		"name": "Ignis - Viêm Chưởng",
		"title": "Minh Giáo Liệt Hỏa",
		"texture_path": "res://assets/textures/hero_pyro.png",
		"starter_weapons": ["fireball", "lightning"],
		"base_hp_bonus": 10.0,
		"armor_bonus": 0,
		"speed_bonus": 0.0,
		"magnet_bonus": 0.0,
		"might_bonus": 0.60,
		"burn_mult": 1.60,
		"damage_taken_mult": 1.15,
		"xp_mult": 1.0,
		"skill_id": "inferno_blink",
		"skill_name": "Liệt Diễm Độn Thuật",
		"skill_icon": "🔥",
		"skill_desc": "Dịch chuyển tức thời để lại vòng xoáy lửa thiêu 70 ST",
		"description": "Thánh Hỏa Minh Giáo thiêu đốt vạn ma.\n🔥 Khởi đầu: Liệt Hỏa Chưởng Cầu & Cửu Thiên Lôi\n💥 Tuyệt kỹ: Liệt Diễm Độn Thuật (SPACE)\n🔥 Thiên phú: +60% Thiêu Đốt, +60% Sức Mạnh\n💀 Đánh đổi: chịu thêm 15% sát thương"
	},
	"ranger": {
		"id": "ranger",
		"name": "Đường Ảnh (Zephyr)",
		"title": "Đường Môn Thích Khách",
		"texture_path": "res://assets/textures/hero_ranger.png",
		"starter_weapons": ["dagger"],
		"base_hp_bonus": 0.0,
		"armor_bonus": 0,
		"speed_bonus": 45.0,
		"magnet_bonus": 0.0,
		"might_bonus": 0.10,
		"attack_speed_bonus": 0.35,
		"piercing_bonus": 1,
		"slash_damage_mult": 0.50,
		"xp_mult": 1.0,
		"skill_id": "shadow_roll",
		"skill_name": "Thất Tinh Độn Bộ",
		"skill_icon": "💨",
		"skill_desc": "Lộn nhào né đòn đồng thời bắn 10 phi kim tỏa tròn",
		"description": "Sát thủ Tứ Xuyên Đường Môn thiên hạ vô song.\n🪓 Khởi đầu: Ám Khí Phi Đao\n💨 Tuyệt kỹ: Thất Tinh Độn Bộ (SPACE)\n🗡️ Thiên phú: Phi Đao xuyên thêm 1 mục tiêu, +35% Tốc Đánh\n⚠️ Đánh đổi: kiếm cận chỉ còn 50% sát thương"
	},
	"mage": {
		"id": "mage",
		"name": "Thanh Loan (Morrigan)",
		"title": "Nga Mi Tiên Tử",
		"texture_path": "res://assets/textures/hero_mage.png",
		"starter_weapons": ["shield", "slash"],
		"base_hp_bonus": 0.0,
		"armor_bonus": 0,
		"speed_bonus": 0.0,
		"magnet_bonus": 60.0,
		"might_bonus": 0.15,
		"lifesteal_bonus": 0.25,
		"combo_heal": 5.0,
		"damage_mult": 0.85,
		"xp_mult": 1.20,
		"skill_id": "frost_singularity",
		"skill_name": "Huyền Băng Định Thân",
		"skill_icon": "❄️",
		"skill_desc": "Đóng băng toàn bộ kẻ địch 280px trong 2.4s và gây 35 ST",
		"description": "Nga Mi chân truyền khống chế huyền băng và thiên lôi.\n🛡️ Khởi đầu: Khiên Bát Quái & Độc Cô Cửu Kiếm\n❄️ Tuyệt kỹ: Huyền Băng Định Thân (SPACE)\n🩸 Thiên phú: +25% Hút Sinh Lực, Cửu Kiếm Quy Tông hồi 5 Máu\n⚠️ Đánh đổi: -15% Sát Thương nền"
	},
	"beggar": {
		"id": "beggar",
		"name": "Tiêu Lãng",
		"title": "Cái Bang Chưởng Môn",
		"texture_path": "res://assets/textures/hero_beggar.png",
		"starter_weapons": ["axe"],
		"base_hp_bonus": -20.0,
		"armor_bonus": 1,
		"speed_bonus": 30.0,
		"magnet_bonus": 25.0,
		"might_bonus": 0.15,
		"dodge_bonus": 0.30,
		"area_of_effect_bonus": 0.40,
		"xp_mult": 1.10,
		"skill_id": "drunken_brew",
		"skill_name": "Say Rượu Bát Tiên",
		"skill_icon": "🍶",
		"skill_desc": "Uống Rượu Tiên: +40% Né Đòn & +50% Tốc Đánh trong 6.0s",
		"description": "Lãng tử Cái Bang tiêu dao tự tại.\n🪓 Khởi đầu: Đả Cẩu Rìu Trận\n🍶 Tuyệt kỹ: Say Rượu Bát Tiên (SPACE)\n💥 Thiên phú: +40% Phạm Vi Diện Rộng, +30% Né Đòn\n⚠️ Đánh đổi: -20 Máu Tối Đa"
	}
}

var meta_upgrades: Dictionary = {
	"might": 0,      # +10% Damage per level
	"vitality": 0,   # +25 Max HP per level
	"swiftness": 0,  # +20 Move Speed per level
	"magnetism": 0,  # +30 Magnet Radius per level
	"pyro": 0,       # +12% AoE Radius per level
	"armor": 0       # -1 Damage Taken per level
}

# Martial Companions (Linh Thú)
var selected_companion: String = "dragon_whelp"
const COMPANIONS: Dictionary = {
	"dragon_whelp": {
		"id": "dragon_whelp",
		"name": "Tiểu Kim Long",
		"icon": "🐉",
		"desc": "Chi Dragon Orbs & Gem Magnet"
	},
	"white_tiger": {
		"id": "white_tiger",
		"name": "Bạch Hổ Thần Thú",
		"icon": "🐅",
		"desc": "Pounce Cleave & Coin Snatcher"
	}
}

# Hệ Thống Kinh Mạch (Meridian Cultivation)
var meridian_upgrades: Dictionary = {
	"nham_mach": 0,  # +30 Qi Shield & +1.5 HP/s Regen per level
	"doc_mach": 0,   # +7% Crit Chance & +35% Crit Damage per level
	"xung_mach": 0,  # +15 Move Speed & -10% Skill Cooldown per level
	"dan_dien": 0    # +30% Dragon Soul Harvest & +20% AoE per level
}

const MAX_MERIDIAN_LEVEL: int = 5
const MERIDIAN_BASE_COST: int = 70
const MERIDIANS: Dictionary = {
	"nham_mach": {
		"id": "nham_mach",
		"name": "Nhâm Mạch (Âm Nhu)",
		"icon": "☯️",
		"desc": "+30 Qi Shield & +1.5 HP/s Regen"
	},
	"doc_mach": {
		"id": "doc_mach",
		"name": "Đốc Mạch (Dương Cương)",
		"icon": "⚡",
		"desc": "+7% Crit Chance & +35% Crit DMG"
	},
	"xung_mach": {
		"id": "xung_mach",
		"name": "Xung Mạch (Thân Pháp)",
		"icon": "💨",
		"desc": "+15 Move Speed & -10% Cooldown"
	},
	"dan_dien": {
		"id": "dan_dien",
		"name": "Đan Điền (Tụ Khí)",
		"icon": "🐉",
		"desc": "+30% Dragon Soul & +20% AoE"
	}
}

const MAX_META_LEVEL: int = 5
const BASE_COSTS: Dictionary = {
	"might": 50,
	"vitality": 40,
	"swiftness": 40,
	"magnetism": 35,
	"pyro": 45,
	"armor": 60
}

var is_run_active: bool = false
var has_revived_this_run: bool = false

const SAVE_PATH: String = "user://save_data.cfg"

func get_selected_character_data() -> Dictionary:
	return CHARACTERS.get(selected_character, CHARACTERS["knight"])

func select_character(char_id: String) -> void:
	if CHARACTERS.has(char_id):
		selected_character = char_id
		save_game_data()
		emit_signal("character_selected", char_id)

func select_stage(stage_id: String) -> void:
	if STAGES.has(stage_id):
		selected_stage = stage_id
		save_game_data()
		emit_signal("stage_selected", stage_id)

func get_selected_stage_data() -> Dictionary:
	return STAGES.get(selected_stage, STAGES["plains"])

func equip_gear(slot: String, gear_id: String) -> bool:
	if not equipment_slots.has(slot):
		return false
	if gear_id != "" and not EQUIPMENT_CATALOG.has(gear_id):
		return false
	equipment_slots[slot] = gear_id
	save_game_data()
	emit_signal("equipment_updated", slot, gear_id)
	var p = get_tree().get_first_node_in_group("player")
	if p and p.has_method("refresh_meta_stats"):
		p.refresh_meta_stats()
	return true

func has_equipped(gear_id: String) -> bool:
	for slot in equipment_slots:
		if equipment_slots[slot] == gear_id:
			return true
	return false

func get_equipped_gear(slot: String) -> Dictionary:
	var gear_id = equipment_slots.get(slot, "")
	if gear_id != "" and EQUIPMENT_CATALOG.has(gear_id):
		return EQUIPMENT_CATALOG[gear_id]
	return {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_save_data()

func _process(delta: float) -> void:
	if is_run_active and not get_tree().paused:
		run_time += delta
		emit_signal("score_updated", kills, run_time)
		
		# 8-Minute Web Run: Climax & Victory Trigger
		if not is_endless_mode and not is_victory_triggered and run_time >= MAX_RUN_TIME:
			trigger_victory()
		
		# Blood moon timer countdown
		if is_blood_moon:
			blood_moon_timer -= delta
			if blood_moon_timer <= 0.0:
				is_blood_moon = false
				emit_signal("blood_moon_ended")
				if CodexManager:
					CodexManager.report_stat("blood_moon", 1)
		
		# Process time-based bounties and codex time
		if CodexManager and int(run_time) % 5 == 0:
			CodexManager.report_stat("time", int(run_time))
		for b in active_bounties:
			if not b["completed"] and b["target_type"] == "time":
				b["current"] = int(run_time)
				if b["current"] >= b["target"]:
					b["completed"] = true
					add_gold(b["reward_gold"])
					emit_signal("bounty_completed", b)
					SoundManager.play("powerup")
					emit_signal("bounty_updated", active_bounties)

func trigger_blood_moon(duration: float = 30.0) -> void:
	is_blood_moon = true
	blood_moon_timer = duration
	emit_signal("blood_moon_started", duration)

func trigger_victory() -> void:
	if is_victory_triggered:
		return
	is_victory_triggered = true
	add_gold(1000)
	if CodexManager:
		CodexManager.report_stat("time", int(run_time))
	var stats = {
		"time": run_time,
		"kills": kills,
		"gold": run_gold,
		"total_gold": total_gold,
		"character": selected_character,
		"stage": selected_stage
	}
	end_run(true)
	emit_signal("victory_achieved", stats)

func enter_endless_mode() -> void:
	is_endless_mode = true
	is_run_active = true
	get_tree().paused = false

var _hitstop_timer: float = 0.0

func trigger_hitstop(duration: float = 0.038, scale: float = 0.05) -> void:
	if Engine.is_editor_hint():
		return
	if _hitstop_timer > 0.0:
		return
	_hitstop_timer = duration
	Engine.time_scale = scale
	var tree = get_tree()
	if tree:
		var timer = tree.create_timer(duration, true, false, true)
		timer.timeout.connect(func():
			Engine.time_scale = 1.0
			_hitstop_timer = 0.0
		)

func start_new_run() -> void:
	Engine.time_scale = 1.0
	_hitstop_timer = 0.0
	run_time = 0.0
	kills = 0
	run_gold = 0
	is_blood_moon = false
	blood_moon_timer = 0.0
	has_revived_this_run = false
	is_endless_mode = false
	is_victory_triggered = false
	discovered_landmarks.clear()
	collected_relics.clear()
	dragon_pearls_collected = 0
	collected_scrolls.clear()
	shenron_wishes_used = 0
	for weapon_id in weapon_damage_stats.keys():
		weapon_damage_stats[weapon_id] = 0.0
	reached_kill_milestones.clear()
	is_run_active = true
	get_tree().paused = false
	init_run_bounties()
	emit_signal("run_started")
	emit_signal("gold_updated", total_gold)

func has_relic(relic_id: String) -> bool:
	return collected_relics.has(relic_id)

func add_relic(relic_id: String) -> bool:
	if not RELICS.has(relic_id) or collected_relics.has(relic_id):
		return false
	collected_relics.append(relic_id)
	emit_signal("relic_collected", relic_id, RELICS[relic_id])
	var p = get_tree().get_first_node_in_group("player")
	if p and p.has_method("apply_relic_effects"):
		p.apply_relic_effects()
	return true

func collect_dragon_pearl() -> bool:
	if dragon_pearls_collected >= 7:
		return false
	dragon_pearls_collected += 1
	SoundManager.play("powerup", 0.1)
	emit_signal("dragon_pearl_collected", dragon_pearls_collected, 7)
	if dragon_pearls_collected == 7:
		SoundManager.play("dragon_wish")
		emit_signal("shenron_summon_ready")
		if CodexManager:
			CodexManager.report_stat("pearls", 7)
	return true

func has_scroll(scroll_id: String) -> bool:
	return collected_scrolls.has(scroll_id)

func add_scroll(scroll_id: String) -> bool:
	if not MARTIAL_SCROLLS.has(scroll_id) or collected_scrolls.has(scroll_id):
		return false
	collected_scrolls.append(scroll_id)
	SoundManager.play("powerup")
	emit_signal("scroll_collected", scroll_id)
	var p = get_tree().get_first_node_in_group("player")
	if p and p.has_method("apply_scroll_effects"):
		p.apply_scroll_effects()
	return true

func select_shenron_wish(wish_id: String) -> void:
	if not SHENRON_WISHES.has(wish_id):
		return
	shenron_wishes_used += 1
	SoundManager.play("dragon_wish")
	emit_signal("shenron_wish_selected", wish_id)
	var p = get_tree().get_first_node_in_group("player")
	if p and p.has_method("apply_shenron_wish"):
		p.apply_shenron_wish(wish_id)

func init_run_bounties() -> void:
	active_bounties = [
		{
			"id": "slay_bats",
			"title": "Bat Hunter",
			"desc": "Slay 25 Bats",
			"target_type": "kill_bat",
			"current": 0,
			"target": 25,
			"reward_gold": 40,
			"completed": false
		},
		{
			"id": "survive_time",
			"title": "Iron Resolve",
			"desc": "Survive 2 Minutes",
			"target_type": "time",
			"current": 0,
			"target": 120,
			"reward_gold": 60,
			"completed": false
		},
		{
			"id": "defeat_champion",
			"title": "Champion Slayer",
			"desc": "Slay an Elite Champion",
			"target_type": "kill_champion",
			"current": 0,
			"target": 1,
			"reward_gold": 80,
			"completed": false
		},
		{
			"id": "defeat_goblin",
			"title": "Greed Hunter",
			"desc": "Slay a Treasure Goblin",
			"target_type": "kill_goblin",
			"current": 0,
			"target": 1,
			"reward_gold": 90,
			"completed": false
		}
	]
	emit_signal("bounty_updated", active_bounties)

func record_bounty_event(event_type: String, amount: int = 1) -> void:
	var any_completed = false
	for b in active_bounties:
		if b["completed"]:
			continue
		if b["target_type"] == event_type:
			b["current"] = min(b["target"], b["current"] + amount)
			if b["current"] >= b["target"]:
				b["completed"] = true
				add_gold(b["reward_gold"])
				emit_signal("bounty_completed", b)
				SoundManager.play("powerup")
				any_completed = true
	if any_completed or amount > 0:
		emit_signal("bounty_updated", active_bounties)

func is_landmark_discovered(id: String) -> bool:
	return discovered_landmarks.has(id)

func discover_landmark(id: String, name: String) -> void:
	if not discovered_landmarks.has(id):
		discovered_landmarks[id] = true
		emit_signal("landmark_discovered", id, name)

func add_kill(enemy_type: String = "", is_champ: bool = false) -> void:
	kills += 1
	emit_signal("score_updated", kills, run_time)
	_check_kill_milestones()

	# Relic: Vampire Fang heal every 10 kills
	if has_relic("vampire_fang") and kills % 10 == 0:
		var p = get_tree().get_first_node_in_group("player")
		if p and p.has_method("heal"):
			p.heal(3.0)
			FloatingText.spawn(p.global_position, "+3 HP (Fang)", Color(0.9, 0.2, 0.3))
			
	# Bounty tracking
	if enemy_type == "bat":
		record_bounty_event("kill_bat", 1)
	if enemy_type == "goblin":
		record_bounty_event("kill_goblin", 1)
	if is_champ:
		record_bounty_event("kill_champion", 1)

# --- Expansion 21.0: Chiến Tích Bảng (Weapon Damage Tracking & DPS Breakdown) --

## Every damage-dealing weapon calls this at the exact point it hurts an enemy,
## so the ledger totals always match what the player actually dealt.
func record_weapon_damage(weapon_id: String, amount: float) -> void:
	weapon_damage_stats[weapon_id] = float(weapon_damage_stats.get(weapon_id, 0.0)) + amount

func get_total_weapon_damage() -> float:
	var total: float = 0.0
	for weapon_id in weapon_damage_stats.keys():
		total += float(weapon_damage_stats[weapon_id])
	return total

## Damage-sorted rows for the end-of-run report. Weapons that never landed a
## hit are omitted rather than shown as 0.0% noise.
func get_weapon_dps_breakdown() -> Array[Dictionary]:
	var total = get_total_weapon_damage()
	var elapsed = max(1.0, run_time)
	var rows: Array[Dictionary] = []
	for weapon_id in weapon_damage_stats.keys():
		var dmg = float(weapon_damage_stats[weapon_id])
		if dmg <= 0.0:
			continue
		rows.append({
			"id": weapon_id,
			"name": WEAPON_DISPLAY_NAMES.get(weapon_id, weapon_id),
			"damage": dmg,
			"percent": (dmg / total * 100.0) if total > 0.0 else 0.0,
			"dps": dmg / elapsed
		})
	rows.sort_custom(func(a, b): return float(a["damage"]) > float(b["damage"]))
	return rows

func get_combat_rank() -> String:
	var dps = get_total_weapon_damage() / max(1.0, run_time)
	if dps >= 800.0 or kills >= 300:
		return "S"
	if dps >= 450.0 or kills >= 150:
		return "A"
	if dps >= 200.0 or kills >= 60:
		return "B"
	return "C"

# --- Expansion 21.0: Bảo Rương Kim Quy (Cinematic Treasure Chest) -------------

## Rolls the jackpot tier, auto-applies the upgrades, pays the gold, freezes the
## run and emits `chest_opened` for the HUD ceremony. Returns the same payload.
func open_treasure_chest(_player_ref: Node2D = null) -> Dictionary:
	var roll = randf()
	var jackpot: Dictionary = CHEST_JACKPOTS[CHEST_JACKPOTS.size() - 1]
	var acc: float = 0.0
	for entry in CHEST_JACKPOTS:
		acc += float(entry["chance"])
		if roll < acc:
			jackpot = entry
			break

	var tier: int = int(jackpot["tier"])
	var gold: int = int(jackpot["gold"])

	var upgrade_mgr = get_tree().get_first_node_in_group("upgrade_manager")
	var pool: Array[Dictionary] = []
	if upgrade_mgr and upgrade_mgr.has_method("get_upgrade_catalog"):
		pool = upgrade_mgr.get_upgrade_catalog()
	pool.shuffle()

	var chosen: Array[Dictionary] = []
	for i in range(mini(int(jackpot["upgrades"]), pool.size())):
		chosen.append(pool[i])
	for item in chosen:
		upgrade_mgr.select_upgrade(item)

	add_gold(gold)
	# select_upgrade() unpauses the tree, so re-freeze for the ceremony.
	get_tree().paused = true

	emit_signal("chest_opened", tier, chosen, gold)
	return {"tier": tier, "upgrades": chosen, "gold": gold}

# --- Expansion 21.0: Vạn Nhân Trảm (Kill Streak Rampage) ----------------------

func _check_kill_milestones() -> void:
	for milestone in KILL_MILESTONES:
		if kills < milestone or reached_kill_milestones.has(milestone):
			continue
		reached_kill_milestones.append(milestone)
		emit_signal("kill_milestone_reached", milestone, KILL_MILESTONE_TITLES.get(milestone, ""))
		var p = get_tree().get_first_node_in_group("player")
		if p and p.has_method("activate_blood_rush"):
			p.activate_blood_rush(5.0)

func add_gold(amount: int) -> void:
	var final_amount = amount
	if has_relic("golden_horseshoe"):
		final_amount = int(float(amount) * 1.5)
	if is_blood_moon:
		final_amount *= 2
	var p = get_tree().get_first_node_in_group("player")
	if p and "golden_frenzy_timer" in p and p.golden_frenzy_timer > 0.0:
		final_amount *= 2
	if CodexManager and CodexManager.bonus_gold_drop_mult > 1.0:
		final_amount = int(float(final_amount) * CodexManager.bonus_gold_drop_mult)
		
	run_gold += final_amount
	total_gold += final_amount
	save_game_data()
	emit_signal("gold_updated", total_gold)
	if CodexManager:
		CodexManager.report_stat("total_gold", total_gold)

func double_run_gold() -> void:
	total_gold += run_gold
	run_gold *= 2
	save_game_data()
	emit_signal("gold_updated", total_gold)

func end_run(victory: bool) -> void:
	is_run_active = false
	save_game_data()
	emit_signal("run_ended", victory)

# Meta Upgrades API
func get_meta_stat(stat: String) -> int:
	return meta_upgrades.get(stat, 0)

func get_upgrade_cost(stat: String) -> int:
	var lvl = get_meta_stat(stat)
	if lvl >= MAX_META_LEVEL:
		return 999999
	var base = BASE_COSTS.get(stat, 50)
	return int(base * pow(1.8, lvl))

func buy_meta_upgrade(stat: String) -> bool:
	var cost = get_upgrade_cost(stat)
	var lvl = get_meta_stat(stat)
	if lvl < MAX_META_LEVEL and total_gold >= cost:
		total_gold -= cost
		meta_upgrades[stat] = lvl + 1
		save_game_data()
		emit_signal("gold_updated", total_gold)
		emit_signal("meta_upgraded", stat, meta_upgrades[stat])
		SoundManager.play("level_up")
		return true
	return false

func select_companion(comp_id: String) -> void:
	if COMPANIONS.has(comp_id):
		selected_companion = comp_id
		save_game_data()
		emit_signal("companion_changed", comp_id)

func get_meridian_stat(stat: String) -> int:
	return meridian_upgrades.get(stat, 0)

func get_meridian_cost(stat: String) -> int:
	var lvl = get_meridian_stat(stat)
	if lvl >= MAX_MERIDIAN_LEVEL:
		return 999999
	return int(MERIDIAN_BASE_COST * pow(1.75, lvl))

func buy_meridian_upgrade(stat: String) -> bool:
	var cost = get_meridian_cost(stat)
	var lvl = get_meridian_stat(stat)
	if lvl < MAX_MERIDIAN_LEVEL and total_gold >= cost:
		total_gold -= cost
		meridian_upgrades[stat] = lvl + 1
		save_game_data()
		emit_signal("gold_updated", total_gold)
		emit_signal("meridian_upgraded", stat, meridian_upgrades[stat])
		SoundManager.play("chi_meditate")
		
		# Refresh player stats if player is alive in scene
		var p = get_tree().get_first_node_in_group("player")
		if p and p.has_method("refresh_meta_stats"):
			p.refresh_meta_stats()
		return true
	return false

## Save/Load persistent meta-currency and upgrades with Web localStorage dual-persistence
func save_game_data() -> void:
	# 1. ConfigFile persistent save (Desktop / Local)
	var config = ConfigFile.new()
	config.set_value("player", "total_gold", total_gold)
	config.set_value("player", "selected_character", selected_character)
	config.set_value("player", "selected_companion", selected_companion)
	config.set_value("player", "selected_stage", selected_stage)
	config.set_value("player", "is_first_run", is_first_run)
	for slot in equipment_slots.keys():
		config.set_value("equipment", slot, equipment_slots[slot])
	for key in meta_upgrades.keys():
		config.set_value("meta_upgrades", key, meta_upgrades[key])
	for key in meridian_upgrades.keys():
		config.set_value("meridian_upgrades", key, meridian_upgrades[key])
	config.save(SAVE_PATH)
	
	# 2. Web localStorage instant synchronous save (HTML5 / Web portals / itch.io)
	if OS.has_feature("web"):
		var save_dict: Dictionary = {
			"total_gold": total_gold,
			"selected_character": selected_character,
			"selected_companion": selected_companion,
			"selected_stage": selected_stage,
			"equipment_slots": equipment_slots,
			"is_first_run": is_first_run,
			"meta_upgrades": meta_upgrades,
			"meridian_upgrades": meridian_upgrades
		}
		var json_str = JSON.stringify(save_dict)
		var escaped = json_str.c_escape()
		JavaScriptBridge.eval("try { localStorage.setItem('survivorquest_save_v1', '%s'); } catch(e) { console.error('Save failed:', e); }" % escaped)
		JavaScriptBridge.eval("try { if (typeof FS !== 'undefined' && FS.syncfs) { FS.syncfs(false, function(err){}); } } catch(e) {}")

func mark_first_run_completed() -> void:
	if is_first_run:
		is_first_run = false
		save_game_data()

func load_save_data() -> void:
	# 1. Try loading from Web localStorage first (synchronous & immune to IDBFS mounting races)
	if OS.has_feature("web"):
		var result = JavaScriptBridge.eval("try { localStorage.getItem('survivorquest_save_v1'); } catch(e) { null; }")
		if result != null and str(result) != "" and str(result) != "null":
			var parsed = JSON.parse_string(str(result))
			if parsed is Dictionary:
				if parsed.has("total_gold"):
					total_gold = int(parsed["total_gold"])
				if parsed.has("is_first_run"):
					is_first_run = bool(parsed["is_first_run"])
				if parsed.has("selected_character"):
					var c_id = str(parsed["selected_character"])
					if CHARACTERS.has(c_id):
						selected_character = c_id
				if parsed.has("selected_companion"):
					var p_id = str(parsed["selected_companion"])
					if COMPANIONS.has(p_id):
						selected_companion = p_id
				if parsed.has("selected_stage"):
					var s_id = str(parsed["selected_stage"])
					if STAGES.has(s_id):
						selected_stage = s_id
				if parsed.has("equipment_slots") and parsed["equipment_slots"] is Dictionary:
					for slot in equipment_slots.keys():
						if parsed["equipment_slots"].has(slot):
							equipment_slots[slot] = str(parsed["equipment_slots"][slot])
				if parsed.has("meta_upgrades") and parsed["meta_upgrades"] is Dictionary:
					for key in meta_upgrades.keys():
						if parsed["meta_upgrades"].has(key):
							meta_upgrades[key] = int(parsed["meta_upgrades"][key])
				if parsed.has("meridian_upgrades") and parsed["meridian_upgrades"] is Dictionary:
					for key in meridian_upgrades.keys():
						if parsed["meridian_upgrades"].has(key):
							meridian_upgrades[key] = int(parsed["meridian_upgrades"][key])
				print("[GameManager] Restored save from localStorage. Gold: ", total_gold, " Char: ", selected_character, " Comp: ", selected_companion, " Stage: ", selected_stage, " Gear: ", equipment_slots)
				return
				
	# 2. Fallback / Desktop ConfigFile load
	var config = ConfigFile.new()
	var err = config.load(SAVE_PATH)
	if err == OK:
		total_gold = config.get_value("player", "total_gold", total_gold)
		selected_character = config.get_value("player", "selected_character", "knight")
		selected_companion = config.get_value("player", "selected_companion", "dragon_whelp")
		selected_stage = config.get_value("player", "selected_stage", "plains")
		is_first_run = config.get_value("player", "is_first_run", true)
		for slot in equipment_slots.keys():
			equipment_slots[slot] = config.get_value("equipment", slot, equipment_slots.get(slot, ""))
		for key in meta_upgrades.keys():
			meta_upgrades[key] = config.get_value("meta_upgrades", key, meta_upgrades.get(key, 0))
		for key in meridian_upgrades.keys():
			meridian_upgrades[key] = config.get_value("meridian_upgrades", key, meridian_upgrades.get(key, 0))
		print("[GameManager] Restored save from ConfigFile. Gold: ", total_gold, " Char: ", selected_character, " Comp: ", selected_companion, " Stage: ", selected_stage, " Gear: ", equipment_slots)



