extends Node2D



func _on_button_toilet_pressed() -> void:
	get_tree().change_scene_to_file("res://main_screen.tscn")
