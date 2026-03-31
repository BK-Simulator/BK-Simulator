class_name BKSim_Game extends Control

const end_names: Array[String] = ["EmilyV"]

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
@export var stats: Container
@export var text_scene: TextScene
@export var settings_panel: MarginContainer
@export var rain_sfx: FadeSFXPlayer
@export var deathlink_checkbox: CheckBox
@export var deathlink_group_edit: LineEdit
@export_group("")

signal return_to_menu
signal unintentional_disconnect
signal play_opening
signal open_game

signal unpaused

const MILES := 60
const RUN_SPEED := 5
const FADE_DUR := 1.0
enum Weather {
	NONE = -1, SUN, RAIN, SNOW
}
enum State {
	HOME, TO_BK_RIGHT, TO_BK_LEFT, FROM_BK, GOAL, DYING, HOSPITAL
}

const AUTOSAVE_DURATION := 60.0 # 1 minute
# Stats, which change when you get items
var run_speed: float
var snow_speed: float
var bk_position: int

# slot data values, updated on connection
var locs_per_weather: int
var bk_start_miles: int
var speed_per_upgrade: int

# saved data, saved to the server
var current_position: float :
	set(val):
		current_position = val
		progress_label.text = "%.2f" % (current_position / MILES)
var current_weather: Weather :
	set(val):
		if val != current_weather:
			weather_changed = true
		current_weather = val
var post_cutscene_state: State = State.HOME

# other live data
var current_state: State = State.HOME
var direction: int = 1
var remaining_locations: int = -1

var autosave_timer: float = AUTOSAVE_DURATION
var connected_key: String
var in_focus: bool = false
var paused: bool = true : set = set_paused
var goaled: bool = false
var weather_changed := false
var expecting_disconnect := true

# DeathLink data
var dying_source: String
var dying_cause: String
var car: TextureRect

func get_deathlink() -> bool:
	return Archipelago.is_deathlink()
func set_deathlink(val: bool) -> void:
	Archipelago.set_deathlink(val)
	deathlink_checkbox.set_pressed_no_signal(val)
func get_deathlink_group() -> String:
	return Archipelago.get_deathlink_group()
func set_deathlink_group(group: String) -> void:
	deathlink_group_edit.text = group
	Archipelago.set_deathlink_group(group)

func set_paused(val: bool) -> void:
	paused = val
	if not val:
		unpaused.emit()

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
	set_deathlink_group(conn.slot_data.get("DeathLinkGroup", ""))
	set_deathlink(conn.slot_data.get("DeathLink", false))

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
	stats.visible = false
	settings_panel.visible = false
	Archipelago.connected.connect(on_connect)
	Archipelago.disconnected.connect(on_disconnect)
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
	conn.deathlink.connect(on_linked_death)
	load_slot_data(conn)
	reset_item()
	set_state(State.HOME)
	current_position = 0
	autosave_timer = 60.0
	current_weather = Weather.NONE
	connected_key = "BK_Simulator_%d_%d" % [conn.team_id, conn.player_id]
	conn.retrieve(connected_key, resume_from_server)
	conn.force_scout_all()
	refresh()
	refr_locs()
	conn.retrieve("_read_client_status_%d_%d" % [conn.team_id, conn.player_id], check_status)
	in_focus = get_window().has_focus()
	paused = false
	expecting_disconnect = false

func on_disconnect() -> void:
	message_queue.clear()
	if expecting_disconnect:
		return
	unintentional_disconnect.emit()
	expecting_disconnect = true

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
			if current_state == State.TO_BK_RIGHT and current_position >= bk_position:
				current_state = State.TO_BK_LEFT # turn around, it's behind you now!
	refresh()

func item_refr(items: Array[NetworkItem]) -> void:
	reset_item()
	for item in items:
		item_get(item)

func _exit_tree() -> void:
	if Archipelago.is_ap_connected():
		save_to_server()
		expecting_disconnect = true

func resume_from_server(data: Variant) -> void:
	if data == null:
		data = {
			"pos": 0,
			"weather": Weather.NONE,
			"state": State.HOME,
		}
	if data is Dictionary:
		if data.is_empty(): return
		current_position = data["pos"]
		current_weather = data["weather"] as Weather
		if data.has("dir"): # old version
			if current_weather == Weather.NONE:
				set_state(State.HOME)
			else:
				set_state(State.TO_BK_RIGHT if data["dir"] > 0 else State.FROM_BK)
		else: # new version
			set_state(data["state"] as State)
			match current_state:
				State.DYING, State.HOSPITAL: # Resume from home if quitting during deathlink death
					set_state(State.HOME)
		if data.has("deathlink"):
			set_deathlink(data["deathlink"])
		if data.has("deathlink_group"):
			set_deathlink_group(data["deathlink_group"])
		init_backdrop(true)
		if current_state == State.HOME and remaining_locations > 0:
			play_opening.emit()
		else:
			open_game.emit()

func save_to_server() -> void:
	if Archipelago.is_not_connected(): return
	Archipelago.send_command("Set", {
		"key": connected_key,
		"default": {},
		"want_reply": false,
		"operations": [
			{"operation": "replace", "value": {
				"pos": roundi(current_position),
				"weather": current_weather as int,
				"state": post_cutscene_state,
				"deathlink": get_deathlink(),
				"deathlink_group": get_deathlink_group(),
			}}
		]
	})

func _on_embark(weather: int) -> void:
	if current_weather == Weather.NONE:
		current_weather = weather as Weather
		current_position = 0
		set_state(State.TO_BK_RIGHT)
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

func _physics_process(delta: float) -> void:
	if weather_changed:
		if current_weather == Weather.RAIN:
			rain_sfx.fade_start()
		else:
			rain_sfx.fade_end()
		if current_weather != Weather.NONE:
			for node in moving_backdrop.sunny_nodes:
				node.set_visible(current_weather == Weather.SUN)
			for node in moving_backdrop.rainy_nodes:
				node.set_visible(current_weather == Weather.RAIN)
			for node in moving_backdrop.snowy_nodes:
				node.set_visible(current_weather == Weather.SNOW)
			moving_backdrop.weather = current_weather
		weather_changed = false
	if not in_focus: return
	if paused: return
	if current_state in [State.HOME, State.GOAL]: return
	if current_weather == Weather.NONE: return

	autosave_timer -= delta
	if autosave_timer <= 0.0:
		# periodically save incase of crash / power outage / etc
		save_to_server.call_deferred()
		autosave_timer = AUTOSAVE_DURATION

	var dx := get_speed() * direction
	current_position += dx * 1
	if current_state in [State.TO_BK_RIGHT, State.TO_BK_LEFT]:
		var at_goal := (current_position >= bk_position) if direction > 0 else (current_position <= bk_position)
		if at_goal:
			current_position = bk_position
			#if not in_focus: return
			paused = true
			moving_backdrop.bk_mode = true
			while not moving_backdrop.bk_building or (moving_backdrop.bk_building.position.x + moving_backdrop.bk_building.size.x / 2.0 > 320):
				var limit: float = (moving_backdrop.bk_building.position.x + moving_backdrop.bk_building.size.x / 2.0 - 320) if moving_backdrop.bk_building else 320.0
				var dist := minf(limit, dx * 2)
				moving_backdrop.move_by(dist)
				await get_tree().physics_frame
			var start_key := (current_weather as int) * 100 + 1
			var found_loc := -1
			for loc in range(start_key, start_key + locs_per_weather):
				if not Archipelago.conn.slot_locations[loc]:
					Archipelago.collect_location(loc)
					# instantly save the return state to the server, to avoid well-timed exiting from sending the NEXT location
					post_cutscene_state = State.FROM_BK
					save_to_server()
					found_loc = loc
					break
			if found_loc > -1:
				Archipelago.conn.scout(found_loc, 0, popup_found)
			else: # Final location got collected out while you were already en-route?
				popup_found(null)
				await unpaused
				set_state(State.FROM_BK)
				save_to_server()
		else:
			moving_backdrop.move_by(dx)
	elif current_state == State.FROM_BK:
		#current_position = minf(current_position, 10 * MILES)
		if current_position <= 0:
			current_position = 0
			#if not in_focus: return
			set_state(State.HOME)
			save_to_server()
			if remaining_locations == 0:
				goal()
			else:
				paused = true
				play_get_home(false)
		else:
			moving_backdrop.move_by(dx)
	elif current_state == State.DYING:
		var hit := false
		if not moving_backdrop.killer_car:
			hit = true
		elif direction > 0:
			if moving_backdrop.killer_car.get_rect().get_center().x < MovingBackdrop.WIDTH / 2.0:
				hit = true
		else:
			if moving_backdrop.killer_car.get_rect().get_center().x > MovingBackdrop.WIDTH / 2.0:
				hit = true
		if hit:
			# TODO play thud sfx
			set_state(State.HOME)
			play_deathlink_scene()
	else:
		AP.log("State '%d' is invalid!" % current_state)
		assert(false)
func set_state(state: State) -> void:
	post_cutscene_state = state
	if current_state != state:
		current_state = state

		var dir := 1
		match current_state:
			State.FROM_BK, State.TO_BK_LEFT:
				dir = -1
			State.HOME:
				current_weather = Weather.NONE
				current_position = 0
		if direction != dir:
			direction = dir
			moving_backdrop.swap_direction()

func popup_found(itm: NetworkItem) -> void:
	var msg: String
	if not itm:
		msg = "Your meal came with no bonus."
	elif itm.dest_player_id == Archipelago.conn.player_id:
		msg = "Your meal came with a bonus!\nFound your own '%s'!" % itm.get_name()
	else:
		msg = "Your meal came with a bonus!\nFound %s's '%s'!" % [Archipelago.conn.get_player_name(itm.dest_player_id), itm.get_name()]
	await text_scene.play(msg, 3.0, 10.0)
	var tw := create_tween()
	tw.tween_property(text_scene, "modulate:a", 0.0, 1.0)
	await tw.finished
	set_state(State.FROM_BK)
	save_to_server()
	set_paused(false)

func goal() -> void:
	current_position = 0
	current_weather = Weather.NONE
	set_state(State.GOAL)
	if goaled: return
	goaled = true
	Archipelago.set_client_status(AP.ClientStatus.CLIENT_GOAL)
	paused = true
	play_get_home(true)

func check_status(status: AP.ClientStatus) -> void:
	goaled = status == AP.ClientStatus.CLIENT_GOAL
	if remaining_locations == 0 and (current_position <= 0 or goaled):
		goal()

func play_get_home(done: bool) -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, FADE_DUR)
	await tw.finished
	init_backdrop(true)
	if done:
		await text_scene.play("Oh, finally! '%s' sent me the item I was waiting for.\nNow I can keep playing Archipelago!" % pick_username(), 4.0, 10.0)
	else:
		await text_scene.play("Still in BK Mode...", 2.0, 2.0)
	tw = create_tween()
	tw.tween_property(text_scene, "modulate:a", 0.0, FADE_DUR)
	tw.parallel().tween_property(self, "modulate:a", 1.0, FADE_DUR)
	await tw.finished
	text_scene.set_visible(false)
	paused = false

func play_deathlink_scene() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, FADE_DUR)
	await tw.finished
	init_backdrop(true)
	await text_scene.play("Ouch... %s needs to watch where they are going!\n(%s)" % [dying_source, dying_cause], 2.0, 30.0)
	tw = create_tween()
	tw.tween_property(text_scene, "modulate:a", 0.0, FADE_DUR)
	tw.parallel().tween_property(self, "modulate:a", 1.0, FADE_DUR)
	await tw.finished
	text_scene.set_visible(false)
	paused = false

func pick_username() -> String:
	var available_names: Array[String]
	available_names.assign(end_names)

	for player in Archipelago.conn.players:
		if player.slot == Archipelago.conn.player_id:
			continue
		available_names.append(player.get_name())

	return available_names.pick_random()

func _on_back_to_menu_pressed() -> void:
	save_to_server()
	expecting_disconnect = true
	return_to_menu.emit()
	paused = true

func _on_toggle_stats_pressed() -> void:
	stats.visible = not stats.visible

func _on_toggle_settings_pressed() -> void:
	settings_panel.visible = not settings_panel.visible

func _on_pin_window_toggled(toggled_on: bool) -> void:
	get_window().always_on_top = toggled_on

func on_linked_death(source: String, cause: String, _json: Dictionary = {}) -> void:
	if current_state in [State.HOME, State.DYING, State.GOAL]:
		return # ignore deathlinks in these states
	dying_source = source
	dying_cause = cause
	moving_backdrop.add_car(true)
	assert(moving_backdrop.killer_car)
	set_state(State.DYING)
	save_to_server()
