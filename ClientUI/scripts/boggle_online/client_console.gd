extends Container

@onready var log_container: VBoxContainer = $ScrollContainer/LogContainer

func _ready() -> void:
	var client = GlobalClientConnect.client
	if client != null:
		initialize(client)
	GlobalClientConnect.on_client_initialized.connect(initialize)

func initialize(client: BoggleClientNode) -> void:
	client.OnReceiveMessage.connect(func(message: String):
		add_log("Serveur: " + message)
	)
	client.OnLogging.connect(func(message: String, _serverity):
		add_log("Client: " + message)
	)

func add_log(log: String) -> void:
	var label = Label.new()
	label.text = log
	log_container.add_child(label)
