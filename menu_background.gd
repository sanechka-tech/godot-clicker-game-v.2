extends Control

const TV_NOISE := preload("res://Audio/SFX/menu/TV_noise.mp3")
const TV_ADS := preload("res://Audio/SFX/menu/TV_ads.mp3")
const TV_NOISE_VOLUME := 0.07
const TV_ADS_VOLUME := 0.008

const NOISE_FRAMES := [2, 4, 7, 9, 12]
const ADS_FRAMES := [5, 6, 10, 11]

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var tv_audio_player: AudioStreamPlayer
var current_tv_state := ""


func _ready() -> void:
	tv_audio_player = AudioStreamPlayer.new()
	tv_audio_player.bus = "SFX"
	add_child(tv_audio_player)

	animated_sprite.frame_changed.connect(_on_tv_frame_changed)
	animated_sprite.animation_looped.connect(_on_tv_animation_looped)

	_update_tv_audio_for_frame(animated_sprite.frame)


func _on_tv_frame_changed() -> void:
	if not animated_sprite.is_playing():
		return

	_update_tv_audio_for_frame(animated_sprite.frame)


func _on_tv_animation_looped() -> void:
	current_tv_state = ""
	_update_tv_audio_for_frame(animated_sprite.frame)


func _update_tv_audio_for_frame(frame_index: int) -> void:
	var next_state := _get_tv_state_for_frame(frame_index)
	if next_state == current_tv_state:
		return

	current_tv_state = next_state

	match current_tv_state:
		"noise":
			_play_tv_stream(TV_NOISE, TV_NOISE_VOLUME)
		"ads":
			_play_tv_stream(TV_ADS, TV_ADS_VOLUME)
		_:
			tv_audio_player.stop()


func _get_tv_state_for_frame(frame_index: int) -> String:
	if frame_index in NOISE_FRAMES:
		return "noise"

	if frame_index in ADS_FRAMES:
		return "ads"

	return ""


func _play_tv_stream(stream: AudioStream, volume_linear: float) -> void:
	if stream == null:
		tv_audio_player.stop()
		return

	tv_audio_player.volume_db = linear_to_db(volume_linear)

	if tv_audio_player.stream != stream:
		tv_audio_player.stream = stream

	tv_audio_player.play()


func freeze_and_stop_tv() -> void:
	if animated_sprite.has_method("pause"):
		animated_sprite.pause()
	else:
		animated_sprite.speed_scale = 0.0

	current_tv_state = ""

	if tv_audio_player != null:
		tv_audio_player.stop()
