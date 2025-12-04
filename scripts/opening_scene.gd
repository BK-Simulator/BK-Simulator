class_name TextScene extends Control

@export var lbl: Label
@export var spinner: Sprite2D

signal anim_done
signal delay_done

var rate := 0.0
var start_delay := 0.0
var delay_left := 0.0

func _ready() -> void:
	modulate.a = 0.0
	visible = false

func play(text: String, dur := 3.0, delay := 3.0) -> void:
	lbl.text = text
	lbl.visible_characters = 0
	lbl.visible_ratio = 0.0
	modulate.a = 1.0
	spinner.visible = false
	rate = 1.0 / dur
	start_delay = delay
	delay_left = delay
	await anim_done
	await delay_done

func _process(delta: float) -> void:
	if visible and modulate.a <= 0.0:
		visible = false
	elif modulate.a > 0.0 and not visible:
		visible = true

	if rate >= 0.0:
		lbl.visible_ratio += rate * delta
		if lbl.visible_ratio >= 1.0:
			anim_done.emit()
			rate = -1.0
			if delay_left > 0.0:
				spinner.visible = true
				spinner.frame = 0
	elif delay_left > 0.0:
		delay_left -= delta
		spinner.frame = lerp(0, 15, 1.0 - (delay_left / start_delay))
		if delay_left <= 0.0:
			spinner.visible = false
			delay_done.emit()

func reset() -> void:
	lbl.text = ""
	lbl.visible_characters = 0
	spinner.visible = false
	visible = false

func _on_panel_container_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not event.is_echo():
			if rate > 0.0:
				rate *= 3.0
			elif delay_left > 0.5:
				delay_left = 0.5
