class_name TimedMessage extends PanelContainer

@export var label: Label
var time_left: float
var paused := true

func _ready() -> void:
	time_left = 5.0 if OS.is_debug_build() else 30.0
func _process(delta: float) -> void:
	if paused: return
	if time_left <= 0: return
	time_left -= delta
	if time_left <= 0:
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 0.0, 1.0)
		tw.tween_callback(queue_free)

func set_text(text: String) -> void:
	label.set_text(text)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not event.is_echo():
			time_left = min(time_left, 0.01)
