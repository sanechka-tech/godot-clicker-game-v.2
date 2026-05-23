extends Node2D

const PLAYER_START_POSITION := Vector2(635.0, 445.0)
const GAME_MIN_X := 400.0
const GAME_MAX_X := 870.0
const GAME_MIN_Y := 201.0
const GAME_MAX_Y := 479.0
const ENEMY_SPAWN_MIN_Y := 201.0
const ENEMY_SPAWN_MAX_Y := 240.0
const MAX_ACTIVE_ENEMIES := 6
const MAX_SUPPORT_ENEMIES_DURING_BOSS := 2
const BOSS_SPAWN_TIME := 90.0
const WIN_SCREEN_INPUT_LOCK_DURATION := 2.0
const AFTER_MINI_GAME_SCENE_PATH := "res://cutscenes/lvl_2_2_after_mini_game.tscn"
const SPACE_ENEMY_1_SCENE := preload("res://character/Mobs/space_enemy_1.tscn")
const SPACE_ENEMY_2_SCENE := preload("res://character/Mobs/space_enemy_2.tscn")
const SPACE_ENEMY_3_SCENE := preload("res://character/Mobs/space_enemy_3.tscn")

@onready var player = $Spaceship
@onready var start_button: Button = $Control/MinigameStart
@onready var game_name_label: Control = $Control/GameName
@onready var lose_label: Control = $"Control/Loose label"
@onready var retry_button: Button = $"Control/Loose label/Button"
@onready var quit_button: Button = $"Control/Loose label/Button2"
@onready var win_label: Label = $"Control/Win Label"
@onready var enemy_template_1 = $SpaceEnemy1
@onready var enemy_template_2 = $SpaceEnemy2
@onready var enemy_template_3 = $SpaceEnemy3

var game_running := false
var elapsed_time := 0.0
var spawn_time_left := 0.0
var boss_spawned := false
var boss_defeated := false
var boss_support_spawn_time_left := 0.0
var death_audio_started := false
var death_sound_player: AudioStreamPlayer
var win_screen_visible := false
var win_screen_accepts_input := false


func _ready() -> void:
	start_button.pressed.connect(_on_start_button_pressed)
	retry_button.pressed.connect(_on_retry_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	player.died.connect(_on_player_died)

	enemy_template_1.queue_free()
	enemy_template_2.queue_free()
	enemy_template_3.queue_free()

	_show_start_screen()
	set_process(false)
	call_deferred("_play_music_after_transition")


func _play_music_after_transition() -> void:
	var transition_screen = get_node_or_null("/root/TransitionScreen")
	if transition_screen != null and transition_screen.is_transitioning():
		await transition_screen.scene_revealed

	AudioManager.play_minigame_music()


func _process(delta: float) -> void:
	if not game_running:
		return

	elapsed_time += delta

	if not boss_spawned and elapsed_time >= BOSS_SPAWN_TIME:
		_spawn_boss()

	if boss_spawned and not boss_defeated:
		_process_boss_phase(delta)
		return

	_process_regular_phase(delta)


func _on_start_button_pressed() -> void:
	_start_game()


func _on_retry_button_pressed() -> void:
	AudioManager.stop_music()
	_stop_death_sound()
	get_tree().reload_current_scene()


func _on_quit_button_pressed() -> void:
	AudioManager.stop_music()
	_stop_death_sound()
	GameState.mini_game_after_story_key = &"STORY_LVL2_MINIGAME_LOSE"
	get_tree().change_scene_to_file(AFTER_MINI_GAME_SCENE_PATH)


func _on_player_died() -> void:
	if death_audio_started:
		return

	death_audio_started = true
	game_running = false
	set_process(false)
	player.stop_run()
	_clear_enemies_and_projectiles()
	lose_label.visible = true
	AudioManager.stop_music()
	death_sound_player = AudioManager.play_you_died()


func _stop_death_sound() -> void:
	if not is_instance_valid(death_sound_player):
		return

	death_sound_player.stop()
	death_sound_player.queue_free()


func _start_game() -> void:
	_clear_enemies_and_projectiles()

	game_running = true
	elapsed_time = 0.0
	boss_spawned = false
	boss_defeated = false
	spawn_time_left = randf_range(1.1, 1.3)
	boss_support_spawn_time_left = randf_range(6.0, 8.0)

	start_button.visible = false
	game_name_label.visible = false
	lose_label.visible = false
	win_label.visible = false

	player.start_run(PLAYER_START_POSITION)
	set_process(true)


func _show_start_screen() -> void:
	start_button.visible = true
	game_name_label.visible = true
	lose_label.visible = false
	win_label.visible = false


func _process_regular_phase(delta: float) -> void:
	if _active_enemy_count() >= MAX_ACTIVE_ENEMIES:
		return

	spawn_time_left -= delta
	if spawn_time_left > 0.0:
		return

	spawn_time_left = _next_spawn_delay()
	_spawn_regular_enemy()


func _process_boss_phase(delta: float) -> void:
	var support_enemy_count := _active_non_boss_enemy_count()
	if support_enemy_count >= MAX_SUPPORT_ENEMIES_DURING_BOSS:
		return

	boss_support_spawn_time_left -= delta
	if boss_support_spawn_time_left > 0.0:
		return

	boss_support_spawn_time_left = randf_range(6.0, 8.0)
	_spawn_enemy_instance(SPACE_ENEMY_1_SCENE, &"weak")


func _next_spawn_delay() -> float:
	if elapsed_time < 45.0:
		return randf_range(1.1, 1.3)

	if elapsed_time < 105.0:
		return randf_range(0.75, 0.95)

	return randf_range(0.65, 0.8)


func _spawn_regular_enemy() -> void:
	if elapsed_time < 45.0:
		if randf() < 0.75:
			_spawn_enemy_instance(SPACE_ENEMY_1_SCENE, &"weak")
			return

		_spawn_enemy_instance(SPACE_ENEMY_2_SCENE, &"medium")
		return

	if randf() < 0.55:
		_spawn_enemy_instance(SPACE_ENEMY_1_SCENE, &"weak")
		return

	_spawn_enemy_instance(SPACE_ENEMY_2_SCENE, &"medium")


func _spawn_boss() -> void:
	boss_spawned = true
	boss_support_spawn_time_left = randf_range(6.0, 8.0)
	_clear_regular_enemies_and_projectiles()
	_spawn_enemy_instance(SPACE_ENEMY_3_SCENE, &"boss")


func _spawn_enemy_instance(scene: PackedScene, enemy_role: StringName) -> void:
	var enemy = scene.instantiate()
	add_child(enemy)
	enemy.defeated.connect(_on_enemy_defeated)
	enemy.enemy_role = enemy_role
	enemy.min_x = GAME_MIN_X
	enemy.max_x = GAME_MAX_X
	enemy.min_y = GAME_MIN_Y
	enemy.max_y = GAME_MAX_Y
	enemy.activate(
		Vector2(
			randf_range(GAME_MIN_X, GAME_MAX_X),
			randf_range(ENEMY_SPAWN_MIN_Y, ENEMY_SPAWN_MAX_Y)
		),
		player
	)


func _on_enemy_defeated(enemy_role: StringName) -> void:
	if enemy_role != &"boss":
		return

	boss_defeated = true
	game_running = false
	set_process(false)
	player.stop_run()
	_clear_enemies_and_projectiles()
	AudioManager.stop_music()
	AudioManager.play_win()
	win_label.visible = true
	win_screen_visible = true
	win_screen_accepts_input = false
	call_deferred("_unlock_win_screen_input")


func _unlock_win_screen_input() -> void:
	await get_tree().create_timer(WIN_SCREEN_INPUT_LOCK_DURATION).timeout
	win_screen_accepts_input = true


func _unhandled_input(event: InputEvent) -> void:
	if not win_screen_visible or not win_screen_accepts_input:
		return

	if not _is_confirm_input(event):
		return

	get_viewport().set_input_as_handled()
	GameState.mini_game_after_story_key = &"STORY_LVL2_MINIGAME_WIN"
	get_tree().change_scene_to_file(AFTER_MINI_GAME_SCENE_PATH)


func _is_confirm_input(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return event.pressed

	if event is InputEventMouseButton:
		return event.pressed and event.button_index == MOUSE_BUTTON_LEFT

	return false


func _active_enemy_count() -> int:
	return get_tree().get_nodes_in_group("mini_enemies").size()


func _active_non_boss_enemy_count() -> int:
	var count := 0
	for enemy in get_tree().get_nodes_in_group("mini_enemies"):
		if not enemy.is_in_group("mini_boss"):
			count += 1
	return count


func _clear_enemies_and_projectiles() -> void:
	for enemy in get_tree().get_nodes_in_group("mini_enemies"):
		enemy.queue_free()

	for child in get_tree().current_scene.get_children():
		if child.is_in_group("mini_projectiles"):
			child.queue_free()


func _clear_enemy_projectiles() -> void:
	for child in get_tree().current_scene.get_children():
		if child.is_in_group("mini_enemy_projectiles"):
			child.queue_free()


func _clear_regular_enemies_and_projectiles() -> void:
	for enemy in get_tree().get_nodes_in_group("mini_enemies"):
		if enemy.is_in_group("mini_boss"):
			continue
		enemy.queue_free()

	_clear_enemy_projectiles()
