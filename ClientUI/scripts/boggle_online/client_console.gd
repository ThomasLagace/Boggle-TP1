extends Container

@onready var log_container: VBoxContainer = $ScrollContainer/LogContainer
@onready var scroll_container: ScrollContainer = $ScrollContainer

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
	var time = Time.get_time_dict_from_system()
	var formatted: String = "[%02d:%02d:%02d] " % [time.hour, time.minute, time.second]
	var label = Label.new()
	label.text = formatted + log
	log_container.add_child(label)
	log_container.move_child(label, 0)
