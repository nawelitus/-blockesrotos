extends Node
## Autoload: sound effects and vibration for game events.
## Sounds are synthesized on first use and cached. Both channels can be turned
## off from GameSettings.

const PLAYER_COUNT := 8
## Vibration tuning. The scale shortens every pulse; the amplitude (0..1) only has
## an effect on phones with amplitude control.
const HAPTIC_SCALE := 0.5
const HAPTIC_AMPLITUDE := 0.4
const HAPTIC_MIN_MS := 5
const BASE_FREQ := 392.0  # G4
## Semitone offsets of a major pentatonic scale: any chain of notes sounds pleasant.
const PENTATONIC: Array[int] = [0, 2, 4, 7, 9, 12, 14, 16, 19, 21, 24, 26]
const NOTE_C5 := 523.25
const NOTE_E5 := 659.25
const NOTE_G5 := 783.99
const NOTE_C6 := 1046.5
const MAX_COMBO_STEP := 6

var _players: Array[AudioStreamPlayer] = []
var _next_player := 0
var _cache := {}


func _ready() -> void:
	for i in PLAYER_COUNT:
		var player := AudioStreamPlayer.new()
		player.volume_db = -4.0
		add_child(player)
		_players.append(player)


## A piece was picked up from the tray.
func pick() -> void:
	_play("pick", func() -> Array[Dictionary]:
		return [ToneSynth.note(620.0, 0.0, 0.05, 0.3)])
	_vibrate(10)


## A piece landed without completing a line.
func place() -> void:
	_play("place", func() -> Array[Dictionary]:
		return [ToneSynth.note(260.0, 0.0, 0.1, 0.45, ToneSynth.Wave.SOFT, 170.0)])
	_vibrate(18)


## The piece did not fit where it was dropped.
func invalid() -> void:
	_play("invalid", func() -> Array[Dictionary]:
		return [ToneSynth.note(180.0, 0.0, 0.18, 0.35, ToneSynth.Wave.BUZZ, 110.0)])
	_vibrate(45)


## Lines cleared. Pitch climbs with the combo and the arpeggio grows with the lines.
func clear(lines: int, combo: int) -> void:
	var step := clampi(combo - 1, 0, MAX_COMBO_STEP)
	var count := clampi(lines + 1, 2, 5)
	var key := "clear_%d_%d" % [count, step]
	_play(key, func() -> Array[Dictionary]:
		var notes: Array[Dictionary] = []
		for i in count:
			var semitones: int = PENTATONIC[mini(step + i * 2, PENTATONIC.size() - 1)]
			notes.append(ToneSynth.note(BASE_FREQ * pow(2.0, semitones / 12.0), i * 0.06, 0.28, 0.34))
		return notes)
	_vibrate(30 + 20 * lines)


func game_over(new_record: bool) -> void:
	if new_record:
		_play("end_record", func() -> Array[Dictionary]:
			return [
				ToneSynth.note(NOTE_C5, 0.0, 0.3, 0.3),
				ToneSynth.note(NOTE_E5, 0.12, 0.3, 0.3),
				ToneSynth.note(NOTE_G5, 0.24, 0.3, 0.3),
				# Final chord: kept quiet per note so the sum does not clip.
				ToneSynth.note(NOTE_C6, 0.36, 0.7, 0.3),
				ToneSynth.note(NOTE_E5, 0.36, 0.7, 0.14),
				ToneSynth.note(NOTE_G5, 0.36, 0.7, 0.14)])
		_vibrate(220)
	else:
		_play("end", func() -> Array[Dictionary]:
			return [
				ToneSynth.note(NOTE_G5, 0.0, 0.3, 0.35),
				ToneSynth.note(NOTE_E5, 0.14, 0.3, 0.35),
				ToneSynth.note(NOTE_C5, 0.28, 0.3, 0.35),
				ToneSynth.note(BASE_FREQ, 0.42, 0.6, 0.38)])
		_vibrate(150)


func click() -> void:
	_play("click", func() -> Array[Dictionary]:
		return [ToneSynth.note(700.0, 0.0, 0.05, 0.3)])


func _play(key: String, build_notes: Callable) -> void:
	if not GameSettings.sound_enabled:
		return
	if not _cache.has(key):
		var notes: Array[Dictionary] = build_notes.call()
		_cache[key] = ToneSynth.render(notes)
	var player := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	player.stream = _cache[key]
	player.play()


func _vibrate(milliseconds: int) -> void:
	if GameSettings.haptics_enabled:
		var scaled := maxi(int(milliseconds * HAPTIC_SCALE), HAPTIC_MIN_MS)
		Input.vibrate_handheld(scaled, HAPTIC_AMPLITUDE)
