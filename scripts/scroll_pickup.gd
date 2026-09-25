class_name ScrollPickup
extends Area2D

## Collectible Martial Arts Secret Scroll (Võ Học Bí Tịch).

@export var scroll_id: String = "yijinjing"
@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")
@onready var name_label: Label = get_node_or_null("NameLabel")

var time_passed: float = 0.0
var target: Node2D = null
var current_speed: float = 80.0
var scroll_info: Dictionary = {}

func _ready() -> void:
	add_to_group("scrolls")
	time_passed = randf() * 10.0
	body_entered.connect(_on_body_entered)
	_setup_visuals()
	
	scale = Vector2.ZERO
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK)

func set_scroll(new_id: String) -> void:
	scroll_id = new_id
	_setup_visuals()

func _setup_visuals() -> void:
	if GameManager and GameManager.MARTIAL_SCROLLS.has(scroll_id):
		scroll_info = GameManager.MARTIAL_SCROLLS[scroll_id]
	else:
		scroll_info = {"name": "Võ Học Bí Tịch", "texture_path": "res://assets/textures/scroll_gold.png", "color": Color.GOLD}
		
	if sprite:
		var tex_p = scroll_info.get("texture_path", "res://assets/textures/scroll_gold.png")
		if ResourceLoader.exists(tex_p):
			sprite.texture = load(tex_p)
			
	if name_label:
		name_label.text = scroll_info.get("name", "Bí Tịch")
		var col = scroll_info.get("color", Color(1.0, 0.85, 0.2))
		name_label.add_theme_color_override("font_color", col)

func _process(delta: float) -> void:
	time_passed += delta
	
	if is_instance_valid(target):
		current_speed += 900.0 * delta
		global_position = global_position.move_toward(target.global_position, current_speed * delta)
		if global_position.distance_to(target.global_position) < 20.0:
			_collect()
		return
		
	if sprite:
		sprite.position.y = sin(time_passed * 4.0) * 4.5
		sprite.scale = Vector2.ONE * (1.0 + 0.08 * sin(time_passed * 5.0))

func _draw() -> void:
	var col = scroll_info.get("color", Color(1.0, 0.85, 0.2))
	draw_circle(Vector2(0, 8), 16.0, Color(col.r, col.g, col.b, 0.25))
	draw_arc(Vector2(0, 8), 17.0, 0, TAU, 24, Color(col.r, col.g, col.b, 0.8), 2.0)

func target_player(player_ref: Node2D) -> void:
	target = player_ref

func _collect() -> void:
	if GameManager:
		GameManager.add_scroll(scroll_id)
		var s_name = scroll_info.get("name", "Bí Tịch Cổ")
		FloatingText.spawn(global_position + Vector2(0, -26), "📜 BÍ TỊCH: %s!" % s_name.to_upper(), scroll_info.get("color", Color(1.0, 0.85, 0.2)))
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_collect()
