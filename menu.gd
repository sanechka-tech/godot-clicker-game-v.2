extends Node2D

@onready var settings_popup = $SettingsPopup
@onready var settings_button: Button = $TextureRect/VBoxContainer/Settings


func _ready() -> void:
	AudioManager.play_default_music()
	settings_button.pressed.connect(_on_settings_pressed)


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://main_screen.tscn")


func _on_texture_button_pressed() -> void:
	get_tree().change_scene_to_file("res://main_screen.tscn")


func _on_settings_pressed() -> void:
	settings_popup.open()
