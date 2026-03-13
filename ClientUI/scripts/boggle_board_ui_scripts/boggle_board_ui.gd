class_name BoggleBoardUI
extends Control

signal on_submit_guess(guess: Array[BoggleCoords])
signal on_modify_guess(guess: Array[BoggleCoords])
signal on_guess_canceled()

@export var boggle_letter_scene: PackedScene
@export var boggle_letter_parent: Control
@export var cancel_guess_area: Array[Control]

var _current_guess_ui: Array[BoggleLetterUI] = []
var _board: BoggleBoardResource

func initialize(board: BoggleBoardResource) -> void:
	_board = board

	var string_board = _board.GetBoardLetters()
	for y in range(len(string_board)):
		for x in range(len(string_board.get(0))):
			var coords = BoggleCoords.new()
			coords.X = x
			coords.Y = y
			var btn = boggle_letter_scene.instantiate()
			btn.initialize(self, string_board.get(y).get(x), coords)
			boggle_letter_parent.add_child(btn)

func get_current_guess_coords() -> Array[BoggleCoords]:
	return get_coords_from_ui_guess(_current_guess_ui)

func get_coords_from_ui_guess(letter_uis: Array[BoggleLetterUI]) -> Array[BoggleCoords]:
	var guess: Array[BoggleCoords] = []
	for letter_ui in letter_uis:
		guess.append(letter_ui._coords)
	return guess

func submit_guess() -> void:
	for area in cancel_guess_area:
		if area.get_rect().has_point(get_viewport().get_mouse_position()):
			clear_guess()
			return
	on_submit_guess.emit(get_current_guess_coords())
	_current_guess_ui = []

func clear_guess() -> void:
	_current_guess_ui.clear()
	on_modify_guess.emit(get_current_guess_coords())
	on_guess_canceled.emit()

func remove_last_guess() -> void:
	_current_guess_ui.pop_back()
	on_modify_guess.emit(get_current_guess_coords())

func add_guess(letter_ui: BoggleLetterUI) -> void:
	var new_ui_guess: Array[BoggleLetterUI] = _current_guess_ui.duplicate()
	new_ui_guess.append(letter_ui)

	var new_coords_guess: Array[BoggleCoords] = get_coords_from_ui_guess(new_ui_guess)
	
	if _board.AreCoordsValid(new_coords_guess):
		print("Adding a guess at [%d, %d]" % [letter_ui._coords.X, letter_ui._coords.Y])
		_current_guess_ui.assign(new_ui_guess)
		on_modify_guess.emit(get_current_guess_coords())

func get_current_word() -> String:
	return _board.GetStringFromCoords(get_current_guess_coords())
