extends Node2D

const TAP_GAIN_EFFECT_SCENE = preload("res://tap_gain_effect.tscn")
const SHOP_UNKNOWN_TEXTURE = preload("res://Images/Shops/button_unknown.png")
const PROGRESS_GOAL_ICON_TRACK_START_OFFSET := 0.0
const PROGRESS_GOAL_ICON_TRACK_END_OFFSET := 0.0
const PROGRESS_GOAL_ICON_OFFSET := Vector2.ZERO
const SHOP_BUTTON_TEXT_PRESS_OFFSET := Vector2(0.0, 2.0)
const SHOP_UPGRADE_BUTTONS := {
	"spread_the_cheeks": "ShopLvl1/VBoxContainer/SpreadtheCheeks",
	"scroll_tiktok": "ShopLvl1/VBoxContainer/ScrollTikTok",
	"run_the_tap": "ShopLvl1/VBoxContainer/RuntheTap",
	"use_an_enema": "ShopLvl1/VBoxContainer/UseanEnema",
}
const ONBOARDING_ANIMATION_NAMES: Array[StringName] = [&"Onboarding_tap", &"Oboarding_tap"]
const FIRST_LEVEL_SHOP_ONBOARDING_THRESHOLD := 125
const FINAL_UI_EXIT_DURATION := 0.8
const FINAL_UI_EXIT_EXTRA_DISTANCE := 80.0
const LEVEL_1_AFTER_SCENE_PATH := "res://cutscenes/lvl_1_3_after.tscn"
const LEVEL_1_AFTER_TRANSITION_FADE_OUT_DURATION := 0.6
const LEVEL_1_AFTER_TRANSITION_FADE_IN_DURATION := 0.1

const SHOP_TEXTURE_NORMAL := &"normal"
const SHOP_TEXTURE_PRESSED := &"pressed"
const SHOP_TEXTURE_DISABLED := &"disabled"

@onready var character = $Character
@onready var counter: CanvasLayer = $Counter
@onready var shop_lvl_1: Control = $ShopLvl1
@onready var coins_label: Label = $Counter/CoinsCounter/Label
@onready var progress_goal: Range = $ProgressGoal
@onready var progress_goal_icon: Control = _find_progress_goal_icon()
@onready var effects_layer: Node2D = $TapEffects
@onready var onboarding: CanvasItem = _find_onboarding()
@onready var onboarding_animated_sprite: AnimatedSprite2D = _find_onboarding_animated_sprite()
@onready var onboarding_shop: CanvasItem = _find_onboarding_shop()
@onready var onboarding_shop_animated_sprite: AnimatedSprite2D = _find_onboarding_shop_animated_sprite()

var shop_button_text_group_start_positions := {}
var shop_button_original_textures := {}
var shop_onboarding_was_shown := false
var shop_onboarding_was_completed := false
var final_pressure_sequence_started := false


func _ready() -> void:
	AudioManager.play_default_music()

	character.tapped.connect(_on_character_tapped)
	GameState.coins_changed.connect(_on_coins_changed)
	GameState.score_changed.connect(_on_score_changed)
	GameState.shop_changed.connect(_on_shop_changed)
	_setup_shop_button_press_offsets()
	_setup_shop_buttons()

	_update_coins_label()
	_update_shop_buttons()
	_setup_goal_progress()
	_update_goal_progress()
	_update_onboarding_visibility()
	_update_shop_onboarding_visibility()
	_try_start_final_pressure_sequence()


func _on_character_tapped(tap_position: Vector2) -> void:
	_hide_onboarding()

	var tap_gain := GameState.add_tap_coins()
	_spawn_tap_gain_effect(tap_position, tap_gain)


func _on_coins_changed(_new_value: int) -> void:
	_update_coins_label()
	_update_shop_buttons()
	_update_shop_onboarding_visibility()


func _on_score_changed(_new_value: int) -> void:
	_update_goal_progress()
	_try_start_final_pressure_sequence()


func _on_shop_changed() -> void:
	_update_shop_buttons()


func _setup_shop_button_press_offsets() -> void:
	for button_path in SHOP_UPGRADE_BUTTONS.values():
		var button := get_node(button_path) as TextureButton
		var text_group := button.get_node("TextGroup") as Control
		shop_button_text_group_start_positions[text_group] = text_group.position
		button.button_down.connect(_on_shop_button_down.bind(text_group))
		button.button_up.connect(_on_shop_button_up.bind(text_group))


func _on_shop_button_down(text_group: Control) -> void:
	text_group.position = shop_button_text_group_start_positions[text_group] + SHOP_BUTTON_TEXT_PRESS_OFFSET


func _on_shop_button_up(text_group: Control) -> void:
	text_group.position = shop_button_text_group_start_positions[text_group]


func _setup_shop_buttons() -> void:
	for upgrade_id in SHOP_UPGRADE_BUTTONS:
		var button := get_node(SHOP_UPGRADE_BUTTONS[upgrade_id]) as TextureButton
		_store_shop_button_textures(button)
		button.pressed.connect(_on_shop_upgrade_pressed.bind(upgrade_id))


func _on_shop_upgrade_pressed(upgrade_id: String) -> void:
	if upgrade_id == "spread_the_cheeks":
		_complete_shop_onboarding()

	GameState.buy_upgrade(upgrade_id)


func _update_shop_buttons() -> void:
	for upgrade_id in SHOP_UPGRADE_BUTTONS:
		var button := get_node(SHOP_UPGRADE_BUTTONS[upgrade_id]) as TextureButton
		var price_label := button.get_node("TextGroup/Price") as Label
		var text_group := button.get_node("TextGroup") as Control
		var is_revealed := GameState.is_upgrade_revealed(upgrade_id)

		price_label.text = GameState.format_price(GameState.upgrade_prices[upgrade_id])
		text_group.visible = is_revealed
		_apply_shop_button_reveal_state(button, is_revealed)
		button.disabled = not is_revealed or not GameState.can_buy_upgrade(upgrade_id)


func _store_shop_button_textures(button: TextureButton) -> void:
	shop_button_original_textures[button] = {
		SHOP_TEXTURE_NORMAL: button.texture_normal,
		SHOP_TEXTURE_PRESSED: button.texture_pressed,
		SHOP_TEXTURE_DISABLED: button.texture_disabled,
	}


func _apply_shop_button_reveal_state(button: TextureButton, is_revealed: bool) -> void:
	if is_revealed:
		var original_textures: Dictionary = shop_button_original_textures[button]
		button.texture_normal = original_textures[SHOP_TEXTURE_NORMAL]
		button.texture_pressed = original_textures[SHOP_TEXTURE_PRESSED]
		button.texture_disabled = original_textures[SHOP_TEXTURE_DISABLED]
		return

	button.texture_normal = SHOP_UNKNOWN_TEXTURE
	button.texture_pressed = SHOP_UNKNOWN_TEXTURE
	button.texture_disabled = SHOP_UNKNOWN_TEXTURE


func _update_coins_label() -> void:
	coins_label.text = GameState.format_number(GameState.shitty_coins)


func _setup_goal_progress() -> void:
	progress_goal.min_value = 0
	progress_goal.max_value = GameState.score_goal
	call_deferred("_update_goal_icon")


func _update_goal_progress() -> void:
	progress_goal.value = min(GameState.score, GameState.score_goal)
	_update_goal_icon()


func _try_start_final_pressure_sequence() -> void:
	if final_pressure_sequence_started:
		return

	if GameState.score < GameState.score_goal:
		return

	final_pressure_sequence_started = true
	_play_final_pressure_sequence()


func _play_final_pressure_sequence() -> void:
	if character.has_method("lock_final_pose"):
		character.lock_final_pose()

	for upgrade_id in SHOP_UPGRADE_BUTTONS:
		var button := get_node(SHOP_UPGRADE_BUTTONS[upgrade_id]) as TextureButton
		button.disabled = true

	var final_pressure_player := AudioManager.play_final_pressure()
	var exit_distance := get_viewport_rect().size.x + FINAL_UI_EXIT_EXTRA_DISTANCE
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(counter, "offset:x", counter.offset.x + exit_distance, FINAL_UI_EXIT_DURATION)
	tween.tween_property(shop_lvl_1, "position:x", shop_lvl_1.position.x + exit_distance, FINAL_UI_EXIT_DURATION)

	await tween.finished
	if is_instance_valid(final_pressure_player) and final_pressure_player.playing:
		await final_pressure_player.finished

	AudioManager.play_final_toilet_flush()

	var transition_screen = get_node_or_null("/root/TransitionScreen")
	if transition_screen != null:
		transition_screen.change_scene(
			LEVEL_1_AFTER_SCENE_PATH,
			LEVEL_1_AFTER_TRANSITION_FADE_OUT_DURATION,
			LEVEL_1_AFTER_TRANSITION_FADE_IN_DURATION
		)
	else:
		get_tree().change_scene_to_file(LEVEL_1_AFTER_SCENE_PATH)


func _update_goal_icon() -> void:
	if progress_goal_icon == null:
		return

	var progress_control := progress_goal as Control
	if progress_control == null:
		return

	var progress_range := progress_goal.max_value - progress_goal.min_value
	if progress_range <= 0.0:
		return

	var progress_ratio := clampf(
		(progress_goal.value - progress_goal.min_value) / progress_range,
		0.0,
		1.0
	)
	var icon_size := progress_goal_icon.size
	var half_icon_width := icon_size.x * 0.5
	var start_x := PROGRESS_GOAL_ICON_TRACK_START_OFFSET - half_icon_width
	var end_x := progress_control.size.x - PROGRESS_GOAL_ICON_TRACK_END_OFFSET - half_icon_width
	var target_x := lerpf(start_x, end_x, progress_ratio)

	progress_goal_icon.position.x = target_x + PROGRESS_GOAL_ICON_OFFSET.x
	progress_goal_icon.position.y = progress_control.size.y * 0.5 - icon_size.y * 0.5 + PROGRESS_GOAL_ICON_OFFSET.y


func _find_progress_goal_icon() -> Control:
	for icon_path in [
		"ProgressGoal/GoalIcon",
		"ProgressGoal/Icon",
		"ProgressGoal/TextureRect",
	]:
		var icon := get_node_or_null(icon_path) as Control
		if icon != null:
			return icon

	for child in $ProgressGoal.get_children():
		var icon := child as Control
		if icon != null:
			return icon

	return null


func _spawn_tap_gain_effect(tap_position: Vector2, amount: int) -> void:
	var effect := TAP_GAIN_EFFECT_SCENE.instantiate() as Node2D
	effect.position = effects_layer.to_local(tap_position) + Vector2(randf_range(-14.0, 14.0), 5.0)
	effects_layer.add_child(effect)
	effect.call("setup", amount)


func _find_onboarding() -> CanvasItem:
	for onboarding_path in [
		"Onboarding",
		"CanvasLayer/Onboarding",
		"main_background/Onboarding",
	]:
		var onboarding_node := get_node_or_null(onboarding_path) as CanvasItem
		if onboarding_node != null:
			return onboarding_node

	return null


func _update_onboarding_visibility() -> void:
	if onboarding == null:
		return

	var is_level_1_start := GameState.score == 0 and GameState.shitty_coins == 0
	onboarding.visible = is_level_1_start

	if is_level_1_start:
		_play_onboarding_animation(onboarding_animated_sprite)


func _hide_onboarding() -> void:
	if onboarding == null:
		return

	onboarding.visible = false

	if onboarding_animated_sprite != null:
		onboarding_animated_sprite.stop()


func _find_onboarding_shop() -> CanvasItem:
	for onboarding_path in [
		"Onboarding2",
		"CanvasLayer/Onboarding2",
		"main_background/Onboarding2",
	]:
		var onboarding_node := get_node_or_null(onboarding_path) as CanvasItem
		if onboarding_node != null:
			return onboarding_node

	return null


func _find_onboarding_shop_animated_sprite() -> AnimatedSprite2D:
	if onboarding_shop == null:
		return null

	return onboarding_shop.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D


func _update_shop_onboarding_visibility() -> void:
	if onboarding_shop == null:
		return

	if shop_onboarding_was_completed:
		onboarding_shop.visible = false
		return

	if not shop_onboarding_was_shown and GameState.shitty_coins >= FIRST_LEVEL_SHOP_ONBOARDING_THRESHOLD:
		shop_onboarding_was_shown = true
		onboarding_shop.visible = true
		_play_onboarding_animation(onboarding_shop_animated_sprite)
		return

	if not shop_onboarding_was_shown:
		onboarding_shop.visible = false


func _complete_shop_onboarding() -> void:
	if onboarding_shop == null:
		return

	shop_onboarding_was_completed = true
	onboarding_shop.visible = false

	if onboarding_shop_animated_sprite != null:
		onboarding_shop_animated_sprite.stop()


func _find_onboarding_animated_sprite() -> AnimatedSprite2D:
	if onboarding == null:
		return null

	return onboarding.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D


func _play_onboarding_animation(animated_sprite: AnimatedSprite2D) -> void:
	if animated_sprite == null:
		return

	for animation_name in ONBOARDING_ANIMATION_NAMES:
		if animated_sprite.sprite_frames.has_animation(animation_name):
			animated_sprite.play(animation_name)
			return

	animated_sprite.play()
