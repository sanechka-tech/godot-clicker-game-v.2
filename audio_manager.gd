extends Node

signal music_mute_changed(is_muted: bool)
signal music_volume_changed(value: float)

var music_player: AudioStreamPlayer
var music_muted := false
var music_volume := 1.0
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
	music_player = AudioStreamPlayer.new()
	add_child(music_player)

	music_player.stream = load("res://Audio/background_music.ogg")
	music_player.bus = "Music"
	music_player.play()

	_apply_music_mute()
	_apply_music_volume()


func toggle_music_mute() -> void:
	set_music_muted(not music_muted)


func set_music_muted(value: bool) -> void:
	if music_muted == value:
		return

	music_muted = value
	_apply_music_mute()
	music_mute_changed.emit(music_muted)


func set_music_volume(value: float) -> void:
	var clamped_value := clampf(value, 0.0, 1.0)
	if is_equal_approx(music_volume, clamped_value):
		return

	music_volume = clamped_value
	_apply_music_volume()
	music_volume_changed.emit(music_volume)


func _apply_music_mute() -> void:
	var music_bus_index := AudioServer.get_bus_index("Music")
	if music_bus_index == -1:
		return

	AudioServer.set_bus_mute(music_bus_index, music_muted)


func _apply_music_volume() -> void:
	var music_bus_index := AudioServer.get_bus_index("Music")
	if music_bus_index == -1:
		return

	var volume_db := -80.0 if music_volume <= 0.0 else linear_to_db(music_volume)
	AudioServer.set_bus_volume_db(music_bus_index, volume_db)


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
	player.bus = "Master"
	player.stream = streams[randi() % streams.size()]
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
