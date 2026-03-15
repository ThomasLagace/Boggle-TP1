class_name ConnectClientUI
extends Control

@onready var name_edit: LineEdit = $ConnectionInformation/NameEdit
@onready var address_edit: LineEdit = $ConnectionInformation/AddressEdit
@onready var port_edit: LineEdit = $ConnectionInformation/PortEdit
@onready var connect_button: Button = $ConnectionInformation/ConnectButton

func _ready() -> void:
	connect_button.pressed.connect(on_connect_button_press)

	GlobalClientConnect.on_client_connect.connect(func():
		GlobalClientConnect.client.SubmitNameToServer(name_edit.text)
	)

func on_connect_button_press() -> void:
	if name_edit.text.strip_edges() == "":
		return
	var ip = address_edit.text
	var port = port_edit.text
	if GlobalClientConnect.create_client(ip, port):
		GlobalClientConnect.connect_client()
