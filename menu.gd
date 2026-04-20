extends Node2D

const MUTE_ON_TEXTURE := preload("res://Images/settings/mute_on.png")
const MUTE_OFF_TEXTURE := preload("res://Images/settings/mute_off.png")

@onready var settings_panel: Control = $SettingsPanel
@onready var mute_button: TextureButton = $"SettingsPanel/TextureButton Mute"
@onready var volume_slider: HSlider = $SettingsPanel/HSlider
@onready var volume_fill_clip: Control = $SettingsPanel/VolumeFillClip
@onready var volume_knob: TextureRect = $SettingsPanel/VolumeKnob

var volume_fill_full_width := 0.0
var volume_knob_min_x := 0.0
var volume_knob_max_x := 0.0


func _ready() -> void:
	settings_panel.visible = false
	mute_button.pressed.connect(_on_texture_button_mute_pressed)
	volume_slider.value_changed.connect(_on_volume_slider_value_changed)
	AudioManager.music_mute_changed.connect(_on_music_mute_changed)
	AudioManager.music_volume_changed.connect(_on_music_volume_changed)

	volume_fill_full_width = volume_fill_clip.size.x
	volume_knob_min_x = volume_knob.position.x
	volume_knob_max_x = volume_fill_clip.position.x + volume_fill_full_width - volume_knob.size.x

	volume_slider.min_value = 0.0
	volume_slider.max_value = 100.0
	volume_slider.step = 1.0
	volume_slider.value = AudioManager.music_volume * 100.0

	_update_mute_button()
	_update_volume_ui(AudioManager.music_volume)


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://main_screen.tscn")


func _on_texture_button_pressed() -> void:
	get_tree().change_scene_to_file("res://main_screen.tscn")


func _on_texture_button_settings_pressed() -> void:
	settings_panel.visible = true


func _on_texture_button_back_pressed() -> void:
	settings_panel.visible = false


func _on_texture_button_mute_pressed() -> void:
	AudioManager.toggle_music_mute()


func _on_music_mute_changed(is_muted: bool) -> void:
	_update_mute_button(is_muted)


func _on_volume_slider_value_changed(value: float) -> void:
	AudioManager.set_music_volume(value / 100.0)


func _on_music_volume_changed(value: float) -> void:
	_update_volume_ui(value)


func _update_mute_button(is_muted: bool = AudioManager.music_muted) -> void:
	var current_texture: Texture2D = MUTE_OFF_TEXTURE if is_muted else MUTE_ON_TEXTURE
	mute_button.texture_normal = current_texture
	mute_button.texture_pressed = current_texture
	mute_button.texture_hover = current_texture


func _update_volume_ui(value: float) -> void:
	var percent := clampf(value, 0.0, 1.0)
	volume_fill_clip.size.x = volume_fill_full_width * percent
	volume_knob.position.x = lerpf(volume_knob_min_x, volume_knob_max_x, percent)
