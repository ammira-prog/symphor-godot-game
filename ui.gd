extends CanvasLayer

# All the screens (start, pause, game over) and the pause button.
# Built in code so the scene file stays simple. main.gd tells this script
# which screen to show and listens for the button signals below.

signal start_pressed
signal restart_pressed
signal menu_pressed
signal pause_pressed
signal resume_pressed
signal sound_pressed
signal escape_pressed

const TITLE_COLOR := Color(0.99, 0.90, 0.54)
const TEXT_COLOR := Color(1.0, 1.0, 1.0)
const DIM_COLOR := Color(0.05, 0.07, 0.13, 0.78)

var menu_panel: Control
var pause_panel: Control
var over_panel: Control
var pause_button: Button

var menu_best_label: Label
var menu_sound_button: Button
var pause_sound_button: Button
var over_score_label: Label
var over_distance_label: Label
var over_best_label: Label

@onready var score_label: Label = $ScoreLabel
@onready var distance_label: Label = $DistanceLabel


func _ready() -> void:
	# Keep working while the game is paused so the buttons still respond.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_hud()
	_build_menu()
	_build_pause()
	_build_game_over()
	_hide_screens()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		escape_pressed.emit()


# ---------------------------------------------------------------------------
# Screens
# ---------------------------------------------------------------------------
func show_menu(best_score: int, best_distance: int, sound_on: bool) -> void:
	_hide_screens()
	menu_best_label.text = "Best score: %d\nBest distance: %dm" % [best_score, best_distance]
	set_sound_text(sound_on)
	menu_panel.show()


func show_playing() -> void:
	_hide_screens()
	_set_hud_visible(true)
	pause_button.show()


func show_paused(sound_on: bool) -> void:
	_hide_screens()
	_set_hud_visible(true)
	set_sound_text(sound_on)
	pause_panel.show()


func show_game_over(score: int, distance_m: int, best_score: int, new_best: bool) -> void:
	_hide_screens()
	_set_hud_visible(false)
	over_score_label.text = "Score: %d" % score
	over_distance_label.text = "Distance: %dm" % distance_m
	if new_best:
		over_best_label.text = "NEW BEST!"
		over_best_label.add_theme_color_override("font_color", TITLE_COLOR)
	else:
		over_best_label.text = "Best: %d" % best_score
		over_best_label.add_theme_color_override("font_color", TEXT_COLOR)
	over_panel.show()


func set_sound_text(sound_on: bool) -> void:
	var text := "SOUND: ON" if sound_on else "SOUND: OFF"
	menu_sound_button.text = text
	pause_sound_button.text = text


func _hide_screens() -> void:
	menu_panel.hide()
	pause_panel.hide()
	over_panel.hide()
	pause_button.hide()
	_set_hud_visible(false)


func _set_hud_visible(shown: bool) -> void:
	score_label.visible = shown
	distance_label.visible = shown


# ---------------------------------------------------------------------------
# Building the interface
# ---------------------------------------------------------------------------
func _build_hud() -> void:
	score_label.position = Vector2(24.0, 20.0)
	score_label.add_theme_font_size_override("font_size", 36)

	distance_label.position = Vector2(0.0, 20.0)
	distance_label.size = Vector2(720.0, 44.0)
	distance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	distance_label.add_theme_font_size_override("font_size", 36)

	pause_button = Button.new()
	pause_button.text = "II"
	pause_button.custom_minimum_size = Vector2(84.0, 84.0)
	_style_button(pause_button, 36)
	add_child(pause_button)
	pause_button.position = Vector2(720.0 - 84.0 - 20.0, 12.0)
	pause_button.size = Vector2(84.0, 84.0)
	pause_button.pressed.connect(func(): pause_pressed.emit())


func _build_menu() -> void:
	var parts := _make_overlay()
	menu_panel = parts[0]
	var box: VBoxContainer = parts[1]
	_add_label(box, "PROJECT\nSYMPHOR", 88, TITLE_COLOR)
	menu_best_label = _add_label(box, "", 32, TEXT_COLOR)
	_add_spacer(box, 30.0)
	_add_button(box, "PLAY", func(): start_pressed.emit())
	menu_sound_button = _add_button(box, "SOUND: ON", func(): sound_pressed.emit(), 30)


func _build_pause() -> void:
	var parts := _make_overlay()
	pause_panel = parts[0]
	var box: VBoxContainer = parts[1]
	_add_label(box, "PAUSED", 88, TITLE_COLOR)
	_add_spacer(box, 30.0)
	_add_button(box, "RESUME", func(): resume_pressed.emit())
	pause_sound_button = _add_button(box, "SOUND: ON", func(): sound_pressed.emit(), 30)
	_add_button(box, "MENU", func(): menu_pressed.emit(), 30)


func _build_game_over() -> void:
	var parts := _make_overlay()
	over_panel = parts[0]
	var box: VBoxContainer = parts[1]
	_add_label(box, "GAME OVER", 88, TITLE_COLOR)
	over_score_label = _add_label(box, "", 44, TEXT_COLOR)
	over_distance_label = _add_label(box, "", 44, TEXT_COLOR)
	over_best_label = _add_label(box, "", 38, TEXT_COLOR)
	_add_spacer(box, 30.0)
	_add_button(box, "RESTART", func(): restart_pressed.emit())
	_add_button(box, "MENU", func(): menu_pressed.emit(), 30)


# A full-screen dark overlay with a centred column inside. Returns [overlay, column].
func _make_overlay() -> Array:
	var root := Control.new()
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var dim := ColorRect.new()
	dim.color = DIM_COLOR
	root.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	root.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 22)
	center.add_child(box)
	return [root, box]


func _add_label(box: Control, text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	box.add_child(label)
	return label


func _add_spacer(box: Control, height: float) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, height)
	box.add_child(spacer)


func _add_button(box: Control, text: String, action: Callable, font_size: int = 40) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(380.0, 96.0)
	_style_button(button, font_size)
	button.pressed.connect(action)
	box.add_child(button)
	return button


func _style_button(button: Button, font_size: int) -> void:
	button.add_theme_stylebox_override("normal", _make_style(Color(0.8627, 0.3843, 0.4078)))
	button.add_theme_stylebox_override("hover", _make_style(Color(0.9176, 0.5216, 0.5373)))
	button.add_theme_stylebox_override("pressed", _make_style(Color(0.7255, 0.2784, 0.3137)))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", TEXT_COLOR)
	button.add_theme_color_override("font_hover_color", TEXT_COLOR)
	button.add_theme_color_override("font_pressed_color", TEXT_COLOR)
	button.add_theme_font_size_override("font_size", font_size)


func _make_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(16)
	style.set_content_margin_all(12.0)
	return style
