extends Control
## Root screen: background, game view, HUD and game-over overlay.

var _bg: SkinBackground
var _view: GameView
var _score_label: Label
var _best_label: Label
var _combo_label: Label
var _skin_button: Button
var _credits_button: Button
var _sound_button: Button
var _haptics_button: Button
var _credits: CreditsView
var _over_layer: Control
var _over_panel: PanelContainer
var _over_title: Label
var _over_score: Label
var _over_record: Label
var _again_button: Button


func _ready() -> void:
	_bg = SkinBackground.new()
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_bg)
	_view = GameView.new()
	_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_view)
	_build_hud()
	_build_game_over()
	_credits = CreditsView.new()
	_credits.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_credits)
	_view.state_changed.connect(_on_state_changed)
	_view.game_over.connect(_on_game_over)
	_view.piece_picked.connect(Feedback.pick)
	_view.piece_dropped_invalid.connect(Feedback.invalid)
	_view.move_made.connect(_on_move_made)
	GameSettings.skin_changed.connect(_apply_skin)
	_apply_skin(GameSettings.current_skin())
	_view.new_game()


func _build_hud() -> void:
	_score_label = _make_label(90, 70.0, 170.0)
	_best_label = _make_label(30, 170.0, 215.0)
	_combo_label = _make_label(34, 205.0, 250.0)
	_skin_button = Button.new()
	_skin_button.text = "Estilo"
	_skin_button.add_theme_font_size_override("font_size", 28)
	_skin_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_skin_button.offset_left = -170.0
	_skin_button.offset_right = -20.0
	_skin_button.offset_top = 20.0
	_skin_button.offset_bottom = 80.0
	_skin_button.focus_mode = Control.FOCUS_NONE
	_skin_button.pressed.connect(Feedback.click)
	_skin_button.pressed.connect(GameSettings.cycle_skin)
	add_child(_skin_button)
	_credits_button = _make_corner_button("Créditos", 20.0)
	_credits_button.pressed.connect(Feedback.click)
	# Credits are created after the HUD so they draw on top of it.
	_credits_button.pressed.connect(func() -> void: _credits.show_credits())
	_sound_button = _make_corner_button("", 86.0)
	_sound_button.pressed.connect(_on_sound_pressed)
	_haptics_button = _make_corner_button("", 152.0)
	_haptics_button.pressed.connect(_on_haptics_pressed)
	_refresh_toggles()


## Small button stacked in the top-left corner.
func _make_corner_button(text: String, top: float) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", 24)
	button.position = Vector2(20.0, top)
	button.size = Vector2(190.0, 56.0)
	button.focus_mode = Control.FOCUS_NONE
	add_child(button)
	return button


func _refresh_toggles() -> void:
	_sound_button.text = "Sonido: %s" % ("sí" if GameSettings.sound_enabled else "no")
	_haptics_button.text = "Vibración: %s" % ("sí" if GameSettings.haptics_enabled else "no")


func _on_sound_pressed() -> void:
	GameSettings.set_sound_enabled(not GameSettings.sound_enabled)
	_refresh_toggles()
	Feedback.click()


func _on_haptics_pressed() -> void:
	GameSettings.set_haptics_enabled(not GameSettings.haptics_enabled)
	_refresh_toggles()
	Feedback.click()


func _make_label(font_size: int, top: float, bottom: float) -> Label:
	var label := Label.new()
	label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	label.offset_top = top
	label.offset_bottom = bottom
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	add_child(label)
	return label


func _build_game_over() -> void:
	_over_layer = Control.new()
	_over_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_over_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_over_layer.visible = false
	add_child(_over_layer)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_over_layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_over_layer.add_child(center)
	_over_panel = PanelContainer.new()
	_over_panel.custom_minimum_size = Vector2(520, 0)
	center.add_child(_over_panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 36)
	_over_panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 22)
	margin.add_child(box)
	_over_title = _panel_label(box, 52)
	_over_title.text = "Fin del juego"
	_over_score = _panel_label(box, 40)
	_over_record = _panel_label(box, 32)
	_again_button = Button.new()
	_again_button.text = "Jugar de nuevo"
	_again_button.custom_minimum_size = Vector2(0, 84)
	_again_button.add_theme_font_size_override("font_size", 36)
	_again_button.focus_mode = Control.FOCUS_NONE
	_again_button.pressed.connect(_on_again)
	box.add_child(_again_button)


func _panel_label(parent: Control, font_size: int) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label


func _on_state_changed(score: int, combo: int) -> void:
	_score_label.text = str(score)
	_best_label.text = "Mejor: %d" % maxi(GameSettings.high_score, score)
	_combo_label.text = "Combo x%d" % combo if combo >= 2 else ""


func _on_move_made(_gained: int, lines: int, combo: int) -> void:
	if lines > 0:
		Feedback.clear(lines, combo)
	else:
		Feedback.place()


func _on_game_over(score: int, new_record: bool) -> void:
	Feedback.game_over(new_record)
	_over_score.text = "Puntaje: %d" % score
	_over_record.text = "¡Nuevo récord!" if new_record else "Mejor: %d" % GameSettings.high_score
	_over_layer.visible = true


func _notification(what: int) -> void:
	# The Back button closes the credits screen; otherwise it does nothing.
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and _credits != null and _credits.visible:
		_credits.hide_credits()


func _on_again() -> void:
	Feedback.click()
	_over_layer.visible = false
	_view.new_game()


# --- Skin ---------------------------------------------------------------------------

func _apply_skin(skin: GameSkin) -> void:
	_bg.set_skin(skin)
	_score_label.add_theme_color_override("font_color", skin.text_color)
	_best_label.add_theme_color_override("font_color", skin.text_dim_color)
	_combo_label.add_theme_color_override("font_color", skin.accent_color)
	_style_button(_skin_button, skin)
	_style_button(_credits_button, skin)
	_style_button(_sound_button, skin)
	_style_button(_haptics_button, skin)
	_style_button(_again_button, skin)
	_credits.set_skin(skin)
	_over_panel.add_theme_stylebox_override("panel", _flat(skin.panel_color, skin.panel_border_color, skin.panel_border_width, skin.panel_radius))
	_over_title.add_theme_color_override("font_color", skin.text_color)
	_over_score.add_theme_color_override("font_color", skin.text_color)
	_over_record.add_theme_color_override("font_color", skin.accent_color)


func _style_button(button: Button, skin: GameSkin) -> void:
	var normal := _flat(skin.button_color, skin.button_border_color, skin.button_border_width, skin.button_radius)
	var pressed := _flat(skin.button_color.darkened(0.15), skin.button_border_color, skin.button_border_width, skin.button_radius)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", normal)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", skin.button_text_color)
	button.add_theme_color_override("font_hover_color", skin.button_text_color)
	button.add_theme_color_override("font_pressed_color", skin.button_text_color)


func _flat(fill: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(border_width)
	sb.set_corner_radius_all(radius)
	return sb
