extends Button

var _board_ui: BoggleBoardUI
var _letter: String
var _coords: BoggleCoords

func initialize(board_ui: BoggleBoardUI, letter: String, coords: BoggleCoords) -> void:
	_board_ui = board_ui

	_letter = letter
	text = _letter

	_coords = coords
	if pressed.is_connected(on_pressed):
		pressed.disconnect(on_pressed)

	pressed.connect(on_pressed)

func on_pressed() -> void:
	print("Boggle button pressed at [%d, %d]" % [_coords.X, _coords.Y])
	_board_ui.add_guess(_coords)
