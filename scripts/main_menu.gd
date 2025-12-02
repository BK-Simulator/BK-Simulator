extends MarginContainer

@export_group("Nodes")
@export var menu_main: Container
@export var menu_connect: Container
@export var edit_ip: LineEdit
@export var edit_port: LineEdit
@export var edit_slot: LineEdit
@export var edit_pwd: LineEdit
@export var error_label: Label
@export_group("")

@onready var menus: Array[Control] = [menu_main, menu_connect]
var active_menu: Control :
	set(val):
		active_menu = val
		for menu in menus:
			menu.set_visible(menu == val)

func _ready() -> void:
	active_menu = menu_main
	Archipelago.connectionrefused.connect(connect_refused)
	Archipelago.connected.connect(connected)
	if OS.is_debug_build():
		edit_ip.text = "localhost"
		edit_slot.text = "Tester"

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_start_pressed() -> void:
	active_menu = menu_connect

func _on_back_pressed() -> void:
	active_menu = menu_main

func _on_connect_pressed() -> void:
	if error_label.text:
		error_label.text = "..."
	var ip: String = edit_ip.placeholder_text if edit_ip.text.is_empty() else edit_ip.text
	var port: String = edit_port.placeholder_text if edit_port.text.is_empty() else edit_port.text
	Archipelago.ap_connect(ip, port, edit_slot.text, edit_pwd.text)

func connect_refused(_conn: ConnectionInfo, json: Dictionary) -> void:
	var error: String = ", ".join(json["errors"])
	error_label.text = error

func connected(_conn: ConnectionInfo, _json: Dictionary) -> void:
	error_label.text = ""
