class_name RouteStrip
extends Control
## A vertical line diagram: each accepted word becomes a stop.
## Newest stop arrives at the top and pushes the line down.

@export var line_color: Color = Metro.VERMILLION
## The header row (labels) drawn on a colored pill at the top of the line.
@export var header: Control
@export var align_right: bool = false

const STOP_GAP := 46.0
const TOP := 74.0

var _stops: Array = [] # [{text, points, t, y}]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if header:
		for c in header.get_children():
			if c is Label:
				c.add_theme_color_override("font_color", Metro.WHITE)
				c.add_theme_font_override("font", Metro.font_black)
				c.add_theme_font_size_override("font_size", 17)

func add_stop(text: String, points: int) -> void:
	var stop := {"text": text.to_upper(), "points": points, "t": 0.0, "y": TOP}
	_stops.push_front(stop)
	var tw := create_tween()
	tw.tween_method(func(v: float): stop.t = v, 0.0, 1.0, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	for i in range(_stops.size()):
		var target := TOP + i * STOP_GAP
		_stops[i].y = lerpf(_stops[i].y, target, 1.0 - exp(-delta * 12.0))
	if _stops.size() > 24:
		_stops.resize(24)
	queue_redraw()

func _line_x() -> float:
	return size.x - 26.0 if align_right else 26.0

func _draw() -> void:
	var lx := _line_x()
	var bottom := size.y - 10.0

	# Header pill
	if header and header.visible:
		var hr := Rect2(header.position, header.size).grow_individual(16, 8, 16, 8)
		draw_style_box(Metro.shadowed(Metro.box(line_color, 20), 8, Vector2(0, 4), Color(Metro.INK, 0.2)), hr)

	# The line itself, fading out toward the bottom.
	var top := TOP - 22.0
	var alpha := 1.0 if _stops.size() > 0 else 0.4
	draw_polyline_colors(PackedVector2Array([Vector2(lx, top), Vector2(lx, lerpf(top, bottom, 0.45)), Vector2(lx, bottom)]),
		PackedColorArray([Color(line_color, alpha), Color(line_color, alpha * 0.7), Color(line_color, 0.0)]), 12.0)

	var font := Metro.font_black
	for i in range(_stops.size()):
		var st: Dictionary = _stops[i]
		var y: float = st.y
		if y > bottom - 10:
			continue
		var fade := clampf((bottom - y) / 120.0, 0.0, 1.0)
		var t: float = st.t
		var r := 13.0 * t
		draw_circle(Vector2(lx, y), r + 3, Color(Metro.INK, fade), true, -1, true)
		draw_circle(Vector2(lx, y), maxf(r - 2.0, 0.0), Color(Metro.WHITE, fade), true, -1, true)
		var label: String = st.text
		var pts := ("+%d" % st.points) if st.points > 0 else ""
		var fs := 20 if i == 0 else 17
		var col := Color(Metro.INK, fade * clampf(t, 0.0, 1.0))
		var pcol := Color(line_color.darkened(0.15), fade * clampf(t, 0.0, 1.0))
		var slide := (1.0 - t) * 18.0
		if align_right:
			var tx := lx - 24.0 - slide
			var pw := Metro.font_digits.get_string_size(pts, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
			draw_string(Metro.font_digits, Vector2(tx - pw, y + 6), pts, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, pcol)
			if label != "":
				var lw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
				draw_string(font, Vector2(tx - pw - 10 - lw, y + 7), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
		else:
			var tx := lx + 24.0 + slide
			var lw := 0.0
			if label != "":
				draw_string(font, Vector2(tx, y + 7), label, HORIZONTAL_ALIGNMENT_LEFT, size.x - tx - 40, fs, col)
				lw = minf(font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x, size.x - tx - 40) + 10
			draw_string(Metro.font_digits, Vector2(tx + lw, y + 6), pts, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, pcol)
