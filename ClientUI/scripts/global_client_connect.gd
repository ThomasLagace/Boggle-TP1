extends Node

signal on_client_connect()

var client: BoggleClientNode = null

func create_client(ip: String, port: String) -> bool:
	if client != null:
		client.queue_free()
		client = null
	print("Trying to create client")
	client = BoggleClientNode.CreateClientNode(ip, port)
	
	var creating_client_was_success = client != null
	
	if creating_client_was_success:
		print("Client created!")
		client.OnConnectReturn.connect(func(connected):
			if connected:
				print("Connected successfully!")
				on_client_connect.emit()
			else:
				print("Failed to connect")
		)
		
		client.OnLogging.connect(func(log, severity):
			var prefix: String
			match severity:
				0:
					prefix = "Info"
				1:
					prefix = "Warning"
				2:
					prefix = "Error"
				_:
					prefix = "Undef"
			print("[%s]: " % prefix, log)
		)
	else:
		print("Failed to create client!")
	return creating_client_was_success

func connect_client() -> void:
	if client != null:
		print("Trying to connect")
		client.ConnectAsync()
	else:
		print("Trying to connect with no client created")
