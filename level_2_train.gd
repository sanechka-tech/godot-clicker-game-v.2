extends Node2D

const ROUND_DURATION_SECONDS := 300.0
const LEVEL_GOAL_SCORE := 216000

@onready var character = $Character
@onready var coins_label: Label = $CanvasLayer/CoinsLabel
@onready var time_label: Label = $CanvasLayer/TextureRect/TimeLabel
@onready var progress_goal: Range = $ProgressGoalLvl2
@onready var level_2_win: CanvasItem = $Lvl2Win
@onready var level_2_lose: CanvasItem = $Lvl2Lose
@onready var level_2_retry_button: BaseButton = $Lvl2Lose/Lvl2Retry
@onready var level_2_passed_button: BaseButton = $Lvl2Win/Lvl2Passed

var time_left_seconds := ROUND_DURATION_SECONDS
var round_finished := false


func _ready() -> void:
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

	if GameState.score >= LEVEL_GOAL_SCORE:
		_finish_round(true)
		return

	if time_left_seconds <= 0.0:
		_finish_round(false)


func _on_character_tapped() -> void:
	if round_finished:
		return

	GameState.add_tap_coins()


func _on_coins_changed(_new_value: int) -> void:
	_update_coins_label()


func _on_score_changed(_new_value: int) -> void:
	_update_goal_progress()

	if GameState.score >= LEVEL_GOAL_SCORE:
		_finish_round(true)


func _update_coins_label() -> void:
	coins_label.text = GameState.format_number(GameState.shitty_coins)


func _update_time_label() -> void:
	var total_seconds := ceili(time_left_seconds)
	var minutes := int(total_seconds / 60)
	var seconds := int(total_seconds % 60)

	time_label.text = "%02d:%02d" % [minutes, seconds]


func _setup_goal_progress() -> void:
	progress_goal.min_value = 0
	progress_goal.max_value = LEVEL_GOAL_SCORE


func _update_goal_progress() -> void:
	progress_goal.value = min(GameState.score, LEVEL_GOAL_SCORE)


func _hide_round_result_panels() -> void:
	level_2_win.visible = false
	level_2_lose.visible = false


func _finish_round(did_win: bool) -> void:
	if round_finished:
		return

	round_finished = true
	level_2_win.visible = did_win
	level_2_lose.visible = not did_win


func _on_lvl_2_retry_pressed() -> void:
	get_tree().reload_current_scene()


func _on_lvl_2_passed_pressed() -> void:
	pass
