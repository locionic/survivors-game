extends Node

## CodexManager: Manages the Wuxia Unlock Codex (Sổ Tay Thành Tựu & Mở Khóa Tuyệt Kỹ).
## Tracks milestones, achievements, dynamic in-run unlocks, and permanent game modifiers.

signal quest_completed(quest_id: String, quest_data: Dictionary)
signal quest_reward_claimed(quest_id: String, quest_data: Dictionary)
signal codex_updated

const SAVE_KEY_WEB: String = "survivorquest_codex_v1"
const CFG_PATH: String = "user://codex_data.cfg"

var quests: Array[Dictionary] = [
	{
		"id": "survive_3m",
		"title": "Sơ Xuất Giang Hồ",
		"desc": "Sống sót ít nhất 3 phút (180s) trong một lượt thi đấu võ lâm",
		"icon": "🥋",
		"target": 180,
		"type": "time",
		"reward_desc": "+15 Tốc độ di chuyển cơ bản vĩnh viễn",
		"reward_type": "speed_buff",
		"reward_val": 15,
		"unlocked": false,
		"claimed": false,
		"progress": 0
	},
	{
		"id": "slay_500",
		"title": "Trảm Yêu Trừ Ma",
		"desc": "Tiêu diệt 500 quái vật tích lũy",
		"icon": "💀",
		"target": 500,
		"type": "cumulative_kills",
		"reward_desc": "+600 Vàng Meta nâng cấp hiệp khách",
		"reward_type": "gold",
		"reward_val": 600,
		"unlocked": false,
		"claimed": false,
		"progress": 0
	},
	{
		"id": "kill_boss",
		"title": "Diệt Tuyệt Ma Vương",
		"desc": "Tiêu diệt 1 Ma Vương Thống Lĩnh (Boss hoặc Behemoth)",
		"icon": "👹",
		"target": 1,
		"type": "boss_kill",
		"reward_desc": "Mở khóa Cổ Vật: Bát Tiên Hồ Lô (Phun rượu thánh khi Né Đòn)",
		"reward_type": "relic",
		"reward_val": "drunken_gourd",
		"unlocked": false,
		"claimed": false,
		"progress": 0
	},
	{
		"id": "collect_pearls_7",
		"title": "Thất Tinh Quy Vị",
		"desc": "Thu thập đủ 7 Viên Ngọc Rồng và mở ước nguyện Thần Long",
		"icon": "🐉",
		"target": 7,
		"type": "pearls",
		"reward_desc": "Thần Long Lệnh: Khởi đầu mỗi ván mới có sẵn 1 Long Châu",
		"reward_type": "start_pearl",
		"reward_val": 1,
		"unlocked": false,
		"claimed": false,
		"progress": 0
	},
	{
		"id": "sign_pact",
		"title": "Ma Đạo Huyết Khế",
		"desc": "Ký kết 1 khế ước đánh đổi sinh tử tại Tà Thần Tế Đàn",
		"icon": "🩸",
		"target": 1,
		"type": "pact",
		"reward_desc": "Mở khóa Cổ Vật: Tà Ma Lệnh Bài (+25% Sát thương Chí Mạng)",
		"reward_type": "relic",
		"reward_val": "demonic_token",
		"unlocked": false,
		"claimed": false,
		"progress": 0
	},
	{
		"id": "blood_moon",
		"title": "Huyết Nguyệt Tắm Máu",
		"desc": "Sống sót qua toàn bộ thời gian của một đợt Nhật Thực Huyết Nguyệt",
		"icon": "🌑",
		"target": 1,
		"type": "blood_moon",
		"reward_desc": "Mở khóa Cổ Vật: Huyết Ma Kiếm (Hồi 4% Máu từ đòn đánh)",
		"reward_type": "relic",
		"reward_val": "blood_blade",
		"unlocked": false,
		"claimed": false,
		"progress": 0
	},
	{
		"id": "slay_1500",
		"title": "Vạn Địch Bất Bại",
		"desc": "Tiêu diệt 1,500 kẻ địch trong một ván chơi duy nhất",
		"icon": "⚔️",
		"target": 1500,
		"type": "run_kills",
		"reward_desc": "Bí Kíp Hỏa Luân: +20% Tốc độ xuất chiêu cho mọi vũ khí",
		"reward_type": "attack_speed_buff",
		"reward_val": 0.20,
		"unlocked": false,
		"claimed": false,
		"progress": 0
	},
	{
		"id": "rich_master",
		"title": "Vạn Tiền Đại Phú",
		"desc": "Tích lũy tổng cộng 2,500 Vàng trong kho bảo khố",
		"icon": "💰",
		"target": 2500,
		"type": "total_gold",
		"reward_desc": "Kim Thiềm Thần Thú: Tăng vĩnh viễn +30% Giá trị tiền vàng rơi",
		"reward_type": "gold_drop_buff",
		"reward_val": 0.30,
		"unlocked": false,
		"claimed": false,
		"progress": 0
	}
]

var unlocked_count: int = 0
var claimed_count: int = 0

# Permanent bonuses awarded from Codex claims
var bonus_speed: float = 0.0
var bonus_attack_speed: float = 0.0
var bonus_gold_drop_mult: float = 1.0
var bonus_starting_pearls: int = 0
var unlocked_relic_keys: Array[String] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_register_codex_relic("drunken_gourd")
	_register_codex_relic("demonic_token")
	_register_codex_relic("blood_blade")
	load_codex_data()

func report_stat(stat_type: String, value: int = 1) -> void:
	var state_changed = false
	for q in quests:
		if q["unlocked"]:
			continue
		if q["type"] == stat_type:
			if stat_type in ["cumulative_kills"]:
				q["progress"] += value
			else:
				# High watermark or absolute value
				q["progress"] = max(q["progress"], value)
				
			if q["progress"] >= q["target"]:
				q["unlocked"] = true
				unlocked_count += 1
				state_changed = true
				SoundManager.play("quest_complete", 0.05)
				emit_signal("quest_completed", q["id"], q)
				
				# Display floating announcement banner on HUD
				var hud = get_tree().get_first_node_in_group("hud")
				if hud and hud.has_method("announce_codex_unlock"):
					hud.announce_codex_unlock(q["title"], q["reward_desc"])
					
	if state_changed:
		save_codex_data()
		emit_signal("codex_updated")

func claim_reward(quest_id: String) -> bool:
	for q in quests:
		if q["id"] == quest_id and q["unlocked"] and not q["claimed"]:
			q["claimed"] = true
			claimed_count += 1
			_apply_reward(q)
			save_codex_data()
			SoundManager.play("powerup")
			emit_signal("quest_reward_claimed", quest_id, q)
			emit_signal("codex_updated")
			return true
	return false

func _apply_reward(q: Dictionary) -> void:
	var r_type = q.get("reward_type", "")
	var r_val = q.get("reward_val", 0)
	match r_type:
		"gold":
			if GameManager:
				GameManager.add_gold(int(r_val))
		"speed_buff":
			bonus_speed += float(r_val)
			var p = get_tree().get_first_node_in_group("player")
			if p and p.has_method("refresh_meta_stats"):
				p.refresh_meta_stats()
		"attack_speed_buff":
			bonus_attack_speed += float(r_val)
		"gold_drop_mult":
			bonus_gold_drop_mult += float(r_val)
		"start_pearl":
			bonus_starting_pearls = int(r_val)
		"relic":
			var r_key = str(r_val)
			if not unlocked_relic_keys.has(r_key):
				unlocked_relic_keys.append(r_key)
			# Register with GameManager RELICS catalog if special
			_register_codex_relic(r_key)

func _register_codex_relic(r_key: String) -> void:
	if not GameManager:
		return
	match r_key:
		"drunken_gourd":
			GameManager.RELICS["drunken_gourd"] = {
				"id": "drunken_gourd",
				"name": "Bát Tiên Hồ Lô",
				"icon": "🍶",
				"desc": "Khi Né Đòn thành công, bộc phát rượu thánh nổ 120 ST AoE",
				"color": Color(0.95, 0.75, 0.2)
			}
		"demonic_token":
			GameManager.RELICS["demonic_token"] = {
				"id": "demonic_token",
				"name": "Tà Ma Lệnh Bài",
				"icon": "💀",
				"desc": "Tăng +25% Sát thương chí mạng và +15% Tốc độ đánh khi dưới 50% HP",
				"color": Color(0.85, 0.15, 0.25)
			}
		"blood_blade":
			GameManager.RELICS["blood_blade"] = {
				"id": "blood_blade",
				"name": "Huyết Ma Kiếm",
				"icon": "🩸",
				"desc": "Mọi đòn đánh hồi phục 4% sát thương gây ra thành sinh lực",
				"color": Color(0.9, 0.1, 0.1)
			}

func get_quest(quest_id: String) -> Dictionary:
	for q in quests:
		if q["id"] == quest_id:
			return q
	return {}

func get_completion_percentage() -> float:
	if quests.is_empty():
		return 0.0
	var count = 0
	for q in quests:
		if q["unlocked"]:
			count += 1
	return float(count) / float(quests.size()) * 100.0

func save_codex_data() -> void:
	# 1. Desktop ConfigFile
	var cfg = ConfigFile.new()
	for q in quests:
		cfg.set_value(q["id"], "progress", q["progress"])
		cfg.set_value(q["id"], "unlocked", q["unlocked"])
		cfg.set_value(q["id"], "claimed", q["claimed"])
	cfg.set_value("global", "bonus_speed", bonus_speed)
	cfg.set_value("global", "bonus_attack_speed", bonus_attack_speed)
	cfg.set_value("global", "bonus_gold_drop_mult", bonus_gold_drop_mult)
	cfg.set_value("global", "bonus_starting_pearls", bonus_starting_pearls)
	cfg.set_value("global", "unlocked_relic_keys", unlocked_relic_keys)
	cfg.save(CFG_PATH)
	
	# 2. Web localStorage
	if OS.has_feature("web"):
		var q_data = []
		for q in quests:
			q_data.append({
				"id": q["id"],
				"progress": q["progress"],
				"unlocked": q["unlocked"],
				"claimed": q["claimed"]
			})
		var save_dict = {
			"quests": q_data,
			"bonus_speed": bonus_speed,
			"bonus_attack_speed": bonus_attack_speed,
			"bonus_gold_drop_mult": bonus_gold_drop_mult,
			"bonus_starting_pearls": bonus_starting_pearls,
			"unlocked_relic_keys": unlocked_relic_keys
		}
		var json_str = JSON.stringify(save_dict)
		var escaped = json_str.c_escape()
		JavaScriptBridge.eval("try { localStorage.setItem('%s', '%s'); } catch(e) { console.error(e); }" % [SAVE_KEY_WEB, escaped])

func load_codex_data() -> void:
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
			unlocked_count = 0
			claimed_count = 0
			for q in quests:
				if cfg.has_section_key(q["id"], "progress"):
					q["progress"] = int(cfg.get_value(q["id"], "progress"))
				if cfg.has_section_key(q["id"], "unlocked"):
					q["unlocked"] = bool(cfg.get_value(q["id"], "unlocked"))
					if q["unlocked"]:
						unlocked_count += 1
				if cfg.has_section_key(q["id"], "claimed"):
					q["claimed"] = bool(cfg.get_value(q["id"], "claimed"))
					if q["claimed"]:
						claimed_count += 1
						_apply_reward(q)
			bonus_speed = float(cfg.get_value("global", "bonus_speed", 0.0))
			bonus_attack_speed = float(cfg.get_value("global", "bonus_attack_speed", 0.0))
			bonus_gold_drop_mult = float(cfg.get_value("global", "bonus_gold_drop_mult", 1.0))
			bonus_starting_pearls = int(cfg.get_value("global", "bonus_starting_pearls", 0))
			var rels = cfg.get_value("global", "unlocked_relic_keys", [])
			if rels is Array:
				for rk in rels:
					if not unlocked_relic_keys.has(str(rk)):
						unlocked_relic_keys.append(str(rk))
					_register_codex_relic(str(rk))

func _apply_save_dict(dict: Dictionary) -> void:
	unlocked_count = 0
	claimed_count = 0
	if dict.has("quests") and dict["quests"] is Array:
		for sq in dict["quests"]:
			var q_id = str(sq.get("id", ""))
			for q in quests:
				if q["id"] == q_id:
					q["progress"] = int(sq.get("progress", 0))
					q["unlocked"] = bool(sq.get("unlocked", false))
					q["claimed"] = bool(sq.get("claimed", false))
					if q["unlocked"]:
						unlocked_count += 1
					if q["claimed"]:
						claimed_count += 1
						_apply_reward(q)
					break
	if dict.has("bonus_speed"):
		bonus_speed = float(dict["bonus_speed"])
	if dict.has("bonus_attack_speed"):
		bonus_attack_speed = float(dict["bonus_attack_speed"])
	if dict.has("bonus_gold_drop_mult"):
		bonus_gold_drop_mult = float(dict["bonus_gold_drop_mult"])
	if dict.has("bonus_starting_pearls"):
		bonus_starting_pearls = int(dict["bonus_starting_pearls"])
	if dict.has("unlocked_relic_keys") and dict["unlocked_relic_keys"] is Array:
		for rk in dict["unlocked_relic_keys"]:
			if not unlocked_relic_keys.has(str(rk)):
				unlocked_relic_keys.append(str(rk))
			_register_codex_relic(str(rk))

func reset_codex_data() -> void:
	unlocked_count = 0
	claimed_count = 0
	bonus_speed = 0.0
	bonus_attack_speed = 0.0
	bonus_gold_drop_mult = 1.0
	bonus_starting_pearls = 0
	unlocked_relic_keys.clear()
	for q in quests:
		q["progress"] = 0
		q["unlocked"] = false
		q["claimed"] = false
	save_codex_data()
	emit_signal("codex_updated")
