class_name MessageQueue extends Control

@export var queue_vbox: VBoxContainer
@export var message_scene: PackedScene
@export var notifier: VisibleOnScreenNotifier2D
var dirty := false

func _ready() -> void:
	notifier.screen_entered.connect(queue_refresh)
	notifier.screen_exited.connect(queue_refresh)

func queue_refresh() -> void:
	dirty = true

func queue_message(text: String) -> void:
	var msg: TimedMessage = message_scene.instantiate()
	msg.set_text(text)
	queue_vbox.add_child(msg)
	queue_vbox.move_child(msg, 0)
	msg.tree_exited.connect(queue_refresh)
	msg.tree_entered.connect(queue_refresh)
	queue_refresh()

func _process(_delta: float) -> void:
	if dirty:
		dirty = false
		refresh()
func refresh() -> void:
	if not is_node_ready():
		queue_refresh()
		return
	for child: TimedMessage in queue_vbox.get_children():
		child.paused = child.global_position.y < global_position.y or not notifier.is_on_screen()
	if queue_vbox.get_child_count() > 0:
		queue_vbox.get_child(-1).paused = not notifier.is_on_screen()
