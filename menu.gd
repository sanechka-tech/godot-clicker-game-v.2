extends Node2D

const MENU_SLIDE_DURATION := 1.1
const BUTTONS_FADE_DURATION := 0.25
const MENU_START_BOTTOM_MARGIN := 24.0

@onready var settings_popup = $SettingsPopup
@onready var vhs_panel: TextureRect = $VHS
@onready var buttons_container: VBoxContainer = $VHS/VBoxContainer
@onready var settings_button: Button = $VHS/VBoxContainer/Settings


func _ready() -> void:
	AudioManager.play_default_music()
	settings_button.pressed.connect(_on_settings_pressed)
	_play_intro_animation()


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://main_screen.tscn")


func _on_texture_button_pressed() -> void:
	get_tree().change_scene_to_file("res://main_screen.tscn")


func _on_settings_pressed() -> void:
	settings_popup.open()


func _play_intro_animation() -> void:
	var final_position := vhs_panel.position
	var start_position := final_position
	start_position.y = get_viewport_rect().size.y + MENU_START_BOTTOM_MARGIN

	vhs_panel.position = start_position
	buttons_container.visible = false
	buttons_container.modulate.a = 0.0

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(vhs_panel, "position", final_position, MENU_SLIDE_DURATION)
	tween.tween_callback(_show_menu_buttons)


func _show_menu_buttons() -> void:
	buttons_container.visible = true

	var tween := create_tween()
	tween.tween_property(buttons_container, "modulate:a", 1.0, BUTTONS_FADE_DURATION)
