extends SceneTree
## Plays some moves through the real input path and saves a screenshot.
## Needs a window: godot --path . --resolution 576x1024 --rendering-driver opengl3 \
##   --quit-after 600 -s tools/shot.gd -- <out.png> <moves> <skin_cycles>

# Untyped on purpose: in a -s script the autoloads do not exist at compile time, so
# referencing GameView (which uses GameSettings) by name would fail to compile.
var _view


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out_path: String = args[0] if args.size() > 0 else "user://shot.png"
	var moves: int = int(args[1]) if args.size() > 1 else 6
	var cycles: int = int(args[2]) if args.size() > 2 else 0
	var main: Node = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var settings := root.get_node("GameSettings")
	for _i in cycles:
		settings.cycle_skin()
	_view = main.get_child(1)
	await process_frame
	for i in moves:
		var before: int = _view._keeper.score
		if not _play_one():
			print("move ", i, ": no placement found, playing=", _view._playing)
			break
		print("move ", i, ": score ", before, " -> ", _view._keeper.score, " playing=", _view._playing)
		await process_frame
	for _i in 30:
		await process_frame
	var img := root.get_texture().get_image()
	print("saving ", out_path, " size=", img.get_size(), " err=", img.save_png(out_path))
	quit()


func _play_one() -> bool:
	var board: BoardState = _view._board
	for slot in _view._hand.size():
		if _view._hand[slot]["used"]:
			continue
		var cells: Array = _view._piece_cells(slot)
		var b: Vector2i = _view._bounds(cells)
		for oy in BoardState.SIZE:
			for ox in BoardState.SIZE:
				if not board.can_place(cells, ox, oy):
					continue
				var press: Vector2 = _view._slot_rect(slot).get_center()
				var drop: Vector2 = _view._origin + Vector2(ox, oy) * _view._cell \
					+ Vector2(b.x * _view._cell / 2.0, b.y * _view._cell + _view.DRAG_LIFT * _view._cell)
				_send(true, press)
				_motion(drop)
				_send(false, drop)
				return true
	return false


func _send(pressed: bool, pos: Vector2) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.position = pos
	_view._gui_input(e)


func _motion(pos: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = pos
	_view._gui_input(e)
