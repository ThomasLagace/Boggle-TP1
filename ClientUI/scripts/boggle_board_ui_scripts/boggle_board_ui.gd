class_name BoggleBoardUI
extends Control

signal on_submit_guess(guess: Array[BoggleCoords])
signal on_modify_guess(guess: Array[BoggleCoords])
signal on_guess_canceled()

@export var boggle_button_scene: PackedScene
@export var boggle_button_parent: Control
@export var cancel_guess_area: Array[Control]

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
	for area in cancel_guess_area:
		if area.get_rect().has_point(get_viewport().get_mouse_position()):
			clear_guess()
			return
	on_submit_guess.emit(_current_guess)
	_current_guess = []

func clear_guess() -> void:
	_current_guess.clear()
	on_modify_guess.emit(_current_guess)
	on_guess_canceled.emit()

func remove_last_guess() -> void:
	_current_guess.pop_back()
	on_modify_guess.emit(_current_guess)

func add_guess(coords: BoggleCoords) -> void:
	var new_guess = _current_guess + [coords]
	if _board.AreCoordsValid(new_guess):
		print("Adding a guess at [%d, %d]" % [coords.X, coords.Y])
		_current_guess.assign(new_guess)
		on_modify_guess.emit(_current_guess)

func get_current_word() -> String:
	return _board.GetStringFromCoords(_current_guess)
