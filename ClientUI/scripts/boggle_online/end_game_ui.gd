class_name EndGameUI
extends Control

@onready var winner_label: Label = $CenterContainer/HBoxContainer/WinnerLabel
@onready var won_label: Label = $CenterContainer/HBoxContainer/WonLabel
@onready var your_score_label: Label = $CenterContainer2/HBoxContainer/YourScoreLabel
@onready var opponent_score_label: Label = $CenterContainer2/HBoxContainer/OpponentScoreLabel
@onready var return_to_connection_button: Button = $CenterContainer3/ReturnToConnectionButton
@onready var race: MetroSceneArt = $Race
const CONNECT_CLIENT_UI = preload("uid://doidx1hat37mv")

var _winner: String
var _client_score: int
var _opponent_score: int
var _you_name := ""
var _them_name := ""

func _ready() -> void:
	winner_label.text = _winner
	your_score_label.text = str(_client_score)
	opponent_score_label.text = str(_opponent_score)
	# On a draw the winner text already says "Nulle!"; "a gagné!" would contradict it.
	won_label.visible = _client_score != _opponent_score

	Metro.style_title(winner_label, 54, Metro.VERMILLION if _client_score > _opponent_score else (Metro.TEAL if _client_score < _opponent_score else Metro.INK))
	Metro.style_title(won_label, 54)
	Metro.style_title(your_score_label, 30, Metro.VERMILLION)
	Metro.style_title(opponent_score_label, 30, Metro.TEAL)
	for l in [$CenterContainer2/HBoxContainer/ToLabel, $CenterContainer2/HBoxContainer/PointsLabel]:
		l.add_theme_font_size_override("font_size", 22)
		l.add_theme_color_override("font_color", Metro.INK_SOFT)

	race.setup_race(_client_score, _opponent_score, _you_name, _them_name)
	Metro.reveal.call_deferred([$CenterContainer, $CenterContainer2, $CenterContainer3], 1.7, 0.18)

	return_to_connection_button.pressed.connect(func():
		Metro.go_to_packed(CONNECT_CLIENT_UI)
	)

func initialize(client_score: int, opponent_score: int, winner_name: String) -> void:
	_winner = winner_name
	_client_score = client_score
	_opponent_score = opponent_score
	_you_name = GlobalClientConnect.client_name
	_them_name = GlobalClientConnect.opponent_name
