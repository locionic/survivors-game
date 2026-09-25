extends Node

## LeaderboardManager: Handles Đại Hội Võ Lâm (Martial Tournament Hall of Fame),
## player nickname persistence, run score submission, and Daily Seeded Celestial Trials.

signal leaderboard_updated
signal daily_trial_refreshed

const SAVE_KEY_WEB: String = "survivorquest_leaderboard_v1"
const CFG_PATH: String = "user://leaderboard_data.cfg"

var player_nickname: String = "Vô Danh Đại Hiệp"
var tournament_entries: Array[Dictionary] = []
var daily_completed: bool = false
var daily_high_score: int = 0
var last_daily_date: String = ""

const DEFAULT_SECT_MASTERS: Array[Dictionary] = [
	{
		"name": "Tiêu Phong",
		"sect": "Cái Bang Bang Chủ",
		"hero": "beggar",
		"time": 1512.0, # 25m 12s
		"kills": 2150,
		"score": 68500,
		"scrolls": ["dichcankinh", "lucmach"],
		"date": "2026-09-15",
		"is_player": false
	},
	{
		"name": "Vô Danh Thần Tăng",
		"sect": "Thiếu Lâm Tàng Kinh Các",
		"hero": "monk",
		"time": 1425.0, # 23m 45s
		"kills": 1820,
		"score": 59200,
		"scrolls": ["dichcankinh", "thaicuc"],
		"date": "2026-09-14",
		"is_player": false
	},
	{
		"name": "Trương Tam Phong",
		"sect": "Võ Đang Chưởng Môn",
		"hero": "knight",
		"time": 1290.0, # 21m 30s
		"kills": 1590,
		"score": 51400,
		"scrolls": ["thaicuc"],
		"date": "2026-09-13",
		"is_player": false
	},
	{
		"name": "Đông Phương Bất Bại",
		"sect": "Nhật Nguyệt Giáo Chủ",
		"hero": "pyro",
		"time": 1155.0, # 19m 15s
		"kills": 1410,
		"score": 44800,
		"scrolls": ["lucmach"],
		"date": "2026-09-12",
		"is_player": false
	},
	{
		"name": "Lệnh Hồ Xung",
		"sect": "Hoa Sơn Kiếm Khách",
		"hero": "ranger",
		"time": 1070.0, # 17m 50s
		"kills": 1220,
		"score": 38900,
		"scrolls": ["lucmach"],
		"date": "2026-09-11",
		"is_player": false
	},
	{
		"name": "Dương Quá",
		"sect": "Thần Điêu Đại Hiệp",
		"hero": "knight",
		"time": 920.0, # 15m 20s
		"kills": 1050,
		"score": 32100,
		"scrolls": ["dichcankinh"],
		"date": "2026-09-10",
		"is_player": false
	},
	{
		"name": "Quách Tĩnh",
		"sect": "Hàng Long Tông Sư",
		"hero": "beggar",
		"time": 820.0, # 13m 40s
		"kills": 890,
		"score": 26400,
		"scrolls": ["dichcankinh"],
		"date": "2026-09-09",
		"is_player": false
	},
	{
		"name": "Hoàng Dung",
		"sect": "Đả Cẩu Nữ Hiệp",
		"hero": "ranger",
		"time": 675.0, # 11m 15s
		"kills": 740,
		"score": 21500,
		"scrolls": ["thaicuc"],
		"date": "2026-09-08",
		"is_player": false
	},
	{
		"name": "Đoàn Dự",
		"sect": "Đại Lý Vương Tử",
		"hero": "mage",
		"time": 570.0, # 9m 30s
		"kills": 580,
		"score": 16800,
		"scrolls": ["lucmach"],
		"date": "2026-09-07",
		"is_player": false
	},
	{
		"name": "Hư Trúc",
		"sect": "Tiêu Dao Cung Chủ",
		"hero": "monk",
		"time": 465.0, # 7m 45s
		"kills": 420,
		"score": 12200,
		"scrolls": ["dichcankinh"],
		"date": "2026-09-06",
		"is_player": false
	}
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_leaderboard_data()

func calculate_score(run_time: float, kills: int, gold: int, scrolls_count: int) -> int:
	return int(run_time * 12.0) + (kills * 28) + (gold * 2) + (scrolls_count * 2500)

func submit_run(hero_id: String, run_time: float, kills: int, gold: int, scrolls: Array = []) -> int:
	var total_score = calculate_score(run_time, kills, gold, scrolls.size())
	var date_dict = Time.get_date_dict_from_system()
	var date_str = "%04d-%02d-%02d" % [date_dict.get("year", 2026), date_dict.get("month", 9), date_dict.get("day", 17)]
	
	var new_entry: Dictionary = {
		"name": player_nickname,
		"sect": "Đại Hiệp",
		"hero": hero_id,
		"time": run_time,
		"kills": kills,
		"score": total_score,
		"scrolls": scrolls.duplicate(),
		"date": date_str,
		"is_player": true
	}
	
	tournament_entries.append(new_entry)
	_sort_entries()
	
	# Check daily score
	if total_score > daily_high_score:
		daily_high_score = total_score
		daily_completed = true
		
	save_leaderboard_data()
	emit_signal("leaderboard_updated")
	
	var rank = tournament_entries.find(new_entry) + 1
	if rank <= 10:
		SoundManager.play("fanfare", 0.05)
	return rank

func _sort_entries() -> void:
	tournament_entries.sort_custom(func(a: Dictionary, b: Dictionary):
		return a.get("score", 0) > b.get("score", 0)
	)
	if tournament_entries.size() > 20:
		tournament_entries.resize(20)

func get_top_entries() -> Array[Dictionary]:
	if tournament_entries.is_empty():
		_init_default_masters()
	return tournament_entries

func _init_default_masters() -> void:
	tournament_entries.clear()
	for master in DEFAULT_SECT_MASTERS:
		tournament_entries.append(master.duplicate())
	_sort_entries()

func reset_leaderboard_data() -> void:
	player_nickname = "Vô Danh Đại Hiệp"
	daily_completed = false
	daily_high_score = 0
	last_daily_date = ""
	_init_default_masters()
	save_leaderboard_data()
	emit_signal("leaderboard_updated")

func set_player_nickname(new_name: String) -> void:
	var clean = new_name.strip_edges()
	if clean != "":
		player_nickname = clean.substr(0, 20)
		save_leaderboard_data()
		emit_signal("leaderboard_updated")

func get_daily_trial_info() -> Dictionary:
	var date_dict = Time.get_date_dict_from_system()
	var day_num = date_dict.get("year", 2026) * 10000 + date_dict.get("month", 9) * 100 + date_dict.get("day", 17)
	var date_str = "%04d-%02d-%02d" % [date_dict.get("year", 2026), date_dict.get("month", 9), date_dict.get("day", 17)]
	
	# Check date shift for daily reset
	if last_daily_date != date_str:
		last_daily_date = date_str
		daily_completed = false
		daily_high_score = 0
		save_leaderboard_data()
	
	var mutators = [
		{
			"id": "fire_surge",
			"title": "Hỏa Diệm Sơn Khí",
			"desc": "🔥 Hỏa thương +50% Sát thương, Quái vật tăng +20% Tốc độ",
			"reward_gold": 600,
			"might_mult": 1.25,
			"speed_mult": 1.15
		},
		{
			"id": "diamond_body",
			"title": "Kim Cương Bất Hoại",
			"desc": "🛡️ Khí Thuẫn x2 dung lượng, Quái Thủ Lĩnh (Champion) xuất hiện gấp đôi",
			"reward_gold": 750,
			"might_mult": 1.0,
			"speed_mult": 1.0
		},
		{
			"id": "sword_rain",
			"title": "Vạn Kiếm Quy Tông",
			"desc": "⚔️ Thời gian hồi chiêu giảm 30%, Đợt quái đông hơn +40%",
			"reward_gold": 800,
			"might_mult": 1.35,
			"speed_mult": 1.10
		},
		{
			"id": "drunken_goblins",
			"title": "Bát Tiên Túy Võ",
			"desc": "🍶 Tỷ lệ Né đòn +25%, Yêu Tinh Kho Báu (Goblin) xuất hiện gấp 3 lần",
			"reward_gold": 900,
			"might_mult": 1.15,
			"speed_mult": 1.20
		}
	]
	var selected_idx = day_num % mutators.size()
	var trial = mutators[selected_idx].duplicate()
	trial["date"] = date_str
	trial["day_seed"] = day_num
	trial["completed"] = daily_completed
	trial["high_score"] = daily_high_score
	return trial

func save_leaderboard_data() -> void:
	# 1. Desktop save
	var cfg = ConfigFile.new()
	cfg.set_value("player", "nickname", player_nickname)
	cfg.set_value("daily", "last_date", last_daily_date)
	cfg.set_value("daily", "completed", daily_completed)
	cfg.set_value("daily", "high_score", daily_high_score)
	
	var player_runs: Array = []
	for entry in tournament_entries:
		if entry.get("is_player", false):
			player_runs.append(entry)
	cfg.set_value("tournament", "player_runs", player_runs)
	cfg.save(CFG_PATH)
	
	# 2. Web localStorage save
	if OS.has_feature("web"):
		var save_dict: Dictionary = {
			"nickname": player_nickname,
			"last_date": last_daily_date,
			"completed": daily_completed,
			"high_score": daily_high_score,
			"player_runs": player_runs
		}
		var json_str = JSON.stringify(save_dict)
		var escaped = json_str.c_escape()
		JavaScriptBridge.eval("try { localStorage.setItem('%s', '%s'); } catch(e) { console.error(e); }" % [SAVE_KEY_WEB, escaped])

func load_leaderboard_data() -> void:
	_init_default_masters()
	
	var loaded = false
	# 1. Try web localStorage
	if OS.has_feature("web"):
		var result = JavaScriptBridge.eval("try { localStorage.getItem('%s'); } catch(e) { null; }" % SAVE_KEY_WEB)
		if result != null and str(result) != "" and str(result) != "null":
			var parsed = JSON.parse_string(str(result))
			if parsed is Dictionary:
				_apply_save_dict(parsed)
				loaded = true
				
	# 2. Try desktop ConfigFile
	if not loaded:
		var cfg = ConfigFile.new()
		var err = cfg.load(CFG_PATH)
		if err == OK:
			if cfg.has_section_key("player", "nickname"):
				player_nickname = str(cfg.get_value("player", "nickname"))
			if cfg.has_section_key("daily", "last_date"):
				last_daily_date = str(cfg.get_value("daily", "last_date"))
			if cfg.has_section_key("daily", "completed"):
				daily_completed = bool(cfg.get_value("daily", "completed"))
			if cfg.has_section_key("daily", "high_score"):
				daily_high_score = int(cfg.get_value("daily", "high_score"))
			if cfg.has_section_key("tournament", "player_runs"):
				var runs = cfg.get_value("tournament", "player_runs")
				if runs is Array:
					for r in runs:
						tournament_entries.append(r)
					_sort_entries()

func _apply_save_dict(dict: Dictionary) -> void:
	if dict.has("nickname"):
		player_nickname = str(dict["nickname"])
	if dict.has("last_date"):
		last_daily_date = str(dict["last_date"])
	if dict.has("completed"):
		daily_completed = bool(dict["completed"])
	if dict.has("high_score"):
		daily_high_score = int(dict["high_score"])
	if dict.has("player_runs") and dict["player_runs"] is Array:
		for r in dict["player_runs"]:
			tournament_entries.append(r)
		_sort_entries()
