extends Node

signal on_client_connect()
signal on_client_initialized(client: BoggleClientNode)

var client: BoggleClientNode = null
var client_name: String
var opponent_name: String

func create_client(ip: String, port: String) -> bool:
	if client != null:
		client.queue_free()
		client = null
	print("Trying to create client")
	client = BoggleClientNode.CreateClientNode(ip, port)
	
	var creating_client_was_success = client != null
	
	if creating_client_was_success:
		print("Client created!")
		on_client_initialized.emit(client)
	else:
		print("Failed to create client!")
	return creating_client_was_success

func connect_client() -> void:
	if client != null:
		print("Trying to connect")
		client.ConnectAsync(on_client_connect_callback)
	else:
		print("Trying to connect with no client created")

func on_client_connect_callback(connected):
	if connected:
		print("Connected successfully!")
		on_client_connect.emit()
	else:
		print("Failed to connect")
