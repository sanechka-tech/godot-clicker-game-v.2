extends Node

const DEFAULT_MUSIC := preload("res://Audio/background_music.ogg")
const MINIGAME_MUSIC := preload("res://Audio/Music/Minigame_sound.mp3")

var music_player: AudioStreamPlayer
var pops_since_last_fart := 0

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


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	music_player = AudioStreamPlayer.new()
	music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(music_player)

	music_player.bus = "Music"
	play_default_music()


func play_default_music() -> void:
	_play_music(DEFAULT_MUSIC)


func play_minigame_music() -> void:
	_play_music(MINIGAME_MUSIC)


func play_fart_mob_pop_sounds() -> void:
	_play_random_stream(bubble_burst_streams)

	var should_play_fart := pops_since_last_fart >= 3 or randf() < 0.25
	if should_play_fart:
		_play_random_stream(fart_streams)
		pops_since_last_fart = 0
		return

	pops_since_last_fart += 1


func _play_random_stream(streams: Array[AudioStream]) -> void:
	if streams.is_empty():
		return

	var player := AudioStreamPlayer.new()
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	player.bus = "Master"
	player.stream = streams[randi() % streams.size()]
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func _play_music(stream: AudioStream) -> void:
	if music_player == null or stream == null:
		return

	if music_player.stream == stream and music_player.playing:
		return

	music_player.stream = stream
	music_player.play()
