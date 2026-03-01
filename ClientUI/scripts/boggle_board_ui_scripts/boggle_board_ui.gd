class_name BoggleBoardUI
extends Control

signal on_submit_guess(guess: Array[BoggleCoords])

@export var boggle_button_scene: PackedScene
@export var boggle_button_parent: Control

var _current_guess: Array[BoggleCoords] = []
var _board: BoggleBoardResource

func initialize(board: BoggleBoardResource) -> void:
	_board = board

	var string_board = _board.GetBoardLetters()
	for y in range(len(string_board)):
		for x in range(len(string_board.get(0))):
			var coords = BoggleCoords.new()
			coords.X = x
			coords.Y = y
			var btn = boggle_button_scene.instantiate()
			btn.initialize(self, string_board.get(y).get(x), coords)
			boggle_button_parent.add_child(btn)

func submit_guess() -> void:
	on_submit_guess.emit(_current_guess)
	_current_guess = []

func add_guess(coords: BoggleCoords) -> void:
	var new_guess = _current_guess + [coords]
	if _board.AreCoordsValid(new_guess):
		print("Adding a guess at [%d, %d]" % [coords.X, coords.Y])
		_current_guess.assign(new_guess)
