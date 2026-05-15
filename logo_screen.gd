extends Control

const NEXT_SCENE := "res://loading_screen.tscn"

@onready var logo: TextureRect = $Logo


func _ready() -> void:
	logo.modulate.a = 0.0

	var tween := create_tween()
	tween.tween_interval(1.0)
	tween.tween_property(logo, "modulate:a", 1.0, 1.0)
	tween.finished.connect(_go_to_loading_screen)


func _go_to_loading_screen() -> void:
	get_tree().change_scene_to_file(NEXT_SCENE)
