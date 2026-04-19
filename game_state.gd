extends Node

signal coins_changed(new_value: int)
signal tap_power_changed(new_value: int)
signal shop_changed

var shitty_coins: int = 0
var tap_power: int = 1

var price_step: int = 25

var upgrade_prices := {
	"golden_toilet_seat": 200,
	"bathroom_reader": 100,
	"turbo_toilet_paper": 75,
	"plunger": 50,
}


func add_tap_coins() -> void:
	shitty_coins += tap_power
	coins_changed.emit(shitty_coins)


func can_buy_upgrade(upgrade_id: String) -> bool:
	return shitty_coins >= upgrade_prices[upgrade_id]


func buy_upgrade(upgrade_id: String) -> bool:
	if not can_buy_upgrade(upgrade_id):
		return false

	shitty_coins -= upgrade_prices[upgrade_id]
	tap_power += 1
	upgrade_prices[upgrade_id] += price_step

	coins_changed.emit(shitty_coins)
	tap_power_changed.emit(tap_power)
	shop_changed.emit()

	return true
