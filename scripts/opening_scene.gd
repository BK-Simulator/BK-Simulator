class_name TextScene extends Control

@export var lbl: Label

func play(text: String, dur := 3.0, delay := 3.0) -> void:
	lbl.text = text
	lbl.visible_characters = 0
	visible = true
	modulate.a = 1.0
	var tw := create_tween()
	tw.tween_method(lbl.set_visible_ratio, 0.0, 1.0, dur)
	await tw.finished
	await get_tree().create_timer(delay).timeout

func reset() -> void:
	lbl.text = ""
	lbl.visible_characters = 0
