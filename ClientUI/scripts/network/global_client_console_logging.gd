extends Node

enum LoggingSeverity {
	INFO,
	WARNING,
	ERROR
}

func _ready() -> void:
	GlobalClientConnect.on_client_initialized.connect(on_client_initialized)

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
