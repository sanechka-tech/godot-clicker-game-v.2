extends Node2D

const FLOATING_NUMBER_FONT = preload("res://CustomFont/EpilepsySansBold.ttf")
const COIN_FRAME_1 = preload("res://Images/Coin/coin1.png")
const COIN_FRAME_2 = preload("res://Images/Coin/coin2.png")
const COIN_FRAME_3 = preload("res://Images/Coin/coin3.png")

@onready var character = $Character
@onready var coins_label: Label = $CanvasLayer/CoinsLabel
@onready var progress_goal: Range = $ProgressGoal
@onready var effects_layer: CanvasLayer = $CanvasLayer


func _ready() -> void:
	character.tapped.connect(_on_character_tapped)
	GameState.coins_changed.connect(_on_coins_changed)
	GameState.score_changed.connect(_on_score_changed)

	_update_coins_label()
	_setup_goal_progress()
	_update_goal_progress()


func _on_character_tapped(tap_position: Vector2) -> void:
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


func _update_goal_progress() -> void:
	progress_goal.value = min(GameState.score, GameState.score_goal)


func _spawn_tap_gain_effect(tap_position: Vector2, amount: int) -> void:
	var effect := Node2D.new()
	effect.position = tap_position + Vector2(randf_range(-18.0, 18.0), -28.0)
	effects_layer.add_child(effect)

	var coin := AnimatedSprite2D.new()
	coin.sprite_frames = _create_coin_sprite_frames()
	coin.position = Vector2(62.0, -15.0)
	coin.scale = Vector2(0.6, 0.6)
	effect.add_child(coin)
	coin.play(&"spin")

	var label := Label.new()
	label.text = "+" + str(amount)
	label.position = Vector2(6.0, -34.0)
	label.label_settings = _create_tap_gain_label_settings()
	effect.add_child(label)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(effect, "position", effect.position + Vector2(0.0, -86.0), 0.75).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(effect, "scale", Vector2(1.16, 1.16), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(effect, "modulate:a", 0.0, 0.3).set_delay(0.45)
	tween.finished.connect(effect.queue_free)


func _create_coin_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation(&"spin")
	frames.set_animation_speed(&"spin", 14.0)
	frames.set_animation_loop(&"spin", true)
	frames.add_frame(&"spin", COIN_FRAME_1)
	frames.add_frame(&"spin", COIN_FRAME_2)
	frames.add_frame(&"spin", COIN_FRAME_3)
	return frames


func _create_tap_gain_label_settings() -> LabelSettings:
	var settings := LabelSettings.new()
	settings.font = FLOATING_NUMBER_FONT
	settings.font_size = 36
	settings.font_color = Color(0.914, 0.651, 0.239, 1.0)
	settings.outline_size = 8
	settings.outline_color = Color(0.11, 0.05, 0.02)
	settings.shadow_size = 0
	settings.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	settings.shadow_offset = Vector2(0.0, 0.0)
	return settings
