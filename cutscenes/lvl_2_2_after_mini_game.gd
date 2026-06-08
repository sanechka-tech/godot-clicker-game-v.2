extends Control

const INTRO_DELAY_AFTER_REVEAL := 0.5
const BG_TEXT_FADE_DURATION := 0.25
const NAME_FADE_DURATION := 0.2
const STORY_SECONDS_PER_CHARACTER := 0.05
const FAST_STORY_SECONDS_PER_CHARACTER := 0.004
const NEXT_SCENE_PATH := "res://cutscenes/lvl_2_3_train_end.tscn"

@onready var bg_text: TextureRect = $"BG Text"
@onready var name_label: Label = $"BG Text/Name"
@onready var story_label: Label = $"BG Text/Story"

var _name_key := ""
var _story_key := ""
var _is_typing_story := false
var _story_type_speed := STORY_SECONDS_PER_CHARACTER
var _story_finished := false
var _dialog_finished := false
var _is_changing_scene := false


func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return

	if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return

	if _is_typing_story:
		_set_story_type_speed(FAST_STORY_SECONDS_PER_CHARACTER)
		return

	if _dialog_finished:
		_change_to_next_scene()
		return

	if _story_finished:
		_dialog_finished = true


func _ready() -> void:
	_name_key = name_label.text
	_story_key = String(GameState.mini_game_after_story_key)

	bg_text.visible = false
	name_label.visible = false
	story_label.visible = false
	bg_text.modulate.a = 0.0
	name_label.modulate.a = 0.0
	story_label.visible_characters = 0

	call_deferred("_play_intro_sequence")


func _exit_tree() -> void:
	AudioManager.stop_typewriter_sfx()


func _play_intro_sequence() -> void:
	var transition_screen = get_node_or_null("/root/TransitionScreen")
	if transition_screen != null and transition_screen.is_transitioning():
		await transition_screen.scene_revealed

	await get_tree().create_timer(INTRO_DELAY_AFTER_REVEAL).timeout
	await _show_bg_text()
	await _show_name()
	await _type_story()


func _show_bg_text() -> void:
	bg_text.visible = true

	var tween := create_tween()
	tween.tween_property(bg_text, "modulate:a", 1.0, BG_TEXT_FADE_DURATION)
	await tween.finished


func _show_name() -> void:
	name_label.text = tr(_name_key)
	name_label.visible = true

	var tween := create_tween()
	tween.tween_property(name_label, "modulate:a", 1.0, NAME_FADE_DURATION)
	await tween.finished


func _type_story() -> void:
	story_label.text = tr(_story_key).replace("\\n", "\n")
	story_label.visible = true
	story_label.visible_characters = 0

	var character_count := story_label.get_total_character_count()
	if character_count <= 0:
		AudioManager.stop_typewriter_sfx()
		_story_finished = true
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


func _set_story_type_speed(value: float) -> void:
	_story_type_speed = value
	if _is_typing_story:
		AudioManager.set_typewriter_speed(STORY_SECONDS_PER_CHARACTER / _story_type_speed)


func _change_to_next_scene() -> void:
	if _is_changing_scene:
		return

	_is_changing_scene = true
	var transition_screen = get_node_or_null("/root/TransitionScreen")
	if transition_screen != null:
		transition_screen.change_scene(NEXT_SCENE_PATH)
	else:
		get_tree().change_scene_to_file(NEXT_SCENE_PATH)
