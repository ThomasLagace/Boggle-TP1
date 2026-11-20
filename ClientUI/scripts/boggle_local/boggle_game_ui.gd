extends Control

@export var boggle_board_ui: BoggleBoardUI
@export var current_guess_label: Label
@export var route_you: RouteStrip

var _boggle_game: BoggleGameResource

func _ready() -> void:
	var abs_path = ProjectSettings.globalize_path("res://dict.txt")
	_boggle_game = BoggleGameResource.CreateInstance(abs_path)
	boggle_board_ui.initialize(_boggle_game.Board())
	boggle_board_ui.on_submit_guess.connect(on_submit_guess)
	boggle_board_ui.on_modify_guess.connect(on_modify_guess)
	current_guess_label.add_theme_font_override("font", Metro.font_black)
	current_guess_label.add_theme_font_size_override("font_size", 40)
	current_guess_label.add_theme_color_override("font_color", Metro.WHITE)
	current_guess_label.text = ""

func on_submit_guess(guess: Array[BoggleCoords]) -> void:
	var word := _boggle_game.Board().GetStringFromCoords(guess)
	var valid: bool = _boggle_game.ValidateGuess(guess)
	print("A the guess \"%s\" was submited, and it was : " % [word], valid)
	current_guess_label.text = ""
	# Defer so the departure animation starts before the verdict lands.
	await get_tree().create_timer(0.35).timeout
	boggle_board_ui.show_result(valid)
	if valid:
		Metro.chime_accept()
		if route_you:
			route_you.add_stop(word, 0)
	else:
		Metro.chime_reject()

func on_modify_guess(_guess: Array[BoggleCoords]) -> void:
	var before := current_guess_label.text
	current_guess_label.text = boggle_board_ui.get_current_word()
	if current_guess_label.text.length() > before.length():
		Metro.bump(current_guess_label, 1.1, 0.3)
