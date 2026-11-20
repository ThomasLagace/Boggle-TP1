class_name BoggleLetterUI
extends Control
## One die, drawn as a metro station roundel.
## States: idle, hover, available (next stop), dimmed, on the line.

@export var letter_label: Label

var _board_ui: BoggleBoardUI
var _letter: String
var _coords: BoggleCoords

# Animated state (0..1 unless noted)
var _on_line := false
var _available := false
var _dimmed := false
var _hovered := false
var sel_t := 0.0
var avail_t := 0.0
var dim_t := 0.0
var hover_t := 0.0
var pop := 1.0          # scale multiplier, tweened
var enter := 0.0        # entrance scale, tweened
var flash_t := 0.0      # saffron acceptance flash
var shake_x := 0.0      # rejection shake offset (px)
var _ripples: Array = [] # [{t, color}]
var _time := 0.0
var _line_color := Metro.VERMILLION


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(func(): _hovered = false)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if letter_label:
		letter_label.visible = false # drawn in _draw for full control
	_time = randf() * 10.0

func initialize(board_ui: BoggleBoardUI, letter: String, coords: BoggleCoords) -> void:
	_board_ui = board_ui
	_letter = letter
	if letter_label:
		letter_label.text = _letter
	_coords = coords

func on_pressed() -> void:
	_board_ui.add_guess(self)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		on_pressed()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_board_ui.submit_guess()

func _on_mouse_entered() -> void:
	_hovered = true
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		return
	if len(_board_ui._current_guess_ui) <= 0:
		return
	if not self in _board_ui._current_guess_ui:
		_board_ui.add_guess(self)
	elif len(_board_ui._current_guess_ui) > 1 and _board_ui._current_guess_ui[-2] == self:
		_board_ui.remove_last_guess()


# --- State API used by the board ---------------------------------------------

func set_trace_state(on_line: bool, available: bool, dimmed: bool) -> void:
	if on_line and not _on_line:
		_join_line()
	elif not on_line and _on_line:
		_leave_line()
	_on_line = on_line
	_available = available
	_dimmed = dimmed

func is_adjacent_to(other: BoggleLetterUI) -> bool:
	return maxi(absi(other._coords.X - _coords.X), absi(other._coords.Y - _coords.Y)) == 1

func play_entrance(delay: float) -> void:
	enter = 0.0
	var tw := create_tween()
	tw.tween_interval(delay)
	tw.tween_property(self, "enter", 1.0, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func play_accept(delay: float) -> void:
	var tw := create_tween()
	tw.tween_interval(delay)
	tw.tween_callback(func():
		_ripples.append({"t": 0.0, "color": Metro.SAFFRON})
		flash_t = 1.0
		pop = 1.22
	)
	tw.tween_property(self, "pop", 1.0, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	var tf := create_tween()
	tf.tween_interval(delay + 0.1)
	tf.tween_property(self, "flash_t", 0.0, 0.7).set_ease(Tween.EASE_IN)

func play_reject(delay: float) -> void:
	var tw := create_tween()
	tw.tween_interval(delay)
	for i in range(6):
		var amt := 7.0 * (1.0 - i / 6.0) * (1 if i % 2 == 0 else -1)
		tw.tween_property(self, "shake_x", amt, 0.05).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "shake_x", 0.0, 0.05)

func _join_line() -> void:
	_ripples.append({"t": 0.0, "color": _line_color})
	var tw := create_tween()
	tw.tween_property(self, "sel_t", 1.0, 0.14).set_ease(Tween.EASE_OUT)
	pop = 1.24
	var tp := create_tween()
	tp.tween_property(self, "pop", 1.0, 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _leave_line() -> void:
	var tw := create_tween()
	tw.tween_property(self, "sel_t", 0.0, 0.22).set_ease(Tween.EASE_OUT)
	pop = 0.9
	var tp := create_tween()
	tp.tween_property(self, "pop", 1.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# --- Animation & drawing -------------------------------------------------------

func _process(delta: float) -> void:
	_time += delta
	var k := 1.0 - exp(-delta * 14.0)
	avail_t = lerpf(avail_t, 1.0 if _available else 0.0, k)
	dim_t = lerpf(dim_t, 1.0 if _dimmed else 0.0, k)
	var hovering := _hovered and not _on_line and _board_ui != null and _board_ui._current_guess_ui.is_empty()
	hover_t = lerpf(hover_t, 1.0 if hovering else 0.0, k)
	for r in _ripples:
		r.t += delta / 0.5
	_ripples = _ripples.filter(func(r): return r.t < 1.0)
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5 + Vector2(shake_x, 0)
	var radius := minf(size.x, size.y) * 0.5 * 0.86
	var breathe := 1.0 + sin(_time * 5.5) * 0.025 * avail_t
	var s := enter * pop * (1.0 + 0.05 * hover_t + 0.04 * avail_t) * breathe
	if s <= 0.001:
		return

	# Ripples expand beyond the roundel (drawn unscaled by pop).
	for r in _ripples:
		var e := 1.0 - pow(1.0 - r.t, 3.0)
		var rr := radius * (1.0 + e * 0.85)
		draw_arc(center, rr, 0, TAU, 48, Color(r.color, 0.55 * (1.0 - r.t)), lerpf(8.0, 1.5, r.t), true)

	draw_set_transform(center, 0.0, Vector2(s, s))
	var alpha := 1.0 - 0.6 * dim_t

	# "Next stop" — a rotating dashed ring around reachable stations.
	if avail_t > 0.01:
		var dash_r := radius + 10.0
		var dashes := 14
		var spin := _time * 1.4
		for i in range(dashes):
			var a0 := spin + TAU * i / dashes
			draw_arc(Vector2.ZERO, dash_r, a0, a0 + TAU / dashes * 0.55, 6,
				Color(_line_color, 0.85 * avail_t), 4.0, true)

	Metro.draw_soft_shadow(self, Vector2.ZERO, radius, alpha * (1.0 - 0.5 * sel_t))

	var ring := Metro.INK.lerp(_line_color, hover_t * 0.85)
	var fill := Metro.WHITE.lerp(_line_color, sel_t)
	if flash_t > 0.0:
		fill = fill.lerp(Metro.SAFFRON, flash_t)
		ring = ring.lerp(Metro.INK, flash_t)
	ring.a = alpha
	fill.a = alpha
	var ring_w := radius * (0.15 + 0.04 * hover_t)
	draw_circle(Vector2.ZERO, radius, ring, true, -1, true)
	draw_circle(Vector2.ZERO, radius - ring_w, fill, true, -1, true)

	# Letter
	var text := _letter.to_upper() if _letter != null else ""
	var fs := int(radius * (1.02 if text.length() <= 1 else 0.72))
	var txt_col := Metro.INK.lerp(Metro.WHITE, sel_t)
	if flash_t > 0.0:
		txt_col = txt_col.lerp(Metro.INK, flash_t)
	txt_col.a = alpha
	Metro.draw_centered_text(self, Metro.font_black, text, Vector2(0, 1), fs, txt_col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
