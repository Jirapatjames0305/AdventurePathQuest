extends Control
## Small decorative compass rose (top-right). Eight two-tone star points in a
## gold ring; N is red. Points line up with the town's directions on screen
## (North = up-left, East = up-right, South = down-right, West = down-left).

const DIAMETER := 104.0
const GOLD := Color(0.93, 0.76, 0.36)
const GOLD_DARK := Color(0.55, 0.4, 0.16)
const FACE := Color(0.14, 0.16, 0.13, 0.78)
const LIGHT := Color(0.97, 0.94, 0.86)
const SHADE := Color(0.62, 0.58, 0.5)
const RED := Color(0.86, 0.22, 0.18)
const RED_SHADE := Color(0.55, 0.12, 0.1)
## Screen direction of each cardinal point.
const POINTS := {
	"N": Vector2(-0.70710678, -0.70710678),
	"E": Vector2(0.70710678, -0.70710678),
	"S": Vector2(0.70710678, 0.70710678),
	"W": Vector2(-0.70710678, 0.70710678),
}


func _ready() -> void:
	anchor_left = 1.0
	anchor_right = 1.0
	offset_left = -DIAMETER - 22.0
	offset_right = -22.0
	offset_top = 18.0
	offset_bottom = 18.0 + DIAMETER
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var c := size / 2.0
	var r := DIAMETER / 2.0
	draw_circle(c, r - 3.0, FACE)
	draw_arc(c, r - 3.0, 0.0, TAU, 72, GOLD_DARK, 6.0, true)
	draw_arc(c, r - 3.0, 0.0, TAU, 72, GOLD, 3.0, true)
	# Tick marks every 15°.
	for i in 24:
		var a := TAU * i / 24.0
		var d := Vector2(cos(a), sin(a))
		draw_line(c + d * (r - 10.0), c + d * (r - (14.0 if i % 6 == 0 else 12.0)), Color(GOLD, 0.7), 1.2, true)
	# Minor (diagonal-between-cardinal) points first, then the cardinals on top.
	for key in POINTS:
		var d: Vector2 = POINTS[key]
		var between := d.rotated(PI / 4.0)
		_point(c, between, r * 0.42, r * 0.11, SHADE.lightened(0.15), SHADE.darkened(0.25))
	for key in POINTS:
		var north: bool = key == "N"
		_point(c, POINTS[key], r * 0.66, r * 0.15, RED if north else LIGHT, RED_SHADE if north else SHADE)
	draw_circle(c, r * 0.09, GOLD_DARK)
	draw_circle(c, r * 0.06, GOLD)
	var font := get_theme_default_font()
	for key in POINTS:
		var font_size := 15 if key == "N" else 12
		var text_size := font.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		var at: Vector2 = c + POINTS[key] * (r * 0.8) + Vector2(-text_size.x / 2.0, font_size * 0.36)
		draw_string_outline(font, at, key, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 3, Color(0, 0, 0, 0.8))
		draw_string(font, at, key, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, RED.lightened(0.2) if key == "N" else LIGHT)


## One star point: two triangles (lit / shaded halves) from the centre outward.
func _point(c: Vector2, dir: Vector2, length: float, half_width: float, lit: Color, shade: Color) -> void:
	var side := Vector2(-dir.y, dir.x) * half_width
	var tip := c + dir * length
	draw_colored_polygon(PackedVector2Array([c, tip, c + side]), lit)
	draw_colored_polygon(PackedVector2Array([c, c - side, tip]), shade)
