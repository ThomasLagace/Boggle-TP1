class_name BoggleOnlineGameUI
extends Control

@export var timer_label: Label
@export var boggle_board_ui: BoggleBoardUI
@export var client_score_label: Label
@export var opponent_score_label: Label
@export var opponent_name_label: Label
@export var current_guess_label: Label
@export var departure_board: DepartureBoard
@export var route_you: RouteStrip
@export var route_them: RouteStrip
@export var you_name_label: Label

signal on_submit_guess(guess: Array[BoggleCoords])

## The server only sends a score update for a valid word, so a submit with
## no rise in our score within this window was not accepted.
const VERDICT_WINDOW := 1.6

var _unix_endtime = 0;
var _total_secs := 0.0
var _client_score := 0
var _opponent_score := 0
var _shown_client := 0.0
var _shown_opponent := 0.0
var _pending: Array = [] # [{word, at}]
var _last_second := -1


func _ready() -> void:
	boggle_board_ui.on_modify_guess.connect(_on_modify_guess)
	boggle_board_ui.on_submit_guess.connect(_on_submit_guess)
	_style()

	current_guess_label.text = ""
	client_score_label.text = "0"
	opponent_score_label.text = "0"
	var me: String = GlobalClientConnect.client_name
	you_name_label.text = me
	you_name_label.get_parent().visible = me.strip_edges() != ""

func _style() -> void:
	timer_label.add_theme_font_override("font", Metro.font_digits)
	timer_label.add_theme_font_size_override("font_size", 50)
	timer_label.add_theme_color_override("font_color", Metro.SAFFRON)

	current_guess_label.add_theme_font_override("font", Metro.font_black)
	current_guess_label.add_theme_font_size_override("font_size", 40)
	current_guess_label.add_theme_color_override("font_color", Metro.WHITE)

	for small in [client_score_label.get_parent().get_child(0), opponent_score_label.get_parent().get_child(0)]:
		small.add_theme_font_override("font", Metro.font_bold)
		small.add_theme_font_size_override("font_size", 13)
		small.add_theme_color_override("font_color", Metro.ON_INK_SOFT)

	for pair in [[client_score_label, Metro.VERMILLION], [opponent_score_label, Metro.TEAL]]:
		var l: Label = pair[0]
		l.add_theme_font_override("font", Metro.font_digits)
		l.add_theme_font_size_override("font_size", 30)
		l.add_theme_color_override("font_color", Metro.WHITE)
		var chip := Metro.box(pair[1], 10, 0, Metro.INK, 14, 0)
		chip.content_margin_top = 1
		chip.content_margin_bottom = -2
		l.add_theme_stylebox_override("normal", chip)
		l.custom_minimum_size.x = 86

func initialize(boggle_board: BoggleBoardResource, opponent_name: String, unix_endtime: int) -> void:
	boggle_board_ui.initialize(boggle_board)
	opponent_name_label.text = opponent_name
	_unix_endtime = unix_endtime
	_total_secs = maxf(1.0, unix_endtime - Time.get_unix_time_from_system())

func _on_modify_guess(_guess: Array[BoggleCoords]) -> void:
	var before := current_guess_label.text
	current_guess_label.text = boggle_board_ui.get_current_word()
	if current_guess_label.text.length() > before.length():
		Metro.bump(current_guess_label, 1.1, 0.3)

func _on_submit_guess(guess: Array[BoggleCoords]) -> void:
	var word := current_guess_label.text
	_pending.append({"word": word, "at": Time.get_ticks_msec() / 1000.0})
	_send_word_off(word)
	current_guess_label.text = ""
	on_submit_guess.emit(guess)

## The submitted word leaves the departure board to the right.
func _send_word_off(word: String) -> void:
	if word == "":
		return
	var ghost := current_guess_label.duplicate() as Label
	ghost.text = word
	departure_board.add_child(ghost)
	ghost.global_position = current_guess_label.global_position
	ghost.size = current_guess_label.size
	var tw := ghost.create_tween().set_parallel(true)
	tw.tween_property(ghost, "position:x", ghost.position.x + 120.0, 0.45).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(ghost, "modulate:a", 0.0, 0.45).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(ghost.queue_free)

func update_score(client_score: int, opponent_score: int) -> void:
	# Score updates may arrive off the main thread.
	call_deferred("_apply_score", client_score, opponent_score)

func _apply_score(client_score: int, opponent_score: int) -> void:
	if client_score > _client_score:
		var gained := client_score - _client_score
		var word := ""
		if not _pending.is_empty():
			word = _pending.pop_front().word
		route_you.add_stop(word, gained)
		boggle_board_ui.show_result(true)
		Metro.chime_accept()
		_flash_chip(client_score_label, Metro.VERMILLION)
		Metro.bump(client_score_label, 1.3, 0.5)
	if opponent_score > _opponent_score:
		var opp_gain := opponent_score - _opponent_score
		route_them.add_stop("", opp_gain)
		Metro.chime_opponent()
		_flash_chip(opponent_score_label, Metro.TEAL)
		Metro.bump(opponent_score_label, 1.22, 0.45)
	_client_score = client_score
	_opponent_score = opponent_score

## The score chip lights up saffron, then settles back to its line colour.
func _flash_chip(label: Label, base: Color) -> void:
	var chip := label.get_theme_stylebox("normal") as StyleBoxFlat
	if chip == null:
		return
	var tw := label.create_tween()
	tw.tween_method(func(c: Color):
		chip.bg_color = c
		label.add_theme_color_override("font_color", Metro.WHITE if (c.r + c.g + c.b) < 1.6 else Metro.INK)
	, Metro.SAFFRON, base, 0.7).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

func update_timer() -> void:
	var unix_current_time = int(Time.get_unix_time_from_system())
	var unix_time_left_secs = maxi(0, _unix_endtime - unix_current_time)
	var seconds: int = unix_time_left_secs % 60
	var minutes: int = floor(float(unix_time_left_secs) / 60)
	timer_label.text = "%d:%02d" % [minutes, seconds]

	var urgent: bool = unix_time_left_secs <= 30
	departure_board.urgent = unix_time_left_secs <= 10
	departure_board.progress = 1.0 - unix_time_left_secs / _total_secs if _total_secs > 0 else -1.0
	timer_label.add_theme_color_override("font_color", Metro.VERMILLION_HOT if urgent else Metro.SAFFRON)
	if unix_time_left_secs != _last_second:
		if _last_second != -1 and unix_time_left_secs <= 10 and unix_time_left_secs > 0:
			Metro.bump(timer_label, 1.18, 0.4)
			Metro.chime_tick(unix_time_left_secs <= 5)
		_last_second = unix_time_left_secs

func _process(delta: float) -> void:
	update_timer()
	# Count-up on the score chips.
	var k := 1.0 - exp(-delta * 9.0)
	_shown_client = lerpf(_shown_client, _client_score, k)
	_shown_opponent = lerpf(_shown_opponent, _opponent_score, k)
	client_score_label.text = str(roundi(_shown_client))
	opponent_score_label.text = str(roundi(_shown_opponent))
	# Words with no score rise in time were not accepted.
	var now := Time.get_ticks_msec() / 1000.0
	while not _pending.is_empty() and now - _pending[0].at > VERDICT_WINDOW:
		_pending.pop_front()
		if _pending.is_empty():
			boggle_board_ui.show_result(false)
			Metro.chime_reject()
