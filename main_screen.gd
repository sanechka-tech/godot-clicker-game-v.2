extends Node2D

@onready var character = $Character
@onready var coins_label: Label = $CanvasLayer/CoinsLabel
@onready var progress_goal: Range = $ProgressGoal


func _ready() -> void:
	character.tapped.connect(_on_character_tapped)
	GameState.coins_changed.connect(_on_coins_changed)
	GameState.score_changed.connect(_on_score_changed)

	_update_coins_label()
	_setup_goal_progress()
	_update_goal_progress()


func _on_character_tapped() -> void:
	GameState.add_tap_coins()


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
