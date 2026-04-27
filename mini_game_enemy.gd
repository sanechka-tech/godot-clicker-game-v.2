extends CharacterBody2D

signal defeated(enemy_role: StringName)

const ENEMY_PROJECTILE_SCENE := preload("res://mini_projectile.tscn")
const ENEMY_PROJECTILE_SPRITESHEET := preload("res://Images/MiniGame/SpaceEnemy/Kla'ed/Projectiles/PNGs/Kla'ed - Torpedo.png")

@export var enemy_role: StringName = &"weak"
@export var min_x: float = 400.0
@export var max_x: float = 870.0
@export var min_y: float = 201.0
@export var max_y: float = 479.0
@export var projectile_max_y: float = 479.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var main_sprite: AnimatedSprite2D = $AnimatedSprite2D

var player: CharacterBody2D
var active := false
var dying := false
var max_hp := 1
var current_hp := 1
var move_speed := 88.0
var shots_per_second := 0.0
var projectile_speed := 380.0
var projectile_damage := 1
var ram_damage := 0
var movement_target := Vector2.ZERO
var movement_target_cooldown := 0.0
var shoot_cooldown := 0.0
var shoot_flash_time_left := 0.0
var shoot_visual: AnimatedSprite2D
var damage_animation_name := StringName()


func _ready() -> void:
	set_collision_layer_value(3, true)
	set_collision_mask_value(2, true)
	main_sprite.animation_finished.connect(_on_main_sprite_animation_finished)

	if not visible and get_parent() != null and get_parent().name == "MiniGame":
		collision_shape.set_deferred("disabled", true)

	shoot_visual = _find_shoot_visual()
	if shoot_visual != null:
		shoot_visual.visible = false

	damage_animation_name = _find_animation_name(main_sprite, "damaged")


func activate(spawn_position: Vector2, player_node: CharacterBody2D) -> void:
	player = player_node
	global_position = spawn_position
	visible = true
	active = true
	dying = false
	collision_shape.set_deferred("disabled", false)
	_setup_role_stats()
	_play_fly_animation()
	_play_move_visual()

	shoot_cooldown = 1.0 / maxf(shots_per_second, 1.0) if shots_per_second > 0.0 else 0.0
	shoot_flash_time_left = 0.0
	movement_target_cooldown = 0.0
	movement_target = global_position

	add_to_group("mini_enemies")
	if enemy_role == &"boss":
		add_to_group("mini_boss")


func _process(delta: float) -> void:
	if not active or dying:
		return

	if shoot_flash_time_left > 0.0:
		shoot_flash_time_left = maxf(shoot_flash_time_left - delta, 0.0)
		if shoot_flash_time_left <= 0.0 and shoot_visual != null:
			shoot_visual.visible = false

	match enemy_role:
		&"weak":
			_process_weak_enemy(delta)
		&"medium", &"boss":
			_process_shooting_enemy(delta)


func take_damage(amount: int) -> void:
	if not active or dying:
		return

	current_hp -= amount
	if current_hp <= 0:
		_die()
		return

	_play_damage_feedback()


func _process_weak_enemy(delta: float) -> void:
	if player == null:
		return

	var direction := (player.global_position - global_position).normalized()
	global_position += direction * move_speed * delta

	if global_position.distance_to(player.global_position) <= 28.0:
		if player.has_method("take_damage"):
			player.take_damage(ram_damage)
		_die()


func _process_shooting_enemy(delta: float) -> void:
	movement_target_cooldown -= delta
	if movement_target_cooldown <= 0.0:
		movement_target_cooldown = randf_range(0.8, 1.4)
		movement_target = Vector2(
			randf_range(min_x, max_x),
			global_position.y
		)

	global_position.x = move_toward(global_position.x, movement_target.x, move_speed * delta)
	global_position.y = clampf(global_position.y, min_y, max_y)

	shoot_cooldown -= delta
	if shoot_cooldown <= 0.0:
		shoot_cooldown += 1.0 / shots_per_second
		_fire_projectile()


func _setup_role_stats() -> void:
	match enemy_role:
		&"weak":
			max_hp = 1
			move_speed = 78.0
			shots_per_second = 0.0
			ram_damage = 1
		&"medium":
			max_hp = 2
			move_speed = 58.0
			shots_per_second = 0.7
			ram_damage = 0
		&"boss":
			max_hp = 30
			move_speed = 52.5
			shots_per_second = 1.0
			ram_damage = 0

	current_hp = max_hp


func _fire_projectile() -> void:
	if player == null or not is_instance_valid(player) or not player.visible:
		return

	var projectile_texture := _make_projectile_texture()
	var projectile_directions: Array[Vector2] = [Vector2.DOWN]
	if enemy_role == &"boss":
		projectile_directions = [
			Vector2.DOWN,
			Vector2(-0.35, 1.0).normalized(),
			Vector2(0.35, 1.0).normalized(),
		]

	for projectile_direction in projectile_directions:
		var projectile := ENEMY_PROJECTILE_SCENE.instantiate()
		get_tree().current_scene.add_child(projectile)
		projectile.call(
			"setup",
			global_position + Vector2(0.0, 28.0),
			projectile_direction,
			projectile_speed,
			projectile_damage,
			&"mini_player",
			projectile_texture,
			Vector2(1.0, 1.0),
			-10000.0,
			projectile_max_y
		)

	if shoot_visual != null:
		shoot_visual.visible = true
		shoot_flash_time_left = 0.18
		var shoot_animation := _find_animation_name(shoot_visual, "shoot")
		if shoot_animation != StringName():
			shoot_visual.play(shoot_animation)


func _die() -> void:
	if dying:
		return

	active = false
	dying = true
	collision_shape.set_deferred("disabled", true)
	remove_from_group("mini_enemies")
	remove_from_group("mini_boss")
	defeated.emit(enemy_role)

	var death_animation := _find_animation_name(main_sprite, "die")
	if death_animation == StringName():
		death_animation = _find_animation_name(main_sprite, "dies")

	if death_animation != StringName():
		main_sprite.animation_finished.connect(_on_death_animation_finished, CONNECT_ONE_SHOT)
		main_sprite.play(death_animation)
		return

	queue_free()


func _on_death_animation_finished() -> void:
	queue_free()


func _on_main_sprite_animation_finished() -> void:
	if dying:
		return

	if damage_animation_name == StringName():
		return

	if main_sprite.animation != damage_animation_name:
		return

	_play_fly_animation()


func _play_fly_animation() -> void:
	var fly_animation := _find_animation_name(main_sprite, "fly")
	if fly_animation != StringName():
		main_sprite.play(fly_animation)


func _play_damage_feedback() -> void:
	if damage_animation_name == StringName():
		return

	main_sprite.play(damage_animation_name)


func _play_move_visual() -> void:
	var move_visual := _find_child_animation_sprite("move")
	if move_visual != null:
		var move_animation := _find_animation_name(move_visual, "move")
		if move_animation != StringName():
			move_visual.play(move_animation)


func _find_shoot_visual() -> AnimatedSprite2D:
	return _find_child_animation_sprite("shoot")


func _find_child_animation_sprite(fragment: String) -> AnimatedSprite2D:
	for node in find_children("*", "AnimatedSprite2D", true, false):
		var sprite := node as AnimatedSprite2D
		if sprite == null or sprite == main_sprite:
			continue

		var animation_name := _find_animation_name(sprite, fragment)
		if animation_name != StringName():
			return sprite

	return null


func _find_animation_name(sprite: AnimatedSprite2D, fragment: String) -> StringName:
	if sprite == null or sprite.sprite_frames == null:
		return StringName()

	for animation_name in sprite.sprite_frames.get_animation_names():
		if String(animation_name).to_lower().contains(fragment):
			return animation_name

	return StringName()


func _make_projectile_texture() -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = ENEMY_PROJECTILE_SPRITESHEET
	texture.region = Rect2(0, 0, 11, 32)
	return texture
