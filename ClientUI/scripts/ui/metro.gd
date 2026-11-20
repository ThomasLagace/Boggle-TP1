extends Node
## Ligne de métro — shared visual system for the Boggle client.
## Palette, fonts, the generated Theme, synthesized station chimes,
## and the line-wipe scene transition all live here.

# --- Palette -----------------------------------------------------------------
const PAPER      := Color("#e7eaee")
const STREET     := Color("#f5f7f9")
const PARK       := Color("#d6e6d4")
const WATER      := Color("#c6dbec")
const INK        := Color("#17192b")
const INK_SOFT   := Color("#474c66")
const INK_MUTED  := Color("#8a90a8")
const ON_INK     := Color("#f2f3f7")
const ON_INK_SOFT := Color("#aab0c8")
const WHITE      := Color("#ffffff")
const VERMILLION := Color("#d63a24")
const VERMILLION_HOT := Color("#ff5a3c")
const VERMILLION_DEEP := Color("#a92a17")
const TEAL       := Color("#0f8577")
const TEAL_BRIGHT := Color("#22b5a2")
const SAFFRON    := Color("#f5b700")
const VIOLET     := Color("#6a4bc4")
const TRACK      := Color("#c9cfd8")

# --- Fonts -------------------------------------------------------------------
var font_regular: Font
var font_bold: Font
var font_black: Font
var font_mono: Font
## Tabular figures for clocks and scores.
var font_digits: Font
var theme: Theme

# --- Sound -------------------------------------------------------------------
const MIX_RATE := 22050
## Pentatonic steps so any run of stations sounds like a melody, never a clash.
const SCALE := [0, 2, 4, 7, 9, 12, 14, 16, 19, 21, 24, 26, 28, 31, 33, 36]
var _players: Array[AudioStreamPlayer] = []
var _player_index := 0
var _tone_cache := {}

# --- Transition --------------------------------------------------------------
var _wipe_layer: CanvasLayer
var _wipe: Control
var _wipe_t := 0.0
var _wipe_tween: Tween
var _pending_scene: Node = null
var _covered := false


func _ready() -> void:
	_load_fonts()
	theme = _build_theme()
	get_tree().root.theme = theme
	RenderingServer.set_default_clear_color(PAPER)
	_setup_audio()
	_setup_wipe()


# =============================================================================
# Fonts & theme
# =============================================================================

func _font_file(path: String) -> FontFile:
	var f := load(path) as FontFile
	if f == null:
		f = FontFile.new()
		f.load_dynamic_font(ProjectSettings.globalize_path(path))
	return f

func _tag(name: String) -> int:
	return TextServerManager.get_primary_interface().name_to_tag(name)

func _weighted(base: Font, weight: int, features: Dictionary = {}) -> FontVariation:
	var v := FontVariation.new()
	v.base_font = base
	v.variation_opentype = {_tag("wght"): weight}
	if not features.is_empty():
		var f := {}
		for k in features:
			f[_tag(k)] = features[k]
		v.opentype_features = f
	return v

func _load_fonts() -> void:
	var sans := _font_file("res://assets/fonts/Overpass.ttf")
	var mono := _font_file("res://assets/fonts/OverpassMono.ttf")
	font_regular = _weighted(sans, 500)
	font_bold = _weighted(sans, 750)
	font_black = _weighted(sans, 900)
	font_mono = _weighted(mono, 700)
	font_digits = _weighted(sans, 850, {"tnum": 1})

func box(bg: Color, radius: int = 12, border: int = 0, border_color: Color = INK,
		pad_h: float = 0.0, pad_v: float = 0.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.corner_detail = 10
	s.set_border_width_all(border)
	s.border_color = border_color
	s.content_margin_left = pad_h
	s.content_margin_right = pad_h
	s.content_margin_top = pad_v
	s.content_margin_bottom = pad_v
	s.anti_aliasing = true
	return s

func shadowed(s: StyleBoxFlat, size: int = 18, offset: Vector2 = Vector2(0, 8),
		color: Color = Color(INK, 0.22)) -> StyleBoxFlat:
	s.shadow_size = size
	s.shadow_offset = offset
	s.shadow_color = color
	return s

func _build_theme() -> Theme:
	var t := Theme.new()
	t.default_font = font_regular
	t.default_font_size = 18

	# Labels
	t.set_color("font_color", "Label", INK)
	t.set_font("font", "Label", font_bold)

	# Buttons — vermillion pills, signage weight.
	var btn_normal := shadowed(box(VERMILLION, 28, 0, INK, 30, 12), 6, Vector2(0, 5), Color(INK, 0.22))
	var btn_hover := shadowed(box(VERMILLION_HOT, 28, 0, INK, 30, 12), 10, Vector2(0, 8), Color(INK, 0.24))
	var btn_pressed := shadowed(box(VERMILLION_DEEP, 28, 0, INK, 30, 12), 2, Vector2(0, 2), Color(INK, 0.25))
	var btn_disabled := box(Color("#c3c8d2"), 28, 0, INK, 30, 12)
	var btn_focus := box(Color(0, 0, 0, 0), 32, 3, INK)
	btn_focus.draw_center = false
	btn_focus.expand_margin_left = 5
	btn_focus.expand_margin_right = 5
	btn_focus.expand_margin_top = 5
	btn_focus.expand_margin_bottom = 5
	t.set_stylebox("normal", "Button", btn_normal)
	t.set_stylebox("hover", "Button", btn_hover)
	t.set_stylebox("pressed", "Button", btn_pressed)
	t.set_stylebox("hover_pressed", "Button", btn_pressed)
	t.set_stylebox("disabled", "Button", btn_disabled)
	t.set_stylebox("focus", "Button", btn_focus)
	t.set_font("font", "Button", font_black)
	t.set_font_size("font_size", "Button", 20)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		t.set_color(c, "Button", WHITE)
	t.set_color("font_disabled_color", "Button", INK_SOFT)

	# LineEdit — white signage plates with an ink rule.
	var le_normal := box(WHITE, 12, 3, Color(INK, 0.85), 16, 10)
	var le_focus := box(Color(0, 0, 0, 0), 14, 3, VERMILLION)
	le_focus.draw_center = false
	le_focus.expand_margin_left = 3
	le_focus.expand_margin_right = 3
	le_focus.expand_margin_top = 3
	le_focus.expand_margin_bottom = 3
	t.set_stylebox("normal", "LineEdit", le_normal)
	t.set_stylebox("focus", "LineEdit", le_focus)
	t.set_stylebox("read_only", "LineEdit", box(Color("#dfe2e8"), 12, 3, INK_MUTED, 16, 10))
	t.set_font("font", "LineEdit", font_bold)
	t.set_font_size("font_size", "LineEdit", 20)
	t.set_color("font_color", "LineEdit", INK)
	t.set_color("font_placeholder_color", "LineEdit", INK_MUTED)
	t.set_color("caret_color", "LineEdit", VERMILLION)
	t.set_color("selection_color", "LineEdit", Color(VERMILLION, 0.28))
	t.set_color("font_selected_color", "LineEdit", INK)
	t.set_constant("caret_width", "LineEdit", 3)

	# Panels
	t.set_stylebox("panel", "Panel", box(PAPER, 0))
	t.set_stylebox("panel", "PanelContainer", box(PAPER, 0, 0, INK, 14, 10))

	# Scrollbars (client console)
	var grab := box(Color(INK, 0.55), 6)
	grab.content_margin_left = 4
	grab.content_margin_right = 4
	t.set_stylebox("grabber", "VScrollBar", grab)
	t.set_stylebox("grabber_highlight", "VScrollBar", box(VERMILLION, 6))
	t.set_stylebox("grabber_pressed", "VScrollBar", box(VERMILLION_DEEP, 6))
	t.set_stylebox("scroll", "VScrollBar", box(Color(INK, 0.08), 6, 0, INK, 4, 0))
	return t


# =============================================================================
# Drawing helpers
# =============================================================================

## Draw a string centered on `center` (optical vertical centering on caps).
func draw_centered_text(ci: CanvasItem, font: Font, text: String, center: Vector2,
		font_size: int, color: Color) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var ascent := font.get_ascent(font_size)
	var cap := ascent * 0.72
	ci.draw_string(font, Vector2(center.x - w * 0.5, center.y + cap * 0.5), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

## Soft two-step drop shadow for round shapes.
func draw_soft_shadow(ci: CanvasItem, center: Vector2, radius: float, strength: float = 1.0) -> void:
	ci.draw_circle(center + Vector2(0, 6), radius + 3, Color(INK, 0.06 * strength), true, -1, true)
	ci.draw_circle(center + Vector2(0, 4), radius + 1, Color(INK, 0.10 * strength), true, -1, true)

## A station roundel: white body, ink ring.
func draw_station(ci: CanvasItem, center: Vector2, radius: float, fill: Color = WHITE,
		ring: Color = INK, ring_width: float = -1.0) -> void:
	if ring_width < 0:
		ring_width = maxf(3.0, radius * 0.16)
	ci.draw_circle(center, radius, ring, true, -1, true)
	ci.draw_circle(center, radius - ring_width, fill, true, -1, true)

## Point at distance `d` along a polyline. Returns [position, direction].
func point_along(points: PackedVector2Array, d: float) -> Array:
	if points.size() == 0:
		return [Vector2.ZERO, Vector2.RIGHT]
	if points.size() == 1:
		return [points[0], Vector2.RIGHT]
	var remaining := maxf(d, 0.0)
	for i in range(points.size() - 1):
		var a := points[i]
		var b := points[i + 1]
		var seg := a.distance_to(b)
		if remaining <= seg or i == points.size() - 2:
			var t := 0.0 if seg == 0.0 else clampf(remaining / seg, 0.0, 1.0)
			return [a.lerp(b, t), (b - a).normalized() if seg > 0.0 else Vector2.RIGHT]
		remaining -= seg
	return [points[-1], Vector2.RIGHT]

func polyline_length(points: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(points.size() - 1):
		total += points[i].distance_to(points[i + 1])
	return total

## The first `d` pixels of a polyline.
func polyline_head(points: PackedVector2Array, d: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	if points.size() == 0:
		return out
	out.append(points[0])
	var remaining := d
	for i in range(points.size() - 1):
		var seg := points[i].distance_to(points[i + 1])
		if remaining >= seg:
			out.append(points[i + 1])
			remaining -= seg
		else:
			if seg > 0.0:
				out.append(points[i].lerp(points[i + 1], remaining / seg))
			break
	return out

## Shake a Control horizontally around its current position.
func shake(node: CanvasItem, strength: float = 10.0, duration: float = 0.4) -> void:
	if node == null:
		return
	var base: Vector2 = node.position
	var tw := node.create_tween()
	var steps := 6
	for i in range(steps):
		var amt := strength * (1.0 - float(i) / steps) * (1 if i % 2 == 0 else -1)
		tw.tween_property(node, "position:x", base.x + amt, duration / steps).set_trans(Tween.TRANS_SINE)
	tw.tween_property(node, "position:x", base.x, duration / steps)

## Signage headline: Overpass Black in ink.
func style_title(label: Label, font_size: int = 40, color: Color = INK) -> void:
	label.add_theme_font_override("font", font_black)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)

## Staggered rise-and-fade entrance for already-laid-out nodes.
func reveal(nodes: Array, delay: float = 0.4, stagger: float = 0.12) -> void:
	for i in range(nodes.size()):
		var n: CanvasItem = nodes[i]
		if n == null:
			continue
		n.modulate.a = 0.0
		var tw := n.create_tween().set_parallel(true)
		tw.tween_property(n, "modulate:a", 1.0, 0.45).set_delay(delay + i * stagger)
		if n is Control:
			var c := n as Control
			c.pivot_offset = c.size * 0.5
			c.scale = Vector2(0.96, 0.96)
			tw.tween_property(c, "scale", Vector2.ONE, 0.6).set_delay(delay + i * stagger).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

## Springy scale bump; keeps the pivot centered.
func bump(node: Control, amount: float = 1.18, duration: float = 0.38) -> void:
	if node == null:
		return
	node.pivot_offset = node.size * 0.5
	var tw := node.create_tween()
	node.scale = Vector2.ONE * amount
	tw.tween_property(node, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


# =============================================================================
# Sound — synthesized station chimes (no audio files shipped)
# =============================================================================

func _setup_audio() -> void:
	for i in range(8):
		var p := AudioStreamPlayer.new()
		p.volume_db = -12.0
		add_child(p)
		_players.append(p)

func _tone(semitone: int, duration: float, bright: float) -> AudioStreamWAV:
	var key := "%d_%.2f_%.2f" % [semitone, duration, bright]
	if _tone_cache.has(key):
		return _tone_cache[key]
	var freq := 523.25 * pow(2.0, semitone / 12.0) # from C5
	var frames := int(MIX_RATE * duration)
	var data := PackedByteArray()
	data.resize(frames * 2)
	for i in range(frames):
		var t := float(i) / MIX_RATE
		var attack := minf(1.0, t / 0.006)
		var env := attack * exp(-t * (5.5 / duration))
		var s := sin(TAU * freq * t) * 0.62
		s += sin(TAU * freq * 2.0 * t) * 0.22 * bright
		s += sin(TAU * freq * 3.01 * t) * 0.08 * bright
		var v := int(clampf(s * env, -1.0, 1.0) * 32000.0)
		data.encode_s16(i * 2, v)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = data
	_tone_cache[key] = wav
	return wav

func _play(stream: AudioStream, volume_db: float = -12.0) -> void:
	if _players.is_empty():
		return
	var p := _players[_player_index]
	_player_index = (_player_index + 1) % _players.size()
	p.stream = stream
	p.volume_db = volume_db
	p.play()

func _play_seq(semitones: Array, gap: float, duration: float, bright: float, volume_db: float) -> void:
	for i in range(semitones.size()):
		if i > 0:
			await get_tree().create_timer(gap).timeout
		_play(_tone(semitones[i], duration, bright), volume_db)

## One station joined the line. `step` is its index in the word.
func chime_station(step: int) -> void:
	_play(_tone(SCALE[clampi(step, 0, SCALE.size() - 1)], 0.32, 0.8), -13.0)

func chime_back() -> void:
	_play(_tone(-5, 0.18, 0.3), -18.0)

func chime_depart() -> void:
	_play_seq([7, 0], 0.11, 0.35, 0.6, -14.0)

func chime_accept() -> void:
	_play_seq([12, 16, 19, 24], 0.065, 0.42, 1.0, -11.0)

func chime_reject() -> void:
	_play_seq([-3, -8], 0.09, 0.22, 0.2, -16.0)

func chime_cancel() -> void:
	_play_seq([4, -1, -8], 0.06, 0.18, 0.3, -17.0)

func chime_opponent() -> void:
	_play(_tone(-12, 0.3, 0.4), -20.0)

func chime_tick(urgent: bool) -> void:
	_play(_tone(19 if urgent else 12, 0.08, 0.1), -24.0 if not urgent else -18.0)


# =============================================================================
# Scene transition — three metro lines sweep across the screen
# =============================================================================

func _setup_wipe() -> void:
	_wipe_layer = CanvasLayer.new()
	_wipe_layer.layer = 100
	add_child(_wipe_layer)
	_wipe = Control.new()
	_wipe.set_anchors_preset(Control.PRESET_FULL_RECT)
	_wipe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wipe.draw.connect(_draw_wipe)
	_wipe_layer.add_child(_wipe)

func _set_wipe_t(v: float) -> void:
	_wipe_t = v
	_wipe.mouse_filter = Control.MOUSE_FILTER_STOP if v > 0.0 and v < 2.0 else Control.MOUSE_FILTER_IGNORE
	_wipe.queue_redraw()

func _draw_wipe() -> void:
	# _wipe_t: 0 → 1 covers the screen, 1 → 2 uncovers it.
	if _wipe_t <= 0.0 or _wipe_t >= 2.0:
		return
	# Each band is a 45° parallelogram; its top edge spans [left, right].
	var vp := _wipe.get_viewport_rect().size
	var far := vp.x + vp.y + 4.0
	var colors := [SAFFRON, TEAL, VERMILLION]
	for i in range(3):
		var left := -4.0
		var right := far
		if _wipe_t <= 1.0:
			var p := clampf((_wipe_t - i * 0.15) / 0.7, 0.0, 1.0)
			right = lerpf(-4.0, far, 1.0 - pow(1.0 - p, 3.0))
		else:
			var q := clampf((_wipe_t - 1.0 - (2 - i) * 0.15) / 0.7, 0.0, 1.0)
			left = lerpf(-4.0, far, q * q * (3.0 - 2.0 * q))
		if right <= left:
			continue
		var pts := PackedVector2Array([
			Vector2(left, -2), Vector2(right, -2),
			Vector2(right - vp.y - 4.0, vp.y + 2), Vector2(left - vp.y - 4.0, vp.y + 2)])
		_wipe.draw_colored_polygon(pts, colors[i])
	if _covered:
		_wipe.draw_rect(Rect2(Vector2.ZERO, vp), VERMILLION)

## Swap to an already-built scene root with a line wipe. Safe from any thread.
func go_to_node(node: Node) -> void:
	call_deferred("_go_to_node", node)

func go_to_packed(packed: PackedScene) -> void:
	call_deferred("_go_to_node", packed.instantiate())

func _go_to_node(node: Node) -> void:
	if _pending_scene != null and is_instance_valid(_pending_scene) and _pending_scene != node:
		_pending_scene.queue_free()
	_pending_scene = node
	if _wipe_tween != null and _wipe_tween.is_running() and _wipe_t < 1.0:
		return # already covering; the swap will pick up the newest scene
	if _wipe_tween != null:
		_wipe_tween.kill()
	_covered = false
	_wipe_tween = create_tween()
	_wipe_tween.tween_method(_set_wipe_t, minf(_wipe_t, 1.0) if _wipe_t < 1.0 else 0.0, 1.0, 0.42)
	_wipe_tween.tween_callback(_swap_scene)
	_wipe_tween.tween_interval(0.06)
	_wipe_tween.tween_method(_set_wipe_t, 1.0, 2.0, 0.55)

func _swap_scene() -> void:
	_covered = true
	_wipe.queue_redraw()
	var node := _pending_scene
	_pending_scene = null
	if node != null and is_instance_valid(node):
		get_tree().change_scene_to_node(node)
	await get_tree().process_frame
	_covered = false
