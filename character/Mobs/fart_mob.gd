extends CharacterBody2D

signal popped

@export var move_speed: float = 200.0
@export var drift_up_speed: float = -30.0
@export var bob_height: float = 50.0
@export var bob_speed: float = 5.0
@export var right_despawn_x: float = 1400.0
@export var top_despawn_y: float = -120.0
@export var pop_animation: StringName = &"Death"
@export var speed_variation: float = 30.0
@export var drift_variation: float = 6.0
@export var startup_boost_seconds: float = 0.5

var _base_y: float
var _time: float = 0.0
var _is_popped := false
var _current_move_speed: float
var _current_drift_up_speed: float

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D
@onready var animated_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D


func _ready() -> void:
	input_pickable = true
	_base_y = global_position.y
	_time = randf() * TAU
	_current_move_speed = move_speed + randf_range(-speed_variation, speed_variation)
	_current_drift_up_speed = drift_up_speed + randf_range(-drift_variation, drift_variation)
	global_position.x += _current_move_speed * startup_boost_seconds
	add_to_group("fart_mobs")

	if animated_sprite != null:
		animated_sprite.visible = false
		animated_sprite.stop()
		animated_sprite.animation_finished.connect(_on_pop_animation_finished)


func _physics_process(delta: float) -> void:
	if _is_popped:
		return

	_time += delta * bob_speed

	global_position.x += _current_move_speed * delta
	_base_y += _current_drift_up_speed * delta
	global_position.y = _base_y + sin(_time) * bob_height

	if global_position.x > right_despawn_x or global_position.y < top_despawn_y:
		queue_free()


func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if _is_popped:
		return

	if event is InputEventScreenTouch and event.pressed:
		_pop()

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_pop()


func _pop() -> void:
	if _is_popped:
		return

	_is_popped = true
	popped.emit()
	input_pickable = false
	collision_shape.disabled = true

	if animated_sprite != null and animated_sprite.sprite_frames.has_animation(pop_animation):
		if sprite != null:
			sprite.visible = false

		animated_sprite.visible = true
		animated_sprite.play(pop_animation)
		return

	queue_free()


func _on_pop_animation_finished() -> void:
	if animated_sprite == null:
		return

	if animated_sprite.animation != pop_animation:
		return

	queue_free()
