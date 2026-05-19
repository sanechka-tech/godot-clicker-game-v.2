extends CanvasLayer

const FADE_OUT_DURATION := 0.35
const FADE_IN_DURATION := 0.35

@export var next_scene_path := "res://cutscenes/lvl_1_room_intro.tscn"
@export var auto_start := true
@export var hold_duration := 0.25

@onready var fade_rect: CanvasItem = $FadeRect

var _is_transitioning := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	fade_rect.modulate.a = 0.0

	if auto_start:
		call_deferred("_play_standalone_transition")


func _play_standalone_transition() -> void:
	await _fade_out()
	await get_tree().create_timer(hold_duration).timeout
	get_tree().change_scene_to_file(next_scene_path)


func change_scene(scene_path: String) -> void:
	if _is_transitioning:
		return

	await _fade_out()
	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	await _fade_in()


func change_scene_to_packed(scene: PackedScene) -> void:
	if _is_transitioning or scene == null:
		return

	await _fade_out()
	get_tree().change_scene_to_packed(scene)
	await get_tree().process_frame
	await _fade_in()


func _fade_out() -> void:
	_is_transitioning = true
	visible = true
	fade_rect.modulate.a = 0.0

	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, FADE_OUT_DURATION)
	await tween.finished


func _fade_in() -> void:
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, FADE_IN_DURATION)
	await tween.finished

	visible = false
	_is_transitioning = false
