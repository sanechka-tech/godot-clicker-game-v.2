extends Node

const DEFAULT_MUSIC := preload("res://Audio/background_music.ogg")
const MINIGAME_MUSIC := preload("res://Audio/Music/Minigame_sound.mp3")
const LEVEL_3_MUSIC := preload("res://Audio/Music/lvl3_background_music.mp3")
const FINAL_PRESSURE := preload("res://Audio/SFX/lvl1/final_pressure.mp3")
const FINAL_TOILET_FLUSH := preload("res://Audio/SFX/lvl1/final_zvuk-unitaza.mp3")
const MUSIC_BUS := &"Music"
const SFX_BUS := &"SFX"

var music_player: AudioStreamPlayer
var pops_since_last_fart := 0
var restart_music_on_finish := false

var bubble_burst_streams: Array[AudioStream] = [
	preload("res://Audio/bubble_burst1.mp3"),
	preload("res://Audio/bubble_burst2.mp3"),
	preload("res://Audio/bubble_burst3.mp3"),
	preload("res://Audio/bubble_burst4.mp3"),
]

var fart_streams: Array[AudioStream] = [
	preload("res://Audio/fart_sound1.mp3"),
	preload("res://Audio/fart_sound2.mp3"),
	preload("res://Audio/fart_sound3.mp3"),
]

var level_3_bug_death_streams := {
	&"fly": preload("res://Audio/SFX/lvl3Mobs/fly.mp3"),
	&"maggot": preload("res://Audio/SFX/lvl3Mobs/maggot.mp3"),
	&"mantis": preload("res://Audio/SFX/lvl3Mobs/mantis.mp3"),
	&"spider": preload("res://Audio/SFX/lvl3Mobs/spider.mp3"),
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	music_player = AudioStreamPlayer.new()
	music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(music_player)

	music_player.bus = MUSIC_BUS
	music_player.finished.connect(_on_music_finished)
	play_default_music()


func play_default_music() -> void:
	_play_music(DEFAULT_MUSIC)


func play_minigame_music() -> void:
	_play_music(MINIGAME_MUSIC)


func play_level_3_music() -> void:
	_play_music(LEVEL_3_MUSIC, true)


func stop_music() -> void:
	restart_music_on_finish = false

	if music_player == null:
		return

	music_player.stop()


func play_fart_mob_pop_sounds() -> void:
	_play_random_stream(bubble_burst_streams)

	var should_play_fart := pops_since_last_fart >= 3 or randf() < 0.25
	if should_play_fart:
		_play_random_stream(fart_streams)
		pops_since_last_fart = 0
		return

	pops_since_last_fart += 1


func play_level_3_bug_death_sound(bug_kind: StringName) -> void:
	var stream: AudioStream = level_3_bug_death_streams.get(bug_kind)
	if stream == null:
		return

	_play_stream(stream)


func play_fart_sound_3() -> void:
	_play_stream(preload("res://Audio/fart_sound3.mp3"))


func play_final_pressure() -> AudioStreamPlayer:
	return _play_stream(FINAL_PRESSURE)


func play_final_toilet_flush() -> AudioStreamPlayer:
	return _play_stream(FINAL_TOILET_FLUSH)


func _play_random_stream(streams: Array[AudioStream]) -> void:
	if streams.is_empty():
		return

	_play_stream(streams[randi() % streams.size()])


func _play_stream(stream: AudioStream) -> AudioStreamPlayer:
	if stream == null:
		return null

	var player := AudioStreamPlayer.new()
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	player.bus = SFX_BUS
	player.stream = stream
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
	return player


func _play_music(stream: AudioStream, should_restart_on_finish: bool = false) -> void:
	if music_player == null or stream == null:
		return

	restart_music_on_finish = should_restart_on_finish

	if music_player.stream == stream and music_player.playing:
		return

	music_player.stream = stream
	music_player.play()


func _on_music_finished() -> void:
	if not restart_music_on_finish:
		return

	if music_player == null or music_player.stream == null:
		return

	music_player.play()
