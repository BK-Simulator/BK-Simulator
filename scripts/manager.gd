extends PanelContainer

@export var main_menu: Container
@export var opening_scene: Control
@export var game: Control

const FADE_DUR := 1.5

func _ready() -> void:
	main_menu.set_visible(true)
	opening_scene.set_visible(false)
	game.set_visible(false)
	Archipelago.connected.connect(connected)

func connected(_conn: ConnectionInfo, _json: Dictionary) -> void:
	if main_menu.visible:
		fade_to_opening()

func fade_to_opening() -> void:
	main_menu.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_property(main_menu, "modulate:a", 0.0, FADE_DUR)
	await tw.finished
	main_menu.set_visible(false)
	opening_scene.reset()
	opening_scene.modulate.a = 1.0
	opening_scene.set_visible(true)
	await opening_scene.play()
	game.set_visible(true)
	game.modulate.a = 0.0
	tw = create_tween()
	tw.tween_property(opening_scene, "modulate:a", 0.0, FADE_DUR)
	tw.parallel().tween_property(game, "modulate:a", 1.0, FADE_DUR)
	await tw.finished
	opening_scene.set_visible(false)
	game.activate()

func fade_to_menu() -> void:
	var tw := create_tween()
	tw.tween_property(game, "modulate:a", 0.0, FADE_DUR)
	tw.tween_callback(main_menu.set_visible.bind(true))
	tw.tween_callback(game.set_visible.bind(false))
	tw.tween_property(main_menu, "modulate:a", 1.0, FADE_DUR)
	await tw.finished


func _on_back_to_menu_pressed() -> void:
	await fade_to_menu()
	Archipelago.ap_disconnect()
