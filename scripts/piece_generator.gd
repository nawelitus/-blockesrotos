class_name PieceGenerator
extends RefCounted
## Picks the three pieces offered each turn. Weights blend from "easy" to "hard" as the
## score rises, and a hand always contains at least one piece that fits the board.

const HAND_SIZE := 3
const HARD_SCORE := 3000.0
const MAX_ATTEMPTS := 30

var _rng := RandomNumberGenerator.new()


func _init(seed_value: int = -1) -> void:
	if seed_value >= 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()


## Returns an Array of catalog ids.
func next_hand(board: BoardState, score: int) -> Array[int]:
	var entries := PieceCatalog.entries()
	var t := clampf(float(score) / HARD_SCORE, 0.0, 1.0)
	var weights := PackedFloat32Array()
	for e in entries:
		weights.append(lerpf(e["easy"], e["hard"], t))
	for _a in MAX_ATTEMPTS:
		var hand: Array[int] = []
		var any_fits := false
		for _i in HAND_SIZE:
			var id := _rng.rand_weighted(weights)
			hand.append(id)
			if board.fits_anywhere(entries[id]["cells"]):
				any_fits = true
		if any_fits:
			return hand
	# Nothing sampled fits: the board is crowded. Offer one piece that does fit, if any.
	var hand: Array[int] = []
	for _i in HAND_SIZE:
		hand.append(_rng.rand_weighted(weights))
	var fitting: Array[int] = []
	for e in entries:
		if board.fits_anywhere(e["cells"]):
			fitting.append(e["id"])
	if not fitting.is_empty():
		hand[0] = fitting[_rng.randi() % fitting.size()]
	return hand
