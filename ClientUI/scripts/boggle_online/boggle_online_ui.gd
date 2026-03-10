extends Control

@export var timer_label: Label
@export var boggle_board_ui: BoggleBoardUI
@export var submit_button: Button
var _unix_endtime = 0;

func _ready() -> void:
	var client = GlobalClientConnect.client
	if client == null:
		push_error("Trying to initialize BoggleOnline Scene with uninitialized client.")
		return
	client.OnGameStart.connect(on_game_start)

func update_timer() -> void:
	var unix_current_time = int(Time.get_unix_time_from_system())
	var unix_time_left_secs = _unix_endtime - unix_current_time
	var seconds = unix_time_left_secs % 60
	var minutes = floor(float(unix_time_left_secs) / 60)
	timer_label.text = seconds + ":" + minutes

func on_game_start(endtime: int) -> void:
	boggle_board_ui.initialize(GlobalClientConnect.client.GetBoggleBoard())
	boggle_board_ui.on_submit_guess.connect(on_submit_guess)
	submit_button.pressed.connect(func():
		boggle_board_ui.submit_guess()
	)
	_unix_endtime = endtime

func on_submit_guess(guess: Array[BoggleCoords]) -> void:
	var client = GlobalClientConnect.client
	print("A the guess \"%s\" was submited." % [client.GetBoggleBoard().GetStringFromCoords(guess)])
