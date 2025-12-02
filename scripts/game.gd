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
@export_group("")

signal return_to_menu
signal play_opening
signal open_game

const MILES := 60
const RUN_SPEED := 5
enum Weather {
	NONE = -1, CLEAR, RAIN, SNOW
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
var current_weather: Weather
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
func load_slot_data(conn: ConnectionInfo) -> void:
	locs_per_weather = conn.slot_data["LocsPerWeather"]
	bk_start_miles = conn.slot_data["StartDistance"]
	speed_per_upgrade = conn.slot_data["SpeedPerUpgrade"]

func refresh() -> void:
	runwalk_label.text = "%s Speed:" % ("Walk" if run_speed < RUN_SPEED else "Run")
	speed_label.text = str(run_speed)
	rain_label.text = str(run_speed / 2.0)
	snow_label.text = str(snow_speed)
	distance_label.text = str(bk_position / float(MILES))

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
	Archipelago.connected.connect(on_connect)
	Archipelago.remove_location.connect(refr_locs.unbind(1))

func on_connect(conn: ConnectionInfo, _json: Dictionary) -> void:
	conn.obtained_item.connect(item_get)
	conn.refresh_items.connect(item_refr)
	load_slot_data(conn)
	reset_item()
	current_position = 0
	current_weather = Weather.NONE
	connected_key = "BK_Simulator_%d" % conn.player_id
	conn.retrieve(connected_key, resume_from_server)
	refresh()
	refr_locs()
	in_focus = get_window().has_focus()
	init_backdrop()
	paused = false

func item_get(item: NetworkItem) -> void:
	var iname: String = item.get_name()
	match iname.to_upper():
		"BETTER SHOES":
			run_speed += speed_per_upgrade
		"SNOW BOOTS":
			snow_speed += speed_per_upgrade / 2.0
			snow_button.disabled = false
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

func resume_from_server(data: Variant) -> void:
	if data is Dictionary:
		if data.is_empty(): return
		current_position = data["pos"]
		current_weather = data["weather"] as Weather
		direction = data["dir"]
		init_backdrop()
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
		direction = 1
		init_backdrop()

func init_backdrop() -> void:
	buttons.set_visible(current_weather == Weather.NONE)
	progress.set_visible(current_weather != Weather.NONE)
	# TODO: Set up backdrop generation

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		in_focus = true
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		in_focus = false

func _physics_process(_delta: float) -> void:
	#if not in_focus: return
	if paused: return
	if current_weather == Weather.NONE: return
	current_position += get_speed() * direction
	if roundi(current_position) % 50 == 0:
		save_to_server()
	if direction > 0:
		if current_position >= bk_position:
			current_position = bk_position
			if not in_focus: return
			var start_key := (current_weather as int) * 100 + 1
			for loc in range(start_key, start_key + locs_per_weather):
				if not Archipelago.conn.slot_locations[loc]:
					Archipelago.collect_location(loc)
					break
			# TODO: Reach BK animation
			direction = -1
		else:
			# TODO: Move the backdrop in some way
			pass
	else:
		if current_position <= 0:
			current_position = 0
			if not in_focus: return
			# TODO: Reach home
			if remaining_locations == 0:
				Archipelago.set_client_status(AP.ClientStatus.CLIENT_GOAL)
			current_weather = Weather.NONE
			direction = 1
			init_backdrop()
		else:
			# TODO: Move the backdrop in some way
			pass
