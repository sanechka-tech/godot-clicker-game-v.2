extends CanvasLayer

signal scene_revealed

const FADE_OUT_DURATION := 2.0
const FADE_IN_DURATION := 2.0

@export var next_scene_path := "res://cutscenes/lvl_1_room_intro.tscn"
@export var auto_start := false
@export var reveal_on_ready := false
@export var hold_duration := 1.5

@onready var fade_rect: CanvasItem = $FadeRect

var _is_transitioning := false


func is_transitioning() -> bool:
	return _is_transitioning


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	if reveal_on_ready:
		visible = true
		fade_rect.modulate.a = 1.0
		call_deferred("_fade_in")
		return

	visible = false
	fade_rect.modulate.a = 0.0

	if auto_start:
		call_deferred("_play_standalone_transition")


func _play_standalone_transition() -> void:
	await _fade_out()
	await get_tree().create_timer(hold_duration).timeout
	get_tree().change_scene_to_file(next_scene_path)


func change_scene(
	scene_path: String,
	fade_out_duration: float = FADE_OUT_DURATION,
	fade_in_duration: float = FADE_IN_DURATION
) -> void:
	if _is_transitioning:
		return

	await _fade_out(fade_out_duration)
	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	await get_tree().create_timer(hold_duration).timeout
	await _fade_in(fade_in_duration)


func change_scene_to_packed(
	scene: PackedScene,
	fade_out_duration: float = FADE_OUT_DURATION,
	fade_in_duration: float = FADE_IN_DURATION
) -> void:
	if _is_transitioning or scene == null:
		return

	await _fade_out(fade_out_duration)
	get_tree().change_scene_to_packed(scene)
	await get_tree().process_frame
	await get_tree().create_timer(hold_duration).timeout
	await _fade_in(fade_in_duration)


func _fade_out(duration: float = FADE_OUT_DURATION) -> void:
	_is_transitioning = true
	visible = true
	fade_rect.modulate.a = 0.0

	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, duration)
	await tween.finished


func _fade_in(duration: float = FADE_IN_DURATION) -> void:
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, duration)
	await tween.finished

	visible = false
	_is_transitioning = false
	scene_revealed.emit()
