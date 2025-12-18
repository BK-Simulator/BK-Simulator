class_name Building extends Resource

@export var back_tex: Texture2D ## is randomly modulated
@export var front_tex: Texture2D ## is not modulated
@export var snow_texs: Array[Texture2D] ## is not modulated
@export_range(1, 100, 1, "or_greater") var weight: int = 1 ## weight for random picking

var last_snow_tex: Texture2D = null

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
		var snow_tex: Texture2D = snow_texs.pick_random()
		if snow_texs.size() > 1: # avoid repeats, if multiple options exist
			while snow_tex == last_snow_tex:
				snow_tex = snow_texs.pick_random()
		snow_rect.texture = snow_tex
		last_snow_tex = snow_tex
		back_rect.add_child(snow_rect)

	back_rect.self_modulate = get_tint()
	return back_rect
