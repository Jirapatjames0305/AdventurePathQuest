extends SceneTree
## Builds the project-wide UI theme (roadmap V6, chosen 2026-10-20):
## "Dark glass, gold rim" with Godot's default font.
## Run: Godot --headless --path . --script res://scripts/tools/build_theme.gd
## Writes res://themes/frontier_theme.tres (set as gui/theme/custom).

const OUT := "res://themes/frontier_theme.tres"

const GLASS := Color(0.12, 0.098, 0.075, 0.92)
const GOLD := Color(0.85, 0.68, 0.36)
const GOLD_BRIGHT := Color(0.96, 0.8, 0.45)
const GOLD_DARK := Color(0.48, 0.33, 0.13)
const BUTTON := Color(0.23, 0.17, 0.11)
const BUTTON_HOVER := Color(0.31, 0.23, 0.14)
const BUTTON_ON := Color(0.6, 0.45, 0.2)
const BUTTON_OFF := Color(1, 1, 1, 0.07)
const TEXT := Color(0.965, 0.933, 0.863)
const MUTED := Color(0.79, 0.73, 0.63)
const TITLE := Color(0.95, 0.78, 0.42)
const HP_FILL := Color(0.78, 0.26, 0.2)


func _initialize() -> void:
	var theme := Theme.new()
	_panels(theme)
	_buttons(theme)
	_text(theme)
	_bars(theme)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://themes"))
	var err := ResourceSaver.save(theme, OUT)
	print("[THEME] saved %s (%s)" % [OUT, error_string(err)])
	quit(0 if err == OK else 1)


func _box(bg: Color, border: Color, width: int, radius: int, margin_h := 14, margin_v := 10) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(radius)
	box.content_margin_left = margin_h
	box.content_margin_right = margin_h
	box.content_margin_top = margin_v
	box.content_margin_bottom = margin_v
	box.anti_aliasing = true
	return box


func _panels(theme: Theme) -> void:
	var glass := _box(GLASS, GOLD, 3, 16, 18, 14)
	glass.shadow_color = Color(0, 0, 0, 0.4)
	glass.shadow_size = 10
	glass.shadow_offset = Vector2(0, 4)
	theme.set_stylebox("panel", "PanelContainer", glass)
	theme.set_stylebox("panel", "Panel", glass)
	var line := StyleBoxLine.new()
	line.color = Color(GOLD, 0.35)
	line.thickness = 2
	theme.set_stylebox("separator", "HSeparator", line)
	theme.set_constant("separation", "HSeparator", 10)


func _buttons(theme: Theme) -> void:
	theme.set_stylebox("normal", "Button", _box(BUTTON, GOLD, 2, 10))
	theme.set_stylebox("hover", "Button", _box(BUTTON_HOVER, GOLD_BRIGHT, 2, 10))
	theme.set_stylebox("pressed", "Button", _box(BUTTON_ON, GOLD_BRIGHT, 2, 10))
	theme.set_stylebox("hover_pressed", "Button", _box(BUTTON_ON.lightened(0.08), GOLD_BRIGHT, 2, 10))
	theme.set_stylebox("disabled", "Button", _box(BUTTON_OFF, Color(0, 0, 0, 0), 2, 10))
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_pressed_color", "Button", Color.WHITE)
	theme.set_color("font_hover_pressed_color", "Button", Color.WHITE)
	theme.set_color("font_disabled_color", "Button", Color(MUTED, 0.7))
	theme.set_color("font_focus_color", "Button", TEXT)


func _text(theme: Theme) -> void:
	theme.set_color("font_color", "Label", TEXT)
	theme.set_color("font_outline_color", "Label", Color(0, 0, 0, 0.75))
	# Thin dark outline keeps cream text readable over bright 3D scenes too.
	theme.set_constant("outline_size", "Label", 5)
	theme.set_color("default_color", "RichTextLabel", TEXT)
	theme.set_color("font_color", "LineEdit", TEXT)


func _bars(theme: Theme) -> void:
	theme.set_stylebox("background", "ProgressBar", _box(Color(0, 0, 0, 0.45), GOLD_DARK, 2, 8, 0, 0))
	theme.set_stylebox("fill", "ProgressBar", _box(HP_FILL, Color(0, 0, 0, 0), 0, 8, 0, 0))
	theme.set_color("font_color", "ProgressBar", TEXT)
	theme.set_color("font_outline_color", "ProgressBar", Color(0, 0, 0, 0.8))
	theme.set_constant("outline_size", "ProgressBar", 4)
