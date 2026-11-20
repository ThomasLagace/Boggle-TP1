class_name MetroSceneArt
extends Control
## Drawn line diagrams for the menu screens.
## TITLE: "BOGGLE" built as stations on a line.
## LOOP: a loop line with one station waiting for its partner.
## RACE: two lines racing to their scores.
## BROKEN: an interrupted line.

enum Mode { TITLE, LOOP, RACE, BROKEN }

@export var mode: Mode = Mode.TITLE

var _time := 0.0
var build := 0.0       # 0..1 line construction
var _station_pop: Array[float] = []
var _ripples: Array = [] # [{pos, t, color, r}]
var _confetti: Array = [] # [{pos, vel, rot, spin, color, life}]

# RACE data
var you_score := 0
var them_score := 0
var you_name := ""
var them_name := ""
var winner := -1 # 0 you, 1 them, 2 tie
var _celebrated := false

const TITLE_LETTERS := ["B", "O", "G", "G", "L", "E"]
const TITLE_POINTS := [Vector2(50, 70), Vector2(160, 70), Vector2(270, 70), Vector2(370, 170), Vector2(480, 170), Vector2(590, 170)]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_station_pop.resize(8)
	_station_pop.fill(0.0)
	var tw := create_tween()
	tw.tween_interval(0.35)
	match mode:
		Mode.TITLE:
			tw.tween_method(_set_build, 0.0, 1.0, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		Mode.RACE:
			tw.tween_method(_set_build, 0.0, 1.0, 1.6).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		_:
			tw.tween_method(_set_build, 0.0, 1.0, 0.8).set_ease(Tween.EASE_OUT)

func setup_race(p_you: int, p_them: int, p_you_name: String, p_them_name: String) -> void:
	you_score = p_you
	them_score = p_them
	you_name = p_you_name
	them_name = p_them_name
	winner = 0 if p_you > p_them else (1 if p_them > p_you else 2)

func _set_build(v: float) -> void:
	var before := build
	build = v
	if mode == Mode.TITLE:
		var pts := _title_points()
		var total := Metro.polyline_length(pts)
		var walked := 0.0
		for i in range(pts.size()):
			if i > 0:
				walked += pts[i - 1].distance_to(pts[i])
			var at := walked / total
			if before < at and v >= at or (i == 0 and before == 0.0 and v > 0.0):
				_pop_station(i, pts[i], Metro.VERMILLION)
				Metro.chime_station(i)
	if mode == Mode.RACE and v >= 0.999 and not _celebrated:
		_celebrated = true
		_celebrate()

func _pop_station(i: int, pos: Vector2, color: Color) -> void:
	_station_pop[i] = 0.0
	var tw := create_tween()
	tw.tween_method(func(x: float): _station_pop[i] = x, 0.0, 1.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_ripples.append({"pos": pos, "t": 0.0, "color": color, "r": 40.0})

func _process(delta: float) -> void:
	_time += delta
	for r in _ripples:
		r.t += delta / 0.6
	_ripples = _ripples.filter(func(r): return r.t < 1.0)
	for c in _confetti:
		c.vel.y += 520.0 * delta
		c.vel *= 0.985
		c.pos += c.vel * delta
		c.rot += c.spin * delta
		c.life -= delta
	_confetti = _confetti.filter(func(c): return c.life > 0.0)
	queue_redraw()

func _draw() -> void:
	match mode:
		Mode.TITLE: _draw_title()
		Mode.LOOP: _draw_loop()
		Mode.RACE: _draw_race()
		Mode.BROKEN: _draw_broken()
	for r in _ripples:
		if r.t < 0.0:
			continue
		var e := 1.0 - pow(1.0 - r.t, 3.0)
		draw_arc(r.pos, r.r * (1.0 + e), 0, TAU, 48, Color(r.color, 0.5 * (1.0 - r.t)), lerpf(7.0, 1.0, r.t), true)
	for c in _confetti:
		var d := Vector2.from_angle(c.rot) * 9.0
		draw_line(c.pos - d, c.pos + d, Color(c.color, clampf(c.life / 0.6, 0.0, 1.0)), 6.0, true)


# --- TITLE -----------------------------------------------------------------------

func _title_points() -> PackedVector2Array:
	var k := size.x / 640.0
	var out := PackedVector2Array()
	for p in TITLE_POINTS:
		out.append(p * k + Vector2(0, size.y * 0.5 - 120.0 * k))
	return out

func _draw_title() -> void:
	var pts := _title_points()
	var k := size.x / 640.0
	var radius := 42.0 * k
	# Crossing lines make it a network, not a string of beads.
	var o := pts[1]
	var l := pts[4]
	var cross_a := clampf(build * 1.6, 0.0, 1.0)
	var t0 := o + Vector2(0, -110) * k
	var t1 := t0.lerp(o + Vector2(0, 250) * k, cross_a)
	var s0 := l + Vector2(-120, 120) * k
	var s1 := s0.lerp(l + Vector2(110, -110) * k, cross_a)
	draw_line(t0, t1, Metro.TEAL, 16.0 * k, true)
	draw_line(s0, s1, Metro.SAFFRON, 16.0 * k, true)
	# Termini: small stations capping each crossing line.
	for p in [t0, t1, s0, s1]:
		if cross_a > 0.02:
			Metro.draw_station(self, p, 12.0 * k, Metro.WHITE, Metro.INK, 4.0 * k)

	var length := Metro.polyline_length(pts)
	var head := Metro.polyline_head(pts, length * build)
	if head.size() >= 2:
		var shadow := PackedVector2Array()
		for p in head:
			shadow.append(p + Vector2(0, 6))
		draw_polyline(shadow, Color(Metro.INK, 0.14), 30.0 * k, true)
		draw_polyline(head, Metro.VERMILLION, 28.0 * k, true)
		for p in head:
			draw_circle(p, 14.0 * k, Metro.VERMILLION, true, -1, true)

	# A train idles back and forth once the line is built.
	if build >= 1.0:
		var travel := fposmod(_time * 120.0, length * 2.0)
		var d := travel if travel < length else length * 2.0 - travel
		var at: Array = Metro.point_along(pts, d)
		var dir: Vector2 = at[1] * 16.0 * k
		draw_line(at[0] - dir, at[0] + dir, Metro.WHITE, 16.0 * k, true)
		draw_circle(at[0] - dir, 8.0 * k, Metro.WHITE, true, -1, true)
		draw_circle(at[0] + dir, 8.0 * k, Metro.WHITE, true, -1, true)
		draw_line(at[0] - dir * 0.6, at[0] + dir * 0.6, Metro.INK, 5.0 * k, true)

	for i in range(pts.size()):
		var s := _station_pop[i]
		if s <= 0.001:
			continue
		var c := pts[i]
		draw_set_transform(c, 0.0, Vector2(s, s))
		Metro.draw_soft_shadow(self, Vector2.ZERO, radius)
		var interchange := i == 1 or i == 4
		Metro.draw_station(self, Vector2.ZERO, radius, Metro.WHITE, Metro.INK, radius * (0.2 if interchange else 0.15))
		Metro.draw_centered_text(self, Metro.font_black, TITLE_LETTERS[i], Vector2(0, 1), int(radius * 1.05), Metro.INK)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# --- LOOP ------------------------------------------------------------------------

func _draw_loop() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.36
	var sweep := TAU * build
	draw_arc(c + Vector2(0, 6), r, -PI / 2, -PI / 2 + sweep, 96, Color(Metro.INK, 0.12), 22.0, true)
	draw_arc(c, r, -PI / 2, -PI / 2 + sweep, 96, Metro.VERMILLION, 20.0, true)
	# Train circling
	if build >= 1.0:
		var a := -PI / 2 + _time * 1.6
		var p := c + Vector2.from_angle(a) * r
		var tangent := Vector2.from_angle(a + PI / 2) * 16.0
		draw_line(p - tangent, p + tangent, Metro.WHITE, 16.0, true)
		draw_circle(p - tangent, 8.0, Metro.WHITE, true, -1, true)
		draw_circle(p + tangent, 8.0, Metro.WHITE, true, -1, true)
		draw_line(p - tangent * 0.6, p + tangent * 0.6, Metro.INK, 5.0, true)
	# You: a full station at the top.
	var top := c + Vector2(0, -r)
	Metro.draw_soft_shadow(self, top, 30.0)
	Metro.draw_station(self, top, 30.0, Metro.VERMILLION, Metro.INK, 6.0)
	# Them: an empty station breathing at the bottom.
	var bottom := c + Vector2(0, r)
	var breathe := 0.5 + 0.5 * sin(_time * 3.0)
	for i in range(12):
		var a0 := -_time * 0.8 + TAU * i / 12.0
		draw_arc(bottom, 42.0 + breathe * 5.0, a0, a0 + TAU / 12.0 * 0.5, 6, Color(Metro.TEAL, 0.5 + 0.4 * breathe), 4.0, true)
	Metro.draw_station(self, bottom, 30.0, Metro.WHITE, Color(Metro.INK, 0.85), 6.0)
	draw_circle(bottom, 9.0 * breathe, Color(Metro.TEAL, 0.8), true, -1, true)


# --- RACE ------------------------------------------------------------------------

func _race_rows() -> Array:
	var max_score := maxf(1.0, float(maxi(you_score, them_score)))
	var x0 := 70.0
	var span := size.x - x0 - 90.0
	return [
		{"y": size.y * 0.3, "score": you_score, "color": Metro.VERMILLION, "name": you_name, "len": span * maxf(0.08, you_score / max_score)},
		{"y": size.y * 0.72, "score": them_score, "color": Metro.TEAL, "name": them_name, "len": span * maxf(0.08, them_score / max_score)},
	]

func _draw_race() -> void:
	var x0 := 70.0
	var rows := _race_rows()
	for i in range(rows.size()):
		var row: Dictionary = rows[i]
		var y: float = row.y
		var x1: float = x0 + row.len * build
		var col: Color = row.color
		draw_line(Vector2(x0, y + 6), Vector2(x1, y + 6), Color(Metro.INK, 0.12), 24.0, true)
		draw_line(Vector2(x0, y), Vector2(x1, y), col, 22.0, true)
		Metro.draw_station(self, Vector2(x0, y), 16.0, Metro.WHITE, Metro.INK, 5.0)
		if row.name != "":
			draw_string(Metro.font_black, Vector2(x0 - 16, y - 30), row.name, HORIZONTAL_ALIGNMENT_LEFT, size.x * 0.6, 18, Metro.INK)
		# Terminus with a counting score
		var is_winner := (winner == i)
		var r := 34.0 + (6.0 * (0.5 + 0.5 * sin(_time * 4.0)) if is_winner and build >= 1.0 else 0.0)
		var term := Vector2(x1, y)
		Metro.draw_soft_shadow(self, term, r)
		Metro.draw_station(self, term, r, Metro.SAFFRON if is_winner and build >= 1.0 else Metro.WHITE, Metro.INK, 7.0)
		var shown := str(roundi(float(row.score) * build))
		Metro.draw_centered_text(self, Metro.font_digits, shown, term + Vector2(0, 1), 26 if shown.length() < 3 else 20, Metro.INK)

func _celebrate() -> void:
	var rows := _race_rows()
	var targets := []
	if winner == 2:
		targets = [0, 1]
	else:
		targets = [winner]
	for i in targets:
		var row: Dictionary = rows[i]
		var term := Vector2(70.0 + row.len, row.y)
		_ripples.append({"pos": term, "t": 0.0, "color": Metro.SAFFRON, "r": 40.0})
		_ripples.append({"pos": term, "t": -0.25, "color": row.color, "r": 40.0})
		var palette := [Metro.VERMILLION, Metro.TEAL, Metro.SAFFRON, Metro.VIOLET, Metro.INK]
		for n in range(46):
			var ang := randf_range(-PI * 0.95, -PI * 0.05)
			# Octilinear spin: confetti are little bits of track.
			_confetti.append({
				"pos": term, "vel": Vector2.from_angle(ang) * randf_range(220, 520),
				"rot": (randi() % 4) * PI / 4.0, "spin": randf_range(-6, 6),
				"color": palette[n % palette.size()], "life": randf_range(1.0, 1.8)})
	Metro.chime_accept()


# --- BROKEN -----------------------------------------------------------------------

func _draw_broken() -> void:
	var y := size.y * 0.5
	var x0 := 40.0
	var x1 := size.x - 40.0
	var mid := size.x * 0.5
	var gap := 70.0 + sin(_time * 2.2) * 6.0
	var a := lerpf(x0, mid - gap, build)
	var b := lerpf(x1, mid + gap, build)
	draw_line(Vector2(x0, y + 6), Vector2(a, y + 6), Color(Metro.INK, 0.12), 22.0, true)
	draw_line(Vector2(b, y + 6), Vector2(x1, y + 6), Color(Metro.INK, 0.12), 22.0, true)
	draw_line(Vector2(x0, y), Vector2(a, y), Metro.VERMILLION, 20.0, true)
	draw_line(Vector2(b, y), Vector2(x1, y), Metro.VERMILLION, 20.0, true)
	# Buffer stops at the broken ends
	for x in [a, b]:
		draw_line(Vector2(x, y - 22), Vector2(x, y + 22), Metro.INK, 8.0, true)
	Metro.draw_station(self, Vector2(x0, y), 18.0, Metro.WHITE, Metro.INK, 5.0)
	Metro.draw_station(self, Vector2(x1, y), 18.0, Metro.WHITE, Metro.INK, 5.0)
	# A stranded train nudging the buffer
	var tx := a - 40.0 - absf(sin(_time * 2.6)) * 22.0
	draw_line(Vector2(tx - 16, y), Vector2(tx + 16, y), Metro.WHITE, 16.0, true)
	draw_circle(Vector2(tx - 16, y), 8.0, Metro.WHITE, true, -1, true)
	draw_circle(Vector2(tx + 16, y), 8.0, Metro.WHITE, true, -1, true)
	draw_line(Vector2(tx - 10, y), Vector2(tx + 10, y), Metro.INK, 5.0, true)
	# The interruption mark
	var pulse := 1.0 + 0.08 * sin(_time * 5.0)
	var c := Vector2(mid, y)
	draw_set_transform(c, 0.0, Vector2(pulse, pulse) * build)
	Metro.draw_soft_shadow(self, Vector2.ZERO, 30.0)
	Metro.draw_station(self, Vector2.ZERO, 30.0, Metro.WHITE, Metro.VERMILLION, 7.0)
	draw_line(Vector2(-11, -11), Vector2(11, 11), Metro.VERMILLION, 7.0, true)
	draw_line(Vector2(-11, 11), Vector2(11, -11), Metro.VERMILLION, 7.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
