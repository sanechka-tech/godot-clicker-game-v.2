extends Node2D

const PHRASE_KEYS: Array[StringName] = [
	&"STORY_END_FINISH_001",
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


func _start_current_phrase() -> void:
	story_label.text = tr(String(PHRASE_KEYS[phrase_index]))
	story_label.visible_characters = 0
	visible_characters_progress = 0.0
	typing_finished = story_label.text.length() <= 0

	if typing_finished:
		story_label.visible_characters = -1


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
