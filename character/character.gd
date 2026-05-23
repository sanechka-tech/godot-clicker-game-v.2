extends CharacterBody2D
# Если твой Character является Area2D, замени строку выше на:
# extends Area2D
signal tapped(tap_position: Vector2)

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var tap_animation: StringName = &"tap"

var final_pose_locked := false


func _ready() -> void:
	input_pickable = true
	
func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_on_tap(_event_to_world_position(event))

	if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		_on_tap(_event_to_world_position(event))


func _on_tap(tap_position: Vector2) -> void:
	if final_pose_locked:
		return

	animated_sprite.play(tap_animation)
	tapped.emit(tap_position)


func lock_final_pose() -> void:
	final_pose_locked = true
	input_pickable = false
	animated_sprite.play(tap_animation)
	animated_sprite.set_frame_and_progress(1, 0.0)
	animated_sprite.pause()


func _event_to_world_position(event: InputEvent) -> Vector2:
	return get_canvas_transform().affine_inverse() * event.position
