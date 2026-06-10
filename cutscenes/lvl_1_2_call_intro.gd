extends Control

const INTRO_DELAY_AFTER_REVEAL := 2.5
const BG_TEXT_FADE_DURATION := 0.25
const NAME_FADE_DURATION := 0.2
const STORY_SECONDS_PER_CHARACTER := 0.05
const FAST_STORY_SECONDS_PER_CHARACTER := 0.004
const HIDDEN_SPEAKER_KEY := "NONE"
const BIP_BIP_STORY_KEY := "STORY_LVL1_INTRO_018"
const STOMACH_SOUND_STORY_KEY := "STORY_LVL1_INTRO_022"
const NEXT_SCENE_PATH := "res://main_screen.tscn"
const DIALOG_LINES := [
	{"name": "HERO_LEKS", "story": "STORY_LVL1_INTRO_002"},
	{"name": "HERO_MOM", "story": "STORY_LVL1_INTRO_003"},
	{"name": "HERO_MOM", "story": "STORY_LVL1_INTRO_004"},
	{"name": "HERO_LEKS", "story": "STORY_LVL1_INTRO_005"},
	{"name": "HERO_MOM", "story": "STORY_LVL1_INTRO_006"},
	{"name": "HERO_LEKS", "story": "STORY_LVL1_INTRO_007"},
	{"name": "HERO_MOM", "story": "STORY_LVL1_INTRO_008"},
	{"name": "HERO_LEKS", "story": "STORY_LVL1_INTRO_009"},
	{"name": "HERO_LEKS", "story": "STORY_LVL1_INTRO_010"},
	{"name": "HERO_MOM", "story": "STORY_LVL1_INTRO_011"},
	{"name": "HERO_LEKS", "story": "STORY_LVL1_INTRO_012"},
	{"name": "HERO_MOM", "story": "STORY_LVL1_INTRO_013"},
	{"name": "HERO_LEKS", "story": "STORY_LVL1_INTRO_014"},
	{"name": "HERO_MOM", "story": "STORY_LVL1_INTRO_015"},
	{"name": "HERO_LEKS", "story": "STORY_LVL1_INTRO_016"},
	{"name": "HERO_MOM", "story": "STORY_LVL1_INTRO_017"},
	{"name": HIDDEN_SPEAKER_KEY, "story": "STORY_LVL1_INTRO_018"},
	{"name": "HERO_LEKS", "story": "STORY_LVL1_INTRO_019"},
	{"name": "HERO_LEKS", "story": "STORY_LVL1_INTRO_020"},
	{"name": "HERO_LEKS", "story": "STORY_LVL1_INTRO_021"},
	{"name": HIDDEN_SPEAKER_KEY, "story": "STORY_LVL1_INTRO_022"},
	{"name": "HERO_LEKS", "story": "STORY_LVL1_INTRO_023"},
]

@onready var bg_text: TextureRect = $"BG Text"
@onready var name_label: Label = $"BG Text/Name"
@onready var story_label: Label = $"BG Text/Story"

var _ring_phone_player: AudioStreamPlayer
var _bip_bip_player: AudioStreamPlayer
var _is_typing_story := false
var _story_type_speed := STORY_SECONDS_PER_CHARACTER
var _story_finished := false
var _current_line_index := 0
var _current_name_key := ""
var _scene_confirmed := false
var _dialog_finished := false
var _is_changing_scene := false


func _input(event: InputEvent) -> void:
	if _is_settings_input(event):
		return

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
		_show_next_line()


func _ready() -> void:
	bg_text.visible = false
	name_label.visible = false
	story_label.visible = false
	bg_text.modulate.a = 0.0
	name_label.modulate.a = 0.0
	story_label.visible_characters = 0

	call_deferred("_play_intro_sequence")


func _exit_tree() -> void:
	AudioManager.stop_typewriter_sfx()
	_stop_bip_bip()
	if is_instance_valid(_ring_phone_player):
		_ring_phone_player.stop()


func _play_intro_sequence() -> void:
	var transition_screen = get_node_or_null("/root/TransitionScreen")
	_ring_phone_player = AudioManager.play_level_1_call_ring_phone()

	if transition_screen != null and transition_screen.is_transitioning():
		await transition_screen.scene_revealed

	await get_tree().create_timer(INTRO_DELAY_AFTER_REVEAL, false).timeout
	if is_instance_valid(_ring_phone_player):
		_ring_phone_player.stop()
	await _show_bg_text()
	await _show_current_line()


func _show_bg_text() -> void:
	bg_text.visible = true

	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
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

	if name_key == HIDDEN_SPEAKER_KEY:
		name_label.text = ""
		name_label.visible = false
		return

	name_label.text = tr(name_key)
	name_label.visible = true

	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
	tween.tween_property(name_label, "modulate:a", 1.0, NAME_FADE_DURATION)
	await tween.finished


func _type_story(story_key: String) -> void:
	story_label.text = tr(story_key).replace("\\n", "\n")
	story_label.visible = true
	story_label.visible_characters = 0

	var character_count := story_label.get_total_character_count()
	if character_count <= 0:
		AudioManager.stop_typewriter_sfx()
		_story_finished = true
		return

	_is_typing_story = true
	_set_story_type_speed(STORY_SECONDS_PER_CHARACTER)
	if story_key == BIP_BIP_STORY_KEY:
		_bip_bip_player = AudioManager.play_level_1_intro_bip_bip()
	if story_key == STOMACH_SOUND_STORY_KEY:
		AudioManager.play_level_3_intro_stomach_sound()
	AudioManager.start_typewriter_sfx(STORY_SECONDS_PER_CHARACTER / _story_type_speed)

	while story_label.visible_characters < character_count:
		story_label.visible_characters += 1
		await get_tree().create_timer(_story_type_speed, false).timeout
		character_count = story_label.get_total_character_count()

	_is_typing_story = false
	AudioManager.stop_typewriter_sfx()
	if story_key == BIP_BIP_STORY_KEY:
		_stop_bip_bip()
	_story_finished = true


func _set_story_type_speed(value: float) -> void:
	_story_type_speed = value
	if _is_typing_story:
		AudioManager.set_typewriter_speed(STORY_SECONDS_PER_CHARACTER / _story_type_speed)


func _show_next_line() -> void:
	_story_finished = false
	_current_line_index += 1

	if _current_line_index >= DIALOG_LINES.size():
		_scene_confirmed = true
		_dialog_finished = true
		return

	call_deferred("_show_current_line")


func _change_to_next_scene() -> void:
	if _is_changing_scene:
		return

	_is_changing_scene = true
	_stop_bip_bip()
	if is_instance_valid(_ring_phone_player):
		_ring_phone_player.stop()
	var transition_screen = get_node_or_null("/root/TransitionScreen")
	if transition_screen != null:
		transition_screen.change_scene(NEXT_SCENE_PATH)
	else:
		get_tree().change_scene_to_file(NEXT_SCENE_PATH)


func _stop_bip_bip() -> void:
	if not is_instance_valid(_bip_bip_player):
		_bip_bip_player = null
		return

	_bip_bip_player.stop()
	_bip_bip_player.queue_free()
	_bip_bip_player = null


func refresh_localized_text() -> void:
	if _current_line_index >= DIALOG_LINES.size():
		return

	var line: Dictionary = DIALOG_LINES[_current_line_index]
	var name_key := line.get("name", "") as String
	var story_key := line.get("story", "") as String

	if name_label != null and name_label.visible and not name_key.is_empty() and name_key != "NONE":
		name_label.text = tr(name_key)

	_refresh_story_label_translation(story_key)


func _refresh_story_label_translation(story_key: String) -> void:
	if story_label == null or not story_label.visible or story_key.is_empty():
		return

	var old_total: int = maxi(1, story_label.get_total_character_count())
	var old_visible: int = story_label.visible_characters
	var visible_ratio := clampf(float(old_visible) / float(old_total), 0.0, 1.0)
	story_label.text = tr(story_key).replace("\\n", "\n")
	var new_total: int = story_label.get_total_character_count()

	if _story_finished:
		story_label.visible_characters = new_total
	elif _is_typing_story:
		story_label.visible_characters = clampi(roundi(float(new_total) * visible_ratio), 0, new_total)
	else:
		story_label.visible_characters = old_visible


func _is_settings_input(event: InputEvent) -> bool:
	var settings_popup = get_node_or_null("SettingsLayer/SettingsPopup")
	return settings_popup != null and settings_popup.has_method("is_scene_input_blocked") and settings_popup.is_scene_input_blocked(event)
