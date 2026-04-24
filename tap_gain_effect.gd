extends Node2D

@onready var amount_label: Label = $AmountLabel
@onready var coin: AnimatedSprite2D = $Coin


func setup(amount: int) -> void:
	amount_label.text = str(amount)


func _ready() -> void:
	coin.play(&"spin")

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", position + Vector2(0.0, -16.0), 0.75).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.16, 1.16), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.3).set_delay(0.45)
	tween.finished.connect(queue_free)
