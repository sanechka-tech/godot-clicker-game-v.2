extends Node2D

const NEXT_SCENE_PATH := "res://cutscenes/lvl_3_village_after_2.tscn"
const NEXT_SCENE_FADE_OUT_DURATION := 2.0
const NEXT_SCENE_FADE_IN_DURATION := 0.2
const INTRO_DELAY_AFTER_REVEAL := 0.5
const BG_TEXT_FADE_DURATION := 0.25
const NAME_FADE_DURATION := 0.2
const STORY_SECONDS_PER_CHARACTER := 0.1
const FAST_STORY_SECONDS_PER_CHARACTER := 0.008
const DIALOG_LINES := [
	{"name": "HERO_LEKS", "story": "STORY_LVL3_FINISH_001"},
	{"name": "HERO_LEKS", "story": "STORY_LVL3_FINISH_002"},
	{"name": "HERO_LEKS", "story": "STORY_LVL3_FINISH_003"},
	{"name": "HERO_LEKS", "story": "STORY_LVL3_FINISH_004"},
	{"name": "HERO_LEKS", "story": "STORY_LVL3_FINISH_005"},
	{"name": "HERO_LEKS", "story": "STORY_LVL3_FINISH_006"},
]

@onready var bg_text: TextureRect = $"BG Text"
@onready var name_label: Label = $"BG Text/Name"
@onready var story_label: Label = $"BG Text/Story"

var _is_typing_story := false
var _story_type_speed := STORY_SECONDS_PER_CHARACTER
var _story_finished := false
var _current_line_index := 0
var _current_name_key := ""
var _dialog_finished := false
var _is_changing_scene := false


func _ready() -> void:
	bg_text.visible = false
	name_label.visible = false
	story_label.visible = false
	bg_text.modulate.a = 0.0
	name_label.modulate.a = 0.0
	story_label.visible_characters = 0

	call_deferred("_play_intro_sequence")


func _input(event: InputEvent) -> void:
	if not _is_confirm_input(event) or _is_changing_scene:
		return

	if _is_typing_story:
		_story_type_speed = FAST_STORY_SECONDS_PER_CHARACTER
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
	await _show_bg_text()
	await _show_current_line()


func _show_bg_text() -> void:
	bg_text.visible = true

	var tween := create_tween()
	tween.tween_property(bg_text, "modulate:a", 1.0, BG_TEXT_FADE_DURATION)
	await tween.finished


func _show_current_line() -> void:
	if _current_line_index >= DIALOG_LINES.size():
		return

	_story_finished = false
	story_label.visible = false
	story_label.visible_characters = 0
	var line: Dictionary = DIALOG_LINES[_current_line_index]
	var name_key := line["name"] as String
	var story_key := line["story"] as String

	await _show_name(name_key)
	await _type_story(story_key)


func _show_name(name_key: String) -> void:
	if name_key == _current_name_key:
		return

	_current_name_key = name_key
	name_label.modulate.a = 0.0
	name_label.text = tr(name_key)
	name_label.visible = true

	var tween := create_tween()
	tween.tween_property(name_label, "modulate:a", 1.0, NAME_FADE_DURATION)
	await tween.finished


func _type_story(story_key: String) -> void:
	story_label.text = tr(story_key).replace("\\n", "\n")
	story_label.visible = true
	story_label.visible_characters = 0

	var character_count := story_label.get_total_character_count()
	if character_count <= 0:
		_story_finished = true
		return

	_is_typing_story = true
	_story_type_speed = STORY_SECONDS_PER_CHARACTER

	while story_label.visible_characters < character_count:
		story_label.visible_characters += 1
		await get_tree().create_timer(_story_type_speed).timeout

	_is_typing_story = false
	_story_finished = true


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


func _is_confirm_input(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return event.pressed

	if event is InputEventMouseButton:
		return event.pressed and event.button_index == MOUSE_BUTTON_LEFT

	return false
