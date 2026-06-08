extends Node2D

const NEXT_SCENE_PATH := "res://titles_screen.tscn"
const NEXT_SCENE_FADE_OUT_DURATION := 1.0
const NEXT_SCENE_FADE_IN_DURATION := 1.0
const FINAL_LINE_HOLD_DURATION := 3.0
const INTRO_DELAY_AFTER_REVEAL := 0.0
const STORY_FADE_DURATION := 0.1
const STORY_SECONDS_PER_CHARACTER := 0.05
const FAST_STORY_SECONDS_PER_CHARACTER := 0.004
const DIALOG_LINES := [
	{"story": "STORY_END_FINISH_001"},
]

@onready var story_label: Label = $Story

var _is_typing_story := false
var _story_type_speed := STORY_SECONDS_PER_CHARACTER
var _story_finished := false
var _current_line_index := 0
var _dialog_finished := false
var _is_changing_scene := false


func _ready() -> void:
	if story_label == null:
		return

	story_label.visible = false
	story_label.modulate.a = 0.0
	story_label.visible_characters = 0

	call_deferred("_play_intro_sequence")


func _exit_tree() -> void:
	AudioManager.stop_typewriter_sfx()


func _input(event: InputEvent) -> void:
	if story_label == null or _is_changing_scene or not _is_confirm_input(event):
		return

	if _is_typing_story:
		_set_story_type_speed(FAST_STORY_SECONDS_PER_CHARACTER)
		return

	if _dialog_finished:
		_change_to_next_scene()
		return

	if _story_finished:
		_show_next_line()


func _play_intro_sequence() -> void:
	var transition_screen = get_node_or_null("/root/TransitionScreen")
	if transition_screen != null and transition_screen.is_transitioning():
		await transition_screen.scene_revealed

	await get_tree().create_timer(INTRO_DELAY_AFTER_REVEAL).timeout
	await _show_current_line()


func _show_current_line() -> void:
	if _current_line_index >= DIALOG_LINES.size():
		return

	_story_finished = false
	story_label.visible = false
	story_label.visible_characters = 0
	var line: Dictionary = DIALOG_LINES[_current_line_index]
	var story_key := line["story"] as String

	await _type_story(story_key)


func _type_story(story_key: String) -> void:
	story_label.text = tr(story_key).replace("\\n", "\n")
	story_label.visible = true
	story_label.visible_characters = 0

	var tween := create_tween()
	tween.tween_property(story_label, "modulate:a", 1.0, STORY_FADE_DURATION)
	await tween.finished

	var character_count := story_label.get_total_character_count()
	if character_count <= 0:
		AudioManager.stop_typewriter_sfx()
		_story_finished = true
		_start_auto_transition_if_final_line()
		return

	_is_typing_story = true
	_set_story_type_speed(STORY_SECONDS_PER_CHARACTER)
	AudioManager.start_typewriter_sfx(STORY_SECONDS_PER_CHARACTER / _story_type_speed)

	while story_label.visible_characters < character_count:
		story_label.visible_characters += 1
		await get_tree().create_timer(_story_type_speed).timeout

	_is_typing_story = false
	AudioManager.stop_typewriter_sfx()
	_story_finished = true
	_start_auto_transition_if_final_line()


func _set_story_type_speed(value: float) -> void:
	_story_type_speed = value
	if _is_typing_story:
		AudioManager.set_typewriter_speed(STORY_SECONDS_PER_CHARACTER / _story_type_speed)


func _show_next_line() -> void:
	_story_finished = false
	_current_line_index += 1

	if _current_line_index >= DIALOG_LINES.size():
		_dialog_finished = true
		return

	call_deferred("_show_current_line")


func _change_to_next_scene() -> void:
	if _is_changing_scene:
		return

	_is_changing_scene = true
	var transition_screen = get_node_or_null("/root/TransitionScreen")
	if transition_screen != null:
		transition_screen.change_scene(
			NEXT_SCENE_PATH,
			NEXT_SCENE_FADE_OUT_DURATION,
			NEXT_SCENE_FADE_IN_DURATION
		)
	else:
		get_tree().change_scene_to_file(NEXT_SCENE_PATH)


func _start_auto_transition_if_final_line() -> void:
	if _current_line_index >= DIALOG_LINES.size() - 1:
		_dialog_finished = true
		call_deferred("_change_to_next_scene_after_hold")


func _change_to_next_scene_after_hold() -> void:
	await get_tree().create_timer(FINAL_LINE_HOLD_DURATION).timeout
	_change_to_next_scene()


func _is_confirm_input(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return event.pressed

	if event is InputEventMouseButton:
		return event.pressed and event.button_index == MOUSE_BUTTON_LEFT

	return false
