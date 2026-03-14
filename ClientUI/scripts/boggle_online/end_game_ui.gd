extends Control

@onready var winner_label: Label = $WinnerLabel
@onready var your_score_label: Label = $YourScoreLabel
@onready var opponent_score_label: Label = $OpponentScoreLabel

func initialize(client_score: int, opponent_score: int) -> void:
	if client_score > opponent_score:
		winner_label.text = GlobalClientConnect.client_name
	elif client_score < opponent_score:
		winner_label.text = GlobalClientConnect.opponent_name
	else:
		winner_label.text = "Nulle!"
	your_score_label.text = str(client_score)
	opponent_score_label.text = str(opponent_score)
