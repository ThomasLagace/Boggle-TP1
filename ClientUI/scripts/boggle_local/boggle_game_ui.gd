extends Control

@export var boggle_board_ui: BoggleBoardUI
@export var submit_button: Button
@export var current_guess_label: Label

var _boggle_game: BoggleGameResource

func _ready() -> void:
	var abs_path = ProjectSettings.globalize_path("res://dict.txt")
	_boggle_game = BoggleGameResource.CreateInstance(abs_path)
	boggle_board_ui.initialize(_boggle_game.Board())
	boggle_board_ui.on_submit_guess.connect(on_submit_guess)
	submit_button.pressed.connect(func():
		boggle_board_ui.submit_guess()
	)
	boggle_board_ui.on_add_guess.connect(on_add_guess)
	current_guess_label.text = ""

func on_submit_guess(guess: Array[BoggleCoords]) -> void:
	print("A the guess \"%s\" was submited, and it was : " % [_boggle_game.Board().GetStringFromCoords(guess)], _boggle_game.ValidateGuess(guess))
	current_guess_label.text = ""

func on_add_guess(_guess: Array[BoggleCoords]) -> void:
	current_guess_label.text = boggle_board_ui.get_current_word()
