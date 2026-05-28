extends Node

signal coins_changed(new_value: int)
signal score_changed(new_value: int)
signal tap_power_changed(new_value: int)
signal passive_score_per_second_changed(new_value: int)
signal shop_changed

const SAVE_FILE_PATH := "user://save_game.json"
const SAVE_VERSION := 1

var shitty_coins: int = 0
var score: int = 0
var tap_power: int = 100000
var passive_score_per_second: int = 0
var score_goal: int = 1000000
var mini_game_after_story_key: StringName = &"STORY_LVL2_MINIGAME_WIN"
var _passive_income_buffer: float = 0.0

var upgrade_purchase_counts := {
	"spread_the_cheeks": 0,
	"scroll_tiktok": 0,
	"run_the_tap": 0,
	"use_an_enema": 0,
}

var upgrade_base_prices := {
	"spread_the_cheeks": 125,
	"scroll_tiktok": 400,
	"run_the_tap": 4500,
	"use_an_enema": 25000,
}

var upgrade_price_growth := {
	"spread_the_cheeks": 1.12,
	"scroll_tiktok": 1.14,
	"run_the_tap": 1.17,
	"use_an_enema": 1.18,
}

var upgrade_prices := {
	"spread_the_cheeks": 125,
	"scroll_tiktok": 400,
	"run_the_tap": 4500,
	"use_an_enema": 25000,
}

var upgrade_revealed := {
	"spread_the_cheeks": true,
	"scroll_tiktok": false,
	"run_the_tap": false,
	"use_an_enema": false,
}

var upgrade_effects := {
	"spread_the_cheeks": {
		"tap_power": 1,
		"passive_score_per_second": 0,
	},
	"scroll_tiktok": {
		"tap_power": 0,
		"passive_score_per_second": 25,
	},
	"run_the_tap": {
		"tap_power": 0,
		"passive_score_per_second": 180,
	},
	"use_an_enema": {
		"tap_power": 0,
		"passive_score_per_second": 900,
	},
}


func _process(delta: float) -> void:
	if passive_score_per_second <= 0:
		return

	_passive_income_buffer += passive_score_per_second * delta
	var income_to_add := floori(_passive_income_buffer)

	if income_to_add <= 0:
		return

	_passive_income_buffer -= income_to_add
	_add_score(income_to_add)
	shitty_coins += income_to_add
	var shop_visibility_changed := _update_revealed_upgrades()
	coins_changed.emit(shitty_coins)
	if shop_visibility_changed:
		shop_changed.emit()


func add_tap_coins() -> int:
	var tap_gain := tap_power + 1

	_add_score(tap_gain)
	shitty_coins += tap_gain
	var shop_visibility_changed := _update_revealed_upgrades()
	coins_changed.emit(shitty_coins)
	if shop_visibility_changed:
		shop_changed.emit()

	return tap_gain


func can_buy_upgrade(upgrade_id: String) -> bool:
	return is_upgrade_revealed(upgrade_id) and shitty_coins >= upgrade_prices[upgrade_id]


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


func is_upgrade_revealed(upgrade_id: String) -> bool:
	return upgrade_revealed.get(upgrade_id, true)


func _update_revealed_upgrades() -> bool:
	var has_changes := false

	for upgrade_id in upgrade_revealed.keys():
		if upgrade_revealed[upgrade_id]:
			continue

		if shitty_coins >= upgrade_base_prices[upgrade_id]:
			upgrade_revealed[upgrade_id] = true
			has_changes = true

	return has_changes


func format_number(value: int) -> String:
	if value >= 1000000:
		return _format_compact_number(value / 1000000.0, 2) + "m"

	if value >= 1000:
		return _format_compact_number(value / 1000.0, 2) + "k"

	return str(value)


func format_price(value: int) -> String:
	if value >= 1000000:
		return _format_compact_number(value / 1000000.0, 1) + "m"

	if value >= 1000:
		return _format_compact_number(value / 1000.0, 1) + "k"

	return str(value)


func _format_compact_number(value: float, decimal_places: int) -> String:
	var step := pow(10.0, -decimal_places)
	var rounded_value := snappedf(value, step)
	var formatted_value := "%.*f" % [decimal_places, rounded_value]

	while formatted_value.ends_with("0"):
		formatted_value = formatted_value.left(formatted_value.length() - 1)

	if formatted_value.ends_with("."):
		formatted_value = formatted_value.left(formatted_value.length() - 1)

	return formatted_value


func add_bonus_coins(amount: int) -> void:
	shitty_coins += amount
	var shop_visibility_changed := _update_revealed_upgrades()
	coins_changed.emit(shitty_coins)
	if shop_visibility_changed:
		shop_changed.emit()


func add_score(amount: int) -> void:
	if amount <= 0:
		return

	_add_score(amount)


func remove_score(amount: int) -> void:
	if amount <= 0:
		return

	score = maxi(score - amount, 0)
	score_changed.emit(score)


func start_level(new_score_goal: int) -> void:
	shitty_coins = 0
	score = 0
	tap_power = 0
	passive_score_per_second = 0
	score_goal = new_score_goal
	_passive_income_buffer = 0.0

	for upgrade_id in upgrade_purchase_counts.keys():
		upgrade_purchase_counts[upgrade_id] = 0
		upgrade_prices[upgrade_id] = upgrade_base_prices[upgrade_id]

	for upgrade_id in upgrade_revealed.keys():
		upgrade_revealed[upgrade_id] = upgrade_id == "spread_the_cheeks"

	coins_changed.emit(shitty_coins)
	score_changed.emit(score)
	tap_power_changed.emit(tap_power)
	passive_score_per_second_changed.emit(passive_score_per_second)
	shop_changed.emit()


func save_progress(scene_path: String) -> bool:
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		return false

	var save_data := {
		"version": SAVE_VERSION,
		"scene_path": scene_path,
	}
	var save_file := FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if save_file == null:
		push_warning("Could not open save file for writing: %s" % FileAccess.get_open_error())
		return false

	save_file.store_string(JSON.stringify(save_data))
	return true


func has_save() -> bool:
	var scene_path := get_saved_scene_path()
	return not scene_path.is_empty()


func get_saved_scene_path() -> String:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		return ""

	var save_file := FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if save_file == null:
		return ""

	var parsed_data = JSON.parse_string(save_file.get_as_text())
	if not (parsed_data is Dictionary):
		return ""

	var scene_path := str(parsed_data.get("scene_path", ""))
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		return ""

	return scene_path


func clear_progress() -> void:
	if FileAccess.file_exists(SAVE_FILE_PATH):
		var user_dir := DirAccess.open("user://")
		if user_dir != null:
			user_dir.remove("save_game.json")
