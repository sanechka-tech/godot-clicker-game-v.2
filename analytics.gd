extends Node

const GAME_KEY := "4c22bd2423872902abe1357a057f8828"
const SECRET_KEY := "808785eb88497bd1eb6ce39797a9ece6c879a486"
const BUILD_VERSION := "0.2.0"
const RESOURCE_CURRENCIES := ["coins"]
const RESOURCE_ITEM_TYPES := ["tap", "mob", "shop", "progress", "feedback", "bonus"]
const CUSTOM_DIMENSION_01_VALUES := ["dev", "release"]
const CUSTOM_DIMENSION_02_VALUES := ["en", "ru", "es", "de"]

var game_analytics: Object
var sdk_ready := false
var timer_started_at_msec := {}
var session_end_tracked := false


func _ready() -> void:
	print("[Analytics] Autoload ready")
	_initialize_sdk()
	start_timer("session")
	track_game_open()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		track_session_end()


func start_timer(timer_id: String) -> void:
	timer_started_at_msec[timer_id] = Time.get_ticks_msec()


func stop_timer_and_send(timer_id: String, event_id: String) -> void:
	if not timer_started_at_msec.has(timer_id):
		return

	var started_at: int = timer_started_at_msec[timer_id]
	timer_started_at_msec.erase(timer_id)
	var elapsed_seconds := maxf(float(Time.get_ticks_msec() - started_at) / 1000.0, 0.0)
	_send_design_event_with_value(event_id, elapsed_seconds)


func track_game_open() -> void:
	print("[Analytics] track_game_open")
	_send_design_event("meta:game_open")


func track_game_complete() -> void:
	print("[Analytics] track_game_complete")
	_send_design_event("meta:game_complete")


func track_session_end() -> void:
	if session_end_tracked:
		return

	session_end_tracked = true
	stop_timer_and_send("session", "time:session:total_sec")


func track_feedback_sent() -> void:
	print("[Analytics] track_feedback_sent")
	_send_design_event("ui:feedback_sent")


func track_level_start(level_id: String) -> void:
	print("[Analytics] track_level_start -> %s" % level_id)
	_send_progression_event("start", level_id)
	start_timer("level:%s" % level_id)


func track_level_complete(level_id: String, score: int = 0) -> void:
	print("[Analytics] track_level_complete -> %s (%s)" % [level_id, score])
	_send_progression_event_with_score("complete", level_id, score)
	stop_timer_and_send("level:%s" % level_id, "time:level:%s:duration_sec" % level_id)


func track_level_fail(level_id: String, score: int = 0) -> void:
	print("[Analytics] track_level_fail -> %s (%s)" % [level_id, score])
	_send_progression_event_with_score("fail", level_id, score)
	stop_timer_and_send("level:%s" % level_id, "time:level:%s:duration_sec" % level_id)


func track_minigame_start(minigame_id: String) -> void:
	print("[Analytics] track_minigame_start -> %s" % minigame_id)
	_send_progression_event("start", minigame_id)
	start_timer("minigame:%s" % minigame_id)


func track_minigame_complete(minigame_id: String, score: int = 0) -> void:
	print("[Analytics] track_minigame_complete -> %s (%s)" % [minigame_id, score])
	_send_progression_event_with_score("complete", minigame_id, score)
	stop_timer_and_send(
		"minigame:%s" % minigame_id,
		"time:minigame:%s:duration_sec" % minigame_id
	)


func track_minigame_fail(minigame_id: String, score: int = 0) -> void:
	print("[Analytics] track_minigame_fail -> %s (%s)" % [minigame_id, score])
	_send_progression_event_with_score("fail", minigame_id, score)
	stop_timer_and_send(
		"minigame:%s" % minigame_id,
		"time:minigame:%s:duration_sec" % minigame_id
	)


func _initialize_sdk() -> void:
	if sdk_ready:
		print("[Analytics] SDK already initialized")
		return

	if not Engine.has_singleton("GameAnalytics"):
		print("[Analytics] GameAnalytics singleton not found. Singletons: %s" % [Engine.get_singleton_list()])
		push_warning("GameAnalytics singleton is not available.")
		return

	game_analytics = Engine.get_singleton("GameAnalytics")
	if game_analytics == null:
		print("[Analytics] Engine reported GameAnalytics singleton, but get_singleton returned null")
		push_warning("GameAnalytics singleton could not be retrieved.")
		return

	print("[Analytics] GameAnalytics singleton acquired")
	game_analytics.setEnabledInfoLog(true)
	game_analytics.setEnabledVerboseLog(true)
	game_analytics.enableSDKInitEvent(true)
	game_analytics.configureBuild(BUILD_VERSION)
	game_analytics.configureAvailableResourceCurrencies(RESOURCE_CURRENCIES)
	game_analytics.configureAvailableResourceItemTypes(RESOURCE_ITEM_TYPES)
	game_analytics.configureAvailableCustomDimensions01(CUSTOM_DIMENSION_01_VALUES)
	game_analytics.configureAvailableCustomDimensions02(CUSTOM_DIMENSION_02_VALUES)
	game_analytics.setCustomDimension01(_get_build_channel())
	game_analytics.setCustomDimension02(_get_locale_dimension())
	game_analytics.setEnabledErrorReporting(true)
	game_analytics.configureAutoDetectAppVersion(true)
	game_analytics.setWritablePath(OS.get_user_data_dir())
	print("[Analytics] Initializing SDK with build %s, locale %s, writable path %s" % [
		BUILD_VERSION,
		_get_locale_dimension(),
		OS.get_user_data_dir()
	])
	game_analytics.init(GAME_KEY, SECRET_KEY)

	sdk_ready = true
	print("[Analytics] SDK init called")


func _get_build_channel() -> String:
	return "dev" if OS.is_debug_build() else "release"


func _get_locale_dimension() -> String:
	var locale := TranslationServer.get_locale().left(2)
	return locale if locale in CUSTOM_DIMENSION_02_VALUES else "en"


func _send_design_event(event_id: String) -> void:
	if not sdk_ready:
		print("[Analytics] Skip design event, SDK not ready -> %s" % event_id)
		return

	print("[Analytics] addDesignEvent -> %s" % event_id)
	game_analytics.addDesignEvent(event_id, {})


func _send_design_event_with_value(event_id: String, value: float) -> void:
	if not sdk_ready:
		print("[Analytics] Skip design event with value, SDK not ready -> %s" % event_id)
		return

	print("[Analytics] addDesignEventWithValue -> %s = %s" % [event_id, value])
	game_analytics.addDesignEventWithValue(event_id, value)


func _send_progression_event(
	status: String,
	progression_01: String,
	progression_02: String = "",
	progression_03: String = ""
) -> void:
	if not sdk_ready:
		print("[Analytics] Skip progression event, SDK not ready -> %s/%s/%s/%s" % [
			status,
			progression_01,
			progression_02,
			progression_03
		])
		return

	print("[Analytics] addProgressionEvent -> %s/%s/%s/%s" % [
		status,
		progression_01,
		progression_02,
		progression_03
	])
	game_analytics.addProgressionEvent(status, progression_01, progression_02, progression_03, {})


func _send_progression_event_with_score(
	status: String,
	progression_01: String,
	score: int,
	progression_02: String = "",
	progression_03: String = ""
) -> void:
	if not sdk_ready:
		print("[Analytics] Skip progression event with score, SDK not ready -> %s/%s/%s/%s" % [
			status,
			progression_01,
			progression_02,
			progression_03
		])
		return

	print("[Analytics] addProgressionEventWithScore -> %s/%s/%s/%s = %s" % [
		status,
		progression_01,
		progression_02,
		progression_03,
		score
	])
	game_analytics.addProgressionEventWithScore(
		status,
		progression_01,
		progression_02,
		progression_03,
		score
	)
