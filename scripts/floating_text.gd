extends Node

## FloatingText: High-performance pooled damage number system for massive swarms.

const POOL_SIZE: int = 24
var label_pool: Array[Label] = []
var active_tweens: Dictionary = {}
var pool_index: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func spawn(pos: Vector2, text: String, color: Color = Color(1.0, 0.9, 0.2)) -> void:
	var root = get_tree().current_scene
	if not root:
		return
		
	# Distance Culling: don't spawn damage numbers if off-screen (>600px away)
	var p = get_tree().get_first_node_in_group("player")
	if p and p.global_position.distance_squared_to(pos) > 360000.0:
		return

	# Lazy-populate pool
	if label_pool.size() < POOL_SIZE:
		var needed = POOL_SIZE - label_pool.size()
		for i in range(needed):
			var new_lbl = Label.new()
			new_lbl.visible = false
			new_lbl.z_index = 100
			new_lbl.add_theme_font_size_override("font_size", 14)
			new_lbl.add_theme_constant_override("outline_size", 4)
			new_lbl.add_theme_color_override("font_outline_color", Color(0.04, 0.04, 0.06, 0.95))
			new_lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.7))
			new_lbl.add_theme_constant_override("shadow_offset_x", 1)
			new_lbl.add_theme_constant_override("shadow_offset_y", 1)
			new_lbl.pivot_offset = Vector2(24, 10)
			label_pool.append(new_lbl)
			
	if label_pool.is_empty():
		return
		
	var lbl = label_pool[pool_index]
	pool_index = (pool_index + 1) % label_pool.size()
	
	if not is_instance_valid(lbl):
		return
		
	if not lbl.is_inside_tree():
		root.add_child(lbl)
	elif lbl.get_parent() != root:
		lbl.reparent(root)
		
	if active_tweens.has(lbl) and is_instance_valid(active_tweens[lbl]):
		active_tweens[lbl].kill()
		
	lbl.text = text
	lbl.modulate = color
	lbl.modulate.a = 1.0
	lbl.scale = Vector2(1.35, 1.35)
	lbl.global_position = pos + Vector2(randf_range(-12, 12), -14)
	lbl.visible = true
	
	var tw = lbl.create_tween()
	active_tweens[lbl] = tw
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", lbl.position.y - 32.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.35).set_delay(0.18)
	tw.chain().tween_callback(func():
		if is_instance_valid(lbl):
			lbl.visible = false
		active_tweens.erase(lbl)
	)
