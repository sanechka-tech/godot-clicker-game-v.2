extends Node2D


func _ready() -> void:
	AudioManager.play_default_music()


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://main_screen.tscn")


func _on_texture_button_pressed() -> void:
	get_tree().change_scene_to_file("res://main_screen.tscn")
