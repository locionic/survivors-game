class_name GameCamera
extends Camera2D

## GameCamera: Smooth player tracking with traumatic screen shake effects.

var shake_intensity: float = 0.0
var shake_decay: float = 24.0

func _ready() -> void:
	add_to_group("camera")

func _process(delta: float) -> void:
	if shake_intensity > 0.0:
		shake_intensity = max(0.0, shake_intensity - shake_decay * delta)
		offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake_intensity
	else:
		offset = Vector2.ZERO

func shake(amount: float = 8.0) -> void:
	shake_intensity = max(shake_intensity, amount)
