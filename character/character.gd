extends CharacterBody2D
# Если твой Character является Area2D, замени строку выше на:
# extends Area2D
signal tapped(tap_position: Vector2)

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var tap_animation: StringName = &"tap"


func _ready() -> void:
	input_pickable = true
	
func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_on_tap(_event_to_world_position(event))

	if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		_on_tap(_event_to_world_position(event))


func _on_tap(tap_position: Vector2) -> void:
	animated_sprite.play(tap_animation)
	tapped.emit(tap_position)


func _event_to_world_position(event: InputEvent) -> Vector2:
	return get_canvas_transform().affine_inverse() * event.position
