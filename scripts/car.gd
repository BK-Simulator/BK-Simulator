class_name Car extends Resource

@export var body_tex: Texture2D
@export var extra_tex: Texture2D
@export_range(1, 100, 1, "or_greater") var weight: int = 1 ## weight for random picking

func get_tint() -> Color:
	if randf() < 0.2: # grayscale
		return Color.from_hsv(0.0, 0.0, randf())
	return Color.from_hsv(randf(), randf_range(0.8, 1.0), randf_range(0.8, 1.0))

func instantiate() -> TextureRect:
	var body_rect := TextureRect.new()
	body_rect.texture = body_tex
	var extra_rect := TextureRect.new()
	extra_rect.texture = extra_tex
	body_rect.add_child(extra_rect)
	body_rect.self_modulate = get_tint()
	return body_rect
