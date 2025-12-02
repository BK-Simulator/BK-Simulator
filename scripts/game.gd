extends Control

@export_group("Nodes")
@export var runwalk_label: Label
@export var speed_label: Label
@export var rain_label: Label
@export var snow_label: Label
@export var distance_label: Label
@export_group("")

signal return_to_menu

const MILES := 60
const RUN_SPEED := 5
enum Weather {
	NONE = -1, CLEAR, RAIN, SNOW
}

# Stats, which change when you get items
var run_speed: int
var snow_speed: int
var bk_position: int
# slot data
var locs_per_weather: int
var bk_start_miles: int
var speed_per_upgrade: int
# other
var current_position: int
var current_weather: Weather
var connected_key: String

func reset_item() -> void:
	run_speed = 1
	snow_speed = 0
	bk_position = bk_start_miles * MILES
func load_slot_data(conn: ConnectionInfo) -> void:
	locs_per_weather = conn.slot_data["LocsPerWeather"]
	bk_start_miles = conn.slot_data["StartMiles"]

func activate() -> void:
	refresh()

func refresh() -> void:
	runwalk_label.text = "%s Speed:" % ("Walk" if run_speed < RUN_SPEED else "Run")
	speed_label.text = str(run_speed)
	rain_label.text = str(run_speed / 2.0)
	snow_label.text = str(snow_speed)
	distance_label.text = str(bk_position / float(MILES))

func _ready() -> void:
	Archipelago.connected.connect(on_connect)

func on_connect(conn: ConnectionInfo, _json: Dictionary) -> void:
	conn.obtained_item.connect(item_get)
	conn.refresh_items.connect(item_refr)
	load_slot_data(conn)
	reset_item()
	current_position = -1
	current_weather = Weather.NONE
	connected_key = "BK_Simulator_%d" % conn.player_id
	conn.retrieve(connected_key, resume_from_server)

func item_get(item: NetworkItem) -> void:
	var iname: String = item.get_name()
	match iname.to_upper():
		"BETTER SHOES":
			run_speed += speed_per_upgrade

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

func save_to_server() -> void:
	Archipelago.send_command("Set", {
		"key": connected_key,
		"default": {},
		"want_reply": false,
		"operations": [
			{"operation": "replace", "value": {
				"pos": current_position,
				"weather": current_weather as int,
			}}
		]
	})

func _on_back_to_menu_pressed() -> void:
	save_to_server()
	return_to_menu.emit()
