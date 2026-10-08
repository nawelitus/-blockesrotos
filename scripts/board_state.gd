class_name BoardState
extends RefCounted
## 8x8 grid. 0 = empty, any other value is the colour index of the block in that cell.

const SIZE := 8

var cells: PackedInt32Array = PackedInt32Array()


func _init() -> void:
	cells.resize(SIZE * SIZE)
	cells.fill(0)


func get_cell(x: int, y: int) -> int:
	return cells[y * SIZE + x]


func is_empty() -> bool:
	for v in cells:
		if v != 0:
			return false
	return true


func can_place(piece: Array, ox: int, oy: int) -> bool:
	for c: Vector2i in piece:
		var x := ox + c.x
		var y := oy + c.y
		if x < 0 or y < 0 or x >= SIZE or y >= SIZE:
			return false
		if cells[y * SIZE + x] != 0:
			return false
	return true


func fits_anywhere(piece: Array) -> bool:
	for oy in SIZE:
		for ox in SIZE:
			if can_place(piece, ox, oy):
				return true
	return false


## Places the piece (caller must check can_place) and clears completed lines.
## Returns {rows, cols, cleared: int, flash: [[cell index, colour]], placed: int, empty: bool}.
func place(piece: Array, ox: int, oy: int, color: int) -> Dictionary:
	for c: Vector2i in piece:
		cells[(oy + c.y) * SIZE + ox + c.x] = color
	var rows: Array[int] = []
	var cols: Array[int] = []
	for i in SIZE:
		var row_full := true
		var col_full := true
		for j in SIZE:
			if cells[i * SIZE + j] == 0:
				row_full = false
			if cells[j * SIZE + i] == 0:
				col_full = false
		if row_full:
			rows.append(i)
		if col_full:
			cols.append(i)
	var to_clear := {}
	for r in rows:
		for x in SIZE:
			to_clear[r * SIZE + x] = true
	for c in cols:
		for y in SIZE:
			to_clear[y * SIZE + c] = true
	var flash: Array = []
	for idx: int in to_clear:
		flash.append([idx, cells[idx]])
		cells[idx] = 0
	return {
		"rows": rows,
		"cols": cols,
		"cleared": to_clear.size(),
		"flash": flash,
		"placed": piece.size(),
		"empty": is_empty(),
	}


func duplicate() -> BoardState:
	var copy := BoardState.new()
	copy.cells = cells.duplicate()
	return copy
