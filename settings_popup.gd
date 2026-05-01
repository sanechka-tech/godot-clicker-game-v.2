extends Control

const LANGUAGE_LOCALES := ["en", "ru", "es", "de"]
const LANGUAGE_LABELS := ["English", "Русский", "Español", "Deutsch"]
const MIN_VOLUME_DB := -80.0
const FEEDBACK_LABEL_PRESS_OFFSET := Vector2(0.0, 2.0)
const BACK_BUTTON_PRESS_SHRINK := Vector2(4.0, 4.0)

@onready var menu_root: Control = $MenuRoot
@onready var music_volume: Control = $MenuRoot/MusicVolume
@onready var sfx_volume: Control = $MenuRoot/SFXVolume
@onready var music_slider: HSlider = $MenuRoot/MusicVolume/HSlider
@onready var sfx_slider: HSlider = $MenuRoot/SFXVolume/HSlider
@onready var language_button: OptionButton = $MenuRoot/LanguageButton
@onready var back_button: TextureButton = $MenuRoot/TextureButtonBack
@onready var feedback_button: TextureButton = $MenuRoot/ButtonFeedback
@onready var feedback_label: Label = $MenuRoot/ButtonFeedback/Feedback
@onready var settings_button_root: Control = $SettingsButtonRoot
@onready var settings_button: TextureButton = $SettingsButtonRoot/SettingsButton

var volume_knob_offsets := {}
var feedback_label_start_position := Vector2.ZERO
var back_button_start_position := Vector2.ZERO
var back_button_start_size := Vector2.ZERO


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	menu_root.visible = false

	_remember_volume_knob_offset(music_volume)
	_remember_volume_knob_offset(sfx_volume)
	_setup_volume_slider(music_slider, "Music")
	_setup_volume_slider(sfx_slider, "SFX")
	_setup_language_button()

	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	language_button.item_selected.connect(_on_language_selected)
	back_button_start_position = back_button.position
	back_button_start_size = back_button.size
	back_button.button_down.connect(_on_back_button_down)
	back_button.button_up.connect(_on_back_button_up)
	back_button.pressed.connect(close)
	feedback_label_start_position = feedback_label.position
	feedback_button.button_down.connect(_on_feedback_button_down)
	feedback_button.button_up.connect(_on_feedback_button_up)
	settings_button.pressed.connect(open)

	_update_volume_view(music_volume, music_slider.value)
	_update_volume_view(sfx_volume, sfx_slider.value)


func open() -> void:
	get_tree().paused = true
	settings_button_root.visible = false
	menu_root.visible = true


func close() -> void:
	_reset_back_button_size()
	menu_root.visible = false
	settings_button_root.visible = true
	get_tree().paused = false


func _on_feedback_button_down() -> void:
	feedback_label.position = feedback_label_start_position + FEEDBACK_LABEL_PRESS_OFFSET


func _on_feedback_button_up() -> void:
	feedback_label.position = feedback_label_start_position


func _on_back_button_down() -> void:
	back_button.position = back_button_start_position + BACK_BUTTON_PRESS_SHRINK * 0.5
	back_button.size = back_button_start_size - BACK_BUTTON_PRESS_SHRINK


func _on_back_button_up() -> void:
	_reset_back_button_size()


func _reset_back_button_size() -> void:
	back_button.position = back_button_start_position
	back_button.size = back_button_start_size


func _setup_volume_slider(slider: HSlider, bus_name: String) -> void:
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = _get_bus_volume_linear(bus_name)


func _setup_language_button() -> void:
	var current_locale := TranslationServer.get_locale().left(2)
	var selected_index := LANGUAGE_LOCALES.find(current_locale)

	if selected_index == -1:
		selected_index = 0

	if selected_index < language_button.item_count:
		language_button.select(selected_index)

	_apply_language_popup_font()


func _apply_language_popup_font() -> void:
	var popup := language_button.get_popup()
	var font := language_button.get_theme_font("font")
	var font_size := language_button.get_theme_font_size("font_size")

	if font != null:
		popup.add_theme_font_override("font", font)

	popup.add_theme_font_size_override("font_size", font_size)


func _on_music_volume_changed(value: float) -> void:
	_set_bus_volume("Music", value)
	_update_volume_view(music_volume, value)


func _on_sfx_volume_changed(value: float) -> void:
	_set_bus_volume("SFX", value)
	_update_volume_view(sfx_volume, value)


func _on_language_selected(index: int) -> void:
	var locale_index := language_button.get_item_id(index)

	if locale_index < 0 or locale_index >= LANGUAGE_LOCALES.size():
		return

	TranslationServer.set_locale(LANGUAGE_LOCALES[locale_index])


func _set_bus_volume(bus_name: String, value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return

	AudioServer.set_bus_volume_db(bus_index, _linear_to_volume_db(value))


func _get_bus_volume_linear(bus_name: String) -> float:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return 1.0

	var volume_db := AudioServer.get_bus_volume_db(bus_index)

	if volume_db <= MIN_VOLUME_DB:
		return 0.0

	return clampf(db_to_linear(volume_db), 0.0, 1.0)


func _linear_to_volume_db(value: float) -> float:
	if value <= 0.0:
		return MIN_VOLUME_DB

	return linear_to_db(value)


func _remember_volume_knob_offset(volume_control: Control) -> void:
	var knob := volume_control.get_node("VolumeKnob") as Control
	var slider := volume_control.get_node("HSlider") as HSlider
	var slider_ratio := _get_slider_ratio(slider)
	var slider_handle_x := _get_slider_handle_x(slider, slider_ratio)

	volume_knob_offsets[volume_control] = knob.position - Vector2(slider_handle_x, slider.position.y)


func _update_volume_view(volume_control: Control, value: float) -> void:
	var fill_clip := volume_control.get_node("VolumeFillClip") as Control
	var knob := volume_control.get_node("VolumeKnob") as Control
	var slider := volume_control.get_node("HSlider") as HSlider
	var ratio := clampf(value, 0.0, 1.0)
	var fill_size := fill_clip.size
	var knob_position := knob.position
	var knob_offset := volume_knob_offsets.get(volume_control, Vector2.ZERO) as Vector2

	fill_size.x = slider.size.x * ratio
	knob_position.x = _get_slider_handle_x(slider, ratio) + knob_offset.x
	knob_position.y = slider.position.y + knob_offset.y

	fill_clip.size = fill_size
	knob.position = knob_position


func _get_slider_ratio(slider: HSlider) -> float:
	var value_range := slider.max_value - slider.min_value

	if value_range <= 0.0:
		return 0.0

	return clampf((slider.value - slider.min_value) / value_range, 0.0, 1.0)


func _get_slider_handle_x(slider: HSlider, ratio: float) -> float:
	var grabber_width := 0.0
	var grabber_icon := slider.get_theme_icon("grabber")

	if grabber_icon != null:
		grabber_width = grabber_icon.get_width()

	var half_grabber_width := grabber_width * 0.5
	var start_x := slider.position.x + half_grabber_width
	var end_x := slider.position.x + slider.size.x - half_grabber_width

	return lerpf(start_x, end_x, clampf(ratio, 0.0, 1.0))
