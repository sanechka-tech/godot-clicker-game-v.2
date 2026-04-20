extends Node

var music_player: AudioStreamPlayer


func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	add_child(music_player)

	music_player.stream = load("res://Audio/background_music.ogg")
	music_player.bus = "Master"
	music_player.volume_db = 0
	music_player.play()
