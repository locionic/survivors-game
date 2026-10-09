extends Node

func _ready():
	await get_tree().create_timer(0.5).timeout
	var img = get_viewport().get_texture().get_image()
	img.save_png("/home/runner/.gemini/antigravity-cli/brain/9764b303-5384-4bf8-8452-1711b3f62f12/captures_audit/survivors_title_fixed.png")
	print("SAVED survivors_title_fixed.png")
	get_tree().quit()
