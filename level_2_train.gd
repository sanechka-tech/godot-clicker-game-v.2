extends Node2D

const ROUND_DURATION_SECONDS := 300.0
const LEVEL_GOAL_SCORE := 170000
const MOB_SPAWN_INTERVAL := 5.0
const TAP_GAIN_EFFECT_SCENE := preload("res://tap_gain_effect.tscn")
const SHOP_UNKNOWN_TEXTURE = preload("res://Images/Shops/button_unknown.png")
const PROGRESS_GOAL_ICON_TRACK_START_OFFSET := 0.0
const PROGRESS_GOAL_ICON_TRACK_END_OFFSET := 0.0
const PROGRESS_GOAL_ICON_OFFSET := Vector2.ZERO
const PROGRESS_VISUAL_EXPONENT := 0.55
const SHOP_FACE_PRESS_OFFSET := Vector2(0.0, 2.0)
const SHOP_BUTTON_TEXT_PRESS_OFFSET := Vector2(0.0, 2.0)
const FINAL_UI_EXIT_DURATION := 0.8
const FINAL_UI_EXIT_EXTRA_DISTANCE := 80.0
const LEVEL_2_AFTER_SCENE_PATH := "res://cutscenes/lvl_3_village_intro_1.tscn"
const LEVEL_2_AFTER_TRANSITION_FADE_OUT_DURATION := 2.0
const LEVEL_2_AFTER_TRANSITION_FADE_IN_DURATION := 2.0
const TRAIN_INSIDE_VOLUME := 0.04
const SHOP_TEXTURE_NORMAL := &"normal"
const SHOP_TEXTURE_PRESSED := &"pressed"
const SHOP_TEXTURE_DISABLED := &"disabled"
const SHOP_FACE_BUTTON_PATHS := {
	"PushHarder": "Face",
	"HoldtheRail": "Hold",
	"GetSomeTea": "Tea",
	"StationCheburek": "Cheburek",
}
const SHOP_LEVEL_2_BUTTONS := {
	"push_harder": "ShopLvl2/VBoxContainer/PushHarder",
	"hold_the_rail": "ShopLvl2/VBoxContainer/HoldtheRail",
	"get_some_tea": "ShopLvl2/VBoxContainer/GetSomeTea",
	"station_cheburek": "ShopLvl2/VBoxContainer/StationCheburek",
}
const SHOP_LEVEL_2_BASE_PRICES := {
	"push_harder": 30,
	"hold_the_rail": 150,
	"get_some_tea": 900,
	"station_cheburek": 5000,
}
const SHOP_LEVEL_2_PRICE_GROWTH := {
	"push_harder": 1.13,
	"hold_the_rail": 1.15,
	"get_some_tea": 1.17,
	"station_cheburek": 1.19,
}
const SHOP_LEVEL_2_TAP_POWER := {
	"push_harder": 1,
	"hold_the_rail": 3,
	"get_some_tea": 8,
	"station_cheburek": 20,
}

const FART_1_SCENE := preload("res://character/Mobs/Fart1.tscn")
const FART_2_SCENE := preload("res://character/Mobs/Fart2.tscn")
const FART_3_SCENE := preload("res://character/Mobs/Fart3.tscn")

@onready var character = $Character
@onready var level_2_bg_parallax = $level_2_bg_parallax
@onready var counter: CanvasLayer = $Counter
@onready var shop_lvl_2: Control = $ShopLvl2
@onready var coins_label: Label = $Counter/CoinsCounter2/Label
@onready var time_label: Label = _find_time_label()
@onready var progress_goal: Range = $ProgressGoalLvl2
@onready var progress_goal_icon: Control = _find_progress_goal_icon()
@onready var effects_layer: Node2D = $TapEffects
@onready var level_2_lose_dim: CanvasItem = $LoseLayer/Lvl2LoseDim
@onready var level_2_lose: CanvasItem = $LoseLayer/Lvl2Lose
@onready var level_2_retry_button: BaseButton = $LoseLayer/Lvl2Lose/Lvl2Retry

var time_left_seconds := ROUND_DURATION_SECONDS
var round_finished := false
var final_pressure_sequence_started := false
var mob_spawn_time_left := MOB_SPAWN_INTERVAL
var shop_face_start_positions := {}
var shop_face_tweens := {}
var shop_button_text_group_start_positions := {}
var shop_button_original_textures := {}
var level_2_shop_purchase_counts := {}
var level_2_shop_prices := {}
var level_2_shop_revealed := {}
var train_inside_player: AudioStreamPlayer

var fart_scenes := [
	FART_1_SCENE,
	FART_2_SCENE,
	FART_3_SCENE,
]


func _ready() -> void:
	AudioManager.play_main_theme()
	_start_train_inside()

	GameState.start_level(LEVEL_GOAL_SCORE)
	_reset_level_2_shop_state()

	character.tapped.connect(_on_character_tapped)
	GameState.coins_changed.connect(_on_coins_changed)
	GameState.score_changed.connect(_on_score_changed)
	level_2_retry_button.pressed.connect(_on_lvl_2_retry_pressed)
	_setup_shop_face_press_effects()
	_setup_level_2_shop_buttons()

	_hide_round_result_panels()
	_setup_goal_progress()
	_update_coins_label()
	_update_time_label()
	_update_goal_progress()
	_update_level_2_shop_buttons()


func _exit_tree() -> void:
	_stop_train_inside()


func _process(delta: float) -> void:
	if round_finished:
		return

	time_left_seconds = maxf(time_left_seconds - delta, 0.0)
	_update_time_label()
	_update_mob_spawner(delta)

	if GameState.score >= LEVEL_GOAL_SCORE:
		_finish_round(true)
		return

	if time_left_seconds <= 0.0:
		_finish_round(false)


func _input(event: InputEvent) -> void:
	if round_finished or not _is_primary_press(event):
		return

	var input_global_position := _get_input_global_position(event)
	if _pop_fart_mob_at_global_position(input_global_position):
		get_viewport().set_input_as_handled()


func _on_character_tapped(tap_position: Vector2) -> void:
	if round_finished:
		return

	var tap_gain: int = GameState.add_tap_coins()
	_spawn_tap_gain_effect(tap_position, tap_gain)


func _on_coins_changed(_new_value: int) -> void:
	_update_coins_label()
	_update_level_2_shop_buttons()


func _on_score_changed(_new_value: int) -> void:
	_update_goal_progress()

	if GameState.score >= LEVEL_GOAL_SCORE:
		_finish_round(true)


func _update_coins_label() -> void:
	coins_label.text = GameState.format_number(GameState.shitty_coins)


func _update_time_label() -> void:
	if time_label == null:
		return

	var total_seconds := ceili(time_left_seconds)
	var minutes := int(total_seconds / 60)
	var seconds := int(total_seconds % 60)

	time_label.text = "%02d:%02d" % [minutes, seconds]


func _setup_goal_progress() -> void:
	progress_goal.min_value = 0
	progress_goal.max_value = LEVEL_GOAL_SCORE
	call_deferred("_update_goal_icon")


func _update_goal_progress() -> void:
	progress_goal.value = _get_visual_goal_progress_value(GameState.score, LEVEL_GOAL_SCORE)
	_update_goal_icon()


func _get_visual_goal_progress_value(current_score: int, goal_score: int) -> float:
	if goal_score <= 0:
		return 0.0

	var raw_ratio := clampf(float(current_score) / float(goal_score), 0.0, 1.0)
	var visual_ratio := pow(raw_ratio, PROGRESS_VISUAL_EXPONENT)
	return visual_ratio * goal_score


func _hide_round_result_panels() -> void:
	level_2_lose_dim.visible = false
	level_2_lose.visible = false


func _finish_round(did_win: bool) -> void:
	if round_finished:
		return

	round_finished = true
	if did_win:
		_start_final_pressure_sequence()
	else:
		AudioManager.stop_music()
		_stop_train_inside()
		AudioManager.play_you_died()
		_pause_level_2_background_motion()
		level_2_lose_dim.visible = true
		level_2_lose.visible = true

	for fart_mob in get_tree().get_nodes_in_group("fart_mobs"):
		fart_mob.queue_free()


func _on_lvl_2_retry_pressed() -> void:
	get_tree().reload_current_scene()


func _pause_level_2_background_motion() -> void:
	if level_2_bg_parallax != null and level_2_bg_parallax.has_method("set_scroll_enabled"):
		level_2_bg_parallax.set_scroll_enabled(false)


func _start_final_pressure_sequence() -> void:
	if final_pressure_sequence_started:
		return

	final_pressure_sequence_started = true
	AudioManager.stop_music()
	_play_final_pressure_sequence()


func _play_final_pressure_sequence() -> void:
	if character.has_method("lock_final_pose"):
		character.lock_final_pose()

	for upgrade_id in SHOP_LEVEL_2_BUTTONS:
		var button := get_node(SHOP_LEVEL_2_BUTTONS[upgrade_id]) as TextureButton
		button.disabled = true

	var final_pressure_player: AudioStreamPlayer = AudioManager.play_final_pressure()
	var exit_distance := get_viewport_rect().size.x + FINAL_UI_EXIT_EXTRA_DISTANCE
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(counter, "offset:x", counter.offset.x + exit_distance, FINAL_UI_EXIT_DURATION)
	tween.tween_property(shop_lvl_2, "position:x", shop_lvl_2.position.x + exit_distance, FINAL_UI_EXIT_DURATION)

	await tween.finished
	if is_instance_valid(final_pressure_player) and final_pressure_player.playing:
		await final_pressure_player.finished

	AudioManager.play_final_toilet_flush()
	GameState.save_progress(LEVEL_2_AFTER_SCENE_PATH)

	var transition_screen = get_node_or_null("/root/TransitionScreen")
	if transition_screen != null:
		_fade_train_inside(LEVEL_2_AFTER_TRANSITION_FADE_OUT_DURATION)
		transition_screen.change_scene(
			LEVEL_2_AFTER_SCENE_PATH,
			LEVEL_2_AFTER_TRANSITION_FADE_OUT_DURATION,
			LEVEL_2_AFTER_TRANSITION_FADE_IN_DURATION
		)
	else:
		get_tree().change_scene_to_file(LEVEL_2_AFTER_SCENE_PATH)


func _start_train_inside() -> void:
	if is_instance_valid(train_inside_player):
		return

	train_inside_player = AudioManager.play_level_2_train_inside(TRAIN_INSIDE_VOLUME)


func _fade_train_inside(duration: float) -> void:
	if not is_instance_valid(train_inside_player):
		return

	var tween := create_tween()
	tween.tween_property(train_inside_player, "volume_db", -80.0, duration)


func _stop_train_inside() -> void:
	if not is_instance_valid(train_inside_player):
		train_inside_player = null
		return

	train_inside_player.stop()
	train_inside_player.queue_free()
	train_inside_player = null


func _find_time_label() -> Label:
	var root_time_label := get_node_or_null("TimeLabel") as Label
	if root_time_label != null:
		return root_time_label

	var control_time_label := get_node_or_null("Control/TimeLabel") as Label
	if control_time_label != null:
		return control_time_label

	return get_node_or_null("CanvasLayer/TextureRect/TimeLabel") as Label


func _find_progress_goal_icon() -> Control:
	for icon_path in [
		"ProgressGoalLvl2/GoalIcon",
		"ProgressGoalLvl2/Icon",
		"ProgressGoalLvl2/TextureRect",
	]:
		var icon := get_node_or_null(icon_path) as Control
		if icon != null:
			return icon

	for child in $ProgressGoalLvl2.get_children():
		var icon := child as Control
		if icon != null:
			return icon

	return null


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


func _update_mob_spawner(delta: float) -> void:
	mob_spawn_time_left -= delta

	if mob_spawn_time_left > 0.0:
		return

	mob_spawn_time_left += MOB_SPAWN_INTERVAL
	_spawn_random_fart_mob()


func _spawn_random_fart_mob() -> void:
	var fart_scene: PackedScene = fart_scenes[randi() % fart_scenes.size()]
	var fart_mob := fart_scene.instantiate()

	fart_mob.global_position = Vector2(
		randf_range(40.0, 220.0),
		randf_range(260.0, 560.0)
	)
	fart_mob.popped.connect(_on_fart_mob_popped)
	add_child(fart_mob)


func _pop_fart_mob_at_global_position(global_point: Vector2) -> bool:
	var query := PhysicsPointQueryParameters2D.new()
	query.position = global_point
	query.collide_with_bodies = true
	query.collide_with_areas = false

	var results := get_world_2d().direct_space_state.intersect_point(query, 16)
	for result in results:
		var collider := result.get("collider") as Node
		if collider == null or not collider.is_in_group("fart_mobs"):
			continue

		if collider.has_method("pop_from_external_input"):
			collider.pop_from_external_input()
			return true

	return false


func _on_fart_mob_popped() -> void:
	if round_finished:
		return

	var bonus_coins: int = (GameState.tap_power + 1) * 10
	GameState.add_bonus_coins(bonus_coins)
	AudioManager.play_fart_mob_pop_sounds()


func _is_primary_press(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return event.pressed

	if event is InputEventMouseButton:
		return (
			event.pressed
			and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]
		)

	return false


func _get_input_global_position(event: InputEvent) -> Vector2:
	if event is InputEventScreenTouch:
		return get_global_transform_with_canvas().affine_inverse() * event.position

	if event is InputEventMouseButton:
		return get_global_mouse_position()

	return get_global_mouse_position()


func _spawn_tap_gain_effect(tap_position: Vector2, amount: int) -> void:
	var effect := TAP_GAIN_EFFECT_SCENE.instantiate() as Node2D
	effect.position = effects_layer.to_local(tap_position) + Vector2(randf_range(-14.0, 14.0), 5.0)
	effects_layer.add_child(effect)
	effect.call("setup", amount)


func _setup_shop_face_press_effects() -> void:
	for button_name in SHOP_FACE_BUTTON_PATHS:
		var button := get_node("ShopLvl2/VBoxContainer/" + button_name) as BaseButton
		var face := button.get_node(SHOP_FACE_BUTTON_PATHS[button_name]) as Node2D
		var text_group := button.get_node("TextGroup") as Control
		shop_face_start_positions[face] = face.position
		shop_button_text_group_start_positions[text_group] = text_group.position
		button.button_down.connect(_on_shop_face_button_down.bind(face))
		button.button_up.connect(_on_shop_face_button_up.bind(face))
		button.button_down.connect(_on_shop_button_text_down.bind(text_group))
		button.button_up.connect(_on_shop_button_text_up.bind(text_group))


func _on_shop_face_button_down(face: Node2D) -> void:
	var active_tween = shop_face_tweens.get(face) as Tween
	if active_tween != null and active_tween.is_running():
		active_tween.kill()

	face.position = shop_face_start_positions[face] + SHOP_FACE_PRESS_OFFSET


func _on_shop_face_button_up(face: Node2D) -> void:
	var active_tween = shop_face_tweens.get(face) as Tween
	if active_tween != null and active_tween.is_running():
		active_tween.kill()

	var return_tween := create_tween()
	shop_face_tweens[face] = return_tween
	return_tween.tween_property(
		face,
		"position",
		shop_face_start_positions[face],
		0.08
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _on_shop_button_text_down(text_group: Control) -> void:
	text_group.position = shop_button_text_group_start_positions[text_group] + SHOP_BUTTON_TEXT_PRESS_OFFSET


func _on_shop_button_text_up(text_group: Control) -> void:
	text_group.position = shop_button_text_group_start_positions[text_group]


func _setup_level_2_shop_buttons() -> void:
	for upgrade_id in SHOP_LEVEL_2_BUTTONS:
		var button := get_node(SHOP_LEVEL_2_BUTTONS[upgrade_id]) as TextureButton
		_store_shop_button_textures(button)
		if not button.pressed.is_connected(_on_level_2_shop_upgrade_pressed.bind(upgrade_id)):
			button.pressed.connect(_on_level_2_shop_upgrade_pressed.bind(upgrade_id))


func _reset_level_2_shop_state() -> void:
	level_2_shop_purchase_counts = {}
	level_2_shop_prices = {}
	level_2_shop_revealed = {}

	for upgrade_id in SHOP_LEVEL_2_BASE_PRICES:
		level_2_shop_purchase_counts[upgrade_id] = 0
		level_2_shop_prices[upgrade_id] = SHOP_LEVEL_2_BASE_PRICES[upgrade_id]
		level_2_shop_revealed[upgrade_id] = upgrade_id == "push_harder"


func _on_level_2_shop_upgrade_pressed(upgrade_id: String) -> void:
	if not _can_buy_level_2_upgrade(upgrade_id):
		return

	GameState.shitty_coins -= level_2_shop_prices[upgrade_id]
	GameState.tap_power += SHOP_LEVEL_2_TAP_POWER[upgrade_id]
	level_2_shop_purchase_counts[upgrade_id] += 1
	level_2_shop_prices[upgrade_id] = _calculate_level_2_upgrade_price(upgrade_id)
	_update_level_2_revealed_upgrades()

	GameState.coins_changed.emit(GameState.shitty_coins)
	GameState.tap_power_changed.emit(GameState.tap_power)
	_update_level_2_shop_buttons()


func _update_level_2_shop_buttons() -> void:
	_update_level_2_revealed_upgrades()

	for upgrade_id in SHOP_LEVEL_2_BUTTONS:
		var button := get_node(SHOP_LEVEL_2_BUTTONS[upgrade_id]) as TextureButton
		var text_group := button.get_node("TextGroup") as Control
		var price_label := button.get_node("TextGroup/Price") as Label
		var face_node := button.get_node(SHOP_FACE_BUTTON_PATHS[button.name]) as CanvasItem
		var is_revealed: bool = level_2_shop_revealed.get(upgrade_id, true)

		price_label.text = GameState.format_price(level_2_shop_prices[upgrade_id])
		text_group.visible = is_revealed
		face_node.visible = is_revealed
		_apply_shop_button_reveal_state(button, is_revealed)
		button.disabled = not is_revealed or not _can_buy_level_2_upgrade(upgrade_id)


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


func _can_buy_level_2_upgrade(upgrade_id: String) -> bool:
	return level_2_shop_revealed.get(upgrade_id, true) and GameState.shitty_coins >= level_2_shop_prices[upgrade_id]


func _update_level_2_revealed_upgrades() -> void:
	for upgrade_id in level_2_shop_revealed.keys():
		if level_2_shop_revealed[upgrade_id]:
			continue

		if GameState.shitty_coins >= SHOP_LEVEL_2_BASE_PRICES[upgrade_id]:
			level_2_shop_revealed[upgrade_id] = true


func _calculate_level_2_upgrade_price(upgrade_id: String) -> int:
	var base_price: int = SHOP_LEVEL_2_BASE_PRICES[upgrade_id]
	var growth: float = SHOP_LEVEL_2_PRICE_GROWTH[upgrade_id]
	var purchases: int = level_2_shop_purchase_counts[upgrade_id]

	return roundi(base_price * pow(growth, purchases))
