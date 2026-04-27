extends CharacterBody2D

signal died

const PLAYER_PROJECTILE_SCENE := preload("res://mini_projectile.tscn")
const PLAYER_PROJECTILE_SPRITESHEET := preload("res://Images/MiniGame/Main ship weapons/PNGs/Main ship weapon - Projectile - Big Space Gun.png")

@export var min_x: float = 400.0
@export var max_x: float = 870.0
@export var fixed_y: float = 445.0
@export var follow_speed: float = 1400.0
@export var shots_per_second: float = 3.0
@export var projectile_speed: float = 640.0
@export var projectile_damage: int = 1
@export var max_hp: int = 5
@export var volley_projectile_count: int = 1
@export var volley_spacing: float = 18.0
@export var projectile_min_y: float = 201.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var base_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var fly_sprite: AnimatedSprite2D = $AnimatedSprite2D/Spaceship_fly
@onready var shoot_sprite: AnimatedSprite2D = $AnimatedSprite2D/Spaceship_shoot

var active := false
var target_x := 635.0
var shoot_cooldown := 0.0
var shoot_flash_time_left := 0.0
var damage_cooldown := 0.0
var current_hp := 2
var has_played_damage_animation := false


func _ready() -> void:
	add_to_group("mini_player")
	set_collision_layer_value(2, true)
	set_collision_mask_value(3, true)
	set_collision_mask_value(4, true)

	if fly_sprite.sprite_frames.has_animation(&"Spaceship_flying"):
		fly_sprite.play(&"Spaceship_flying")

	shoot_sprite.visible = false
	visible = false
	set_process(false)
	set_physics_process(false)


func start_run(start_position: Vector2) -> void:
	global_position = start_position
	target_x = start_position.x
	current_hp = max_hp
	damage_cooldown = 0.0
	shoot_cooldown = 0.0
	shoot_flash_time_left = 0.0
	has_played_damage_animation = false
	active = true
	visible = true
	collision_shape.disabled = false
	base_sprite.stop()
	base_sprite.frame = 0
	shoot_sprite.visible = false
	set_process(true)
	set_physics_process(true)


func stop_run() -> void:
	active = false
	visible = false
	collision_shape.disabled = true
	set_process(false)
	set_physics_process(false)
	shoot_sprite.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return

	if event is InputEventMouseMotion:
		target_x = clampf(event.position.x, min_x, max_x)

	if event is InputEventScreenTouch and event.pressed:
		target_x = clampf(event.position.x, min_x, max_x)

	if event is InputEventScreenDrag:
		target_x = clampf(event.position.x, min_x, max_x)


func _process(delta: float) -> void:
	if not active:
		return

	if damage_cooldown > 0.0:
		damage_cooldown = maxf(damage_cooldown - delta, 0.0)

	if shoot_flash_time_left > 0.0:
		shoot_flash_time_left = maxf(shoot_flash_time_left - delta, 0.0)
		if shoot_flash_time_left <= 0.0:
			shoot_sprite.visible = false

	target_x = clampf(target_x, min_x, max_x)
	global_position.x = move_toward(global_position.x, target_x, follow_speed * delta)
	global_position.y = fixed_y

	shoot_cooldown -= delta
	if shoot_cooldown <= 0.0:
		shoot_cooldown += 1.0 / shots_per_second
		_fire_projectile()


func take_damage(amount: int) -> void:
	if not active or damage_cooldown > 0.0:
		return

	current_hp -= amount
	damage_cooldown = 0.4

	if not has_played_damage_animation and base_sprite.sprite_frames.has_animation(&"Mainspaceship_damaged"):
		base_sprite.play(&"Mainspaceship_damaged")
		has_played_damage_animation = true

	if current_hp <= 0:
		stop_run()
		died.emit()


func _fire_projectile() -> void:
	var projectile_count := maxi(volley_projectile_count, 1)
	var total_width := float(projectile_count - 1) * volley_spacing
	var projectile_texture := _make_projectile_texture()

	for index in range(projectile_count):
		var projectile := PLAYER_PROJECTILE_SCENE.instantiate()
		get_tree().current_scene.add_child(projectile)

		var x_offset := (float(index) * volley_spacing) - (total_width * 0.5)
		projectile.call(
			"setup",
			global_position + Vector2(x_offset, -35.0),
			Vector2.UP,
			projectile_speed,
			projectile_damage,
			&"mini_enemies",
			projectile_texture,
			Vector2(0.8, 0.8),
			projectile_min_y
		)

	shoot_sprite.visible = true
	shoot_flash_time_left = 0.12
	if shoot_sprite.sprite_frames.has_animation(&"Spaceship_shoot"):
		shoot_sprite.play(&"Spaceship_shoot")


func _make_projectile_texture() -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = PLAYER_PROJECTILE_SPRITESHEET
	texture.region = Rect2(0, 0, 32, 32)
	return texture
