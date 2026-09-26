extends Node

## SoundManager: Autoload audio pool that plays overlapping sound effects seamlessly.

## Emitted with the name of every cue that actually starts playing. The intermission
## shop's purchase / interest feedback is asserted in the headless suite, and under
## the dummy audio driver there is no other way to observe a sound.
signal sfx_played(sound_name: String)

var sounds: Dictionary = {}
var player_pool: Array[AudioStreamPlayer] = []
var bgm_player: AudioStreamPlayer
const POOL_SIZE: int = 10
const BGM_OGG: String = "res://assets/audio/bgm.ogg"
const BOSS_BGM_OGG: String = "res://assets/audio/boss_bgm.ogg"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_sound("shoot", "res://assets/audio/shoot.wav")
	_load_sound("hit", "res://assets/audio/hit.wav")
	_load_sound("gem", "res://assets/audio/gem.wav")
	_load_sound("level_up", "res://assets/audio/level_up.wav")
	_load_sound("hurt", "res://assets/audio/hurt.wav")
	_load_sound("thunder", "res://assets/audio/thunder.wav")
	_load_sound("coin", "res://assets/audio/coin.wav")
	_load_sound("explosion", "res://assets/audio/explosion.wav")
	_load_sound("axe", "res://assets/audio/axe.wav")
	_load_sound("powerup", "res://assets/audio/powerup.wav")
	_load_sound("boss_alarm", "res://assets/audio/boss_alarm.wav")
	_load_sound("shrine_activate", "res://assets/audio/shrine_activate.wav")
	_load_sound("dragon_roar", "res://assets/audio/dragon_roar.wav")
	_load_sound("dragon_breath", "res://assets/audio/dragon_breath.wav")
	_load_sound("pet_attack", "res://assets/audio/pet_attack.wav")
	_load_sound("chi_meditate", "res://assets/audio/chi_meditate.wav")
	_load_sound("dragon_wish", "res://assets/audio/dragon_wish.wav")
	_load_sound("qi_laser", "res://assets/audio/qi_laser.wav")
	_load_sound("buddha_gong", "res://assets/audio/buddha_gong.wav")
	_load_sound("shield_break", "res://assets/audio/shield_break.wav")
	# OGG first: 395K vs 4.5M WAV. Only the compressed stream ships in the web export.
	_load_sound("boss_bgm", "res://assets/audio/boss_bgm.ogg", true)
	_load_sound("wine_drink", "res://assets/audio/wine_drink.wav")
	_load_sound("fanfare", "res://assets/audio/fanfare.wav")
	_load_sound("curse_pact", "res://assets/audio/curse_pact.wav")
	_load_sound("quest_complete", "res://assets/audio/quest_complete.wav")
	_load_sound("elemental_burst", "res://assets/audio/elemental_burst.wav")
	_load_sound("snow_wind", "res://assets/audio/snow_wind.wav")
	_load_sound("elixir_drink", "res://assets/audio/elixir_drink.wav")
	_load_sound("slash", "res://assets/audio/slash.wav")
	
	# Create pool of AudioStreamPlayers
	for i in range(POOL_SIZE):
		var asp = AudioStreamPlayer.new()
		add_child(asp)
		player_pool.append(asp)
		
	# Setup BGM player
	bgm_player = AudioStreamPlayer.new()
	bgm_player.volume_db = -8.0
	add_child(bgm_player)
	play_bgm(BGM_OGG)

var is_muted: bool = false

func toggle_mute() -> bool:
	is_muted = not is_muted
	AudioServer.set_bus_mute(0, is_muted)
	return is_muted

func play_boss_bgm() -> void:
	if sounds.has("boss_bgm"):
		bgm_player.stream = sounds["boss_bgm"]
		bgm_player.play()
	else:
		play_bgm(BOSS_BGM_OGG)

func restore_normal_bgm() -> void:
	play_bgm(BGM_OGG)

## OGG has no loop_mode -- it loops via the `loop` flag. WAV keeps the explicit
## loop_begin/loop_end span, which is why the two branches stay separate.
func _enable_loop(stream: AudioStream) -> void:
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = stream.data.size() / 2

func play_bgm(path: String) -> void:
	if ResourceLoader.exists(path):
		var stream = load(path)
		if stream is AudioStream:
			_enable_loop(stream)
		bgm_player.stream = stream
		bgm_player.play()

func _load_sound(sound_name: String, path: String, loop: bool = false) -> void:
	if ResourceLoader.exists(path):
		var stream = load(path)
		if stream:
			if loop:
				_enable_loop(stream)
			sounds[sound_name] = stream

func play(sound_name: String, pitch_range: float = 0.1) -> void:
	if not sounds.has(sound_name):
		return

	emit_signal("sfx_played", sound_name)
	var stream = sounds[sound_name]
	# Find available audio player in pool
	for asp in player_pool:
		if not asp.playing:
			asp.stream = stream
			# Subtle random pitch variation for juicy organic game feel
			if pitch_range > 0.0:
				asp.pitch_scale = randf_range(1.0 - pitch_range, 1.0 + pitch_range)
			else:
				asp.pitch_scale = 1.0
			asp.play()
			return
			
	# If all busy, steal the first player
	var fallback = player_pool[0]
	fallback.stream = stream
	fallback.pitch_scale = 1.0
	fallback.play()

func play_pitched(sound_name: String, pitch: float) -> void:
	if not sounds.has(sound_name):
		return
		
	var stream = sounds[sound_name]
	var clamped_pitch = clampf(pitch, 0.4, 3.2)
	for asp in player_pool:
		if not asp.playing:
			asp.stream = stream
			asp.pitch_scale = clamped_pitch
			asp.play()
			return
			
	var fallback = player_pool[0]
	fallback.stream = stream
	fallback.pitch_scale = clamped_pitch
	fallback.play()
