extends Control

@onready var winner_label: Label = $WinnerLabel
@onready var your_score_label: Label = $YourScoreLabel
@onready var opponent_score_label: Label = $OpponentScoreLabel

var _winner: String
var _client_score: int
var _opponent_score: int

func _ready() -> void:
	winner_label.text = _winner
	your_score_label.text = str(_client_score)
	opponent_score_label.text = str(_opponent_score)

func initialize(client_score: int, opponent_score: int) -> void:
	if client_score > opponent_score:
		_winner = GlobalClientConnect.client_name
	elif client_score < opponent_score:
		_winner = GlobalClientConnect.opponent_name
	else:
		_winner = "Nulle!"
	_client_score = client_score
	_opponent_score = opponent_score
