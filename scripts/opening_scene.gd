extends Control

@export var lbl: Label

const TEXT_DUR = 3.0

func play() -> void:
	var tw := create_tween()
	tw.tween_property(lbl, "visible_ratio", 1.0, TEXT_DUR)
	await tw.finished
	await get_tree().create_timer(3.0).timeout

func reset() -> void:
	lbl.visible_characters = 0
