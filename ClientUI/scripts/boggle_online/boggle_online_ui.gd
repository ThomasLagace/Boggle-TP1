extends Control

@export var timer_label: Label
@export var boggle_board_ui: BoggleBoardUI
@export var client_score_label: Label
@export var opponent_score_label: Label
@export var opponent_name_label: Label
const END_GAME_UI: PackedScene = preload("res://scenes/end_game_ui.tscn")

var _unix_endtime = 0;
var _client: BoggleClientNode = null

func initialize(client: BoggleClientNode) -> void:
	_client = client
	_client.OnGameStart.connect(on_game_start)
	_client.OnScoreUpdate.connect(on_score_update)
	_client.OnGameEnd.connect(on_game_end)

func update_timer() -> void:
	var unix_current_time = int(Time.get_unix_time_from_system())
	var unix_time_left_secs = _unix_endtime - unix_current_time
	var seconds = unix_time_left_secs % 60
	var minutes = floor(float(unix_time_left_secs) / 60)
	timer_label.text = seconds + ":" + minutes

func on_game_start(endtime: int, opponent_name: String) -> void:
	boggle_board_ui.initialize(_client.GetBoggleBoard())
	boggle_board_ui.on_submit_guess.connect(on_submit_guess)
	_unix_endtime = endtime
	opponent_name_label.text = opponent_name

func on_submit_guess(guess: Array[BoggleCoords]) -> void:
	print("A the guess \"%s\" was submited." % [_client.GetBoggleBoard().GetStringFromCoords(guess)])
	_client.SubmitGuessToServer(guess)

func on_score_update(client_score: int, opponent_score: int) -> void:
	client_score_label.text = str(client_score)
	opponent_score_label.text = str(opponent_score)

func on_game_end(client_score: int, opponent_score: int) -> void:
	var end_game_scene = END_GAME_UI.instantiate()
	end_game_scene.initialize(client_score, opponent_score)
	get_tree().change_scene_to_node(end_game_scene)

func _process(_delta: float) -> void:
	update_timer()
