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
		_on_tap(event.position)

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_tap(event.position)


func _on_tap(tap_position: Vector2) -> void:
	animated_sprite.play(tap_animation)
	tapped.emit(tap_position)
