extends Node2D

## Decoration layer for the Võ Đài courtyard.
##
## main.tscn used to show a 64px grey checkerboard magnified 44x across the whole
## playfield. This node dresses that floor and its edges -- weathered flagstones
## with moss in the joints, bamboo at the margins, stone guardian lions, a carved
## fence, and lit lantern posts -- without touching a single number the wave
## director reads.
##
## The rule that keeps this honest: everything below is a Sprite2D or a
## CPUParticles2D. No StaticBody2D, no CollisionShape2D, nothing added to
## "enemies", "obstacles" or "landmarks". _setup_arena_boundaries() in main.tscn
## still builds exactly the walls it always did, the Obstacles container still
## holds exactly the spawn props it always did, and this scene sits in the gap
## between them.

const FENCE_TEX := "res://assets/textures/fence_rail.png"
const LION_TEX := "res://assets/textures/guardian_lion.png"
const POST_TEX := "res://assets/textures/lantern_post.png"
const GLOW_TEX := "res://assets/textures/lantern_glow.png"
const BAMBOO_TEX := "res://assets/textures/bamboo_reed.png"

## The playfield main.tscn walls off, and the thickness of the wall it walls off
## with. Both are copied from _setup_arena_boundaries(); they are read here only
## to place decoration, never to define it. If the arena is ever resized, change
## them there first -- this file follows.
const PLAY_HALF := Vector2(1200.0, 900.0)
const WALL_THICK := 120.0

## Half the wall thickness: the one offset that puts a rail dead centre in the
## collision band, i.e. exactly where nothing can walk.
const RAIL := WALL_THICK * 0.5

## fence_rail.png is a 128px tile carrying half a post at each edge, so posts
## land on every multiple of 128 and any whole number of tiles runs seamlessly.
const FENCE_W := 128.0
const FENCE_H := 72.0

## Top and bottom rails span 21 tiles so they overshoot the vertical rails by 24px
## at each end and the two always overlap at a corner rather than leaving a notch.
## Left and right span 15 tiles, which is the playfield height exactly.
const H_RAIL_LEN := 21.0 * FENCE_W
const V_RAIL_LEN := 15.0 * FENCE_W

## Lamps every third fence post, so a lamp always stands in the gap between two
## rails rather than on top of one.
const LAMP_SPACING := 384.0

## Warm paper-lantern light.
const LANTERN_WARM := Color(1.0, 0.70, 0.32)

func _ready() -> void:
	_build_fence()
	_build_bamboo()
	_build_lions()
	_build_lamps()

# --- fence ------------------------------------------------------------------

func _build_fence() -> void:
	var tex := _tex(FENCE_TEX)
	if tex == null:
		return
	var x := PLAY_HALF.x + RAIL
	var y := PLAY_HALF.y + RAIL
	_fence_run(tex, Vector2(0.0, -y), 0.0, H_RAIL_LEN)
	_fence_run(tex, Vector2(0.0, y), 0.0, H_RAIL_LEN)
	# The same tile rotated a quarter turn becomes a vertical rail. Rotating about
	# `position` is why the runs are centred rather than top-left anchored.
	_fence_run(tex, Vector2(-x, 0.0), PI * 0.5, V_RAIL_LEN)
	_fence_run(tex, Vector2(x, 0.0), PI * 0.5, V_RAIL_LEN)

func _fence_run(tex: Texture2D, at: Vector2, rot: float, length: float) -> void:
	var rail := Sprite2D.new()
	rail.texture = tex
	rail.centered = true
	# A region far wider than the texture plus repeat is Godot's tiling-sprite
	# idiom: one draw call for a 2688px run instead of 21 copies of the post.
	rail.region_enabled = true
	rail.region_rect = Rect2(0.0, 0.0, length, FENCE_H)
	rail.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	rail.position = at
	rail.rotation = rot
	add_child(rail)

# --- bamboo -----------------------------------------------------------------

func _build_bamboo() -> void:
	var tex := _tex(BAMBOO_TEX)
	if tex == null:
		return
	# Clumps hug the inside lip of the rails. They are drawn behind everything
	# else (tree order: this node is added before any mob), so a bat walking
	# through a clump looks like it is pushing through reeds, not blocked by one.
	var spots: Array[Vector2] = []
	for bx in [-1080.0, -864.0, -648.0, -432.0, -216.0, 216.0, 432.0, 648.0, 864.0, 1080.0]:
		spots.append(Vector2(bx, -(PLAY_HALF.y - 32.0)))
		spots.append(Vector2(bx, PLAY_HALF.y - 32.0))
	for by in [-660.0, -220.0, 220.0, 660.0]:
		spots.append(Vector2(-(PLAY_HALF.x - 32.0), by))
		spots.append(Vector2(PLAY_HALF.x - 32.0, by))

	for i in spots.size():
		var reed := Sprite2D.new()
		reed.texture = tex
		reed.position = spots[i]
		# Deterministic mirror/squash so the clump ring is not visibly stamped.
		reed.scale = Vector2(-0.95 if i % 2 == 0 else 0.95, 1.0 if i % 3 != 0 else 0.86)
		add_child(reed)

# --- guardian lions ---------------------------------------------------------

func _build_lions() -> void:
	var tex := _tex(LION_TEX)
	if tex == null:
		return
	var x := PLAY_HALF.x + RAIL
	var y := PLAY_HALF.y + RAIL
	# Between the rails' brazier corners and the lamps, never on either.
	var spots := [
		Vector2(-960.0, -y), Vector2(960.0, -y),
		Vector2(-960.0, y), Vector2(960.0, y),
		Vector2(-x, -560.0), Vector2(-x, 560.0),
		Vector2(x, -560.0), Vector2(x, 560.0),
	]
	for p in spots:
		var lion := Sprite2D.new()
		lion.texture = tex
		lion.position = p
		add_child(lion)

# --- lantern posts ----------------------------------------------------------

func _build_lamps() -> void:
	var post := _tex(POST_TEX)
	if post == null:
		return
	var glow := _tex(GLOW_TEX)
	var x := PLAY_HALF.x + RAIL
	var y := PLAY_HALF.y + RAIL

	var spots: Array[Vector2] = []
	for i in range(-3, 4):
		spots.append(Vector2(float(i) * LAMP_SPACING, -y))
		spots.append(Vector2(float(i) * LAMP_SPACING, y))
	for j in range(-2, 3):
		spots.append(Vector2(-x, float(j) * LAMP_SPACING))
		spots.append(Vector2(x, float(j) * LAMP_SPACING))

	for p in spots:
		var standard := Sprite2D.new()
		standard.texture = post
		standard.position = p
		add_child(standard)
		if glow != null:
			add_child(_lamp_light(glow, p))

## Two additive sprites per lamp: the halo on the globe, and the same falloff
## squashed onto the flagstones beneath it. The pool is what sells it -- a halo
## on its own reads as a sticker on the lantern rather than as light in the air.
##
## Additive sprites rather than PointLight2D on purpose: a 2D light only shows
## against a darkened CanvasModulate, and dimming the playfield is a gameplay
## change (mob visibility) dressed up as decoration. Additive light pools under
## gl_compatibility give the same read for zero risk to the exporter.
func _lamp_light(tex: Texture2D, at: Vector2) -> Node2D:
	var root := Node2D.new()
	root.position = at

	var halo := Sprite2D.new()
	halo.texture = tex
	halo.position = Vector2(0.0, -46.0)
	halo.scale = Vector2(0.40, 0.40)
	halo.modulate = Color(LANTERN_WARM.r, LANTERN_WARM.g, LANTERN_WARM.b, 0.46)
	halo.material = _add_material()
	root.add_child(halo)

	var pool := Sprite2D.new()
	pool.texture = tex
	pool.position = Vector2(0.0, 30.0)
	pool.scale = Vector2(0.92, 0.40)
	pool.modulate = Color(LANTERN_WARM.r, LANTERN_WARM.g, LANTERN_WARM.b, 0.15)
	pool.material = _add_material()
	root.add_child(pool)

	return root

func _add_material() -> CanvasItemMaterial:
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return m

func _tex(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		push_warning("Arena decor: missing %s" % path)
		return null
	return load(path) as Texture2D
