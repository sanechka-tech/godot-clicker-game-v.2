extends Node2D

const NEXT_SCENE_PATH := "res://cutscenes/lvl_3_village_after_2.tscn"
const PHRASE_KEYS: Array[StringName] = [
	&"STORY_LVL3_FINISH_001",
	&"STORY_LVL3_FINISH_002",
	&"STORY_LVL3_FINISH_003",
	&"STORY_LVL3_FINISH_004",
	&"STORY_LVL3_FINISH_005",
	&"STORY_LVL3_FINISH_006",
]

@export var characters_per_second: float = 20.0

@onready var story_label: Label = get_node_or_null("BG Text/Story") as Label

var visible_characters_progress := 0.0
var typing_finished := false
var phrase_index := 0


func _ready() -> void:
	if story_label == null:
		return

	_start_current_phrase()


func _process(delta: float) -> void:
	if typing_finished or story_label == null:
		return

	visible_characters_progress += characters_per_second * delta
	story_label.visible_characters = floori(visible_characters_progress)

	if story_label.visible_characters >= story_label.text.length():
		_finish_typing()


func _unhandled_input(event: InputEvent) -> void:
	if story_label == null or not _is_confirm_input(event):
		return

	get_viewport().set_input_as_handled()

	if not typing_finished:
		_finish_typing()
		return

	_show_next_phrase_or_scene()


func _start_current_phrase() -> void:
	story_label.text = tr(String(PHRASE_KEYS[phrase_index]))
	story_label.visible_characters = 0
	visible_characters_progress = 0.0
	typing_finished = story_label.text.length() <= 0

	if typing_finished:
		story_label.visible_characters = -1


func _show_next_phrase_or_scene() -> void:
	if phrase_index >= PHRASE_KEYS.size() - 1:
		get_tree().change_scene_to_file(NEXT_SCENE_PATH)
		return

	phrase_index += 1
	_start_current_phrase()


func _finish_typing() -> void:
	typing_finished = true
	if story_label != null:
		story_label.visible_characters = -1


func _is_confirm_input(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return event.pressed

	if event is InputEventMouseButton:
		return event.pressed and event.button_index == MOUSE_BUTTON_LEFT

	return false
