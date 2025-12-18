extends PanelContainer

signal debug_mode(val: bool)

@export var main_menu: Container
@export var text_scene: TextScene
@export var game: BKSim_Game
@export var rain_sfx: FadeSFXPlayer

@export var web_nodes: Array[Control]
@export var non_web_nodes: Array[Control]

const FADE_DUR := 1.5
var in_transition: bool = false

func _ready() -> void:
	debug_mode.emit(OS.is_debug_build())
	randomize_wallpaper()
	main_menu.set_visible(true)
	text_scene.set_visible(false)
	game.set_visible(false)
	var web := OS.has_feature("web")
	for node in web_nodes:
		node.set_visible(web)
	for node in non_web_nodes:
		node.set_visible(not web)
	_on_sfx_slider_value_changed(sfx_vol)
	_on_environment_slider_value_changed(environment_vol)

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
	rain_sfx.fade_end(FADE_DUR)
	var tw := create_tween()
	tw.tween_property(game, "modulate:a", 0.0, FADE_DUR)
	tw.parallel().tween_property(main_menu, "modulate:a", 1.0, FADE_DUR)
	tw.tween_callback(game.set_visible.bind(false))
	await tw.finished
	Archipelago.set_deathlink(false)
	in_transition = false
	transition_end.emit()

func _on_back_to_menu_pressed() -> void:
	randomize_wallpaper()
	await fade_to_menu()
	Archipelago.ap_disconnect()

var sfx_vol := 50.0
var environment_vol := 50.0
func _on_sfx_slider_value_changed(value: float) -> void:
	sfx_vol = value
	var idx := AudioServer.get_bus_index(&"SFX")
	AudioServer.set_bus_volume_linear(idx, value / 100.0)

func _on_environment_slider_value_changed(value: float) -> void:
	environment_vol = value
	var idx := AudioServer.get_bus_index(&"Environment")
	AudioServer.set_bus_volume_linear(idx, value / 100.0)


func _debug_die() -> void:
	if OS.is_debug_build():
		if game.get_deathlink():
			game.on_linked_death("DEBUG", "PRESSED THE DIE BUTTON")


func _on_stop_debug_pressed() -> void:
	debug_mode.emit(false)
