extends Node2D

@onready var character = $Character
@onready var coins_label: Label = $CanvasLayer/CoinsLabel


func _ready() -> void:
	character.tapped.connect(_on_character_tapped)
	GameState.coins_changed.connect(_on_coins_changed)

	_update_coins_label()


func _on_character_tapped() -> void:
	GameState.add_tap_coins()


func _on_coins_changed(new_value: int) -> void:
	_update_coins_label()


func _update_coins_label() -> void:
	coins_label.text = str(GameState.shitty_coins)
