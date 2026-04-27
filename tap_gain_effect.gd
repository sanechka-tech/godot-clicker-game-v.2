extends Node2D

const COIN_TEXT_GAP := 18.0

@onready var amount_label: Label = $AmountLabel
@onready var coin: AnimatedSprite2D = $Coin


func setup(amount: int) -> void:
	amount_label.text = str(amount)
	_update_coin_position()


func _ready() -> void:
	coin.play(&"spin")
	_update_coin_position()

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", position + Vector2(0.0, -16.0), 0.75).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.16, 1.16), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.3).set_delay(0.45)
	tween.finished.connect(queue_free)


func _update_coin_position() -> void:
	var font := amount_label.label_settings.font
	var font_size := amount_label.label_settings.font_size

	if font == null:
		font = amount_label.get_theme_font("font")
		font_size = amount_label.get_theme_font_size("font_size")

	var text_size := font.get_string_size(
		amount_label.text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size
	)

	coin.position.x = amount_label.position.x + text_size.x + COIN_TEXT_GAP
