extends Area2D

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D

var direction := Vector2.ZERO
var speed := 700.0
var damage := 1
var target_group: StringName = &"mini_enemies"
var active := false
var min_y_limit := -10000.0
var max_y_limit := 10000.0


func _ready() -> void:
	monitoring = true
	monitorable = true
	body_entered.connect(_on_body_entered)


func setup(
	start_position: Vector2,
	projectile_direction: Vector2,
	projectile_speed: float,
	projectile_damage: int,
	projectile_target_group: StringName,
	projectile_texture: Texture2D,
	projectile_scale: Vector2 = Vector2.ONE,
	projectile_min_y_limit: float = -10000.0,
	projectile_max_y_limit: float = 10000.0
) -> void:
	global_position = start_position
	direction = projectile_direction.normalized()
	speed = projectile_speed
	damage = projectile_damage
	target_group = projectile_target_group
	sprite.texture = projectile_texture
	sprite.scale = projectile_scale
	min_y_limit = projectile_min_y_limit
	max_y_limit = projectile_max_y_limit
	add_to_group("mini_projectiles")
	if target_group == &"mini_player":
		add_to_group("mini_enemy_projectiles")
	_configure_collision()
	active = true


func _process(delta: float) -> void:
	if not active:
		return

	global_position += direction * speed * delta

	if global_position.y < min_y_limit or global_position.y > max_y_limit or _is_outside_screen_bounds():
		queue_free()


func _on_body_entered(body: Node) -> void:
	if not active:
		return

	if not body.is_in_group(target_group):
		return

	if body.has_method("take_damage"):
		body.take_damage(damage)

	queue_free()


func _is_outside_screen_bounds() -> bool:
	var rect := get_viewport().get_visible_rect().grow(120.0)
	return not rect.has_point(global_position)


func _configure_collision() -> void:
	for layer in range(1, 5):
		set_collision_layer_value(layer, false)
		set_collision_mask_value(layer, false)

	set_collision_layer_value(4, true)

	match target_group:
		&"mini_enemies":
			set_collision_mask_value(3, true)
		&"mini_player":
			set_collision_mask_value(2, true)
