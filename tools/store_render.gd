extends Node
## Renders the Google Play graphics with the game's own scene, offscreen in SubViewports:
##   store/assets/icon_512.png          (from icon.svg)
##   store/assets/screens/*.png         (1080x1920, 24-bit)
##   store/assets/feature_1024x500.png  (24-bit, no alpha)
## It needs a real window (not --headless) and runs as a scene so the autoloads exist:
##   godot --path . --resolution 360x640 --rendering-driver opengl3 res://tools/store_render.tscn
## It overwrites the saved skin/high score in user://, so it deletes the save at the end.

const OUT_DIR := "res://store/assets"
const SCREEN_SIZE := Vector2i(1080, 1920)
const GAME_SIZE := Vector2i(720, 1280)

## Mid-game board (digits are block colours, 0 = empty). Row 5 only needs a 1x3 piece.
const BOARD := [
	"00000000",
	"00000000",
	"00000000",
	"00000440",
	"00000040",
	"11000555",
	"22233067",
	"62203377",
]
## [skin index, score, combo, show game over]
const SCREENS := [
	["1_madera", 0, 1240, 3, false],
	["2_colorido", 1, 1240, 3, false],
	["3_neon", 2, 1240, 3, false],
	["4_fin_neon", 2, 1980, 1, true],
]

var _board_crop := Image.new()


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR + "/screens"))
	_render_icon()
	for spec in SCREENS:
		await _render_screen(spec)
	await _render_feature()
	var save := ProjectSettings.globalize_path("user://save.cfg")
	if FileAccess.file_exists("user://save.cfg"):
		DirAccess.remove_absolute(save)
	get_tree().quit()


func _render_icon() -> void:
	var image := Image.new()
	var err := image.load_svg_from_string(FileAccess.get_file_as_string("res://icon.svg"), 1.0)
	image.convert(Image.FORMAT_RGBA8)
	image.save_png(OUT_DIR + "/icon_512.png")
	print("icon err=%d size=%s" % [err, image.get_size()])


func _new_viewport(pixels: Vector2i, logical: Vector2i) -> SubViewport:
	var viewport := SubViewport.new()
	viewport.size = pixels
	viewport.size_2d_override = logical
	viewport.size_2d_override_stretch = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	return viewport


func _set_skin(index: int) -> void:
	var settings := get_node("/root/GameSettings")
	settings._skin_index = index
	settings.skin_changed.emit(settings.current_skin())


func _render_screen(spec: Array) -> void:
	var settings := get_node("/root/GameSettings")
	_set_skin(spec[1])
	var score: int = spec[2]
	settings.high_score = score
	var viewport := _new_viewport(SCREEN_SIZE, GAME_SIZE)
	var main: Control = load("res://main.tscn").instantiate()
	viewport.add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	var view: GameView = main.get_child(1)
	main._on_state_changed(score, spec[3])
	_stage_board(view, spec[4])
	if spec[4]:
		main._on_game_over(score, true)
	await _settle()
	var image := viewport.get_texture().get_image()
	image.convert(Image.FORMAT_RGB8)
	image.save_png("%s/screens/%s.png" % [OUT_DIR, spec[0]])
	print("screen %s %s" % [spec[0], image.get_size()])
	if spec[0] == "1_madera":
		var scale := float(SCREEN_SIZE.x) / GAME_SIZE.x
		var rect := Rect2(view._origin, Vector2(view._board_px, view._board_px)).grow(view._cell * 0.15)
		_board_crop = image.get_region(Rect2i(Vector2i(rect.position * scale), Vector2i(rect.size * scale)))
	viewport.queue_free()
	await get_tree().process_frame


## Fills the board, deals a known hand and shows a piece hovering over the open gap.
func _stage_board(view: GameView, game_over: bool) -> void:
	for y in 8:
		for x in 8:
			view._board.cells[y * 8 + x] = int(BOARD[y][x])
	var entries := PieceCatalog.entries()
	var line3 := _find_piece(entries, [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)])
	var corner := _find_piece(entries, [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)])
	var square := _find_piece(entries, [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)])
	view._hand = [
		{"id": line3, "color": 3, "used": false},
		{"id": corner, "color": 6, "used": false},
		{"id": square, "color": 5, "used": false},
	]
	view._playing = true
	if not game_over:
		# The finger is 1.2 cells below the piece; aim at cell (2, 5), a little off so the
		# floating piece and its snapped ghost are both visible.
		var cell: float = view._cell
		var top_left: Vector2 = view._origin + Vector2(2.35, 4.8) * cell
		view._drag_slot = 0
		view._drag_pos = top_left + Vector2(1.5 * cell, 1.0 * cell + 1.2 * cell)
		view._popups.append({"text": "+90", "pos": view._origin + Vector2(3.5, 3.5) * cell, "t": 0.15})
	view.queue_redraw()


func _find_piece(entries: Array, cells: Array) -> int:
	for e in entries:
		if e["cells"] == cells:
			return e["id"]
	push_error("piece not found")
	return 0


func _settle() -> void:
	# The wood grain texture is generated in a thread: wait until it is ready.
	for _i in 90:
		await get_tree().process_frame
	await get_tree().create_timer(1.0).timeout
	for _i in 5:
		await get_tree().process_frame


func _render_feature() -> void:
	_set_skin(0)
	var skin: GameSkin = get_node("/root/GameSettings").current_skin()
	var viewport := _new_viewport(Vector2i(1024, 500), Vector2i(1024, 500))
	var background := SkinBackground.new()
	viewport.add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.set_skin(skin)

	var board := TextureRect.new()
	board.texture = ImageTexture.create_from_image(_board_crop)
	board.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	board.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	board.position = Vector2(580, 40)
	board.size = Vector2(420, 420)
	viewport.add_child(board)

	var fade := GradientTexture2D.new()
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 1.0])
	ramp.colors = PackedColorArray([Color(0, 0, 0, 0.55), Color(0, 0, 0, 0.0)])
	fade.gradient = ramp
	fade.fill_from = Vector2(0.0, 0.0)
	fade.fill_to = Vector2(1.0, 0.0)
	fade.width = 256
	fade.height = 4
	var fade_rect := TextureRect.new()
	fade_rect.texture = fade
	fade_rect.stretch_mode = TextureRect.STRETCH_SCALE
	fade_rect.size = Vector2(560, 500)
	viewport.add_child(fade_rect)

	# Cream text: the skin's dark brown is unreadable over the dark gradient.
	var cream := Color(1.0, 0.94, 0.8)
	viewport.add_child(_label("BlockesRotos", Vector2(48, 90), 70, cream, Vector2(480, 0)))
	var subtitle := _label("Arrastra piezas, completa líneas y encadena combos.", Vector2(52, 215), 30, cream, Vector2(440, 0))
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	viewport.add_child(subtitle)
	viewport.add_child(_label("Sin anuncios  ·  Sin internet  ·  3 estilos", Vector2(52, 410), 24, Color(1.0, 0.82, 0.45), Vector2(480, 0)))

	await _settle()
	var image := viewport.get_texture().get_image()
	image.convert(Image.FORMAT_RGB8)
	image.save_png(OUT_DIR + "/feature_1024x500.png")
	print("feature %s" % image.get_size())
	viewport.queue_free()


func _label(text: String, pos: Vector2, font_size: int, color: Color, min_size: Vector2) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.custom_minimum_size = min_size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	label.add_theme_constant_override("shadow_offset_y", 4)
	return label
