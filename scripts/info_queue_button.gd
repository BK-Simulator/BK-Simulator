@tool class_name InfoQueueButton extends Button

@export_multiline var info_text: String

func _init() -> void:
	text = " ? "
func _ready() -> void:
	if Engine.is_editor_hint(): return
	pressed.connect(send_info)

func send_info() -> void:
	get_tree().call_group("MessageQueues", "queue_message", info_text)
