extends SceneTree
## Headless checks for the game core.
## Run: godot --headless --path . --quit-after 900 -s tools/test_core.gd

var _failures := 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_failures += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	_test_catalog()
	_test_placement_and_clear()
	_test_score()
	_test_generator_and_playouts()
	print("RESULT: ", "OK" if _failures == 0 else "%d FAILURES" % _failures)
	quit(1 if _failures > 0 else 0)


func _test_catalog() -> void:
	var entries := PieceCatalog.entries()
	print("catalog entries: ", entries.size())
	_check(entries.size() > 30, "catalog has expected variety")
	for e in entries:
		for c: Vector2i in e["cells"]:
			_check(c.x >= 0 and c.y >= 0 and c.x < 5 and c.y < 5, "piece %d within 5x5" % e["id"])


func _test_placement_and_clear() -> void:
	var b := BoardState.new()
	var one := [Vector2i(0, 0)]
	_check(b.can_place(one, 0, 0), "empty board accepts a cell")
	_check(not b.can_place(one, 8, 0), "out of bounds rejected")
	# Fill row 0 except the last cell, then complete it with a single block.
	for x in 7:
		b.place(one, x, 0, 1)
	var r := b.place(one, 7, 0, 1)
	_check(r["rows"] == [0] and r["cols"].is_empty(), "row 0 cleared")
	_check(r["cleared"] == 8, "8 cells cleared")
	_check(b.is_empty(), "board empty after clear")
	# Row and column cleared together: the shared corner counts once.
	var d := BoardState.new()
	for i in 8:
		if i != 0:
			d.place(one, i, 0, 1)
			d.place(one, 0, i, 1)
	var r3 := d.place(one, 0, 0, 1)
	_check(r3["rows"] == [0] and r3["cols"] == [0], "row and column together")
	_check(r3["cleared"] == 15, "shared corner counted once (15)")
	var full := BoardState.new()
	for i in 64:
		full.cells[i] = 1
	_check(not full.fits_anywhere(one), "full board fits nothing")


func _test_score() -> void:
	var s := ScoreKeeper.new()
	var no_clear := {"rows": [], "cols": [], "placed": 4, "empty": false}
	_check(s.apply_move(no_clear) == 4, "4 cells = 4 points")
	var one_line := {"rows": [0], "cols": [], "placed": 1, "empty": false}
	_check(s.apply_move(one_line) == 1 + 10, "1 line, combo x1 = 11")
	var two_lines := {"rows": [0], "cols": [3], "placed": 1, "empty": false}
	_check(s.apply_move(two_lines) == 1 + 40 * 2, "2 lines, combo x2 = 81")
	s.apply_move(no_clear)
	_check(s.combo == 0, "combo resets without a clear")
	var three := {"rows": [0, 1, 2], "cols": [], "placed": 1, "empty": true}
	_check(s.apply_move(three) == 1 + 90 + 100, "3 lines + empty bonus = 191")


func _test_generator_and_playouts() -> void:
	var entries := PieceCatalog.entries()
	var scores: Array[int] = []
	var hands_total := 0
	for g in 200:
		var board := BoardState.new()
		var keeper := ScoreKeeper.new()
		var gen := PieceGenerator.new(1000 + g)
		var moves := 0
		while moves < 3000:
			var hand := gen.next_hand(board, keeper.score)
			hands_total += 1
			var remaining := hand.duplicate()
			var dead := false
			while not remaining.is_empty():
				var move := _best_move(board, remaining, entries)
				if move.is_empty():
					dead = true
					break
				var res := board.place(entries[move["id"]]["cells"], move["x"], move["y"], 1)
				keeper.apply_move(res)
				remaining.erase(move["id"])
				moves += 1
			if dead:
				break
		scores.append(keeper.score)
	scores.sort()
	print("playouts: 200 greedy-bot games, %d hands in total" % hands_total)
	print("score min=%d median=%d p90=%d max=%d" % [scores[0], scores[100], scores[180], scores[199]])
	_check(scores[100] > 100, "greedy bot reaches a sensible median score")
	# First-hand guarantee on an empty board.
	var gen2 := PieceGenerator.new(7)
	for _i in 500:
		var h := gen2.next_hand(BoardState.new(), 0)
		var ok := false
		for id in h:
			if BoardState.new().fits_anywhere(entries[id]["cells"]):
				ok = true
		_check(ok, "empty board hand has a fitting piece")


## Greedy bot: prefers the move that clears the most cells, then the lowest placement.
func _best_move(board: BoardState, ids: Array, entries: Array) -> Dictionary:
	var best := {}
	var best_score := -1
	for id in ids:
		var cells: Array = entries[id]["cells"]
		for oy in BoardState.SIZE:
			for ox in BoardState.SIZE:
				if not board.can_place(cells, ox, oy):
					continue
				var sim := board.duplicate()
				var res := sim.place(cells, ox, oy, 1)
				var sc: int = res["cleared"] * 10 + cells.size() + oy
				if sc > best_score:
					best_score = sc
					best = {"id": id, "x": ox, "y": oy}
	return best
