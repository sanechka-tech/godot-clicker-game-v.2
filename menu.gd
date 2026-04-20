extends Node2D
@onready var settings_panel = $SettingsPanel

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://main_screen.tscn")


func _on_texture_button_pressed() -> void:
	get_tree().change_scene_to_file("res://main_screen.tscn")


func _on_texture_button_settings_pressed() -> void:
	settings_panel.visible = true


func _on_texture_button_back_pressed() -> void:
	settings_panel.visible = false
