extends Parallax2D

@export var scroll_speed: float = 100.0

@onready var background_sprite: Sprite2D = $PixelartStarfield


func _ready() -> void:
	autoscroll = Vector2(0.0, scroll_speed)
	_update_repeat_size()


func _update_repeat_size() -> void:
	if background_sprite.texture == null:
		return

	var texture_size: Vector2 = background_sprite.texture.get_size()
	var scaled_size := Vector2(
		texture_size.x * background_sprite.scale.x,
		texture_size.y * background_sprite.scale.y
	)

	repeat_size = scaled_size
