extends Node2D

const MUTE_ON_TEXTURE := preload("res://Images/settings/mute_on.png")
const MUTE_OFF_TEXTURE := preload("res://Images/settings/mute_off.png")

@onready var settings_panel: Control = $SettingsPanel
@onready var mute_button: TextureButton = $"SettingsPanel/TextureButton Mute"


func _ready() -> void:
	settings_panel.visible = false
	mute_button.pressed.connect(_on_texture_button_mute_pressed)
	AudioManager.music_mute_changed.connect(_on_music_mute_changed)
	_update_mute_button()


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


func _update_mute_button(is_muted: bool = AudioManager.music_muted) -> void:
	var current_texture: Texture2D = MUTE_OFF_TEXTURE if is_muted else MUTE_ON_TEXTURE
	mute_button.texture_normal = current_texture
	mute_button.texture_pressed = current_texture
	mute_button.texture_hover = current_texture
