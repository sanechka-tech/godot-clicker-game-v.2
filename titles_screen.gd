extends Control

const CREDIT_FONT := preload("res://CustomFont/EpilepsySansBold.ttf")
const MENU_SCENE_PATH := "res://menu.tscn"
const SCROLL_DURATION := 24.0
const CREDITS_MUSIC_START_TIME := 11.1
const CREDITS_MUSIC_VOLUME := 0.5
const MENU_TRANSITION_FADE_OUT_DURATION := 2.0
const MENU_TRANSITION_FADE_IN_DURATION := 2.0
const START_BOTTOM_MARGIN := 40.0
const END_TOP_MARGIN := 80.0
const SIDE_MARGIN := 150.0
const TITLE_FONT_SIZE := 58
const ROW_FONT_SIZE := 34
const FOOTER_FONT_SIZE := 42
const ROW_MIN_HEIGHT := 44.0
const SECTION_SPACING := 34.0
const ROW_SPACING := 10
const THANK_YOU_FADE_DURATION := 1.0
const THANK_YOU_HOLD_DURATION := 5.0
const FAST_SCROLL_SPEED_SCALE := 4.0
const MAIN_NAME_KEY := "TITLES_NAME_MAIN"
const CREDIT_ROWS := [
	{"role": "TITLES_ROLE_DESIGN", "name": MAIN_NAME_KEY},
	{"role": "TITLES_ROLE_PROGRAMMING", "name": MAIN_NAME_KEY},
	{"role": "TITLES_ROLE_ART", "name": MAIN_NAME_KEY},
	{"role": "TITLES_ROLE_ANIMATION", "name": MAIN_NAME_KEY},
	{"role": "TITLES_ROLE_MUSIC", "name": MAIN_NAME_KEY},
	{"role": "TITLES_ROLE_SOUND_EFFECTS", "name": MAIN_NAME_KEY},
	{"role": "TITLES_ROLE_WRITING", "name": MAIN_NAME_KEY},
	{"role": "TITLES_ROLE_LOCALIZATION", "name": MAIN_NAME_KEY},
	{"role": "TITLES_ROLE_TESTING", "name": MAIN_NAME_KEY},
]

@onready var titles: VBoxContainer = $Titles
@onready var thank_you_label: Label = $ThankYouLabel

var _scroll_finished := false
var _scroll_tween: Tween


func _ready() -> void:
	_build_titles()
	titles.visible = false
	thank_you_label.text = tr("TITLES_THANK_YOU")
	thank_you_label.add_theme_font_override("font", CREDIT_FONT)
	thank_you_label.add_theme_color_override("font_color", Color.WHITE)
	thank_you_label.modulate.a = 0.0
	thank_you_label.visible = false
	call_deferred("_play_titles")


func _input(event: InputEvent) -> void:
	if _scroll_finished:
		return

	if event is InputEventScreenTouch:
		_set_scroll_speed_scale(FAST_SCROLL_SPEED_SCALE if event.pressed else 1.0)
		return

	if not (event is InputEventMouseButton):
		return

	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	_set_scroll_speed_scale(FAST_SCROLL_SPEED_SCALE if event.pressed else 1.0)


func _build_titles() -> void:
	for child in titles.get_children():
		child.queue_free()

	titles.add_theme_constant_override("separation", ROW_SPACING)
	_add_center_label("TITLES_GAME_BY", TITLE_FONT_SIZE)
	_add_spacer(SECTION_SPACING)
	_add_spacer(SECTION_SPACING)

	for row: Dictionary in CREDIT_ROWS:
		_add_credit_row(row["role"] as String, row["name"] as String)

	_add_spacer(SECTION_SPACING)
	_add_spacer(SECTION_SPACING)
	_add_center_label("TITLES_SPECIAL_THANKS", FOOTER_FONT_SIZE)
	_add_center_label("TITLES_SPECIAL_THANKS_NAME", ROW_FONT_SIZE)


func _add_credit_row(role_key: String, name_key: String) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = ROW_MIN_HEIGHT
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_child(row)

	var role_label := _create_label(tr(role_key), ROW_FONT_SIZE, HORIZONTAL_ALIGNMENT_LEFT)
	role_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(role_label)

	var name_label := _create_label(tr(name_key), ROW_FONT_SIZE, HORIZONTAL_ALIGNMENT_RIGHT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)


func _add_center_label(text_key: String, font_size: int) -> void:
	var label := _create_label(tr(text_key), font_size, HORIZONTAL_ALIGNMENT_CENTER)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_child(label)


func _create_label(text_value: String, font_size: int, alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.add_theme_font_override("font", CREDIT_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color.WHITE)
	return label


func _add_spacer(height: float) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size.y = height
	titles.add_child(spacer)


func _play_titles() -> void:
	var transition_screen = get_node_or_null("/root/TransitionScreen")
	if transition_screen != null and transition_screen.is_transitioning():
		await transition_screen.scene_revealed

	await get_tree().process_frame
	await get_tree().process_frame

	var viewport_size := get_viewport_rect().size
	titles.position.x = SIDE_MARGIN
	titles.size.x = viewport_size.x - SIDE_MARGIN * 2.0
	titles.size.y = titles.get_combined_minimum_size().y
	titles.visible = true
	titles.position.y = viewport_size.y + START_BOTTOM_MARGIN
	AudioManager.play_minigame_music_from(CREDITS_MUSIC_START_TIME, CREDITS_MUSIC_VOLUME)

	var end_y := -titles.size.y - END_TOP_MARGIN
	_scroll_tween = create_tween()
	_scroll_tween.tween_property(titles, "position:y", end_y, SCROLL_DURATION)
	await _scroll_tween.finished

	_scroll_finished = true
	_scroll_tween = null
	_show_thank_you()


func _show_thank_you() -> void:
	thank_you_label.visible = true
	thank_you_label.modulate.a = 0.0

	var tween := create_tween()
	tween.tween_property(thank_you_label, "modulate:a", 1.0, THANK_YOU_FADE_DURATION)
	await tween.finished
	await get_tree().create_timer(THANK_YOU_HOLD_DURATION).timeout
	_change_to_menu()


func _change_to_menu() -> void:
	GameState.clear_progress()

	var transition_screen = get_node_or_null("/root/TransitionScreen")
	if transition_screen != null:
		AudioManager.fade_out_music(MENU_TRANSITION_FADE_OUT_DURATION)
		_stop_level_3_ambience_before_menu_fade_in(transition_screen)
		transition_screen.change_scene(
			MENU_SCENE_PATH,
			MENU_TRANSITION_FADE_OUT_DURATION,
			MENU_TRANSITION_FADE_IN_DURATION
		)
	else:
		AudioManager.stop_music()
		AudioManager.stop_level_3_intro_ambience()
		get_tree().change_scene_to_file(MENU_SCENE_PATH)


func _stop_level_3_ambience_before_menu_fade_in(transition_screen) -> void:
	await transition_screen.fade_in_started
	AudioManager.stop_level_3_intro_ambience()


func _set_scroll_speed_scale(speed_scale: float) -> void:
	if _scroll_tween != null and _scroll_tween.is_valid():
		_scroll_tween.set_speed_scale(speed_scale)
