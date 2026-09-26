extends Node

## Loc: the single bilingual string table. English is the default; Vietnamese is
## a toggle away. Every user-facing name in the game resolves through t() so a
## switch is one signal, not a scavenger hunt.
##
## Registered FIRST in project.godot's [autoload] list: GameManager seeds its
## weapon display table from t() inside _ready(), and autoloads are readied in
## declaration order.

signal locale_changed(new_locale: String)

const SAVE_PATH: String = "user://save_data.cfg"
const SAVE_SECTION: String = "locale"
const SAVE_KEY: String = "current_locale"
const DEFAULT_LOCALE: String = "en"
const SUPPORTED: Array[String] = ["en", "vi"]

## One row per key, both languages side by side. A key missing a language falls
## back to English and then to the caller's own default, so a half-filled table
## degrades to a readable string rather than a blank label.
const STRINGS: Dictionary = {
	# --- Môn Phái / Sects ----------------------------------------------------
	"char.knight.name": {"en": "Sir Kaelen", "vi": "Đoàn Kiếm (Sir Kaelen)"},
	"char.knight.title": {"en": "Tide-Dao Sword Hero", "vi": "Tiêu Dao Kiếm Hiệp"},
	"char.knight.sect": {"en": "Tide-Dao Sect", "vi": "Tiêu Dao Phái"},
	"char.pyro.name": {"en": "Ignis, Ember Palm", "vi": "Ignis - Viêm Chưởng"},
	"char.pyro.title": {"en": "Minh Sect Pyromancer", "vi": "Minh Giáo Liệt Hỏa"},
	"char.pyro.sect": {"en": "Minh Sect", "vi": "Minh Giáo"},
	"char.ranger.name": {"en": "Zephyr the Shadow", "vi": "Đường Ảnh (Zephyr)"},
	"char.ranger.title": {"en": "Tang Clan Thief", "vi": "Đường Môn Thích Khách"},
	"char.ranger.sect": {"en": "Tang Sect", "vi": "Đường Môn"},
	"char.mage.name": {"en": "Morrigan the Azure", "vi": "Thanh Loan (Morrigan)"},
	"char.mage.title": {"en": "Emei Ice Fairy", "vi": "Nga Mi Tiên Tử"},
	"char.mage.sect": {"en": "Emei Sect", "vi": "Nga Mi"},
	"char.beggar.name": {"en": "Wandering Beggar", "vi": "Tiêu Lãng"},
	"char.beggar.title": {"en": "Beggar Sect Brawler", "vi": "Cái Bang Chưởng Môn"},
	"char.beggar.sect": {"en": "Beggar Sect", "vi": "Cái Bang"},

	# --- Weapons. These six are CANONICAL: the dps report, the arsenal cards
	# and the HUD badges all read them, so they cannot drift apart. ----------
	"weapon.dagger.name": {"en": "Thousand Daggers", "vi": "Vạn Phi Đao"},
	"weapon.shield.name": {"en": "Eight Trigrams Shield", "vi": "Khiên Bát Quái"},
	"weapon.lightning.name": {"en": "Heaven's Wrath", "vi": "Cửu Thiên Lôi Điện"},
	"weapon.fireball.name": {"en": "Apocalypse Meteor", "vi": "Liệt Hỏa Chưởng Cầu"},
	"weapon.axe.name": {"en": "Dog-Beating Staff", "vi": "Đả Cẩu Trận"},
	"weapon.slash.name": {"en": "Nine Swords Cleave", "vi": "Độc Cô Cửu Kiếm"},

	# --- Evolutions ----------------------------------------------------------
	"evo.dagger.name": {"en": "Thousand Blades", "vi": "Vô Ảnh Thần Châm"},
	"evo.shield.name": {"en": "Solar Bulwark", "vi": "Thái Cực Hộ Thể"},
	"evo.lightning.name": {"en": "Heaven's Wrath", "vi": "Cửu Thiên Huyền Lôi"},
	"evo.fireball.name": {"en": "Apocalypse Meteor", "vi": "Kim Cương Hỏa Chưởng"},
	"evo.axe.name": {"en": "Reaper's Cleave", "vi": "Càn Khôn Đại Na Di"},
	"evo.slash.name": {"en": "Nine Swords Cleave", "vi": "Độc Cô Cửu Kiếm Quy Tông"},

	# --- Tinh Võ Hợp Nhất / dual-weapon synergy fusions -----------------------
	"synergy.lotus_storm.name": {"en": "Lotus Storm", "vi": "Bão Vũ Lê Hoa Châm"},
	"synergy.frost_sovereign.name": {"en": "Frost Sovereign", "vi": "Băng Phách Thần Kiếm"},

	# --- Tàng Kinh Các / Martial Pavilion (intermission shop) ---------------
	"shop.title": {"en": "Martial Pavilion", "vi": "Tàng Kinh Các"},
	"shop.reroll": {"en": "Reroll", "vi": "Đổi bài"},
	"shop.lock": {"en": "Lock", "vi": "Khóa"},
	"shop.unlock": {"en": "Unlock", "vi": "Mở khóa"},
	"shop.fuse": {"en": "Fuse", "vi": "Luyện thể"},
	"shop.sell": {"en": "Sell", "vi": "Bán"},
	"shop.interest": {"en": "Interest earned", "vi": "Lãi tích lũy"},
	"shop.clear_bounty": {"en": "Clear bounty", "vi": "Thưởng thông hiệp"},
	"shop.wave_cleared": {"en": "Wave Cleared", "vi": "Đã Thông Hiệp"},
	"shop.tradeoff_scroll": {"en": "Trade-off Scroll", "vi": "Cuộn Đánh Đổi"},
	"shop.next_wave": {"en": "Next Wave", "vi": "Hiệp Sau"},
	"shop.weapon": {"en": "Weapon", "vi": "Võ Khí"},
	"shop.bought": {"en": "Bought", "vi": "Đã Mua"},
	"shop.broke": {"en": "Not enough gold", "vi": "Không đủ vàng"},
	"shop.sold": {"en": "Sold", "vi": "Đã Bán"},

	# --- HUD: waves, streaks, boss alarms, end screens -----------------------
	"hud.wave": {"en": "Wave", "vi": "Hiệp"},
	"hud.wave_banner": {"en": "WAVE %d / %d - ARENA OPEN!", "vi": "HIỆP %d / %d - VÕ ĐÀI MỞ!"},
	"hud.victory_banner": {"en": "TOTAL VICTORY! THE ARENA FALLS AFTER %d WAVES!", "vi": "TOÀN THẮNG! VÕ ĐÀI CHIẾN THẮNG %d HIỆP!"},
	"hud.streak_50": {"en": "⚔️ 50 KILLS: MASSACRE! (+25% BLOOD RAGE)", "vi": "⚔️ TRẢM TƯỚNG ĐOẠT KỲ! (+25% CUỒNG BẠO)"},
	"hud.streak_100": {"en": "🔥 100 KILLS: ONESWORDED! (+25% BLOOD RAGE)", "vi": "🔥 BÁCH NHÂN ĐỊCH! (+25% CUỒNG BẠO)"},
	"hud.streak_250": {"en": "⚡ 250 KILLS: FRENZY UNLEASHED! (+25% BLOOD RAGE)", "vi": "⚡ CUỒNG MA XUẤT THẾ! (+25% CUỒNG BẠO)"},
	"hud.streak_500": {"en": "👑 500 KILLS: UNSHAKEABLE LEGION! (+25% BLOOD RAGE)", "vi": "👑 VẠN QUÂN BẤT ĐỊCH! (+25% CUỒNG BẠO)"},
	"hud.streak_1000": {"en": "🌌 1000 KILLS: LONE WALKER OF HEAVEN! (+25% BLOOD RAGE)", "vi": "🌌 ĐỘC BỘ THIÊN HẠ! (+25% CUỒNG BẠO)"},
	"hud.boss_alarm": {"en": "ELITE CHAMPION DESCENDS!", "vi": "TINH ANH LỆNH GIÁ THỔNG GIANG!"},
	"hud.victory": {"en": "VICTORY", "vi": "TOÀN THẮNG"},
	"hud.defeat": {"en": "DEFEAT", "vi": "THẤT BẠI"},
	"hud.paused": {"en": "PAUSED", "vi": "TẠM DỪNG"},
	"hud.resume": {"en": "Resume", "vi": "Tiếp tục"},
	"hud.restart": {"en": "Restart Run", "vi": "Chơi lại"},
	"hud.gold": {"en": "Gold", "vi": "Vàng"},
	"hud.level": {"en": "Level", "vi": "Cấp"},
	"hud.kills": {"en": "Kills", "vi": "Kills"},
	"hud.dps": {"en": "Damage Dealt", "vi": "Sát thương gây ra"},
	"hud.rank": {"en": "Combat Rank", "vi": "Trận cấp"},

	# --- Danger / Torture ladder --------------------------------------------
	"danger.title": {"en": "Danger", "vi": "Cấp độ"},
	"danger.0.name": {"en": "Novice", "vi": "Nhập Môn"},
	"danger.1.name": {"en": "Initiate", "vi": "Hiệp Khách"},
	"danger.2.name": {"en": "Adept", "vi": "Chưởng Môn"},
	"danger.3.name": {"en": "Master", "vi": "Tông Sư"},
	"danger.4.name": {"en": "Grandmaster", "vi": "Tuyệt Thế"},
	"danger.5.name": {"en": "Immortal", "vi": "Thiên Hạ Vô Song"},
	"danger.desc": {"en": "Enemy HP %d%% · Speed %d%% · Score x%.1f", "vi": "Máu quái %d%% · Tốc độ %d%% · Điểm x%.1f"},

	# --- Shared chrome -------------------------------------------------------
	"ui.locale_en": {"en": "EN", "vi": "EN"},
	"ui.locale_vi": {"en": "VI", "vi": "VI"},
	"ui.close": {"en": "Close", "vi": "Đóng"},
	"ui.select_hero": {"en": "Select Hero", "vi": "Chọn Nhân Vật"},
	"ui.active_hero": {"en": "ACTIVE HERO", "vi": "ĐANG CHỌN"},
	"ui.locked": {"en": "(Locked)", "vi": "(Chưa mở)"},
}

var current_locale: String = DEFAULT_LOCALE

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_locale()

## Look up a key. `default_text` is what the call site already had hardcoded --
## it keeps a missing key from blanking a button, so new UI can ship before its
## translation row exists.
func t(key: String, default_text: String = "") -> String:
	var row = STRINGS.get(key)
	if row is Dictionary and row.has(current_locale):
		return String(row[current_locale])
	if row is Dictionary and row.has(DEFAULT_LOCALE):
		return String(row[DEFAULT_LOCALE])
	return default_text if default_text != "" else key

## Shorthand for the %-format rows (hud.wave_banner and friends). Uses the `%`
## operator rather than String.format(), which wants `{}` placeholders and would
## hand back the row with every %d still in it.
func tf(key: String, args: Array) -> String:
	return t(key) % args

func set_locale(new_locale: String) -> void:
	if not SUPPORTED.has(new_locale) or new_locale == current_locale:
		return
	current_locale = new_locale
	save_locale()
	emit_signal("locale_changed", new_locale)

func toggle_locale() -> void:
	set_locale("vi" if current_locale == "en" else "en")

func is_supported(new_locale: String) -> bool:
	return SUPPORTED.has(new_locale)

## The localised display name for one of the six weapon ids, falling back to the
## id itself so an unknown weapon still shows something rather than "".
func weapon_name(weapon_id: String) -> String:
	return t("weapon.%s.name" % weapon_id, weapon_id)

func load_locale() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		var saved = str(config.get_value(SAVE_SECTION, SAVE_KEY, DEFAULT_LOCALE))
		if SUPPORTED.has(saved):
			current_locale = saved

## Written into the same save file as everything else, so a locale choice rides
## along with the gold and the hero rather than needing a second profile.
func save_locale() -> void:
	var config := ConfigFile.new()
	config.load(SAVE_PATH) # keep the sections GameManager owns
	config.set_value(SAVE_SECTION, SAVE_KEY, current_locale)
	config.save(SAVE_PATH)

## The `[ EN | VI ]` toggle, built in code so the title screen, the pause menu
## and any future host all get the same button for free. Self-wires and keeps
## itself in sync -- a host only has to add it to the tree.
func make_toggle_button() -> Button:
	var btn := Button.new()
	btn.name = "LocaleToggleButton"
	btn.custom_minimum_size = Vector2(0, 30)
	btn.focus_mode = Control.FOCUS_NONE
	btn.tooltip_text = "Language / Ngôn ngữ"
	btn.add_theme_font_size_override("font_size", 13)
	btn.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	btn.add_theme_stylebox_override("normal", _chip_stylebox(Color(0.10, 0.16, 0.26, 0.92), Color(0.20, 0.55, 0.75, 0.9)))
	btn.add_theme_stylebox_override("hover", _chip_stylebox(Color(0.16, 0.26, 0.40, 0.96), Color(0.35, 0.85, 1.0, 1.0)))
	btn.add_theme_stylebox_override("pressed", _chip_stylebox(Color(0.20, 0.34, 0.50, 1.0), Color(0.55, 0.95, 1.0, 1.0)))
	_refresh_locale_button(btn)
	btn.pressed.connect(func():
		toggle_locale()
		SoundManager.play("button_click", 0.6)
	)
	# One connection per button, not one shared across every host: the title
	# screen, the pause menu and the character sheet each own a chip, and a
	# single signal can only refresh the one it was bound to.
	locale_changed.connect(func(_new_locale: String): _refresh_locale_button(btn))
	return btn

func _refresh_locale_button(btn: Button) -> void:
	if not is_instance_valid(btn):
		return
	# A marker on the active half rather than a case change, so both codes stay
	# legible in either language and the current choice reads at a glance.
	var en := t("ui.locale_en")
	var vi := t("ui.locale_vi")
	btn.text = "🌐 [ %s%s | %s%s ]" % [
		"▸" if current_locale == "en" else "", en,
		"▸" if current_locale == "vi" else "", vi
	]

func _chip_stylebox(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	return sb
