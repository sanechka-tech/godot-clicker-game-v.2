extends Node2D

const LEVEL_GOAL_SCORE := 900
const AFTER_SCENE_PATH := "res://cutscenes/lvl_3_village_after_1.tscn"
const PASSIVE_SCORE_PER_SECOND := 10.0
const BUG_REACH_PENALTY := 100
const BUG_SPAWN_DELAY := 3.0
const SOFT_MAX_ACTIVE_BUGS := 5
const HARD_MAX_ACTIVE_BUGS := 6
const BASE_MAX_AIR_BUGS := 3
const BASE_MAX_GROUND_BUGS := 2
const PROGRESS_GOAL_ICON_TRACK_START_OFFSET := 0.0
const PROGRESS_GOAL_ICON_TRACK_END_OFFSET := 0.0
const PROGRESS_GOAL_ICON_OFFSET := Vector2.ZERO
const BUG_SCENE_PATHS := {
	"fly": preload("res://character/Mobs/bug_fly.tscn"),
	"maggot": preload("res://character/Mobs/bug_maggot.tscn"),
	"mantis": preload("res://character/Mobs/bug_mantis.tscn"),
	"spider": preload("res://character/Mobs/bug_spider.tscn"),
}
const BUG_CONFIGS := {
	"fly": {
		"horizontal_speed": 120.0,
		"vertical_speed": 134.0,
		"alignment_threshold": 26.0,
		"reach_radius": 52.0,
		"mixed_movement": true,
	},
	"spider": {
		"horizontal_speed": 88.0,
		"vertical_speed": 122.0,
		"alignment_threshold": 24.0,
		"reach_radius": 44.0,
		"mixed_movement": true,
	},
	"maggot": {
		"horizontal_speed": 42.0,
		"vertical_speed": 58.0,
		"alignment_threshold": 18.0,
		"reach_radius": 56.0,
		"mixed_movement": false,
	},
	"mantis": {
		"horizontal_speed": 70.0,
		"vertical_speed": 76.0,
		"alignment_threshold": 20.0,
		"reach_radius": 50.0,
		"mixed_movement": true,
	},
}
const PHASE_DEFINITIONS := [
	{
		"end_time": 25.0,
		"spawn_min": 1.7,
		"spawn_max": 2.0,
		"weights": {
			"fly": 4,
			"maggot": 2,
			"mantis": 1,
			"spider": 1,
		},
	},
	{
		"end_time": 60.0,
		"spawn_min": 1.2,
		"spawn_max": 1.5,
		"weights": {
			"fly": 3,
			"maggot": 2,
			"mantis": 2,
			"spider": 2,
		},
	},
	{
		"end_time": INF,
		"spawn_min": 0.85,
		"spawn_max": 1.1,
		"weights": {
			"fly": 4,
			"maggot": 1,
			"mantis": 2,
			"spider": 3,
		},
	},
]

@onready var progress_goal: TextureProgressBar = $ProgressGoalLvl3
@onready var progress_goal_icon: Control = _find_progress_goal_icon()
@onready var character_anchor: CharacterBody2D = $CharacterBody2D
@onready var left_area: CollisionShape2D = $CharacterBody2D/Left_area
@onready var right_area: CollisionShape2D = $CharacterBody2D/Right_area
@onready var paper_hand: CharacterBody2D = $PaperHand
@onready var paper_hand_2: CharacterBody2D = $PaperHand2
@onready var paper_hand_3: CharacterBody2D = $PaperHand3
@onready var paper_hands := {
	&"left": {
		"node": paper_hand_3,
		"collision_shape": $PaperHand3/CollisionShape2D,
		"sprite": $PaperHand3/AnimatedSprite2D,
	},
	&"right": {
		"node": paper_hand_2,
		"collision_shape": $PaperHand2/CollisionShape2D,
		"sprite": $PaperHand2/AnimatedSprite2D,
	},
	&"center_a": {
		"node": paper_hand_3,
		"collision_shape": $PaperHand3/CollisionShape2D,
		"sprite": $PaperHand3/AnimatedSprite2D,
	},
	&"center_b": {
		"node": paper_hand_2,
		"collision_shape": $PaperHand2/CollisionShape2D,
		"sprite": $PaperHand2/AnimatedSprite2D,
	},
	&"center_c": {
		"node": paper_hand,
		"collision_shape": $PaperHand/CollisionShape2D,
		"sprite": $PaperHand/AnimatedSprite2D,
	},
}

var elapsed_time := 0.0
var passive_score_buffer := 0.0
var spawn_cooldown_remaining := BUG_SPAWN_DELAY
var round_finished := false
var play_area := Rect2()
var bug_targets: Array[Vector2] = []
var bugs_root: Node2D


func _ready() -> void:
	AudioManager.stop_level_3_intro_ambience()
	call_deferred("_play_music_after_transition_reveal")
	GameState.start_level(LEVEL_GOAL_SCORE)
	_track_level_start()
	GameState.score_changed.connect(_on_score_changed)

	play_area = Rect2(Vector2.ZERO, get_viewport_rect().size)
	bug_targets = _build_bug_targets()
	bugs_root = Node2D.new()
	bugs_root.name = "ActiveBugs"
	add_child(bugs_root)

	_remove_preview_bugs()
	_setup_goal_progress()
	_update_goal_progress()
	_setup_paper_hand()


func _play_music_after_transition_reveal() -> void:
	var transition_screen = get_node_or_null("/root/TransitionScreen")
	if transition_screen != null and transition_screen.is_transitioning():
		await transition_screen.scene_revealed

	AudioManager.play_level_3_music()


func _process(delta: float) -> void:
	if round_finished:
		return

	elapsed_time += delta
	_advance_passive_score(delta)

	if round_finished:
		return

	spawn_cooldown_remaining -= delta
	if spawn_cooldown_remaining > 0.0:
		return

	if _try_spawn_bug():
		_reset_spawn_cooldown()
	else:
		spawn_cooldown_remaining = 0.2


func _advance_passive_score(delta: float) -> void:
	passive_score_buffer += PASSIVE_SCORE_PER_SECOND * delta
	var score_to_add := floori(passive_score_buffer)

	if score_to_add <= 0:
		return

	passive_score_buffer -= score_to_add
	GameState.add_score(score_to_add)


func _on_score_changed(_new_value: int) -> void:
	_update_goal_progress()

	if GameState.score >= LEVEL_GOAL_SCORE:
		_finish_round()


func _setup_goal_progress() -> void:
	progress_goal.min_value = 0
	progress_goal.max_value = LEVEL_GOAL_SCORE
	call_deferred("_update_goal_icon")


func _update_goal_progress() -> void:
	progress_goal.value = min(GameState.score, LEVEL_GOAL_SCORE)
	_update_goal_icon()


func _update_goal_icon() -> void:
	if progress_goal_icon == null:
		return

	var progress_control := progress_goal as Control
	if progress_control == null:
		return

	var progress_range := progress_goal.max_value - progress_goal.min_value
	if progress_range <= 0.0:
		return

	var progress_ratio := clampf(
		(progress_goal.value - progress_goal.min_value) / progress_range,
		0.0,
		1.0
	)
	var icon_size := progress_goal_icon.size
	var half_icon_width := icon_size.x * 0.5
	var start_x := PROGRESS_GOAL_ICON_TRACK_START_OFFSET - half_icon_width
	var end_x := progress_control.size.x - PROGRESS_GOAL_ICON_TRACK_END_OFFSET - half_icon_width
	var target_x := lerpf(start_x, end_x, progress_ratio)

	progress_goal_icon.position.x = target_x + PROGRESS_GOAL_ICON_OFFSET.x
	progress_goal_icon.position.y = progress_control.size.y * 0.5 - icon_size.y * 0.5 + PROGRESS_GOAL_ICON_OFFSET.y


func _find_progress_goal_icon() -> Control:
	for icon_path in [
		"ProgressGoalLvl3/GoalIcon",
		"ProgressGoalLvl3/Icon",
		"ProgressGoalLvl3/TextureRect",
	]:
		var icon := get_node_or_null(icon_path) as Control
		if icon != null:
			return icon

	for child in $ProgressGoalLvl3.get_children():
		var icon := child as Control
		if icon != null:
			return icon

	return null


func _build_bug_targets() -> Array[Vector2]:
	return [
		character_anchor.global_position + left_area.position,
		character_anchor.global_position + right_area.position,
	]


func _remove_preview_bugs() -> void:
	for preview_bug_name in ["bug_fly", "bug_maggot", "bug_mantis", "bug_spider"]:
		var preview_bug := get_node_or_null(preview_bug_name)
		if preview_bug != null:
			preview_bug.queue_free()


func _setup_paper_hand() -> void:
	for hand_key in paper_hands.keys():
		var hand_data: Dictionary = paper_hands[hand_key]
		var hand_node := hand_data["node"] as CharacterBody2D
		var hand_sprite := hand_data["sprite"] as AnimatedSprite2D

		if hand_node == null or hand_sprite == null:
			continue

		hand_node.visible = false
		hand_sprite.stop()

		if not hand_sprite.animation_finished.is_connected(_on_paper_hand_animation_finished.bind(hand_node)):
			hand_sprite.animation_finished.connect(_on_paper_hand_animation_finished.bind(hand_node))


func _try_spawn_bug() -> bool:
	if elapsed_time < BUG_SPAWN_DELAY:
		return false

	var total_bugs := bugs_root.get_child_count()
	if total_bugs >= HARD_MAX_ACTIVE_BUGS:
		return false

	var allow_overflow := elapsed_time >= 60.0
	if total_bugs >= SOFT_MAX_ACTIVE_BUGS and not allow_overflow:
		return false

	var phase_definition: Dictionary = _get_phase_definition()
	var available_bug_types := _get_available_bug_types(allow_overflow, phase_definition)
	if available_bug_types.is_empty():
		return false

	var bug_type := _pick_weighted_bug_type(available_bug_types, phase_definition["weights"] as Dictionary)
	_spawn_bug(bug_type)
	return true


func _get_phase_definition() -> Dictionary:
	for phase_definition in PHASE_DEFINITIONS:
		if elapsed_time <= float(phase_definition["end_time"]):
			return phase_definition

	return PHASE_DEFINITIONS[PHASE_DEFINITIONS.size() - 1]


func _get_available_bug_types(allow_overflow: bool, phase_definition: Dictionary) -> Array[StringName]:
	var counts := _count_active_bug_types()
	var available_bug_types: Array[StringName] = []
	var air_limit := BASE_MAX_AIR_BUGS + int(allow_overflow)
	var ground_limit := BASE_MAX_GROUND_BUGS + int(allow_overflow)
	var weights: Dictionary = phase_definition["weights"]

	for bug_type_key in weights.keys():
		var bug_type := StringName(bug_type_key)
		var active_count := int(counts.get(bug_type, 0))

		if bug_type == &"fly" or bug_type == &"spider":
			if _count_air_bugs(counts) >= air_limit:
				continue
		else:
			if _count_ground_bugs(counts) >= ground_limit:
				continue

		if active_count < HARD_MAX_ACTIVE_BUGS:
			available_bug_types.append(bug_type)

	return available_bug_types


func _count_active_bug_types() -> Dictionary:
	var counts := {
		&"fly": 0,
		&"maggot": 0,
		&"mantis": 0,
		&"spider": 0,
	}

	for child in bugs_root.get_children():
		if child.has_method("get_bug_kind"):
			var bug_type := child.call("get_bug_kind") as StringName
			counts[bug_type] = int(counts.get(bug_type, 0)) + 1

	return counts


func _count_air_bugs(counts: Dictionary) -> int:
	return int(counts.get(&"fly", 0)) + int(counts.get(&"spider", 0))


func _count_ground_bugs(counts: Dictionary) -> int:
	return int(counts.get(&"maggot", 0)) + int(counts.get(&"mantis", 0))


func _pick_weighted_bug_type(available_bug_types: Array[StringName], weights: Dictionary) -> StringName:
	var total_weight := 0

	for bug_type in available_bug_types:
		total_weight += int(weights.get(String(bug_type), 0))

	if total_weight <= 0:
		return available_bug_types[0]

	var roll := randi_range(1, total_weight)
	var accumulated_weight := 0

	for bug_type in available_bug_types:
		accumulated_weight += int(weights.get(String(bug_type), 0))
		if roll <= accumulated_weight:
			return bug_type

	return available_bug_types[0]


func _spawn_bug(bug_type: StringName) -> void:
	var bug_scene: PackedScene = BUG_SCENE_PATHS[String(bug_type)]
	var bug := bug_scene.instantiate() as CharacterBody2D
	bugs_root.add_child(bug)
	bug.global_position = _get_spawn_position(bug_type)
	bug.connect("reached_target", _on_bug_reached_target)
	bug.connect("squashed", _on_bug_squashed)
	bug.call("configure", BUG_CONFIGS[String(bug_type)], play_area, bug_targets)


func _get_spawn_position(bug_type: StringName) -> Vector2:
	match bug_type:
		&"fly":
			return Vector2(randf_range(120.0, play_area.end.x - 120.0), randf_range(60.0, 120.0))
		&"spider":
			var center_x := play_area.size.x * 0.5
			return Vector2(randf_range(center_x - 160.0, center_x + 160.0), randf_range(80.0, 150.0))
		&"maggot":
			return Vector2(randf_range(90.0, play_area.end.x - 90.0), randf_range(play_area.size.y * 0.60, play_area.size.y * 0.76))
		&"mantis":
			return Vector2(randf_range(90.0, play_area.end.x - 90.0), randf_range(play_area.size.y * 0.58, play_area.size.y * 0.74))

	return play_area.size * 0.5


func _reset_spawn_cooldown() -> void:
	var phase_definition: Dictionary = _get_phase_definition()
	var spawn_min := float(phase_definition["spawn_min"])
	var spawn_max := float(phase_definition["spawn_max"])

	spawn_cooldown_remaining = randf_range(spawn_min, spawn_max)


func _on_bug_reached_target(_bug: CharacterBody2D) -> void:
	if round_finished:
		return

	GameState.remove_score(BUG_REACH_PENALTY)


func _on_bug_squashed(_bug: CharacterBody2D) -> void:
	if _bug != null and _bug.has_method("get_bug_kind"):
		AudioManager.play_level_3_bug_death_sound(_bug.call("get_bug_kind") as StringName)

	_play_paper_hand_hit(_bug)


func _finish_round() -> void:
	if round_finished:
		return

	round_finished = true
	_track_level_complete()
	_track_game_complete()

	for child in bugs_root.get_children():
		child.queue_free()

	_hide_all_paper_hands()
	_play_final_pressure_sequence()


func _go_to_after_scene() -> void:
	GameState.save_progress(AFTER_SCENE_PATH)

	var transition_screen = get_node_or_null("/root/TransitionScreen")
	if transition_screen != null:
		transition_screen.change_scene(AFTER_SCENE_PATH)
	else:
		get_tree().change_scene_to_file(AFTER_SCENE_PATH)


func _play_final_pressure_sequence() -> void:
	AudioManager.stop_music()
	var final_pressure_player: AudioStreamPlayer = AudioManager.play_final_pressure()
	if is_instance_valid(final_pressure_player) and final_pressure_player.playing:
		await final_pressure_player.finished

	_go_to_after_scene()


func _play_paper_hand_hit(bug: CharacterBody2D) -> void:
	var selected_hand_data := _get_paper_hand_data_for_bug(bug)
	var hand_node := selected_hand_data.get("node") as CharacterBody2D
	var hand_collision_shape := selected_hand_data.get("collision_shape") as CollisionShape2D
	var hand_sprite := selected_hand_data.get("sprite") as AnimatedSprite2D

	if hand_node == null or hand_sprite == null or hand_collision_shape == null:
		return

	var hit_point := bug.global_position
	var bug_collision_shape := bug.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if bug_collision_shape != null:
		hit_point = bug_collision_shape.global_position

	_hide_all_paper_hands()
	hand_node.global_position = hit_point - hand_collision_shape.position
	hand_node.visible = true
	hand_sprite.stop()
	hand_sprite.play(&"Hit")


func _on_paper_hand_animation_finished(hand_node: CharacterBody2D) -> void:
	if hand_node == null:
		return

	hand_node.visible = false


func _get_paper_hand_data_for_bug(bug: CharacterBody2D) -> Dictionary:
	if bug == null:
		return paper_hands[&"right"]

	var left_third_boundary := play_area.position.x + play_area.size.x / 3.0
	var right_third_boundary := play_area.position.x + play_area.size.x * 2.0 / 3.0
	var bug_x := bug.global_position.x

	if bug_x <= left_third_boundary:
		return paper_hands[&"left"]

	if bug_x >= right_third_boundary:
		return paper_hands[&"right"]

	var center_hand_keys: Array[StringName] = [&"center_a", &"center_b", &"center_c"]
	var random_center_key := center_hand_keys[randi() % center_hand_keys.size()]
	return paper_hands[random_center_key]


func _hide_all_paper_hands() -> void:
	for hand_key in paper_hands.keys():
		var hand_data: Dictionary = paper_hands[hand_key]
		var hand_node := hand_data["node"] as CharacterBody2D
		if hand_node != null:
			hand_node.visible = false


func _get_analytics() -> Node:
	return get_node_or_null("/root/Analytics")


func _track_level_start() -> void:
	var analytics := _get_analytics()
	if analytics != null:
		analytics.track_level_start("lvl3")


func _track_level_complete() -> void:
	var analytics := _get_analytics()
	if analytics != null:
		analytics.track_level_complete("lvl3", GameState.score)


func _track_game_complete() -> void:
	var analytics := _get_analytics()
	if analytics != null:
		analytics.track_game_complete()
