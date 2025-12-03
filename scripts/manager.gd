extends PanelContainer

@export var main_menu: Container
@export var opening_scene: Control
@export var game: Control

const FADE_DUR := 1.5
var in_transition: bool = false

func _ready() -> void:
	randomize_wallpaper()
	main_menu.set_visible(true)
	opening_scene.set_visible(false)
	game.set_visible(false)

func randomize_wallpaper() -> void:
	RenderingServer.global_shader_parameter_set_override(&"wallpaper_tint", Color.from_hsv(randf(), randf_range(0, 0.2) * randf_range(0.5, 1.0), 1.0))

signal transition_end
func fade_to_opening() -> void:
	if in_transition: await transition_end
	in_transition = true
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
	in_transition = false
	transition_end.emit()

func fade_to_game() -> void:
	if in_transition: await transition_end
	in_transition = true
	main_menu.modulate.a = 1.0
	game.modulate.a = 0.0
	game.set_visible(true)
	var tw := create_tween()
	tw.tween_property(main_menu, "modulate:a", 0.0, FADE_DUR)
	tw.parallel().tween_property(game, "modulate:a", 1.0, FADE_DUR)
	await tw.finished
	main_menu.set_visible(false)
	in_transition = false
	transition_end.emit()

func fade_to_menu() -> void:
	if in_transition: return
	in_transition = true
	main_menu.modulate.a = 0.0
	main_menu.set_visible(true)
	var tw := create_tween()
	tw.tween_property(game, "modulate:a", 0.0, FADE_DUR)
	tw.parallel().tween_property(main_menu, "modulate:a", 1.0, FADE_DUR)
	tw.tween_callback(game.set_visible.bind(false))
	await tw.finished
	in_transition = false
	transition_end.emit()

func _on_back_to_menu_pressed() -> void:
	randomize_wallpaper()
	await fade_to_menu()
	Archipelago.ap_disconnect()
