extends Control

signal on_button_clicked(coords: BoggleCoords)
signal on_guess(guess: Array[BoggleCoords])

var current_guess: Array[BoggleCoords] = []

func _ready() -> void:
	on_button_clicked.connect(handle_button_click)

func handle_button_click(coords: BoggleCoords) -> void:
	current_guess.append(coords)

func guess() -> void:
	on_guess.emit(current_guess);
	current_guess = []
