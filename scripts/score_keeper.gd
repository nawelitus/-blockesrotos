class_name ScoreKeeper
extends RefCounted
## Scoring: 1 point per cell placed, 10 * lines^2 per move clearing lines (1 = 10,
## 2 = 40, 3 = 90), multiplied by a combo that grows on consecutive clearing moves
## and resets on a move that clears nothing. Emptying the board adds a bonus.

const POINTS_PER_CELL := 1
const POINTS_PER_LINE := 10
const EMPTY_BOARD_BONUS := 100

var score := 0
var combo := 0


## Applies a move and returns the points it earned.
func apply_move(result: Dictionary) -> int:
	var lines: int = result["rows"].size() + result["cols"].size()
	var gained: int = result["placed"] * POINTS_PER_CELL
	if lines > 0:
		combo += 1
		gained += POINTS_PER_LINE * lines * lines * combo
	else:
		combo = 0
	if result["empty"]:
		gained += EMPTY_BOARD_BONUS
	score += gained
	return gained
