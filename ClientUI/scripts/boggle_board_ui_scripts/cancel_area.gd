extends MarginContainer
## Side "ANNULER" zone styled as an out-of-service track: ink panel,
## scrolling hazard stripes, turning vermillion when the line is over it.

@export var label: Label

var _hot := false
var hot_t := 0.0
var _time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if label:
		label.add_theme_font_override("font", Metro.font_black)
		label.add_theme_font_size_override("font_size", 26)
		label.add_theme_color_override("font_color", Metro.ON_INK)

func set_hot(hot: bool) -> void:
	if hot and not _hot:
		Metro.chime_tick(true)
	_hot = hot

func _process(delta: float) -> void:
	_time += delta * (1.0 + 2.5 * hot_t)
	hot_t = lerpf(hot_t, 1.0 if _hot else 0.0, 1.0 - exp(-delta * 16.0))
	if label:
		label.pivot_offset = label.size * 0.5
		label.scale = Vector2.ONE * (1.0 + 0.12 * hot_t)
	queue_redraw()

func _draw() -> void:
	var ml := float(get_theme_constant("margin_left"))
	var mt := float(get_theme_constant("margin_top"))
	var mr := float(get_theme_constant("margin_right"))
	var mb := float(get_theme_constant("margin_bottom"))
	var r := Rect2(Vector2(ml, mt), size - Vector2(ml + mr, mt + mb))
	var grow := 6.0 * hot_t
	r = r.grow(grow)
	var fill := Metro.INK.lerp(Metro.VERMILLION, hot_t)
	var panel := Metro.shadowed(Metro.box(fill, 22), 16, Vector2(0, 8), Color(Metro.INK, 0.25))
	draw_style_box(panel, r)

	# Hazard stripes, clipped to the inner rect by drawing short segments.
	var stripe := Color(Metro.WHITE, 0.06 + 0.1 * hot_t)
	var inner := r.grow(-12)
	var spacing := 34.0
	var shift := fposmod(_time * 22.0, spacing)
	var x := inner.position.x - inner.size.y + shift
	while x < inner.end.x:
		var a := Vector2(x, inner.end.y)
		var b := Vector2(x + inner.size.y, inner.position.y)
		# clip to inner rect horizontally
		if a.x < inner.position.x:
			a = Vector2(inner.position.x, inner.end.y - (inner.position.x - x))
		if b.x > inner.end.x:
			b = Vector2(inner.end.x, inner.position.y + (b.x - inner.end.x))
		if a.x < b.x:
			draw_line(a, b, stripe, 12.0, true)
		x += spacing

	# A drawn cross above the label: the "no service" mark.
	var c := r.get_center() + Vector2(0, -58)
	var s := 20.0 + 4.0 * hot_t
	draw_circle(c, s + 12.0, Color(Metro.WHITE, 0.95), true, -1, true)
	var mark := Metro.INK.lerp(Metro.VERMILLION, 1.0 - hot_t * 0.0)
	draw_line(c + Vector2(-s, -s) * 0.55, c + Vector2(s, s) * 0.55, mark, 7.0, true)
	draw_line(c + Vector2(-s, s) * 0.55, c + Vector2(s, -s) * 0.55, mark, 7.0, true)
