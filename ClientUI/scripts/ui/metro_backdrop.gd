class_name MetroBackdrop
extends Control
## The city map every screen sits on: streets, parks, a river,
## and faint ghost lines with small trains running on them.

## How present the ghost network is (menus louder, game board quieter).
@export_range(0.0, 1.0) var intensity: float = 0.55
@export var show_river: bool = true

const BASE := Vector2(1152, 648)

const GHOST_LINES := [
	{"color": Color("#6a4bc4"), "points": [Vector2(-60, 118), Vector2(250, 118), Vector2(392, 260), Vector2(760, 260), Vector2(902, 118), Vector2(1220, 118)]},
	{"color": Color("#0f8577"), "points": [Vector2(176, -60), Vector2(176, 300), Vector2(420, 544), Vector2(1220, 544)]},
	{"color": Color("#f5b700"), "points": [Vector2(-60, 470), Vector2(118, 470), Vector2(330, 682)]},
	{"color": Color("#d63a24"), "points": [Vector2(984, -60), Vector2(984, 330), Vector2(1220, 566)]},
]

const PARKS := [Rect2(52, 512, 176, 96), Rect2(812, 30, 196, 70), Rect2(520, 572, 150, 64), Rect2(1040, 390, 90, 120)]

var _time := 0.0
var _river := PackedVector2Array()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_time = randf() * 20.0

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _scale() -> Vector2:
	return Vector2(size.x / BASE.x, size.y / BASE.y)

func _draw() -> void:
	var k := _scale()
	draw_rect(Rect2(Vector2.ZERO, size), Metro.PAPER)

	# Parks
	for r in PARKS:
		var rr := Rect2(r.position * k, r.size * k)
		draw_style_box(Metro.box(Metro.PARK, 18), rr)

	# Streets: an orthogonal grid plus two avenues.
	var street := Color(Metro.STREET, 0.95)
	var step := 64.0 * k.x
	var x := fposmod(18.0, step)
	while x < size.x:
		draw_line(Vector2(x, 0), Vector2(x, size.y), street, 3.0)
		x += step
	var y := fposmod(30.0, step)
	while y < size.y:
		draw_line(Vector2(0, y), Vector2(size.x, y), street, 3.0)
		y += step
	draw_line(Vector2(-20, size.y * 0.95), Vector2(size.x * 0.62, -20), street, 7.0, true)
	draw_line(Vector2(size.x * 0.48, size.y + 20), Vector2(size.x + 20, size.y * 0.18), street, 7.0, true)

	# River — slow, almost imperceptible drift.
	if show_river:
		_river.clear()
		var n := 48
		for i in range(n + 1):
			var t := float(i) / n
			var px := lerpf(-60.0, BASE.x + 60.0, t)
			var py := 372.0 + sin(t * 5.2 + 0.6) * 46.0 + sin(t * 11.0 + _time * 0.25) * 4.0 - t * 70.0
			_river.append(Vector2(px, py) * k)
		draw_polyline(_river, Metro.WATER, 46.0 * k.y, true)

	# Ghost network
	if intensity <= 0.0:
		return
	for li in range(GHOST_LINES.size()):
		var line: Dictionary = GHOST_LINES[li]
		var pts := PackedVector2Array()
		for p in line.points:
			pts.append(p * k)
		var col: Color = line.color
		draw_polyline(pts, Color(col, 0.22 * intensity), 11.0, true)
		# Stations at the bends
		for i in range(1, pts.size() - 1):
			draw_circle(pts[i], 9.0, Color(Metro.WHITE, 0.85 * intensity), true, -1, true)
			draw_arc(pts[i], 9.0, 0, TAU, 24, Color(Metro.INK, 0.35 * intensity), 3.0, true)
		# A train ping-pongs along each line.
		var length := Metro.polyline_length(pts)
		var speed := 46.0 + li * 9.0
		var travel := fposmod(_time * speed + li * 311.0, length * 2.0)
		var d := travel if travel < length else length * 2.0 - travel
		var at: Array = Metro.point_along(pts, d)
		var pos: Vector2 = at[0]
		var dir: Vector2 = at[1]
		var half := dir * 13.0
		var ta := clampf(intensity * 1.3, 0.0, 0.9)
		draw_line(pos - half, pos + half, Color(Metro.INK, ta * 0.5), 14.0, true)
		draw_line(pos - half, pos + half, Color(Metro.WHITE, ta), 10.0, true)
		draw_circle(pos + half * 0.8, 3.0, Color(col, ta), true, -1, true)
