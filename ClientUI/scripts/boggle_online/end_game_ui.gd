class_name EndGameUI
extends Control

@onready var winner_label: Label = $WinnerLabel
@onready var your_score_label: Label = $YourScoreLabel
@onready var opponent_score_label: Label = $OpponentScoreLabel
@onready var return_to_connection_button: Button = $CenterContainer3/ReturnToConnectionButton
const CONNECT_CLIENT_UI = preload("uid://doidx1hat37mv")

var _winner: String
var _client_score: int
var _opponent_score: int

func _ready() -> void:
	winner_label.text = _winner
	your_score_label.text = str(_client_score)
	opponent_score_label.text = str(_opponent_score)

	return_to_connection_button.pressed.connect(func():
		get_tree().change_scene_to_packed(CONNECT_CLIENT_UI)
	)

func initialize(client_score: int, opponent_score: int, winner_name: String) -> void:
	_winner = winner_name
	_client_score = client_score
	_opponent_score = opponent_score
