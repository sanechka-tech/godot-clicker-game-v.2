extends Node2D

const ROUND_DURATION_SECONDS := 300.0
const LEVEL_GOAL_SCORE := 325000
const MOB_SPAWN_INTERVAL := 5.0
const TAP_GAIN_EFFECT_SCENE := preload("res://tap_gain_effect.tscn")
const PROGRESS_GOAL_ICON_TRACK_START_OFFSET := 0.0
const PROGRESS_GOAL_ICON_TRACK_END_OFFSET := 0.0
const PROGRESS_GOAL_ICON_OFFSET := Vector2.ZERO

const FART_1_SCENE := preload("res://character/Mobs/Fart1.tscn")
const FART_2_SCENE := preload("res://character/Mobs/Fart2.tscn")
const FART_3_SCENE := preload("res://character/Mobs/Fart3.tscn")

@onready var character = $Character
@onready var coins_label: Label = $Counter/CoinsCounter2/Label
@onready var time_label: Label = _find_time_label()
@onready var progress_goal: Range = $ProgressGoalLvl2
@onready var progress_goal_icon: Control = _find_progress_goal_icon()
@onready var effects_layer: Node2D = $TapEffects
@onready var level_2_win: CanvasItem = $Lvl2Win
@onready var level_2_lose: CanvasItem = $Lvl2Lose
@onready var level_2_retry_button: BaseButton = $Lvl2Lose/Lvl2Retry
@onready var level_2_passed_button: BaseButton = $Lvl2Win/Lvl2Passed

var time_left_seconds := ROUND_DURATION_SECONDS
var round_finished := false
var mob_spawn_time_left := MOB_SPAWN_INTERVAL

var fart_scenes := [
	FART_1_SCENE,
	FART_2_SCENE,
	FART_3_SCENE,
]


func _ready() -> void:
	AudioManager.play_default_music()

	GameState.start_level(LEVEL_GOAL_SCORE)

	character.tapped.connect(_on_character_tapped)
	GameState.coins_changed.connect(_on_coins_changed)
	GameState.score_changed.connect(_on_score_changed)
	level_2_retry_button.pressed.connect(_on_lvl_2_retry_pressed)
	level_2_passed_button.pressed.connect(_on_lvl_2_passed_pressed)

	_hide_round_result_panels()
	_setup_goal_progress()
	_update_coins_label()
	_update_time_label()
	_update_goal_progress()


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


func _on_character_tapped(tap_position: Vector2) -> void:
	if round_finished:
		return

	var tap_gain := GameState.add_tap_coins()
	_spawn_tap_gain_effect(tap_position, tap_gain)


func _on_coins_changed(_new_value: int) -> void:
	_update_coins_label()


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
	progress_goal.value = min(GameState.score, LEVEL_GOAL_SCORE)
	_update_goal_icon()


func _hide_round_result_panels() -> void:
	level_2_win.visible = false
	level_2_lose.visible = false


func _finish_round(did_win: bool) -> void:
	if round_finished:
		return

	round_finished = true
	level_2_win.visible = did_win
	level_2_lose.visible = not did_win

	for fart_mob in get_tree().get_nodes_in_group("fart_mobs"):
		fart_mob.queue_free()


func _on_lvl_2_retry_pressed() -> void:
	get_tree().reload_current_scene()


func _on_lvl_2_passed_pressed() -> void:
	pass


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


func _on_fart_mob_popped() -> void:
	if round_finished:
		return

	var bonus_coins := (GameState.tap_power + 1) * 10
	GameState.add_bonus_coins(bonus_coins)
	AudioManager.play_fart_mob_pop_sounds()


func _spawn_tap_gain_effect(tap_position: Vector2, amount: int) -> void:
	var effect := TAP_GAIN_EFFECT_SCENE.instantiate() as Node2D
	effect.position = effects_layer.to_local(tap_position) + Vector2(randf_range(-14.0, 14.0), 5.0)
	effects_layer.add_child(effect)
	effect.call("setup", amount)
