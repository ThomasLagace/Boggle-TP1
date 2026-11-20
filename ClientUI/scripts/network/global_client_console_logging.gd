extends Node

const CLIENT_CONSOLE = preload("uid://cxfanpt5niwxj")

enum LoggingSeverity {
	INFO,
	WARNING,
	ERROR
}

func _ready() -> void:
	GlobalClientConnect.on_client_initialized.connect(on_client_initialized)
	var window = Window.new()
	window.title = "Client console"
	window.size = Vector2i(600, 300)
	window.position = DisplayServer.screen_get_size() / 2 - window.size / 2
	window.theme = Metro.theme
	window.add_child(CLIENT_CONSOLE.instantiate())
	get_tree().root.call_deferred("add_child", window)
	window.visible = true

func on_client_initialized(client: BoggleClientNode) -> void:
	client.OnLogging.connect(on_client_logging)
	client.OnReceiveMessage.connect(on_client_receive_message)

func on_client_logging(log_message: String, logging_severity: LoggingSeverity) -> void:
	var prefix: String
	match logging_severity:
		LoggingSeverity.INFO:
			prefix = "Info"
		LoggingSeverity.WARNING:
			prefix = "Warning"
		LoggingSeverity.ERROR:
			prefix = "Error"
		_:
			prefix = "Undef"
	print("LOG[%s]: " % prefix, log_message)

func on_client_receive_message(message: String) -> void:
	print("Server: ", message)
