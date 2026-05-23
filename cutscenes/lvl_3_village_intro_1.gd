extends Node2D

const NEXT_SCENE_PATH := "res://cutscenes/lvl_3_village_intro_2.tscn"
const RUN_AWAY_FALLBACK_DURATION := 7.0
const PHRASE_KEYS: Array[StringName] = [
	&"STORY_LVL3_INTRO_001",
	&"STORY_LVL3_INTRO_002",
	&"STORY_LVL3_INTRO_003",
	&"STORY_LVL3_INTRO_004",
	&"STORY_LVL3_INTRO_005",
]

@export var characters_per_second: float = 20.0

@onready var story_label: Label = _find_story_label()

var fade_rect: ColorRect
var visible_characters_progress := 0.0
var typing_finished := false
var phrase_index := 0
var transition_locked := false


func _ready() -> void:
	_setup_fade_overlay()
	AudioManager.play_level_3_intro_fields_background()

	if story_label == null:
		return

	_start_current_phrase()


func _process(delta: float) -> void:
	if transition_locked or typing_finished or story_label == null:
		return

	visible_characters_progress += characters_per_second * delta
	story_label.visible_characters = floori(visible_characters_progress)

	if story_label.visible_characters >= story_label.text.length():
		_finish_typing()


func _unhandled_input(event: InputEvent) -> void:
	if not _is_confirm_input(event):
		return

	get_viewport().set_input_as_handled()

	if transition_locked or story_label == null:
		return

	if not typing_finished:
		_finish_typing()
		return

	_show_next_phrase_or_scene()


func _start_current_phrase() -> void:
	story_label.text = tr(String(PHRASE_KEYS[phrase_index]))
	story_label.visible_characters = 0
	visible_characters_progress = 0.0
	typing_finished = story_label.text.length() <= 0

	if PHRASE_KEYS[phrase_index] == &"STORY_LVL3_INTRO_003":
		AudioManager.play_level_3_intro_stomach_sound()

	if typing_finished:
		story_label.visible_characters = -1


func _show_next_phrase_or_scene() -> void:
	if phrase_index >= PHRASE_KEYS.size() - 1:
		get_tree().change_scene_to_file(NEXT_SCENE_PATH)
		return

	phrase_index += 1
	_start_current_phrase()


func _finish_typing() -> void:
	if typing_finished:
		return

	typing_finished = true
	if story_label != null:
		story_label.visible_characters = -1

	var phrase_key := PHRASE_KEYS[phrase_index]
	if phrase_key == &"STORY_LVL3_INTRO_005":
		_start_run_away_transition()


func _start_run_away_transition() -> void:
	if transition_locked:
		return

	transition_locked = true
	var run_away_player: AudioStreamPlayer = AudioManager.play_level_3_intro_run_away()
	var transition_duration := _get_player_stream_length(run_away_player, RUN_AWAY_FALLBACK_DURATION)

	if fade_rect != null:
		fade_rect.visible = true
		fade_rect.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(fade_rect, "modulate:a", 1.0, transition_duration)

	await get_tree().create_timer(transition_duration).timeout
	get_tree().change_scene_to_file(NEXT_SCENE_PATH)


func _setup_fade_overlay() -> void:
	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 100
	add_child(fade_layer)

	fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.visible = false
	fade_rect.modulate.a = 0.0
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_layer.add_child(fade_rect)


func _get_player_stream_length(player: AudioStreamPlayer, fallback_duration: float) -> float:
	if player == null or player.stream == null:
		return fallback_duration

	var stream_length := player.stream.get_length()
	if stream_length <= 0.0:
		return fallback_duration

	return stream_length


func _find_story_label() -> Label:
	for label_path in [
		"BG Text/Story",
		"CanvasLayer/RichTextLabel",
	]:
		var label := get_node_or_null(label_path) as Label
		if label != null:
			return label

	return null


func _is_confirm_input(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return event.pressed

	if event is InputEventMouseButton:
		return event.pressed and event.button_index == MOUSE_BUTTON_LEFT

	return false
