extends Node

signal music_mute_changed(is_muted: bool)

var music_player: AudioStreamPlayer
var music_muted := false


func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	add_child(music_player)

	music_player.stream = load("res://Audio/background_music.ogg")
	music_player.bus = "Music"
	music_player.volume_db = 0
	music_player.play()

	_apply_music_mute()


func toggle_music_mute() -> void:
	set_music_muted(not music_muted)


func set_music_muted(value: bool) -> void:
	if music_muted == value:
		return

	music_muted = value
	_apply_music_mute()
	music_mute_changed.emit(music_muted)


func _apply_music_mute() -> void:
	var music_bus_index := AudioServer.get_bus_index("Music")
	if music_bus_index == -1:
		return

	AudioServer.set_bus_mute(music_bus_index, music_muted)
