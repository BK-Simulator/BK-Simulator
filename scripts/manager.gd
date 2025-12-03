extends PanelContainer

@export var main_menu: Container
@export var text_scene: TextScene
@export var game: BKSim_Game

const end_names: Array[String] = ["EmilyV"]

const FADE_DUR := 1.5
var in_transition: bool = false

func _ready() -> void:
	randomize_wallpaper()
	main_menu.set_visible(true)
	text_scene.set_visible(false)
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
	await text_scene.play("Damn... BK'd again.\nGuess it's time to grab lunch.", 3.0, 3.0)
	game.set_visible(true)
	game.modulate.a = 0.0
	tw = create_tween()
	tw.tween_property(text_scene, "modulate:a", 0.0, FADE_DUR)
	tw.parallel().tween_property(game, "modulate:a", 1.0, FADE_DUR)
	await tw.finished
	text_scene.set_visible(false)
	in_transition = false
	transition_end.emit()

func fade_to_ending(done: bool) -> void:
	if in_transition: await transition_end
	in_transition = true
	var tw := create_tween()
	tw.tween_property(game, "modulate:a", 0.0, FADE_DUR)
	await tw.finished
	if done:
		await text_scene.play("Oh, finally! %s sent me the item I was waiting for.\nNow I can keep playing Archipelago!" % end_names.pick_random(), 4.0, 10.0)
	else:
		await text_scene.play("Still in BK Mode...", 2.0, 2.0)
	tw = create_tween()
	tw.tween_property(text_scene, "modulate:a", 0.0, FADE_DUR)
	tw.parallel().tween_property(game, "modulate:a", 1.0, FADE_DUR)
	await tw.finished
	text_scene.set_visible(false)
	game.paused = false
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
