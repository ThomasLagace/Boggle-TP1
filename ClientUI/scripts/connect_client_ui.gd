extends Control

@onready var address_edit: LineEdit = $ConnectionInformation/AddressEdit
@onready var port_edit: LineEdit = $ConnectionInformation/PortEdit
@onready var connect_button: Button = $ConnectionInformation/ConnectButton

@export var on_connect_scene: PackedScene

func _ready() -> void:
	if on_connect_scene == null:
		push_error("On connect scene is not set.")
		return
	
	connect_button.pressed.connect(on_connect_button_press)
	
	GlobalClientConnect.on_client_connect.connect(func():
		get_tree().change_scene_to_packed(on_connect_scene)
	)

func on_connect_button_press() -> void:
	var ip = address_edit.text
	var port = port_edit.text
	if GlobalClientConnect.create_client(ip, port):
		GlobalClientConnect.connect_client()
