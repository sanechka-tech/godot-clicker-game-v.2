extends Control

const NEXT_SCENE := "res://menu.tscn"
const MIN_LOADING_TIME := 2.0

@onready var loading_line: TextureProgressBar = $Loading/LoadingLine
@onready var background_animation: AnimatedSprite2D = $MenuBackground/AnimatedSprite2D

var _is_changing_scene := false
var _elapsed_time := 0.0
var _loaded_scene: PackedScene = null
var _load_failed := false


func _ready() -> void:
	AudioManager.play_main_theme()
	background_animation.stop()
	loading_line.min_value = 0.0
	loading_line.max_value = 100.0
	loading_line.value = 0.0
	ResourceLoader.load_threaded_request(NEXT_SCENE)


func _process(_delta: float) -> void:
	if _is_changing_scene:
		return

	_elapsed_time += _delta

	var progress := []
	var status := ResourceLoader.load_threaded_get_status(NEXT_SCENE, progress)

	if status == ResourceLoader.THREAD_LOAD_LOADED:
		if _loaded_scene == null:
			_loaded_scene = ResourceLoader.load_threaded_get(NEXT_SCENE) as PackedScene
	elif status == ResourceLoader.THREAD_LOAD_FAILED:
		_load_failed = true
		push_error("Failed to load scene: " + NEXT_SCENE)

	var visual_progress := smoothstep(0.0, 1.0, clampf(_elapsed_time / MIN_LOADING_TIME, 0.0, 1.0))
	loading_line.value = visual_progress * 100.0

	if _loaded_scene != null and _elapsed_time >= MIN_LOADING_TIME:
		_is_changing_scene = true
		loading_line.value = 100.0
		call_deferred("_change_to_loaded_scene")
	elif _load_failed and _elapsed_time >= MIN_LOADING_TIME:
		_is_changing_scene = true
		call_deferred("_change_to_menu_fallback")


func _change_to_loaded_scene() -> void:
	get_tree().change_scene_to_packed(_loaded_scene)


func _change_to_menu_fallback() -> void:
	get_tree().change_scene_to_file(NEXT_SCENE)
