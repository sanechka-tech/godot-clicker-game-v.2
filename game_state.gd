extends Node

signal coins_changed(new_value: int)
signal score_changed(new_value: int)
signal tap_power_changed(new_value: int)
signal passive_score_per_second_changed(new_value: int)
signal shop_changed

var shitty_coins: int = 0
var score: int = 0
var tap_power: int = 1
var passive_score_per_second: int = 0
var score_goal: int = 1000000
var _passive_score_buffer: float = 0.0

var upgrade_purchase_counts := {
	"golden_toilet_seat": 0,
	"bathroom_reader": 0,
	"turbo_toilet_paper": 0,
	"plunger": 0,
}

var upgrade_base_prices := {
	"golden_toilet_seat": 5000,
	"bathroom_reader": 900,
	"turbo_toilet_paper": 80,
	"plunger": 25,
}

var upgrade_price_growth := {
	"golden_toilet_seat": 1.18,
	"bathroom_reader": 1.17,
	"turbo_toilet_paper": 1.14,
	"plunger": 1.12,
}

var upgrade_prices := {
	"golden_toilet_seat": 5000,
	"bathroom_reader": 900,
	"turbo_toilet_paper": 80,
	"plunger": 25,
}

var upgrade_effects := {
	"golden_toilet_seat": {
		"tap_power": 0,
		"passive_score_per_second": 900,
	},
	"bathroom_reader": {
		"tap_power": 0,
		"passive_score_per_second": 180,
	},
	"turbo_toilet_paper": {
		"tap_power": 0,
		"passive_score_per_second": 25,
	},
	"plunger": {
		"tap_power": 1,
		"passive_score_per_second": 0,
	},
}


func _process(delta: float) -> void:
	if passive_score_per_second <= 0:
		return

	_passive_score_buffer += passive_score_per_second * delta
	var score_to_add := floori(_passive_score_buffer)

	if score_to_add <= 0:
		return

	_passive_score_buffer -= score_to_add
	_add_score(score_to_add)


func add_tap_coins() -> void:
	var tap_gain := tap_power + 1

	_add_score(tap_gain)
	shitty_coins += tap_gain
	coins_changed.emit(shitty_coins)


func can_buy_upgrade(upgrade_id: String) -> bool:
	return shitty_coins >= upgrade_prices[upgrade_id]


func buy_upgrade(upgrade_id: String) -> bool:
	if not can_buy_upgrade(upgrade_id):
		return false

	shitty_coins -= upgrade_prices[upgrade_id]
	var upgrade_effect: Dictionary = upgrade_effects[upgrade_id]

	var tap_power_bonus: int = upgrade_effect["tap_power"]
	var passive_score_bonus: int = upgrade_effect["passive_score_per_second"]

	tap_power += tap_power_bonus
	passive_score_per_second += passive_score_bonus
	upgrade_purchase_counts[upgrade_id] += 1
	upgrade_prices[upgrade_id] = _calculate_upgrade_price(upgrade_id)

	coins_changed.emit(shitty_coins)
	tap_power_changed.emit(tap_power)
	passive_score_per_second_changed.emit(passive_score_per_second)
	shop_changed.emit()

	return true


func _add_score(amount: int) -> void:
	score += amount
	score_changed.emit(score)


func _calculate_upgrade_price(upgrade_id: String) -> int:
	var base_price: int = upgrade_base_prices[upgrade_id]
	var growth: float = upgrade_price_growth[upgrade_id]
	var purchases: int = upgrade_purchase_counts[upgrade_id]

	return roundi(base_price * pow(growth, purchases))
