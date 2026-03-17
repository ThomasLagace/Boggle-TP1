class_name BoggleOnlineGameUI
extends Control

@export var timer_label: Label
@export var boggle_board_ui: BoggleBoardUI
@export var client_score_label: Label
@export var opponent_score_label: Label
@export var opponent_name_label: Label
@export var current_guess_label: Label

signal on_submit_guess(guess: Array[BoggleCoords])

var _unix_endtime = 0;

func _ready() -> void:
	boggle_board_ui.on_modify_guess.connect(_on_modify_guess)
	boggle_board_ui.on_submit_guess.connect(_on_submit_guess)

	current_guess_label.text = ""
	client_score_label.text = "0"
	opponent_score_label.text = "0"

func initialize(boggle_board: BoggleBoardResource, opponent_name: String, unix_endtime: int) -> void:
	boggle_board_ui.initialize(boggle_board)
	opponent_name_label.text = opponent_name
	_unix_endtime = unix_endtime

func _on_modify_guess(_guess: Array[BoggleCoords]) -> void:
	current_guess_label.text = boggle_board_ui.get_current_word()

func _on_submit_guess(guess: Array[BoggleCoords]) -> void:
	on_submit_guess.emit(guess)

func update_score(client_score: int, opponent_score: int) -> void:
	client_score_label.text = str(client_score)
	opponent_score_label.text = str(opponent_score)

func update_timer() -> void:
	var unix_current_time = int(Time.get_unix_time_from_system())
	var unix_time_left_secs = _unix_endtime - unix_current_time
	var seconds: int = unix_time_left_secs % 60
	var minutes: int = floor(float(unix_time_left_secs) / 60)
	timer_label.text = "%d:%02d" % [minutes, seconds]

func _process(_delta: float) -> void:
	update_timer()
