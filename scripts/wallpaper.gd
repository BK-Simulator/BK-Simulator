extends TextureRect

var tint: Color

func _ready() -> void:
	random()

func random() -> void:
	tint = Color.from_hsv(randf(), randf_range(0, 0.2) * randf_range(0.5, 1.0), 1.0)
	set_instance_shader_parameter(&"tint_color", tint)
