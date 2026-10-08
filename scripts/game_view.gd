class_name GameView
extends Control
## Draws the board and the piece tray, and handles dragging pieces onto the grid.
## All colours and shapes come from the active GameSkin.

signal state_changed(score: int, combo: int)
signal piece_picked
signal piece_dropped_invalid
signal move_made(gained: int, lines: int, combo: int)
signal game_over(score: int, new_record: bool)

const GRID := BoardState.SIZE
const BLOCK_COLORS := 7
const TOP_RESERVED := 250.0
const SIDE_MARGIN := 24.0
const BOTTOM_MARGIN := 24.0
const TRAY_SCALE := 0.5
## How far above the finger the dragged piece floats, in cells, so the finger never hides it.
const DRAG_LIFT := 1.2
const FLASH_TIME := 0.35
const POPUP_TIME := 0.9

var _skin: GameSkin
var _board := BoardState.new()
var _keeper := ScoreKeeper.new()
var _generator := PieceGenerator.new()
var _hand: Array[Dictionary] = []
var _playing := false
var _record_beaten := false
var _drag_slot := -1
var _drag_pos := Vector2.ZERO
var _flashes: Array[Dictionary] = []
var _popups: Array[Dictionary] = []
var _cell := 40.0
var _origin := Vector2.ZERO
var _board_px := 320.0
var _box := StyleBoxFlat.new()
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_skin = GameSettings.current_skin()
	GameSettings.skin_changed.connect(_on_skin_changed)
	resized.connect(_layout)
	_layout()


func new_game() -> void:
	_board = BoardState.new()
	_keeper = ScoreKeeper.new()
	_generator = PieceGenerator.new()
	_record_beaten = false
	_drag_slot = -1
	_flashes.clear()
	_popups.clear()
	_deal()
	_playing = true
	state_changed.emit(0, 0)
	queue_redraw()


func is_playing() -> bool:
	return _playing


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_drag_slot = -1
		queue_redraw()


func _on_skin_changed(skin: GameSkin) -> void:
	_skin = skin
	queue_redraw()


func _deal() -> void:
	_hand.clear()
	for id in _generator.next_hand(_board, _keeper.score):
		_hand.append({"id": id, "color": _rng.randi_range(1, BLOCK_COLORS), "used": false})


# --- Layout -------------------------------------------------------------------------

func _layout() -> void:
	# Board + gap + tray = board_px * (1 + 3.5 / 8); fit it under the HUD.
	var fit_height := (size.y - TOP_RESERVED - BOTTOM_MARGIN) / (1.0 + 3.5 / GRID)
	_board_px = maxf(80.0, minf(size.x - 2.0 * SIDE_MARGIN, fit_height))
	_cell = _board_px / GRID
	var content := _board_px + 3.5 * _cell
	var top := TOP_RESERVED + maxf(0.0, (size.y - TOP_RESERVED - BOTTOM_MARGIN - content) / 2.0)
	_origin = Vector2((size.x - _board_px) / 2.0, top)
	queue_redraw()


func _slot_rect(slot: int) -> Rect2:
	var w := _board_px / 3.0
	return Rect2(_origin.x + slot * w, _origin.y + _board_px + 0.5 * _cell, w, 3.0 * _cell)


func _slot_at(pos: Vector2) -> int:
	for i in _hand.size():
		if _slot_rect(i).has_point(pos):
			return i
	return -1


func _piece_cells(slot: int) -> Array:
	return PieceCatalog.entries()[_hand[slot]["id"]]["cells"]


func _bounds(cells: Array) -> Vector2i:
	var b := Vector2i.ZERO
	for c: Vector2i in cells:
		b.x = maxi(b.x, c.x + 1)
		b.y = maxi(b.y, c.y + 1)
	return b


## Top-left of the dragged piece for the current finger position.
func _drag_top_left() -> Vector2:
	var b := _bounds(_piece_cells(_drag_slot))
	return _drag_pos - Vector2(b.x * _cell / 2.0, b.y * _cell + DRAG_LIFT * _cell)


func _drag_target() -> Vector2i:
	var g := (_drag_top_left() - _origin) / _cell
	return Vector2i(roundi(g.x), roundi(g.y))


# --- Input --------------------------------------------------------------------------

func _gui_input(event: InputEvent) -> void:
	if not _playing:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var slot := _slot_at(event.position)
			if slot >= 0 and not _hand[slot]["used"]:
				_drag_slot = slot
				_drag_pos = event.position
				piece_picked.emit()
				queue_redraw()
		elif _drag_slot >= 0:
			_drop()
	elif event is InputEventMouseMotion and _drag_slot >= 0:
		_drag_pos = event.position
		queue_redraw()


func _drop() -> void:
	var slot := _drag_slot
	# The target depends on the dragged piece, so compute it before clearing the slot.
	var target := _drag_target()
	_drag_slot = -1
	if _board.can_place(_piece_cells(slot), target.x, target.y):
		_commit(slot, target)
	else:
		piece_dropped_invalid.emit()
	queue_redraw()


func _commit(slot: int, target: Vector2i) -> void:
	var cells := _piece_cells(slot)
	var result := _board.place(cells, target.x, target.y, _hand[slot]["color"])
	var gained := _keeper.apply_move(result)
	var lines: int = result["rows"].size() + result["cols"].size()
	_hand[slot]["used"] = true
	for f: Array in result["flash"]:
		_flashes.append({"x": f[0] % GRID, "y": f[0] / GRID, "color": f[1], "t": 0.0})
	var b := _bounds(cells)
	_popups.append({
		"text": "+%d" % gained,
		"pos": _origin + (Vector2(target) + Vector2(b) / 2.0) * _cell,
		"t": 0.0,
	})
	# Save the record the moment it is beaten, not at game over.
	if GameSettings.submit_score(_keeper.score):
		_record_beaten = true
	move_made.emit(gained, lines, _keeper.combo)
	state_changed.emit(_keeper.score, _keeper.combo)
	var all_used := true
	for h in _hand:
		if not h["used"]:
			all_used = false
	if all_used:
		_deal()
	if not _any_piece_fits():
		_playing = false
		game_over.emit(_keeper.score, _record_beaten)
	set_process(true)


func _any_piece_fits() -> bool:
	for i in _hand.size():
		if not _hand[i]["used"] and _board.fits_anywhere(_piece_cells(i)):
			return true
	return false


func _process(delta: float) -> void:
	for f in _flashes:
		f["t"] += delta / FLASH_TIME
	for p in _popups:
		p["t"] += delta / POPUP_TIME
	_flashes = _flashes.filter(func(f: Dictionary) -> bool: return f["t"] < 1.0)
	_popups = _popups.filter(func(p: Dictionary) -> bool: return p["t"] < 1.0)
	if _flashes.is_empty() and _popups.is_empty():
		set_process(false)
	queue_redraw()


# --- Drawing ------------------------------------------------------------------------

func _draw() -> void:
	if _skin == null:
		return
	_draw_board_frame()
	for y in GRID:
		for x in GRID:
			var v := _board.get_cell(x, y)
			if v == 0:
				_draw_empty_cell(x, y)
			else:
				_draw_block(_cell_rect(x, y), v, 1.0)
	_draw_flashes()
	_draw_tray()
	if _drag_slot >= 0:
		_draw_drag()
	_draw_popups()


func _cell_rect(x: int, y: int) -> Rect2:
	var gap := _cell * _skin.cell_gap
	return Rect2(_origin + Vector2(x, y) * _cell + Vector2(gap, gap) / 2.0, Vector2(_cell - gap, _cell - gap))


func _draw_board_frame() -> void:
	var pad := _cell * 0.12
	_box.bg_color = _skin.board_color
	_box.border_color = _skin.board_border_color
	_box.set_border_width_all(_skin.board_border_width)
	_box.set_corner_radius_all(_skin.board_radius)
	_box.shadow_size = 0
	draw_style_box(_box, Rect2(_origin - Vector2(pad, pad), Vector2(_board_px, _board_px) + Vector2(pad, pad) * 2.0))


func _draw_empty_cell(x: int, y: int) -> void:
	var r := _cell_rect(x, y)
	_box.bg_color = _skin.cell_empty_color
	_box.border_color = _skin.cell_empty_border_color
	_box.set_border_width_all(1)
	_box.set_corner_radius_all(int(r.size.x * _skin.block_radius))
	_box.shadow_size = 0
	draw_style_box(_box, r)


func _draw_block(r: Rect2, color_index: int, alpha: float) -> void:
	var base := _skin.block_colors[(color_index - 1) % _skin.block_colors.size()]
	base.a *= alpha
	match _skin.block_style:
		GameSkin.BlockStyle.WOOD:
			_draw_wood_block(r, base, color_index)
		GameSkin.BlockStyle.NEON:
			_draw_neon_block(r, base)
		_:
			_draw_glossy_block(r, base)


## Fill, border and drop shadow shared by every block style.
func _style_box(fill: Color, border: Color, border_width: int, radius: int, shadow: Color) -> void:
	_box.bg_color = fill
	_box.border_color = border
	_box.set_border_width_all(border_width)
	_box.set_corner_radius_all(radius)
	if shadow.a > 0.0:
		_box.shadow_color = shadow
		_box.shadow_size = _skin.block_shadow_size
		_box.shadow_offset = _skin.block_shadow_offset
	else:
		_box.shadow_size = 0


func _draw_glossy_block(r: Rect2, base: Color) -> void:
	var shadow := _skin.block_shadow_color
	shadow.a *= base.a if base.a >= 0.99 else 0.0
	_style_box(base, Color(base.darkened(_skin.block_border_darken), base.a),
		_skin.block_border_width, int(r.size.x * _skin.block_radius), shadow)
	draw_style_box(_box, r)
	if _skin.block_gloss > 0.0:
		var inset := r.size.x * 0.14
		var gloss := Rect2(r.position + Vector2(inset, inset * 0.8), Vector2(r.size.x - inset * 2.0, r.size.y * 0.2))
		draw_rect(gloss, Color(1, 1, 1, _skin.block_gloss * base.a))


## A small plank: wavy grain lines and a lit top/left edge with a shaded bottom.
func _draw_wood_block(r: Rect2, base: Color, color_index: int) -> void:
	var shadow := _skin.block_shadow_color
	shadow.a *= base.a if base.a >= 0.99 else 0.0
	var radius := int(r.size.x * _skin.block_radius)
	_style_box(base, Color(base.darkened(_skin.block_border_darken), base.a),
		_skin.block_border_width, radius, shadow)
	draw_style_box(_box, r)
	var inner := r.grow(-float(_skin.block_border_width))
	var grain := Color(base.darkened(0.38), 0.4 * base.a)
	var line_width := maxf(1.5, r.size.x * 0.03)
	for line in 4:
		var points := PackedVector2Array()
		var level := (line + 1.0) / 5.0
		var phase := color_index * 1.7 + line * 2.3
		for k in 7:
			var f := k / 6.0
			points.append(Vector2(
				inner.position.x + inner.size.x * f,
				inner.position.y + inner.size.y * level + sin(f * TAU * 0.8 + phase) * inner.size.y * 0.045))
		draw_polyline(points, grain, line_width, true)
	var edge := maxf(2.0, r.size.x * 0.035)
	var span := radius * 0.6
	draw_line(inner.position + Vector2(span, edge / 2.0), inner.position + Vector2(inner.size.x - span, edge / 2.0),
		Color(1, 1, 1, 0.32 * base.a), edge)
	draw_line(inner.position + Vector2(edge / 2.0, span), inner.position + Vector2(edge / 2.0, inner.size.y - span),
		Color(1, 1, 1, 0.18 * base.a), edge)
	var bottom := inner.position.y + inner.size.y - edge / 2.0
	draw_line(Vector2(inner.position.x + span, bottom), Vector2(inner.position.x + inner.size.x - span, bottom),
		Color(0, 0, 0, 0.25 * base.a), edge)


## A dark glass tile with a bright glowing outline and a luminous core.
func _draw_neon_block(r: Rect2, base: Color) -> void:
	var glow := Color(base, 0.45) if base.a >= 0.99 else Color(base, 0.0)
	var radius := int(r.size.x * _skin.block_radius)
	_style_box(Color(base.darkened(0.72), base.a), base, _skin.block_border_width, radius, glow)
	draw_style_box(_box, r)
	var core := r.grow(-r.size.x * 0.24)
	_style_box(Color(base, 0.7 * base.a), Color(base, 0.0), 0, int(core.size.x * 0.25), Color(base, 0.0))
	draw_style_box(_box, core)


func _draw_flashes() -> void:
	for f in _flashes:
		var t: float = f["t"]
		var r := _cell_rect(f["x"], f["y"]).grow(_cell * 0.12 * t)
		_draw_block(r, f["color"], 1.0 - t)
		draw_rect(r, Color(_skin.clear_flash_color, _skin.clear_flash_color.a * (1.0 - t)))


func _draw_tray() -> void:
	var tc := _cell * TRAY_SCALE
	for i in _hand.size():
		if _hand[i]["used"] or i == _drag_slot:
			continue
		var cells := _piece_cells(i)
		var b := _bounds(cells)
		var slot := _slot_rect(i)
		var top_left := slot.position + (slot.size - Vector2(b) * tc) / 2.0
		_draw_piece(cells, top_left, tc, _hand[i]["color"], 1.0)


func _draw_piece(cells: Array, top_left: Vector2, cell_px: float, color_index: int, alpha: float) -> void:
	var gap := cell_px * _skin.cell_gap
	for c: Vector2i in cells:
		var r := Rect2(top_left + Vector2(c) * cell_px + Vector2(gap, gap) / 2.0, Vector2(cell_px - gap, cell_px - gap))
		_draw_block(r, color_index, alpha)


func _draw_drag() -> void:
	var cells := _piece_cells(_drag_slot)
	var color_index: int = _hand[_drag_slot]["color"]
	var target := _drag_target()
	if _board.can_place(cells, target.x, target.y):
		_draw_line_preview(cells, target, color_index)
		for c: Vector2i in cells:
			_draw_block(_cell_rect(target.x + c.x, target.y + c.y), color_index, 0.45)
	_draw_piece(cells, _drag_top_left(), _cell, color_index, 1.0)


## Highlights the rows/columns that the piece would complete at the target.
func _draw_line_preview(cells: Array, target: Vector2i, color_index: int) -> void:
	var sim := _board.duplicate()
	var result := sim.place(cells, target.x, target.y, color_index)
	for row: int in result["rows"]:
		for x in GRID:
			draw_rect(_cell_rect(x, row), _skin.line_preview_color)
	for col: int in result["cols"]:
		for y in GRID:
			draw_rect(_cell_rect(col, y), _skin.line_preview_color)


func _draw_popups() -> void:
	var font := ThemeDB.fallback_font
	for p in _popups:
		var t: float = p["t"]
		var text: String = p["text"]
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 52).x
		var pos: Vector2 = p["pos"] + Vector2(-w / 2.0, -t * 90.0)
		var fade := 1.0 - t * t
		draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 52, 8, Color(0, 0, 0, 0.6 * fade))
		draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 52, Color(_skin.accent_color, fade))
