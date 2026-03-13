class_name BoggleLetterUI
extends Control

@export var letter_label: Label

var _board_ui: BoggleBoardUI
var _letter: String
var _coords: BoggleCoords

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)

func initialize(board_ui: BoggleBoardUI, letter: String, coords: BoggleCoords) -> void:
	_board_ui = board_ui
	_letter = letter
	letter_label.text = _letter
	_coords = coords

func on_pressed() -> void:
	print("Boggle button pressed at [%d, %d]" % [_coords.X, _coords.Y])
	_board_ui.add_guess(self)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		on_pressed()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_board_ui.submit_guess()

func _on_mouse_entered() -> void:
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		return
	if len(_board_ui._current_guess) <= 0:
		return
	if not _coords in _board_ui._current_guess:
		print("Boggle button hovered at [%d, %d]" % [_coords.X, _coords.Y])
		_board_ui.add_guess(self)
	elif len(_board_ui._current_guess) > 1 and _board_ui._current_guess[-2] == _coords:
		_board_ui.remove_last_guess()
