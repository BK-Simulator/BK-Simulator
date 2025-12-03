extends Control

@export_group("Nodes")
@export var runwalk_label: Label
@export var speed_label: Label
@export var rain_label: Label
@export var snow_label: Label
@export var distance_label: Label
@export var sun_button: Button
@export var rain_button: Button
@export var snow_button: Button
@export var buttons: MarginContainer
@export var progress: MarginContainer
@export var progress_label: Label
@export var embark_label: Label
@export var moving_backdrop: MovingBackdrop
@export var message_queue: MessageQueue
@export_group("")

signal return_to_menu
signal play_opening
signal play_ending
signal open_game

const MILES := 60
const RUN_SPEED := 5
const FADE_DUR := 1.0
enum Weather {
	NONE = -1, SUN, RAIN, SNOW
}

# Stats, which change when you get items
var run_speed: float
var snow_speed: float
var bk_position: int
# slot data
var locs_per_weather: int
var bk_start_miles: int
var speed_per_upgrade: int
# other
var current_position: float :
	set(val):
		current_position = val
		progress_label.text = "%.2f" % (current_position / MILES)
var current_weather: Weather :
	set(val):
		current_weather = val
		if val != Weather.NONE:
			for node in moving_backdrop.sunny_nodes:
				node.set_visible(val == Weather.SUN)
			for node in moving_backdrop.rainy_nodes:
				node.set_visible(val == Weather.RAIN)
			for node in moving_backdrop.snowy_nodes:
				node.set_visible(val == Weather.SNOW)
var direction: int = 1
var remaining_locations: int = -1
var connected_key: String
var in_focus: bool = false
var paused: bool = true

func reset_item() -> void:
	run_speed = 1
	snow_speed = 0
	bk_position = bk_start_miles * MILES
	snow_button.disabled = true
	snow_button.focus_mode = FOCUS_NONE
func load_slot_data(conn: ConnectionInfo) -> void:
	locs_per_weather = conn.slot_data["LocsPerWeather"]
	bk_start_miles = conn.slot_data["StartDistance"]
	speed_per_upgrade = conn.slot_data["SpeedPerUpgrade"]

func refresh() -> void:
	runwalk_label.text = "%s Speed:" % ("Walk" if run_speed < RUN_SPEED else "Run")
	speed_label.text = str(run_speed)
	rain_label.text = str(run_speed / 2.0)
	snow_label.text = str(snow_speed)
	distance_label.text = str(roundi(bk_position / float(MILES)))

func get_speed() -> float:
	if current_weather == Weather.SNOW:
		return snow_speed
	if current_weather == Weather.RAIN:
		return run_speed / 2.0
	return run_speed

func refr_locs() -> void:
	sun_button.set_visible(false)
	rain_button.set_visible(false)
	snow_button.set_visible(false)
	var sun_count := 0
	var rain_count := 0
	var snow_count := 0
	for key in Archipelago.conn.slot_locations:
		if not Archipelago.conn.slot_locations[key]:
			if key <= 100:
				sun_button.set_visible(true)
				sun_count += 1
			elif key <= 200:
				rain_button.set_visible(true)
				rain_count += 1
			elif key <= 300:
				snow_button.set_visible(true)
				snow_count += 1
	sun_button.text = "Sunny Weather (%d)" % sun_count
	rain_button.text = "Rainy Weather (%d)" % rain_count
	snow_button.text = "Snowy Weather (%d)" % snow_count
	remaining_locations = sun_count + rain_count + snow_count
	embark_label.text = "Embark:" if remaining_locations else "GOAL COMPLETE!"

func _ready() -> void:
	randomize_wallpaper()
	Archipelago.connected.connect(on_connect)
	Archipelago.remove_location.connect(refr_locs.unbind(1))
	Archipelago.printjson.connect(printjson)
	sun_button.pressed.connect(_on_embark.bind(Weather.SUN))
	rain_button.pressed.connect(_on_embark.bind(Weather.RAIN))
	snow_button.pressed.connect(_on_embark.bind(Weather.SNOW))

func printjson(json: Dictionary, text: String) -> void:
	if json.get("type") == "Tutorial" and "!help" in text:
		return
	message_queue.queue_message(BaseConsole.printjson_out_str(json["data"]))

func on_connect(conn: ConnectionInfo, _json: Dictionary) -> void:
	message_queue.queue_message("Click to instantly dismiss messages.")
	conn.obtained_item.connect(item_get)
	conn.refresh_items.connect(item_refr)
	load_slot_data(conn)
	reset_item()
	current_position = 0
	current_weather = Weather.NONE
	connected_key = "BK_Simulator_%d" % conn.player_id
	conn.retrieve(connected_key, resume_from_server)
	conn.force_scout_all()
	refresh()
	refr_locs()
	in_focus = get_window().has_focus()
	paused = false

func item_get(item: NetworkItem) -> void:
	var iname: String = item.get_name()
	match iname.to_upper():
		"BETTER SHOES":
			run_speed += speed_per_upgrade
		"SNOW BOOTS":
			snow_speed += speed_per_upgrade / 2.0
			snow_button.disabled = false
			snow_button.focus_mode = FOCUS_ALL
		"NEW LOCATION":
			bk_position /= 2
	refresh()

func item_refr(items: Array[NetworkItem]) -> void:
	reset_item()
	for item in items:
		item_get(item)

func _exit_tree() -> void:
	if Archipelago.is_ap_connected():
		save_to_server()

func randomize_wallpaper() -> void:
	RenderingServer.global_shader_parameter_set_override(&"wallpaper_tint", Color.from_hsv(randf(), randf_range(0, 0.2) * randf_range(0.5, 1.0), 1.0))

func resume_from_server(data: Variant) -> void:
	if data == null:
		data = {
			"pos": 0,
			"weather": Weather.NONE,
			"dir": 1,
		}
	if data is Dictionary:
		if data.is_empty(): return
		current_position = data["pos"]
		current_weather = data["weather"] as Weather
		set_direction(data["dir"])
		randomize_wallpaper()
		init_backdrop(true)
		if current_weather == Weather.NONE and remaining_locations > 0:
			play_opening.emit()
		else:
			open_game.emit()

func save_to_server() -> void:
	Archipelago.send_command("Set", {
		"key": connected_key,
		"default": {},
		"want_reply": false,
		"operations": [
			{"operation": "replace", "value": {
				"pos": roundi(current_position),
				"weather": current_weather as int,
				"dir": direction,
			}}
		]
	})

func _on_back_to_menu_pressed() -> void:
	save_to_server()
	return_to_menu.emit()
	paused = true

func _on_embark(weather: int) -> void:
	if current_weather == Weather.NONE:
		current_weather = weather as Weather
		current_position = 0
		set_direction(1)
		init_backdrop()

func init_backdrop(instant := false) -> void:
	var active := current_weather != Weather.NONE
	buttons.set_visible(not active)
	progress.set_visible(active)
	moving_backdrop.set_visible(active)
	if active:
		moving_backdrop.populate_buildings()
	if instant:
		moving_backdrop.modulate.a = 1.0 if active else 0.0
		paused = not active
	else:
		paused = true
		var tw := create_tween()
		tw.tween_property(moving_backdrop, "modulate:a", 1.0 if active else 0.0, FADE_DUR)
		if active:
			tw.tween_callback(func(): paused = false)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		in_focus = true
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		in_focus = false

func _physics_process(_delta: float) -> void:
	if not in_focus: return
	if paused: return
	if current_weather == Weather.NONE: return
	var dx := get_speed() * direction
	current_position += dx
	#current_position = bk_position - 1 * MILES
	#current_position = 1 * MILES
	if roundi(current_position) % 50 == 0:
		save_to_server()
	if direction > 0:
		if current_position >= bk_position:
			current_position = bk_position
			#if not in_focus: return
			var start_key := (current_weather as int) * 100 + 1
			for loc in range(start_key, start_key + locs_per_weather):
				if not Archipelago.conn.slot_locations[loc]:
					Archipelago.collect_location(loc)
					break
			paused = true
			moving_backdrop.bk_mode = true
			while not moving_backdrop.bk_building or (moving_backdrop.bk_building.position.x + moving_backdrop.bk_building.size.x / 2.0 > 320):
				var limit: float = (moving_backdrop.bk_building.position.x + moving_backdrop.bk_building.size.x / 2.0 - 320) if moving_backdrop.bk_building else 320.0
				var dist := minf(limit, dx * 2)
				moving_backdrop.move_by(dist)
				await get_tree().physics_frame
			# TODO Popup for what you got
			paused = false
			set_direction(-1)
		else:
			moving_backdrop.move_by(dx)
	else:
		if current_position <= 0:
			current_position = 0
			#if not in_focus: return
			if remaining_locations == 0:
				play_ending.emit()
				Archipelago.set_client_status(AP.ClientStatus.CLIENT_GOAL)
			current_weather = Weather.NONE
			set_direction(1)
			init_backdrop()
		else:
			moving_backdrop.move_by(dx)

func set_direction(dir: int) -> void:
	assert(dir == 1 or dir == -1)
	if direction != dir:
		direction = dir
		moving_backdrop.swap_direction()
