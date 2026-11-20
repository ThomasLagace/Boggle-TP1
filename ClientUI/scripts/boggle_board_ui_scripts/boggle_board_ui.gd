class_name BoggleBoardUI
extends Control
## The board as a transit network: stations on a track lattice.
## Tracing a word builds a metro line; releasing sends a train down it.

signal on_submit_guess(guess: Array[BoggleCoords])
signal on_modify_guess(guess: Array[BoggleCoords])
signal on_started_guess()
signal on_ended_guess()

@export var boggle_letter_scene: PackedScene
@export var boggle_letter_parent: Control
@export var cancel_guess_area: Array[Control]
@export var line_2d_guess: Line2D
@export var line_2d_to_mouse: Line2D

const LINE_WIDTH := 24.0

var _current_guess_ui: Array[BoggleLetterUI] = []
var _last_submitted: Array[BoggleLetterUI] = []
var _letters: Array[BoggleLetterUI] = []
var _board: BoggleBoardResource
var _shadow_line: Line2D
var _fx: Node2D
var _trains: Array = [] # [{pos, dir, alpha}]
var _over_cancel := false
## Dev capture only: when set, replaces the viewport mouse position for line/cancel visuals.
var debug_mouse_override: Variant = null


func _ready() -> void:
	for line in [line_2d_guess, line_2d_to_mouse]:
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		line.antialiased = true
	line_2d_guess.width = LINE_WIDTH
	line_2d_guess.default_color = Metro.VERMILLION
	line_2d_to_mouse.width = LINE_WIDTH * 0.55
	line_2d_to_mouse.default_color = Color(Metro.VERMILLION, 0.42)

	_shadow_line = Line2D.new()
	_shadow_line.width = LINE_WIDTH + 2.0
	_shadow_line.default_color = Color(Metro.INK, 0.16)
	_shadow_line.joint_mode = Line2D.LINE_JOINT_ROUND
	_shadow_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_shadow_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	_shadow_line.position = Vector2(0, 5)
	add_child(_shadow_line)
	move_child(_shadow_line, line_2d_guess.get_index())

	_fx = Node2D.new()
	_fx.draw.connect(_draw_fx)
	add_child(_fx)

	line_2d_to_mouse.visible = false
	line_2d_to_mouse.add_point(Vector2(1, 1))
	line_2d_to_mouse.add_point(Vector2(1, 1))

func _process(_delta: float) -> void:
	var mouse: Vector2 = debug_mouse_override if debug_mouse_override != null else get_viewport().get_mouse_position()
	var tracing := len(_current_guess_ui) > 0
	_over_cancel = false
	for area in cancel_guess_area:
		var hot := tracing and area.get_rect().has_point(mouse)
		_over_cancel = _over_cancel or hot
		if area.has_method("set_hot"):
			area.set_hot(hot)

	if tracing:
		line_2d_to_mouse.visible = true
		var tip := line_2d_guess.get_point_position(line_2d_guess.get_point_count() - 1) if line_2d_guess.get_point_count() > 0 else _center_of(_current_guess_ui[-1])
		line_2d_to_mouse.set_point_position(0, tip)
		line_2d_to_mouse.set_point_position(1, line_2d_to_mouse.to_local(mouse))
		var tint := Metro.INK_MUTED if _over_cancel else Metro.VERMILLION
		line_2d_to_mouse.default_color = Color(tint, 0.42)
		line_2d_guess.default_color = line_2d_guess.default_color.lerp(Color(Metro.INK_SOFT, 0.75) if _over_cancel else Metro.VERMILLION, 0.25)
	else:
		line_2d_to_mouse.visible = false
	_shadow_line.points = line_2d_guess.points
	queue_redraw()
	_fx.queue_redraw()

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
			_letters.append(btn)
			btn.play_entrance(0.35 + (x + y) * 0.07)

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
	on_ended_guess.emit()
	_last_submitted.assign(_current_guess_ui)
	_depart(line_2d_guess.points)
	if not _current_guess_ui.is_empty():
		Metro.chime_depart()
	_current_guess_ui = []
	line_2d_guess.clear_points()
	_refresh_states()

func clear_guess() -> void:
	if not _current_guess_ui.is_empty():
		Metro.chime_cancel()
	_drop(line_2d_guess.points)
	_current_guess_ui.clear()
	on_modify_guess.emit(get_current_guess_coords())
	on_ended_guess.emit()
	line_2d_guess.clear_points()
	_refresh_states()

func remove_last_guess() -> void:
	_current_guess_ui.pop_back()
	on_modify_guess.emit(get_current_guess_coords())
	if line_2d_guess.get_point_count() > 0:
		line_2d_guess.remove_point(line_2d_guess.get_point_count() - 1)
	Metro.chime_back()
	_refresh_states()

func add_guess(letter_ui: BoggleLetterUI) -> void:
	var new_ui_guess: Array[BoggleLetterUI] = _current_guess_ui.duplicate()
	new_ui_guess.append(letter_ui)

	var new_coords_guess: Array[BoggleCoords] = get_coords_from_ui_guess(new_ui_guess)

	if _board.AreCoordsValid(new_coords_guess):
		_current_guess_ui.assign(new_ui_guess)
		on_modify_guess.emit(get_current_guess_coords())

		var target := _center_of(letter_ui)
		var count := line_2d_guess.get_point_count()
		if count == 0:
			line_2d_guess.default_color = Metro.VERMILLION
			line_2d_guess.add_point(target)
		else:
			# Grow the new segment out of the previous station.
			var from := line_2d_guess.get_point_position(count - 1)
			line_2d_guess.add_point(from)
			var idx := count
			var tw := create_tween()
			tw.tween_method(func(p: Vector2):
				if idx < line_2d_guess.get_point_count():
					line_2d_guess.set_point_position(idx, p)
			, from, target, 0.11).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		Metro.chime_station(len(_current_guess_ui) - 1)
		_refresh_states()
		if len(new_ui_guess) == 1:
			on_started_guess.emit()

func get_current_word() -> String:
	return _board.GetStringFromCoords(get_current_guess_coords())

## Feedback for the last submitted word, once the game knows the verdict.
func show_result(accepted: bool) -> void:
	for i in range(_last_submitted.size()):
		var l := _last_submitted[i]
		if not is_instance_valid(l):
			continue
		if accepted:
			l.play_accept(i * 0.055)
		else:
			l.play_reject(i * 0.03)


# --- internals -----------------------------------------------------------------

func _center_of(letter_ui: Control) -> Vector2:
	return line_2d_guess.to_local(letter_ui.global_position + letter_ui.size * 0.5)

func _refresh_states() -> void:
	var tip: BoggleLetterUI = _current_guess_ui[-1] if not _current_guess_ui.is_empty() else null
	for l in _letters:
		if tip == null:
			l.set_trace_state(false, false, false)
			continue
		var on_line := l in _current_guess_ui
		var avail := not on_line and tip.is_adjacent_to(l)
		l.set_trace_state(on_line, avail, not on_line and not avail)

func _make_ghost(points: PackedVector2Array, color: Color) -> Line2D:
	var ghost := Line2D.new()
	ghost.width = LINE_WIDTH
	ghost.default_color = color
	ghost.joint_mode = Line2D.LINE_JOINT_ROUND
	ghost.begin_cap_mode = Line2D.LINE_CAP_ROUND
	ghost.end_cap_mode = Line2D.LINE_CAP_ROUND
	ghost.antialiased = true
	ghost.points = points
	add_child(ghost)
	move_child(ghost, line_2d_guess.get_index())
	return ghost

## The train runs the line, eating it behind itself, then pulls away.
func _depart(points: PackedVector2Array) -> void:
	if points.size() == 0:
		return
	var path := points.duplicate()
	if path.size() == 1:
		path.append(path[0] + Vector2(1, 0))
	var length := Metro.polyline_length(path)
	var ghost := _make_ghost(path, Metro.VERMILLION)
	var train := {"pos": path[0], "dir": Vector2.RIGHT, "alpha": 1.0}
	_trains.append(train)
	var duration := clampf(0.16 + path.size() * 0.07, 0.25, 0.8)
	var tw := create_tween()
	tw.tween_method(func(d: float):
		var at: Array = Metro.point_along(path, d)
		train.pos = at[0]
		train.dir = at[1]
		ghost.points = _tail(path, d)
	, 0.0, length, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(ghost.queue_free)
	tw.tween_method(func(a: float):
		train.alpha = a
		train.pos += train.dir * 6.0
	, 1.0, 0.0, 0.22)
	tw.tween_callback(func(): _trains.erase(train))

## A cancelled line goes grey and drops off the map.
func _drop(points: PackedVector2Array) -> void:
	if points.size() == 0:
		return
	var ghost := _make_ghost(points, Metro.INK_MUTED)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(ghost, "position:y", 34.0, 0.38).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tw.tween_property(ghost, "modulate:a", 0.0, 0.38).set_ease(Tween.EASE_IN)
	tw.tween_property(ghost, "width", LINE_WIDTH * 0.4, 0.38)
	tw.chain().tween_callback(ghost.queue_free)

func _tail(points: PackedVector2Array, d: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var remaining := d
	for i in range(points.size() - 1):
		var seg := points[i].distance_to(points[i + 1])
		if out.is_empty():
			if remaining <= seg:
				out.append(points[i].lerp(points[i + 1], remaining / seg if seg > 0.0 else 1.0))
				out.append(points[i + 1])
			else:
				remaining -= seg
		else:
			out.append(points[i + 1])
	return out

func _draw() -> void:
	if _letters.is_empty():
		return
	# Track lattice between neighbouring stations.
	var tip: BoggleLetterUI = _current_guess_ui[-1] if not _current_guess_ui.is_empty() else null
	for i in range(_letters.size()):
		var a := _letters[i]
		var ca := a.global_position + a.size * 0.5 - global_position
		for j in range(i + 1, _letters.size()):
			var b := _letters[j]
			if not a.is_adjacent_to(b):
				continue
			var cb := b.global_position + b.size * 0.5 - global_position
			var diagonal := a._coords.X != b._coords.X and a._coords.Y != b._coords.Y
			var col := Color(Metro.TRACK, 0.55 if diagonal else 0.95)
			var w := 3.0 if diagonal else 6.0
			var reach := tip != null and (a == tip or b == tip) and not ((a in _current_guess_ui) and (b in _current_guess_ui))
			if reach:
				col = Color(Metro.VERMILLION, 0.32)
				w = 8.0
			draw_line(ca, cb, col, w, true)

func _draw_fx() -> void:
	for t in _trains:
		var pos: Vector2 = t.pos
		var dir: Vector2 = t.dir
		var a: float = t.alpha
		var half := dir * 15.0
		_fx.draw_line(pos - half, pos + half, Color(Metro.INK, 0.25 * a), 22.0, true)
		_fx.draw_circle(pos - half, 9.0, Color(Metro.WHITE, a), true, -1, true)
		_fx.draw_circle(pos + half, 9.0, Color(Metro.WHITE, a), true, -1, true)
		_fx.draw_line(pos - half, pos + half, Color(Metro.WHITE, a), 18.0, true)
		_fx.draw_line(pos - half * 0.7, pos + half * 0.7, Color(Metro.INK, a), 6.0, true)
		_fx.draw_circle(pos + half, 4.0, Color(Metro.SAFFRON, a), true, -1, true)
