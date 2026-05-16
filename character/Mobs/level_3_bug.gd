extends CharacterBody2D

signal reached_target(bug: CharacterBody2D)
signal squashed(bug: CharacterBody2D)

const ANIMATION_MOVE_LEFT := &"moves_left"
const ANIMATION_MOVE_RIGHT := &"moves_right"
const ANIMATION_TOWARD_CHARACTER := &"moves_toward_character"
const ANIMATION_DIES := &"dies"

@export var bug_kind: StringName = &"bug"
@export var flip_moves_left: bool = false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var move_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var death_sprite: AnimatedSprite2D = $AnimatedSprite2D/AnimatedSprite2D

var play_area := Rect2()
var target_points: Array[Vector2] = []
var horizontal_speed: float = 60.0
var vertical_speed: float = 60.0
var alignment_threshold: float = 24.0
var reach_radius: float = 42.0
var mixed_movement: bool = true
var is_active := false
var is_dying := false


func _ready() -> void:
	input_pickable = true

	if death_sprite != null:
		death_sprite.reparent(self, true)
		if death_sprite.sprite_frames != null and death_sprite.sprite_frames.has_animation(ANIMATION_DIES):
			death_sprite.sprite_frames.set_animation_loop(ANIMATION_DIES, false)
		death_sprite.visible = false
		death_sprite.stop()

	_update_animation_flip()
	move_sprite.animation_changed.connect(_on_animation_changed)


func configure(config: Dictionary, level_play_area: Rect2, level_target_points: Array[Vector2]) -> void:
	play_area = level_play_area
	target_points = level_target_points
	horizontal_speed = float(config.get("horizontal_speed", horizontal_speed))
	vertical_speed = float(config.get("vertical_speed", vertical_speed))
	alignment_threshold = float(config.get("alignment_threshold", alignment_threshold))
	reach_radius = float(config.get("reach_radius", reach_radius))
	mixed_movement = bool(config.get("mixed_movement", mixed_movement))
	is_active = true
	is_dying = false

	move_sprite.visible = true
	move_sprite.play(ANIMATION_TOWARD_CHARACTER)
	_update_animation_flip()

	if death_sprite != null:
		death_sprite.visible = false
		death_sprite.stop()

	if collision_shape != null:
		collision_shape.set_deferred("disabled", false)


func get_bug_kind() -> StringName:
	return bug_kind


func _physics_process(delta: float) -> void:
	if not is_active or is_dying or target_points.is_empty():
		return

	var target_point := _get_nearest_target_point()
	var movement := _calculate_movement(target_point, delta)

	global_position += movement
	_clamp_to_play_area()
	_update_movement_animation(movement)

	if global_position.distance_to(target_point) <= reach_radius:
		_reach_target()


func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if is_dying or not is_active:
		return

	if event is InputEventScreenTouch and event.pressed:
		_squash()
		return

	if event is InputEventMouseButton \
	and event.pressed \
	and event.button_index == MOUSE_BUTTON_LEFT:
		_squash()


func _calculate_movement(target_point: Vector2, delta: float) -> Vector2:
	var delta_to_target := target_point - global_position
	var horizontal_distance := delta_to_target.x
	var vertical_distance := maxf(delta_to_target.y, 0.0)
	var movement := Vector2.ZERO

	if mixed_movement:
		if absf(horizontal_distance) > alignment_threshold:
			movement.x = signf(horizontal_distance) * horizontal_speed * delta

		if vertical_distance > 0.0:
			movement.y = minf(vertical_distance, vertical_speed * delta)
	else:
		if absf(horizontal_distance) > alignment_threshold:
			movement.x = signf(horizontal_distance) * horizontal_speed * delta
		elif vertical_distance > 0.0:
			movement.y = minf(vertical_distance, vertical_speed * delta)

	return movement


func _update_movement_animation(movement: Vector2) -> void:
	if move_sprite == null or not is_active or is_dying:
		return

	if absf(movement.x) > absf(movement.y) and absf(movement.x) > 0.01:
		if movement.x < 0.0:
			_play_move_animation(ANIMATION_MOVE_LEFT)
		else:
			_play_move_animation(ANIMATION_MOVE_RIGHT)
		return

	if movement.y > 0.01:
		_play_move_animation(ANIMATION_TOWARD_CHARACTER)


func _play_move_animation(animation_name: StringName) -> void:
	if move_sprite.animation == animation_name and move_sprite.is_playing():
		return

	move_sprite.play(animation_name)
	_update_animation_flip()


func _update_animation_flip() -> void:
	if move_sprite == null:
		return

	move_sprite.flip_h = flip_moves_left and move_sprite.animation == ANIMATION_MOVE_LEFT


func _on_animation_changed() -> void:
	_update_animation_flip()


func _get_nearest_target_point() -> Vector2:
	var nearest_target := target_points[0]
	var nearest_distance := global_position.distance_squared_to(nearest_target)

	for i in range(1, target_points.size()):
		var candidate := target_points[i]
		var candidate_distance := global_position.distance_squared_to(candidate)

		if candidate_distance < nearest_distance:
			nearest_target = candidate
			nearest_distance = candidate_distance

	return nearest_target


func _clamp_to_play_area() -> void:
	var body_radius := _get_body_radius()
	var min_x := play_area.position.x + body_radius
	var max_x := play_area.end.x - body_radius
	var min_y := play_area.position.y + body_radius
	var max_y := play_area.end.y - body_radius

	global_position.x = clampf(global_position.x, min_x, max_x)
	global_position.y = clampf(global_position.y, min_y, max_y)


func _get_body_radius() -> float:
	if collision_shape == null:
		return 24.0

	var shape := collision_shape.shape
	if shape is CapsuleShape2D:
		return (shape as CapsuleShape2D).radius

	if shape is CircleShape2D:
		return (shape as CircleShape2D).radius

	if shape is RectangleShape2D:
		var rectangle_shape := shape as RectangleShape2D
		return maxf(rectangle_shape.size.x, rectangle_shape.size.y) * 0.5

	return 24.0


func _reach_target() -> void:
	if not is_active or is_dying:
		return

	is_active = false

	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)

	reached_target.emit(self)
	call_deferred("queue_free")


func _squash() -> void:
	if not is_active or is_dying:
		return

	is_active = false
	is_dying = true

	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)

	squashed.emit(self)
	move_sprite.stop()
	move_sprite.visible = false

	if death_sprite == null:
		call_deferred("queue_free")
		return

	death_sprite.visible = true
	if death_sprite.sprite_frames != null and death_sprite.sprite_frames.has_animation(ANIMATION_DIES):
		death_sprite.sprite_frames.set_animation_loop(ANIMATION_DIES, false)
		death_sprite.play(ANIMATION_DIES)
		death_sprite.animation_finished.connect(_on_death_animation_finished, CONNECT_ONE_SHOT)
		return

	call_deferred("queue_free")


func _on_death_animation_finished() -> void:
	call_deferred("queue_free")
