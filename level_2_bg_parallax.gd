extends Node2D

@export var sky_scroll_speed: float = -28.0
@export var wood_scroll_speed: float = -64.0
@export var stolb_scroll_speed: float = -82.0

@onready var parallax_sky: Parallax2D = $Parallax2D_sky
@onready var parallax_wood: Parallax2D = $Parallax2D_wood
@onready var parallax_stolb: Parallax2D = $Parallax2D_stolb


func _ready() -> void:
	_setup_layer(parallax_sky, sky_scroll_speed)
	_setup_layer(parallax_wood, wood_scroll_speed)
	_setup_layer(parallax_stolb, stolb_scroll_speed)


func set_scroll_enabled(is_enabled: bool) -> void:
	_set_layer_scroll_enabled(parallax_sky, sky_scroll_speed, is_enabled)
	_set_layer_scroll_enabled(parallax_wood, wood_scroll_speed, is_enabled)
	_set_layer_scroll_enabled(parallax_stolb, stolb_scroll_speed, is_enabled)


func _setup_layer(layer: Parallax2D, scroll_speed: float) -> void:
	if layer == null:
		return

	layer.autoscroll = Vector2(scroll_speed, 0.0)
	layer.repeat_size = _calculate_repeat_size(layer)


func _set_layer_scroll_enabled(layer: Parallax2D, scroll_speed: float, is_enabled: bool) -> void:
	if layer == null:
		return

	layer.autoscroll = Vector2(scroll_speed, 0.0) if is_enabled else Vector2.ZERO


func _calculate_repeat_size(layer: Parallax2D) -> Vector2:
	var has_visual_child := false
	var min_corner := Vector2(INF, INF)
	var max_corner := Vector2(-INF, -INF)

	for child in layer.get_children():
		var sprite := child as Sprite2D
		if sprite == null or sprite.texture == null:
			continue

		has_visual_child = true

		var scaled_size := sprite.texture.get_size() * sprite.scale
		var half_size := scaled_size * 0.5
		var sprite_min := sprite.position - half_size
		var sprite_max := sprite.position + half_size

		min_corner.x = minf(min_corner.x, sprite_min.x)
		min_corner.y = minf(min_corner.y, sprite_min.y)
		max_corner.x = maxf(max_corner.x, sprite_max.x)
		max_corner.y = maxf(max_corner.y, sprite_max.y)

	if not has_visual_child:
		return Vector2.ZERO

	return max_corner - min_corner
