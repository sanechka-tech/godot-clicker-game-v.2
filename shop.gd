extends Node2D

@onready var coins_label: Label = $CanvasLayer/CoinsLabel

@onready var plunger_price_label: Label = $CanvasLayer/PlungerPrice
@onready var turbo_toilet_paper_price_label: Label = $CanvasLayer/TurboToiletPaperPrice
@onready var bathroom_reader_price_label: Label = $CanvasLayer/BathroomReaderPrice
@onready var golden_toilet_seat_price_label: Label = $CanvasLayer/GoldenToiletSeatPrice

@onready var plunger_button: Button = $"Button Plunger"
@onready var turbo_toilet_paper_button: Button = $"Button Turbo Toilet Paper"
@onready var bathroom_reader_button: Button = $"Button Bathroom Reader"
@onready var golden_toilet_seat_button: Button = $"Button Golden Toilet Seat"


func _ready() -> void:
	GameState.coins_changed.connect(_on_coins_changed)
	GameState.shop_changed.connect(_on_shop_changed)

	plunger_button.pressed.connect(_on_plunger_pressed)
	turbo_toilet_paper_button.pressed.connect(_on_turbo_toilet_paper_pressed)
	bathroom_reader_button.pressed.connect(_on_bathroom_reader_pressed)
	golden_toilet_seat_button.pressed.connect(_on_golden_toilet_seat_pressed)

	_update_ui()


func _on_plunger_pressed() -> void:
	GameState.buy_upgrade("plunger")


func _on_turbo_toilet_paper_pressed() -> void:
	GameState.buy_upgrade("turbo_toilet_paper")


func _on_bathroom_reader_pressed() -> void:
	GameState.buy_upgrade("bathroom_reader")


func _on_golden_toilet_seat_pressed() -> void:
	GameState.buy_upgrade("golden_toilet_seat")


func _on_coins_changed(_new_value: int) -> void:
	_update_ui()


func _on_shop_changed() -> void:
	_update_ui()


func _update_ui() -> void:
	coins_label.text = str(GameState.shitty_coins)

	plunger_price_label.text = str(GameState.upgrade_prices["plunger"])
	turbo_toilet_paper_price_label.text = str(GameState.upgrade_prices["turbo_toilet_paper"])
	bathroom_reader_price_label.text = str(GameState.upgrade_prices["bathroom_reader"])
	golden_toilet_seat_price_label.text = str(GameState.upgrade_prices["golden_toilet_seat"])

	plunger_button.disabled = not GameState.can_buy_upgrade("plunger")
	turbo_toilet_paper_button.disabled = not GameState.can_buy_upgrade("turbo_toilet_paper")
	bathroom_reader_button.disabled = not GameState.can_buy_upgrade("bathroom_reader")
	golden_toilet_seat_button.disabled = not GameState.can_buy_upgrade("golden_toilet_seat")


func _on_button_toilet_pressed() -> void:
	get_tree().change_scene_to_file("res://main_screen.tscn")
	


func _on_button_shop_pressed() -> void:
	get_tree().change_scene_to_file("res://shop.tscn")
