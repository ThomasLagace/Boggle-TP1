class_name DepartureBoard
extends Control
## The ink header: clock, the line being traced, scores.
## A clock train runs along its bottom edge toward the terminus.

## 0 → game start, 1 → time is up. Negative hides the track.
var progress: float = -1.0
var urgent := false
var _time := 0.0
var _flash := 0.0
## Separators drawn between these children (x positions read live).
@export var dividers: Array[Control] = []


func _process(delta: float) -> void:
	_time += delta
	_flash = lerpf(_flash, (0.5 + 0.5 * sin(_time * 8.0)) if urgent else 0.0, 1.0 - exp(-delta * 10.0))
	queue_redraw()

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var fill := Metro.INK.lerp(Color("#3a1414"), _flash * 0.6)
	draw_style_box(Metro.shadowed(Metro.box(fill, 16), 18, Vector2(0, 8), Color(Metro.INK, 0.28)), r)

	for d in dividers:
		if d == null or not d.visible:
			continue
		var x := d.get_global_rect().position.x - get_global_rect().position.x - 14.0
		draw_line(Vector2(x, 14), Vector2(x, size.y - 18), Color(Metro.ON_INK_SOFT, 0.25), 2.0)

	if progress < 0.0:
		return
	# Time track
	var y := size.y - 7.0
	var x0 := 22.0
	var x1 := size.x - 22.0
	var p := clampf(progress, 0.0, 1.0)
	var xp := lerpf(x0, x1, p)
	var track := Metro.VERMILLION_HOT if urgent else Metro.SAFFRON
	draw_line(Vector2(x0, y), Vector2(x1, y), Color(Metro.ON_INK_SOFT, 0.22), 4.0)
	draw_line(Vector2(x0, y), Vector2(xp, y), Color(track, 0.9), 4.0)
	# terminus
	draw_circle(Vector2(x1, y), 6.0, Metro.ON_INK, true, -1, true)
	draw_circle(Vector2(x1, y), 3.0, Metro.INK, true, -1, true)
	# clock train
	draw_line(Vector2(xp - 10, y), Vector2(xp + 10, y), Metro.ON_INK, 8.0, true)
	draw_circle(Vector2(xp + 10, y), 4.0, Metro.ON_INK, true, -1, true)
	draw_circle(Vector2(xp - 10, y), 4.0, Metro.ON_INK, true, -1, true)
	draw_circle(Vector2(xp + 9, y), 2.0, track, true, -1, true)
