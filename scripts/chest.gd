class_name TreasureChest
extends Area2D

## Treasure Chest dropped by bosses giving massive gold and free upgrade card selection.

func _ready() -> void:
	add_to_group("chests")
	# Gentle hover/bounce
	var tween = create_tween().set_loops()
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.5)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.5)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		collect(body)

func collect(player_ref: Node2D) -> void:
	# Expansion 21.0: Bảo Rương Kim Quy — cinematic jackpot ceremony.
	# open_treasure_chest() rolls the tier, applies the upgrades, pays the gold
	# and re-freezes the tree; the HUD plays the modal off the chest_opened signal.
	SoundManager.play("level_up")
	FloatingText.spawn(global_position, "🧰 BẢO RƯƠNG KIM QUY!", Color(1.0, 0.85, 0.1))
	get_tree().paused = true
	GameManager.open_treasure_chest(player_ref)

	queue_free()
