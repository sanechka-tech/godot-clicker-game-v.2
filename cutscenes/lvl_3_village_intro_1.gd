extends Node2D

const NEXT_SCENE_PATH := "res://cutscenes/lvl_3_village_intro_2.tscn"

@export var characters_per_second: float = 20.0

@onready var rich_text_label: RichTextLabel = $CanvasLayer/RichTextLabel

var visible_characters_progress := 0.0
var typing_finished := false


func _ready() -> void:
	rich_text_label.visible_characters = 0
	visible_characters_progress = 0.0
	typing_finished = rich_text_label.get_total_character_count() <= 0

	if typing_finished:
		rich_text_label.visible_characters = -1


func _process(delta: float) -> void:
	if typing_finished:
		return

	visible_characters_progress += characters_per_second * delta
	rich_text_label.visible_characters = floori(visible_characters_progress)

	if rich_text_label.visible_characters >= rich_text_label.get_total_character_count():
		_finish_typing()


func _unhandled_input(event: InputEvent) -> void:
	if not _is_confirm_input(event):
		return

	if not typing_finished:
		_finish_typing()
		return

	get_tree().change_scene_to_file(NEXT_SCENE_PATH)


func _finish_typing() -> void:
	typing_finished = true
	rich_text_label.visible_characters = -1


func _is_confirm_input(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return event.pressed

	if event is InputEventMouseButton:
		return event.pressed and event.button_index == MOUSE_BUTTON_LEFT

	return false
