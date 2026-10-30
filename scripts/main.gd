extends Node2D

func _ready() -> void:
	if GameManager:
		var st_data = GameManager.get_selected_stage_data()
		var bg = get_node_or_null("Background")
		if bg and st_data.has("texture_path"):
			var tex_path = st_data["texture_path"]
			if ResourceLoader.exists(tex_path):
				bg.texture = load(tex_path)
	_setup_arena_boundaries()
	_setup_arena_theming()
	if get_tree().current_scene == self:
		var hud = get_node_or_null("HUD")
		if hud and hud.has_node("TitleScreen"):
			hud.get_node("TitleScreen").open_screen()
			GameManager.is_run_active = false
		else:
			GameManager.start_new_run()
	else:
		GameManager.start_new_run()

func _setup_arena_boundaries() -> void:
	var bounds = StaticBody2D.new()
	bounds.name = "ArenaBoundaries"
	bounds.collision_layer = 4
	bounds.collision_mask = 3
	var half_w = 1200.0
	var half_h = 900.0
	var thick = 120.0
	var walls = [
		{"pos": Vector2(0, -half_h - thick * 0.5), "size": Vector2(half_w * 2.2, thick)},
		{"pos": Vector2(0, half_h + thick * 0.5), "size": Vector2(half_w * 2.2, thick)},
		{"pos": Vector2(-half_w - thick * 0.5, 0), "size": Vector2(thick, half_h * 2.2)},
		{"pos": Vector2(half_w + thick * 0.5, 0), "size": Vector2(thick, half_h * 2.2)}
	]
	for w in walls:
		var col = CollisionShape2D.new()
		var rect = RectangleShape2D.new()
		rect.size = w["size"]
		col.shape = rect
		col.position = w["pos"]
		bounds.add_child(col)
	# Võ Đài perimeter: a bright gate-line plus a dim wide glow, so the walled
	# arena reads as a duel ring instead of an invisible wall.
	var corners = [Vector2(-half_w, -half_h), Vector2(half_w, -half_h), Vector2(half_w, half_h), Vector2(-half_w, half_h), Vector2(-half_w, -half_h)]
	for ring in [[14.0, Color(1.0, 0.82, 0.35, 0.95), 900], [52.0, Color(0.95, 0.55, 0.18, 0.16), 899]]:
		var line = Line2D.new()
		line.points = PackedVector2Array(corners)
		line.width = ring[0]
		line.default_color = ring[1]
		line.z_index = ring[2]
		bounds.add_child(line)

	# Corner Braziers with martial flame embers
	var corner_pts = [Vector2(-half_w, -half_h), Vector2(half_w, -half_h), Vector2(half_w, half_h), Vector2(-half_w, half_h)]
	var brazier_tex = load("res://assets/textures/brazier.png") if ResourceLoader.exists("res://assets/textures/brazier.png") else null
	for pt in corner_pts:
		if brazier_tex:
			var sp = Sprite2D.new()
			sp.texture = brazier_tex
			sp.position = pt
			sp.scale = Vector2(2.5, 2.5)
			sp.z_index = 950
			bounds.add_child(sp)
		var fire = CPUParticles2D.new()
		fire.position = pt + Vector2(0, -16)
		fire.amount = 8
		fire.lifetime = 0.8
		fire.direction = Vector2(0, -1)
		fire.spread = 20.0
		fire.gravity = Vector2(0, -30)
		fire.initial_velocity_min = 20.0
		fire.initial_velocity_max = 45.0
		fire.scale_amount_min = 2.0
		fire.scale_amount_max = 4.0
		fire.color = Color(1.0, 0.65, 0.2, 0.85)
		fire.z_index = 951
		bounds.add_child(fire)
	add_child(bounds)

func _setup_arena_theming() -> void:
	# Only apply Ba Lăng Huyện theming for the martial arts stage
	if not GameManager or GameManager.selected_stage != "martial_arts":
		return
	
	var half_w = 1200.0
	var half_h = 900.0
	var theme_parent = Node2D.new()
	theme_parent.name = "ArenaTheming"
	theme_parent.z_index = 500  # Below boundary lines (900), above floor
	add_child(theme_parent)
	
	# 1. Bamboo reeds along the perimeter
	_make_bamboo_reeds(theme_parent, half_w, half_h)
	
	# 2. Moss patches scattered on the floor
	_make_moss_patches(theme_parent, half_w, half_h)
	
	# 3. Guardian lions at cardinal points
	_make_guardian_lions(theme_parent, half_w, half_h)
	
	# 4. Red lantern posts along the walls
	_make_lantern_posts(theme_parent, half_w, half_h)
	
	# 5. Floating golden autumn leaves (CPUParticles2D)
	_make_autumn_leaves(theme_parent, half_w, half_h)

func _make_bamboo_reeds(parent: Node2D, half_w: float, half_h: float) -> void:
	var bamboo_tex = load("res://assets/textures/bamboo_reed.png") if ResourceLoader.exists("res://assets/textures/bamboo_reed.png") else null
	if not bamboo_tex:
		return
	
	# Place bamboo reeds along north and south walls, slightly inside the boundary
	var y_positions = [-half_h + 40, half_h - 40]
	for y in y_positions:
		for i in range(12):
			var x = lerp(-half_w + 80, half_w - 80, float(i) / 11.0) + randf_range(-30.0, 30.0)
			var sp = Sprite2D.new()
			sp.texture = bamboo_tex
			sp.position = Vector2(x, y)
			sp.scale = Vector2(randf_range(1.2, 1.8), randf_range(1.2, 1.8))
			sp.rotation_degrees = randf_range(-8.0, 8.0)
			sp.z_index = 510
			sp.modulate = Color(0.35, 0.55, 0.25, randf_range(0.7, 0.95))
			parent.add_child(sp)
	
	# Place bamboo reeds along east and west walls
	var x_positions = [-half_w + 40, half_w - 40]
	for x in x_positions:
		for i in range(8):
			var y = lerp(-half_h + 80, half_h - 80, float(i) / 7.0) + randf_range(-25.0, 25.0)
			var sp = Sprite2D.new()
			sp.texture = bamboo_tex
			sp.position = Vector2(x, y)
			sp.scale = Vector2(randf_range(1.2, 1.8), randf_range(1.2, 1.8))
			sp.rotation_degrees = randf_range(-8.0, 8.0)
			sp.z_index = 510
			sp.modulate = Color(0.35, 0.55, 0.25, randf_range(0.7, 0.95))
			parent.add_child(sp)

func _make_moss_patches(parent: Node2D, half_w: float, half_h: float) -> void:
	var moss_tex = load("res://assets/textures/moss_patch.png") if ResourceLoader.exists("res://assets/textures/moss_patch.png") else null
	if not moss_tex:
		return
	
	# Scatter 25 moss patches across the arena floor
	for i in range(25):
		var x = randf_range(-half_w + 100, half_w - 100)
		var y = randf_range(-half_h + 100, half_h - 100)
		var sp = Sprite2D.new()
		sp.texture = moss_tex
		sp.position = Vector2(x, y)
		sp.scale = Vector2(randf_range(1.5, 3.0), randf_range(1.5, 3.0))
		sp.rotation_degrees = randf() * 360.0
		sp.z_index = 490  # Below bamboo, above floor
		sp.modulate = Color(0.25, 0.45, 0.2, randf_range(0.5, 0.8))
		parent.add_child(sp)

func _make_guardian_lions(parent: Node2D, half_w: float, half_h: float) -> void:
	var lion_tex = load("res://assets/textures/guardian_lion.png") if ResourceLoader.exists("res://assets/textures/guardian_lion.png") else null
	if not lion_tex:
		return
	
	# Place guardian lions at four cardinal points, just inside the arena corners
	var lion_positions = [
		Vector2(-half_w + 120, -half_h + 120),  # NW
		Vector2(half_w - 120, -half_h + 120),   # NE
		Vector2(-half_w + 120, half_h - 120),   # SW
		Vector2(half_w - 120, half_h - 120),    # SE
	]
	var lion_rotations = [45.0, -45.0, -45.0, 45.0]  # Facing inward
	
	for i in range(4):
		var sp = Sprite2D.new()
		sp.texture = lion_tex
		sp.position = lion_positions[i]
		sp.rotation_degrees = lion_rotations[i]
		sp.scale = Vector2(3.5, 3.5)
		sp.z_index = 520
		sp.modulate = Color(0.55, 0.45, 0.3, 0.95)
		parent.add_child(sp)

func _make_lantern_posts(parent: Node2D, half_w: float, half_h: float) -> void:
	var lantern_tex = load("res://assets/textures/red_lantern.png") if ResourceLoader.exists("res://assets/textures/red_lantern.png") else null
	if not lantern_tex:
		return
	
	# Place lantern posts along all four walls
	var positions = []
	# North wall
	for i in range(6):
		positions.append(Vector2(lerp(-half_w + 100, half_w - 100, float(i) / 5.0), -half_h + 60))
	# South wall
	for i in range(6):
		positions.append(Vector2(lerp(-half_w + 100, half_w - 100, float(i) / 5.0), half_h - 60))
	# West wall
	for i in range(4):
		positions.append(Vector2(-half_w + 60, lerp(-half_h + 100, half_h - 100, float(i) / 3.0)))
	# East wall
	for i in range(4):
		positions.append(Vector2(half_w - 60, lerp(-half_h + 100, half_h - 100, float(i) / 3.0)))
	
	for pos in positions:
		var sp = Sprite2D.new()
		sp.texture = lantern_tex
		sp.position = pos
		sp.scale = Vector2(1.8, 1.8)
		sp.z_index = 515
		sp.modulate = Color(1.0, 0.85, 0.6, 0.95)
		parent.add_child(sp)
		
		# Add warm glow particle effect on each lantern
		var glow = CPUParticles2D.new()
		glow.position = pos + Vector2(0, -10)
		glow.amount = 4
		glow.lifetime = 1.2
		glow.preprocess = 0.2
		glow.explosiveness = 0.3
		glow.speed_scale = 0.2
		glow.direction = Vector2(0, -1)
		glow.spread = 40.0
		glow.gravity = Vector2(0, -15)
		glow.initial_velocity_min = 5.0
		glow.initial_velocity_max = 15.0
		glow.scale_amount_min = 0.5
		glow.scale_amount_max = 1.2
		glow.color = Color(1.0, 0.6, 0.2, 0.6)
		glow.color_ramp = Gradient.new()
		glow.color_ramp.set_offsets(PackedFloat32Array([0.0, 1.0]))
		glow.color_ramp.set_colors(PackedColorArray([Color(1.0, 0.7, 0.3, 0.7), Color(1.0, 0.4, 0.1, 0.0)]))
		glow.z_index = 516
		parent.add_child(glow)

func _make_autumn_leaves(parent: Node2D, half_w: float, half_h: float) -> void:
	# Floating golden autumn leaves - full arena coverage
	var leaves = CPUParticles2D.new()
	leaves.name = "AutumnLeaves"
	leaves.amount = 60
	leaves.lifetime = 15.0
	leaves.preprocess = 5.0
	leaves.explosiveness = 0.1
	leaves.speed_scale = 0.15
	leaves.direction = Vector2(0, 1)
	leaves.spread = 90.0
	leaves.gravity = Vector2(0, 8.0)
	leaves.initial_velocity_min = 2.0
	leaves.initial_velocity_max = 8.0
	leaves.angular_velocity_min = -30.0
	leaves.angular_velocity_max = 30.0
	leaves.scale_amount_min = 0.4
	leaves.scale_amount_max = 0.9
	leaves.scale_curve = Curve.new()
	leaves.scale_curve.add_point(Vector2(0.0, 0.5))
	leaves.scale_curve.add_point(Vector2(0.3, 1.0))
	leaves.scale_curve.add_point(Vector2(1.0, 0.3))
	leaves.color = Color(1.0, 0.85, 0.3, 0.85)
	leaves.color_ramp = Gradient.new()
	leaves.color_ramp.set_offsets(PackedFloat32Array([0.0, 0.5, 1.0]))
	leaves.color_ramp.set_colors(PackedColorArray([
		Color(1.0, 0.9, 0.4, 0.9),
		Color(1.0, 0.75, 0.25, 0.85),
		Color(0.9, 0.6, 0.15, 0.0)
	]))
	leaves.z_index = 525
	# Emit from top area, spread across full arena width
	leaves.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	leaves.emission_rect_extents = Vector2(half_w * 1.5, 50.0)
	leaves.position = Vector2(0, -half_h - 30)
	leaves.emitting = true
	parent.add_child(leaves)
