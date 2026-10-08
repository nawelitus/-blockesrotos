class_name PieceCatalog
extends RefCounted
## All pieces the player can be offered. Pieces are never rotated by the player,
## so every rotation/mirror is its own catalog entry.
##
## Each base shape has an easy and a hard selection weight. The generator blends
## them according to the current score.

const SIZE := 8

# [rows as strings, easy weight, hard weight, rotations, mirrored]
const BASE_SHAPES := [
	[["#"], 2.0, 0.5, false, false],
	[["##"], 4.0, 1.5, true, false],
	[["###"], 4.0, 2.0, true, false],
	[["####"], 2.0, 2.0, true, false],
	[["#####"], 1.0, 2.5, true, false],
	[["##", "##"], 4.0, 2.0, false, false],
	[["###", "###", "###"], 1.0, 2.5, false, false],
	[["###", "###"], 2.0, 2.5, true, false],
	[["#.", "##"], 4.0, 1.5, true, false],
	[["#..", "#..", "###"], 1.0, 2.5, true, false],
	[["###", ".#."], 2.0, 2.0, true, false],
	[["#.", "#.", "##"], 2.0, 2.5, true, true],
	[["##.", ".##"], 2.0, 2.5, true, true],
]

static var _entries: Array = []


## Returns every distinct piece as {cells: Array[Vector2i], easy: float, hard: float, id: int}.
static func entries() -> Array:
	if _entries.is_empty():
		_build()
	return _entries


static func _build() -> void:
	var seen := {}
	for base in BASE_SHAPES:
		var rows: Array = base[0]
		var variants: Array = [_parse(rows)]
		if base[4]:
			variants.append(_mirror(variants[0]))
		if base[3]:
			var more: Array = []
			for v in variants:
				var cur: Array = v
				for _i in 3:
					cur = _rotate(cur)
					more.append(cur)
			variants.append_array(more)
		for v in variants:
			var cells := _normalize(v)
			var key := _key(cells)
			if seen.has(key):
				continue
			seen[key] = true
			_entries.append({
				"cells": cells,
				"easy": base[1],
				"hard": base[2],
				"id": _entries.size(),
			})


static func _parse(rows: Array) -> Array:
	var cells: Array = []
	for y in rows.size():
		var line: String = rows[y]
		for x in line.length():
			if line[x] == "#":
				cells.append(Vector2i(x, y))
	return cells


static func _rotate(cells: Array) -> Array:
	var out: Array = []
	for c: Vector2i in cells:
		out.append(Vector2i(-c.y, c.x))
	return out


static func _mirror(cells: Array) -> Array:
	var out: Array = []
	for c: Vector2i in cells:
		out.append(Vector2i(-c.x, c.y))
	return out


static func _normalize(cells: Array) -> Array:
	var min_x := 1000
	var min_y := 1000
	for c: Vector2i in cells:
		min_x = mini(min_x, c.x)
		min_y = mini(min_y, c.y)
	var out: Array = []
	for c: Vector2i in cells:
		out.append(Vector2i(c.x - min_x, c.y - min_y))
	out.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
	return out


static func _key(cells: Array) -> String:
	var parts: PackedStringArray = []
	for c: Vector2i in cells:
		parts.append("%d,%d" % [c.x, c.y])
	return ";".join(parts)
