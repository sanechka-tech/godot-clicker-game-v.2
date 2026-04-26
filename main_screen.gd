extends Node2D

const TAP_GAIN_EFFECT_SCENE = preload("res://tap_gain_effect.tscn")
const ONBOARDING_ANIMATION_NAMES: Array[StringName] = [&"Onboarding_tap", &"Oboarding_tap"]

@onready var character = $Character
@onready var coins_label: Label = $CanvasLayer/CoinsLabel
@onready var progress_goal: Range = $ProgressGoal
@onready var progress_goal_icon: Control = _find_progress_goal_icon()
@onready var effects_layer: Node2D = $TapEffects
@onready var onboarding: CanvasItem = _find_onboarding()
@onready var onboarding_animated_sprite: AnimatedSprite2D = _find_onboarding_animated_sprite()


func _ready() -> void:
	character.tapped.connect(_on_character_tapped)
	GameState.coins_changed.connect(_on_coins_changed)
	GameState.score_changed.connect(_on_score_changed)

	_update_coins_label()
	_setup_goal_progress()
	_update_goal_progress()
	_update_onboarding_visibility()


func _on_character_tapped(tap_position: Vector2) -> void:
	_hide_onboarding()

	var tap_gain := GameState.add_tap_coins()
	_spawn_tap_gain_effect(tap_position, tap_gain)


func _on_coins_changed(_new_value: int) -> void:
	_update_coins_label()


func _on_score_changed(_new_value: int) -> void:
	_update_goal_progress()


func _update_coins_label() -> void:
	coins_label.text = GameState.format_number(GameState.shitty_coins)


func _setup_goal_progress() -> void:
	progress_goal.min_value = 0
	progress_goal.max_value = GameState.score_goal
	call_deferred("_update_goal_icon")


func _update_goal_progress() -> void:
	progress_goal.value = min(GameState.score, GameState.score_goal)
	_update_goal_icon()


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
	var target_x := progress_control.size.x * progress_ratio - icon_size.x * 0.5
	var max_x := maxf(progress_control.size.x - icon_size.x, 0.0)

	progress_goal_icon.position.x = clampf(target_x, 0.0, max_x)
	progress_goal_icon.position.y = progress_control.size.y * 0.5 - icon_size.y * 0.5


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
		_play_onboarding_animation()


func _hide_onboarding() -> void:
	if onboarding == null:
		return

	onboarding.visible = false

	if onboarding_animated_sprite != null:
		onboarding_animated_sprite.stop()


func _find_onboarding_animated_sprite() -> AnimatedSprite2D:
	if onboarding == null:
		return null

	return onboarding.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D


func _play_onboarding_animation() -> void:
	if onboarding_animated_sprite == null:
		return

	for animation_name in ONBOARDING_ANIMATION_NAMES:
		if onboarding_animated_sprite.sprite_frames.has_animation(animation_name):
			onboarding_animated_sprite.play(animation_name)
			return

	onboarding_animated_sprite.play()
