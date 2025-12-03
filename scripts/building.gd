class_name Building extends Resource

@export var back_tex: Texture2D ## is randomly modulated
@export var front_tex: Texture2D ## is not modulated
@export var snow_tex: Texture2D ## is not modulated

func get_tint() -> Color:
	return Color.from_hsv(randf(), randf_range(0.2, 0.5), 1.0)

func instantiate(snowing: bool) -> TextureRect:
	var back_rect := TextureRect.new()
	back_rect.texture = back_tex
	var front_rect := TextureRect.new()
	front_rect.texture = front_tex
	back_rect.add_child(front_rect)
	if snowing:
		var snow_rect := TextureRect.new()
		snow_rect.texture = snow_tex
		back_rect.add_child(snow_rect)

	back_rect.self_modulate = get_tint()
	return back_rect
