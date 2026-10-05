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
signal weapon_names_updated
signal danger_changed(level: int)

const MAX_RUN_TIME: float = 480.0 # 8-Minute Web Run (standalone survival only)
var is_endless_mode: bool = false
var is_victory_triggered: bool = false

## Milestone 3a — the danger ladder. Chosen before a run, persisted, and applied
## by EnemySpawner to every grunt it rolls. HP and speed multiply together on
## purpose: a tougher enemy that also closes faster is the only kind of harder
## that reads as harder, while `heal` and `score` shape the reward side so a high
## tier is worth surviving rather than merely avoiding.
const DANGER: Array[Dictionary] = [
	{"level": 0, "speed": 1.00, "hp": 1.00, "heal": 1.00, "score": 1.0, "elite": 0},
	{"level": 1, "speed": 1.12, "hp": 1.35, "heal": 0.92, "score": 1.6, "elite": 0},
	{"level": 2, "speed": 1.24, "hp": 1.70, "heal": 0.84, "score": 2.6, "elite": 1},
	{"level": 3, "speed": 1.36, "hp": 2.10, "heal": 0.76, "score": 4.2, "elite": 1},
	{"level": 4, "speed": 1.48, "hp": 2.55, "heal": 0.68, "score": 6.8, "elite": 2},
	{"level": 5, "speed": 1.60, "hp": 3.00, "heal": 0.60, "score": 11.0, "elite": 2}
]
const MAX_DANGER_LEVEL: int = 5
var danger_level: int = 0

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

## Milestone 3a: weapon names were a three-way mess -- the Vietnamese set here,
## a second variant in UpgradeManager.WEAPON_INFO, and a third in the HUD badges.
## Loc owns the single canonical row; this table is seeded from it in _ready() so
## the end-of-run dps report and the arsenal always read the same names.
var WEAPON_DISPLAY_NAMES: Dictionary = {}

## Mirrors Loc.STRINGS for the six weapon ids. Not a const because it is filled
## at _ready() from the active locale; before that it is empty and
## get_weapon_display_name() falls through to Loc.
func _seed_weapon_display_names() -> void:
	WEAPON_DISPLAY_NAMES.clear()
	for weapon_id in ["dagger", "shield", "lightning", "fireball", "axe", "slash"]:
		WEAPON_DISPLAY_NAMES[weapon_id] = Loc.weapon_name(weapon_id)
	if not Loc.locale_changed.is_connected(_on_locale_changed):
		Loc.locale_changed.connect(_on_locale_changed)

func _on_locale_changed(_new_locale: String) -> void:
	_seed_weapon_display_names()
	# The same re-seed, for the copy init_run_bounties() built once at run start.
	# Without this a player who switches language mid-run gets a pause panel that
	# has changed around four bounties which stayed in the language they began in.
	if not active_bounties.is_empty():
		for b in active_bounties:
			_localise_bounty(b)
		emit_signal("bounty_updated", active_bounties)
	emit_signal("weapon_names_updated")

## The canonical, localised display name for a weapon id.
func get_weapon_display_name(weapon_id: String) -> String:
	return WEAPON_DISPLAY_NAMES.get(weapon_id, Loc.weapon_name(weapon_id))

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
		"desc": "+3 HP mỗi khi hạ 10 kẻ địch",
		"color": Color(0.9, 0.2, 0.25)
	},
	"storm_amulet": {
		"id": "storm_amulet",
		"name": "Storm Amulet",
		"icon": "⚡",
		"desc": "25% cơ hội triệu hồi sấm sét bổ trợ khi trúng đòn",
		"color": Color(0.2, 0.85, 1.0)
	},
	"phoenix_feather": {
		"id": "phoenix_feather",
		"name": "Phoenix Feather",
		"icon": "🪶",
		"desc": "Hồi sinh với 40% Máu Tối Đa & nổ tung kẻ địch (1 lần/trận)",
		"color": Color(1.0, 0.5, 0.1)
	},
	"golden_horseshoe": {
		"id": "golden_horseshoe",
		"name": "Golden Horseshoe",
		"icon": "👑",
		"desc": "+50% Vàng rơi & +60 Bán kính Hút Ngọc",
		"color": Color(1.0, 0.85, 0.2)
	},
	"berserker_brand": {
		"id": "berserker_brand",
		"name": "Berserker Brand",
		"icon": "🔥",
		"desc": "+50% Sát Thương khi Máu dưới 40%",
		"color": Color(1.0, 0.3, 0.15)
	},
	"chrono_hourglass": {
		"id": "chrono_hourglass",
		"name": "Chrono Hourglass",
		"icon": "⏳",
		"desc": "Giảm 20% Thời Gian Hồi Chiêu",
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
		"desc": "Bão Thần Kiếm thiên hà giáng liên tục 20s: mỗi kiếm xuyên 5 mục tiêu, bão đao bào phá diện rộng!",
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
		"desc": "Bắn Chi Long Ngọc & Hút Nam Châm"
	},
	"white_tiger": {
		"id": "white_tiger",
		"name": "Bạch Hổ Thần Thú",
		"icon": "🐅",
		"desc": "Nhảy Liền Cắt & Tự Thu Vàng"
	}
}

# Hệ Thống Kinh Mạch (Meridian Cultivation)
var meridian_upgrades: Dictionary = {
	"nham_mach": 0,  # +30 Khí Thuẫn & +1.5 HP/s Hồi Phục mỗi cấp
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
		"desc": "+30 Khí Thuẫn & +1.5 HP/s Hồi Phục"
	},
	"doc_mach": {
		"id": "doc_mach",
		"name": "Đốc Mạch (Dương Cương)",
		"icon": "⚡",
		"desc": "+7% Tỷ Lệ Bạo Kích & +35% Sức Bạo Kích"
	},
	"xung_mach": {
		"id": "xung_mach",
		"name": "Xung Mạch (Thân Pháp)",
		"icon": "💨",
		"desc": "+15 Tốc Độ Di Chuyển & -10% Thời Gian Hồi Chiêu"
	},
	"dan_dien": {
		"id": "dan_dien",
		"name": "Đan Điền (Tụ Khí)",
		"icon": "🐉",
		"desc": "+30% Linh Hồn Rồng & +20% Phạm Vi AoE"
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
## The rewarded-ad doubling is the second claim the game-over panel offers, and it
## needed the same guard revive got. It had none: double_run_gold() paid out and
## doubled with nothing recording that it had been paid, and hud.gd re-enabled the
## button from inside the very callback that disabled it, so one ad view bought a
## button that stayed live and the repeats compounded. Per-run, like has_revived.
var has_doubled_gold_this_run: bool = false

const SAVE_PATH: String = "user://save_data.cfg"

## Task 4 (Emscripten web save-sync guard): true from the moment FS.syncfs() is
## issued until its JS callback reports completion. save_game_data() is reached
## from a dozen writers inside one run -- every add_gold(), every purchase, every
## stage pick -- and FS.syncfs is asynchronous, so two overlapping calls make
## Emscripten print "warning: 2 FS.syncfs operations in flight at once". Nothing
## waited on the previous call because the callback form was fire-and-forget:
## nobody held the handle, so nobody knew a sync was outstanding.
var is_syncing_filesystem: bool = false
## A save was written while that sync was still running. The follower is ONE sync,
## not one per save: it flushes the state as of the last write, so a burst of ten
## saves costs two syncs and still lands the final state in IndexedDB.
var _pending_filesystem_sync: bool = false
## How many syncs this autoload has actually issued. Nothing in production reads
## it; tests/test_expansion_63.gd reads it, because "at most one in flight" is
## otherwise only observable from inside a browser.
var filesystem_syncs_issued: int = 0
## The JS handle to _on_filesystem_sync_done. Kept for the same reason ad_manager.gd
## keeps its SDK handles: a callback JavaScript is meant to call has to stay
## referenced from GDScript, or it is collected and the completion never arrives.
var _filesystem_sync_done_cb: JavaScriptObject = null

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
	_seed_weapon_display_names()

## Milestone 3a. A Võ Đài run is not on a clock -- it is won by clearing wave 20
## (or slaying the Demon Emperor), which WaveDirector calls itself. The 480s
## ceiling only applies to a standalone survival run, where it is the win
## condition. Previously both paths ran the same check, so a wave-arena player
## hit wave 14 and was handed a victory screen mid-fight.
func is_wave_arena() -> bool:
	var tree := get_tree()
	if tree == null:
		return false
	return tree.get_first_node_in_group("wave_director") != null

func get_danger_data() -> Dictionary:
	return DANGER[clampi(danger_level, 0, MAX_DANGER_LEVEL)]

func set_danger_level(level: int) -> void:
	var clamped := clampi(level, 0, MAX_DANGER_LEVEL)
	if clamped == danger_level:
		return
	danger_level = clamped
	save_game_data()
	emit_signal("danger_changed", danger_level)

## Human-readable label for the current tier, localised and scaled -- the same
## string the character-select row shows and the test asserts on.
func get_danger_name() -> String:
	return Loc.t("danger.%d.name" % danger_level, "Novice")

func _process(delta: float) -> void:
	# Ahead of the run block so a freeze always releases, even with no run live.
	_update_hitstop()

	if is_run_active and not get_tree().paused:
		run_time += delta
		emit_signal("score_updated", kills, run_time)

		# 8-Minute Web Run: Climax & Victory Trigger. Suppressed in the Võ Đài,
		# where the director owns the victory condition.
		if not is_endless_mode and not is_victory_triggered and not is_wave_arena() and run_time >= MAX_RUN_TIME:
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

## Milestone 4 Part 2 -- impact hit-stop. Engine.time_scale is global engine
## state, so exactly ONE node owns it. Callers ask this autoload for a freeze;
## they never touch time_scale themselves, which is what keeps a node freed
## mid-impact (the enemy that just died, the player) from stranding the engine
## at 0.15 forever.
var _hitstop_timer: float = 0.0
var _hitstop_until_msec: int = 0

## Depth floor for every in-game freeze. Below ~0.2 the engine stops dead
## instead of punching, and in the browser that reads as a tab freeze rather
## than an impact -- see the Milestone 3b boss-hitstop guard in
## test_web_perf_milestone_3b.gd, which fails below 0.2.
const HITSTOP_SCALE: float = 0.2

func trigger_hitstop(duration: float = 0.075, scale: float = HITSTOP_SCALE) -> void:
	if Engine.is_editor_hint():
		return
	# Re-entrancy: one live freeze owns the scale outright. A second impact
	# arriving mid-freeze is dropped rather than stacked, so a swarm of
	# simultaneous hits can neither deepen the dip nor push the release out.
	if _hitstop_timer > 0.0:
		return
	_hitstop_timer = duration
	_hitstop_until_msec = Time.get_ticks_msec() + int(duration * 1000.0)
	Engine.time_scale = scale

## The release is a wall-clock deadline, NOT a Timer or create_timer(): those
## tick on scaled time, so every retrigger would slide the deadline further
## out and the freeze would never end. Time.get_ticks_msec() keeps running at
## 0.15, so one check per frame is enough and the dip lasts the requested
## wall-clock duration no matter how slow the frozen frames are.
func _update_hitstop() -> void:
	if _hitstop_timer <= 0.0:
		return
	if Time.get_ticks_msec() < _hitstop_until_msec:
		return
	_release_hitstop()

## Idempotent. Safe to call with no freeze live, and safe to call from the
## predelete backstop below.
func _release_hitstop() -> void:
	_hitstop_timer = 0.0
	_hitstop_until_msec = 0
	if Engine.time_scale < 1.0:
		Engine.time_scale = 1.0

## Backstop for "never leave time_scale below 1.0". If the owner is ever torn
## down while a freeze is live, the engine goes back to full speed instead of
## running the rest of the session in slow motion. PREDELETE fires on free()
## whether or not the node was ever added to the tree.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_release_hitstop()

func start_new_run() -> void:
	Engine.time_scale = 1.0
	_hitstop_timer = 0.0
	run_time = 0.0
	kills = 0
	run_gold = 0
	is_blood_moon = false
	blood_moon_timer = 0.0
	has_revived_this_run = false
	has_doubled_gold_this_run = false
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
	# No apply pass here: the three Võ Học Bí Tịch read GameManager.has_scroll()
	# from Player._physics_process, so a collected scroll starts ticking on the
	# next frame. This used to call an empty Player.apply_scroll_effects().
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
			"target_type": "kill_bat",
			"current": 0,
			"target": 25,
			"reward_gold": 40,
			"completed": false
		},
		{
			"id": "survive_time",
			"target_type": "time",
			"current": 0,
			"target": 120,
			"reward_gold": 60,
			"completed": false
		},
		{
			"id": "defeat_champion",
			"target_type": "kill_champion",
			"current": 0,
			"target": 1,
			"reward_gold": 80,
			"completed": false
		},
		{
			"id": "defeat_goblin",
			"target_type": "kill_goblin",
			"current": 0,
			"target": 1,
			"reward_gold": 90,
			"completed": false
		}
	]
	for b in active_bounties:
		_localise_bounty(b)
	emit_signal("bounty_updated", active_bounties)

## The four title/desc pairs used to be English literals in the dict above, and
## were the standing exemption in test_untranslated_copy.gd. They are filled from
## Loc at build time rather than read through Loc at every print site, so the
## string still lives in exactly one place and the existing `b["title"]` readers
## in hud.gd and Expansion 29.0's suite keep working unchanged.
func _localise_bounty(b: Dictionary) -> void:
	var id: String = b["id"]
	b["title"] = Loc.t("bounty.%s.title" % id, id)
	b["desc"] = Loc.t("bounty.%s.desc" % id, "")

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

## is_elite_champ credits the bounty.defeat_champion row, which advertises an Elite
## Champion. It was named is_champ and fed is_champion, and those are siblings rather
## than a nesting: make_champion() sets is_champion, make_elite_champion() sets
## is_elite_champion and never touches the other. So the flag credited ordinary affix
## champions and not the elite ones the text promises. Renamed at the boundary because
## is_champ is exactly the near-miss that produced that inversion.
func add_kill(enemy_type: String = "", is_elite_champ: bool = false) -> void:
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
	if is_elite_champ:
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
			"name": get_weapon_display_name(weapon_id),
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
		emit_signal("kill_milestone_reached", milestone, Loc.t("hud.streak_%d" % milestone, KILL_MILESTONE_TITLES.get(milestone, "")))
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

## Gold that belongs to the meta layer rather than to the run in progress -- a
## once-a-day Daily Trial payout, not a coin picked up mid-arena. The single
## difference from add_gold() above is that it skips run_gold on purpose: run_gold
## is what the end-of-run Double Gold rewarded ad doubles, and the golden_horseshoe
## / Blood Moon / Codex multipliers in add_gold() are meant for loot that dropped
## while those conditions were live. Routing a flat daily reward through add_gold()
## would scale it by whatever relics the finished run happened to hold, and would
## hand the player a second doubling of the same 600 for the price of an ad.
func add_meta_gold(amount: int) -> void:
	if amount <= 0:
		return
	total_gold += amount
	save_game_data()
	emit_signal("gold_updated", total_gold)
	if CodexManager:
		CodexManager.report_stat("total_gold", total_gold)

## The claim guard lives here rather than in the HUD, because the flag and the gold
## have to move together. hud.gd used to grey the button out inside the ad callback
## and then call _on_player_died(), which set disabled = false again one line later --
## so nothing held the claim except a button that undid its own guard. This is the
## same shape as the codex reward guards: a function you can call twice must decide
## for itself, because it cannot know whether a button was drawn correctly.
func double_run_gold() -> void:
	if has_doubled_gold_this_run:
		return
	has_doubled_gold_this_run = true
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
	config.set_value("player", "danger_level", danger_level)
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
			"danger_level": danger_level,
			"meta_upgrades": meta_upgrades,
			"meridian_upgrades": meridian_upgrades
		}
		var json_str = JSON.stringify(save_dict)
		var escaped = json_str.c_escape()
		JavaScriptBridge.eval("try { localStorage.setItem('survivorquest_save_v1', '%s'); } catch(e) { console.error('Save failed:', e); }" % escaped)
		# The async IDB flush, not the localStorage write above, is what overlaps.
		# Every one of the twelve writers in this file lands here, so the guard
		# lives at the call site rather than in each writer.
		_request_web_filesystem_sync()

## Task 4: the one and only FS.syncfs() call site, so no new save writer can
## bypass the guard by issuing its own sync.
func _request_web_filesystem_sync() -> void:
	if not _claim_filesystem_sync_slot():
		return  # a sync is already running; _pending_filesystem_sync now records it
	if _filesystem_sync_done_cb == null:
		_filesystem_sync_done_cb = JavaScriptBridge.create_callback(_on_filesystem_sync_done)
	var window = JavaScriptBridge.get_interface("window")
	window.SurvivorQuest_syncfs_done = _filesystem_sync_done_cb
	# The trailing call is not a native fallback -- this function is only reached
	# behind OS.has_feature("web"). It is what keeps the guard convergent: when FS
	# is missing the try/catch swallows that, no callback would ever fire, and a
	# slot held forever would silently disable every later flush.
	JavaScriptBridge.eval("""
		(function () {
			try {
				if (typeof FS !== 'undefined' && FS.syncfs) { FS.syncfs(false, window.SurvivorQuest_syncfs_done); return; }
			} catch (e) {}
			window.SurvivorQuest_syncfs_done();
		})();
	""")

## FS.syncfs() completion. Exactly one Array parameter, because a
## JavaScriptBridge callback is always invoked with its JS arguments collected into
## a single Array -- a callable of any other shape is never called at all, which
## would leave the slot held and stall every save that follows.
func _on_filesystem_sync_done(_args: Array) -> void:
	if _release_filesystem_sync_slot():
		_request_web_filesystem_sync()

## Claim the sync slot. True means the caller owns it and must issue the sync;
## false means one is already in flight and the request has been recorded pending.
func _claim_filesystem_sync_slot() -> bool:
	if is_syncing_filesystem:
		_pending_filesystem_sync = true
		return false
	is_syncing_filesystem = true
	filesystem_syncs_issued += 1
	return true

## Release the slot after a sync reports completion, and report whether the caller
## still owes one follower. Returns true only when a save arrived mid-sync, so a
## game that stops saving stops syncing instead of looping forever.
##
## The slot is released, not re-taken: _on_filesystem_sync_done() spends the answer
## by calling _request_web_filesystem_sync(), which claims the slot for itself.
## Re-taking it here would leave the follower's own claim refused, the pending flag
## set again, and every completion after the first one spinning without ever issuing
## the sync it owes.
func _release_filesystem_sync_slot() -> bool:
	is_syncing_filesystem = false
	if not _pending_filesystem_sync:
		return false
	_pending_filesystem_sync = false
	return true

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
				if parsed.has("danger_level"):
					danger_level = clampi(int(parsed["danger_level"]), 0, MAX_DANGER_LEVEL)
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
		danger_level = clampi(int(config.get_value("player", "danger_level", danger_level)), 0, MAX_DANGER_LEVEL)
		for slot in equipment_slots.keys():
			equipment_slots[slot] = config.get_value("equipment", slot, equipment_slots.get(slot, ""))
		for key in meta_upgrades.keys():
			meta_upgrades[key] = config.get_value("meta_upgrades", key, meta_upgrades.get(key, 0))
		for key in meridian_upgrades.keys():
			meridian_upgrades[key] = config.get_value("meridian_upgrades", key, meridian_upgrades.get(key, 0))
		print("[GameManager] Restored save from ConfigFile. Gold: ", total_gold, " Char: ", selected_character, " Comp: ", selected_companion, " Stage: ", selected_stage, " Gear: ", equipment_slots)



