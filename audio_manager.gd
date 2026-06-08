extends Node

const MAIN_THEME := preload("res://Audio/Music/main_theme.mp3")
const MINIGAME_MUSIC := preload("res://Audio/Music/Minigame_sound.mp3")
const LEVEL_3_MUSIC := preload("res://Audio/Music/lvl3_background_music.mp3")
const FINAL_PRESSURE := preload("res://Audio/SFX/lvl1/final_pressure.mp3")
const FINAL_TOILET_FLUSH := preload("res://Audio/SFX/lvl1/final_zvuk-unitaza.mp3")
const ZIPPER := preload("res://Audio/SFX/lvl2/zipper.mp3")
const LEVEL_2_RUN := preload("res://Audio/SFX/lvl2/run.mp3")
const LEVEL_2_STATION_RAILWAY_STATION := preload("res://Audio/SFX/lvl2/station-railway-station.mp3")
const LEVEL_2_INFORMATOR_RAILWAY := preload("res://Audio/SFX/lvl2/informator-railway.mp3")
const LEVEL_2_TRAIN_INSIDE := preload("res://Audio/SFX/lvl2/train-inside.mp3")
const LEVEL_2_ANNOUNCEMENT_STATION := preload("res://Audio/SFX/lvl2/announcement_station.mp3")
const LEVEL_2_ZIPPER_CLOSE_NEW := preload("res://Audio/SFX/lvl2/zipper-close-new.mp3")
const YOU_DIED := preload("res://Audio/SFX/lvl2/mini game/you died.mp3")
const WIN := preload("res://Audio/SFX/lvl2/mini game/win.mp3")
const MUSIC_BUS := &"Music"
const SFX_BUS := &"SFX"
const MINIGAME_MUSIC_LOOP_FADE_DURATION := 0.75
const LEVEL_3_INTRO_FIELDS_BACKGROUND := preload("res://Audio/SFX/lvl3_before/Fields_background.mp3")
const LEVEL_3_INTRO_STOMACH_SOUND := preload("res://Audio/SFX/lvl3_before/stomach_sound.mp3")
const LEVEL_3_INTRO_RUN_AWAY := preload("res://Audio/SFX/lvl3_before/Run_away.mp3")
const LEVEL_3_INTRO_CLOSE_THE_DOOR := preload("res://Audio/SFX/lvl3_before/Close_the_door.mp3")
const LEVEL_3_HAPPY_BIRTHDAY := preload("res://Audio/SFX/lvl3_after/Happy Birthday Song.mp3")
const LEVEL_1_INTRO_BG_ROOM := preload("res://Audio/SFX/lvl1_before/bg_room.mp3")
const LEVEL_1_INTRO_BIP_BIP := preload("res://Audio/SFX/lvl1_before/bip-bip.mp3")
const LEVEL_1_INTRO_ERROR := preload("res://Audio/SFX/lvl1_before/error.mp3")
const LEVEL_1_CALL_RING_PHONE := preload("res://Audio/SFX/lvl1_before/ring_phone.mp3")
const TYPEWRITER_SFX := preload("res://Audio/SFX/keyboard for text.mp3")
const LEVEL_3_INTRO_FIELDS_VOLUME := 0.3
const LEVEL_3_HAPPY_BIRTHDAY_VOLUME := 0.15
const LEVEL_3_MUSIC_VOLUME := 0.15
const MAIN_THEME_VOLUME := 0.3
const LEVEL_1_CALL_RING_PHONE_VOLUME := 0.5
const LEVEL_2_RUN_VOLUME := 0.5
const LEVEL_2_RAILWAY_VOLUME := 0.3
const LEVEL_2_TRAIN_INSIDE_VOLUME := 0.06
const LEVEL_2_ANNOUNCEMENT_STATION_VOLUME := 0.5
const LEVEL_2_ZIPPER_CLOSE_NEW_VOLUME := 0.5
const YOU_DIED_VOLUME := 0.4
const TYPEWRITER_VOLUME := 0.05

var music_player: AudioStreamPlayer
var level_3_intro_ambience_player: AudioStreamPlayer
var typewriter_player: AudioStreamPlayer
var pops_since_last_fart := 0
var restart_music_on_finish := false
var minigame_music_loop_enabled := false
var minigame_music_loop_transitioning := false
var music_fade_tween: Tween
var level_3_intro_ambience_should_loop := false

var bubble_burst_streams: Array[AudioStream] = [
	preload("res://Audio/bubble_burst1.mp3"),
	preload("res://Audio/bubble_burst2.mp3"),
	preload("res://Audio/bubble_burst3.mp3"),
	preload("res://Audio/bubble_burst4.mp3"),
]

var fart_streams: Array[AudioStream] = [
	preload("res://Audio/fart_sound1.mp3"),
	preload("res://Audio/fart_sound2.mp3"),
	preload("res://Audio/fart_sound3.mp3"),
]

var level_3_bug_death_streams := {
	&"fly": preload("res://Audio/SFX/lvl3Mobs/fly.mp3"),
	&"maggot": preload("res://Audio/SFX/lvl3Mobs/maggot.mp3"),
	&"mantis": preload("res://Audio/SFX/lvl3Mobs/mantis.mp3"),
	&"spider": preload("res://Audio/SFX/lvl3Mobs/spider.mp3"),
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	music_player = AudioStreamPlayer.new()
	music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(music_player)

	music_player.bus = MUSIC_BUS
	music_player.finished.connect(_on_music_finished)

	level_3_intro_ambience_player = AudioStreamPlayer.new()
	level_3_intro_ambience_player.process_mode = Node.PROCESS_MODE_ALWAYS
	level_3_intro_ambience_player.bus = "Master"
	level_3_intro_ambience_player.volume_db = linear_to_db(LEVEL_3_INTRO_FIELDS_VOLUME)
	level_3_intro_ambience_player.finished.connect(_on_level_3_intro_ambience_finished)
	add_child(level_3_intro_ambience_player)

	typewriter_player = AudioStreamPlayer.new()
	typewriter_player.process_mode = Node.PROCESS_MODE_ALWAYS
	typewriter_player.bus = SFX_BUS
	typewriter_player.stream = _create_looping_typewriter_stream()
	add_child(typewriter_player)


func play_minigame_music() -> void:
	minigame_music_loop_enabled = true
	minigame_music_loop_transitioning = false
	_play_music(MINIGAME_MUSIC)


func play_minigame_music_from(offset_seconds: float, volume_linear: float = 1.0) -> void:
	if music_player == null or MINIGAME_MUSIC == null:
		return

	minigame_music_loop_enabled = false
	minigame_music_loop_transitioning = false
	restart_music_on_finish = false
	_stop_music_fade_tween()

	music_player.stream = MINIGAME_MUSIC
	music_player.volume_db = linear_to_db(volume_linear)
	music_player.play(maxf(offset_seconds, 0.0))


func play_main_theme() -> void:
	minigame_music_loop_enabled = false
	minigame_music_loop_transitioning = false
	var main_theme_stream := MAIN_THEME.duplicate() as AudioStreamMP3
	if main_theme_stream == null:
		_play_music(MAIN_THEME, true, MAIN_THEME_VOLUME)
		return

	main_theme_stream.loop = true
	_play_music(main_theme_stream, false, MAIN_THEME_VOLUME)


func play_level_3_music() -> void:
	minigame_music_loop_enabled = false
	minigame_music_loop_transitioning = false
	_play_music(LEVEL_3_MUSIC, true, LEVEL_3_MUSIC_VOLUME)


func stop_music() -> void:
	restart_music_on_finish = false
	minigame_music_loop_enabled = false
	minigame_music_loop_transitioning = false
	_stop_music_fade_tween()

	if music_player == null:
		return

	music_player.stop()
	music_player.stream = null
	music_player.volume_db = 0.0


func fade_out_music(duration: float) -> void:
	restart_music_on_finish = false
	minigame_music_loop_enabled = false
	minigame_music_loop_transitioning = false
	_stop_music_fade_tween()

	if music_player == null or not music_player.playing:
		return

	music_fade_tween = create_tween()
	music_fade_tween.tween_property(music_player, "volume_db", -80.0, duration)
	await music_fade_tween.finished

	music_player.stop()
	music_player.volume_db = 0.0
	music_fade_tween = null


func play_level_3_intro_fields_background() -> void:
	if level_3_intro_ambience_player == null:
		return

	stop_music()

	if level_3_intro_ambience_player.playing:
		return

	var fields_stream := LEVEL_3_INTRO_FIELDS_BACKGROUND.duplicate() as AudioStreamMP3
	if fields_stream != null:
		fields_stream.loop = true
		level_3_intro_ambience_player.stream = fields_stream
	else:
		level_3_intro_ambience_player.stream = LEVEL_3_INTRO_FIELDS_BACKGROUND
	level_3_intro_ambience_player.volume_db = linear_to_db(LEVEL_3_INTRO_FIELDS_VOLUME)
	level_3_intro_ambience_should_loop = true
	level_3_intro_ambience_player.play()


func stop_level_3_intro_ambience() -> void:
	level_3_intro_ambience_should_loop = false

	if level_3_intro_ambience_player == null:
		return

	level_3_intro_ambience_player.stop()


func play_level_3_intro_stomach_sound() -> AudioStreamPlayer:
	return _play_stream(LEVEL_3_INTRO_STOMACH_SOUND)


func play_level_3_intro_run_away() -> AudioStreamPlayer:
	return _play_stream(LEVEL_3_INTRO_RUN_AWAY)


func play_level_3_intro_close_the_door() -> AudioStreamPlayer:
	return _play_stream(LEVEL_3_INTRO_CLOSE_THE_DOOR)


func play_level_3_happy_birthday() -> AudioStreamPlayer:
	var happy_birthday_stream := LEVEL_3_HAPPY_BIRTHDAY.duplicate() as AudioStreamMP3
	if happy_birthday_stream == null:
		return _play_stream(LEVEL_3_HAPPY_BIRTHDAY, LEVEL_3_HAPPY_BIRTHDAY_VOLUME)

	happy_birthday_stream.loop = true
	return _play_stream(happy_birthday_stream, LEVEL_3_HAPPY_BIRTHDAY_VOLUME)


func play_level_1_intro_bg_room() -> AudioStreamPlayer:
	var bg_room_stream := LEVEL_1_INTRO_BG_ROOM.duplicate() as AudioStreamMP3
	if bg_room_stream == null:
		return _play_stream(LEVEL_1_INTRO_BG_ROOM)

	bg_room_stream.loop = true
	return _play_stream(bg_room_stream)


func play_level_1_intro_bip_bip() -> AudioStreamPlayer:
	var bip_bip_stream := LEVEL_1_INTRO_BIP_BIP.duplicate() as AudioStreamMP3
	if bip_bip_stream == null:
		return _play_stream(LEVEL_1_INTRO_BIP_BIP)

	bip_bip_stream.loop = true
	return _play_stream(bip_bip_stream)


func play_level_1_intro_error() -> AudioStreamPlayer:
	return _play_stream(LEVEL_1_INTRO_ERROR)


func play_level_1_call_ring_phone() -> AudioStreamPlayer:
	return _play_stream(LEVEL_1_CALL_RING_PHONE, LEVEL_1_CALL_RING_PHONE_VOLUME)


func start_typewriter_sfx(speed_scale: float = 1.0) -> void:
	if typewriter_player == null or TYPEWRITER_SFX == null:
		return

	if typewriter_player.stream == null:
		typewriter_player.stream = _create_looping_typewriter_stream()

	typewriter_player.volume_db = linear_to_db(TYPEWRITER_VOLUME)
	typewriter_player.pitch_scale = 1.0
	typewriter_player.play()


func set_typewriter_speed(speed_scale: float) -> void:
	return


func stop_typewriter_sfx() -> void:
	if typewriter_player == null:
		return

	typewriter_player.stop()


func play_fart_mob_pop_sounds() -> void:
	_play_random_stream(bubble_burst_streams)

	var should_play_fart := pops_since_last_fart >= 3 or randf() < 0.25
	if should_play_fart:
		_play_random_stream(fart_streams)
		pops_since_last_fart = 0
		return

	pops_since_last_fart += 1


func play_level_3_bug_death_sound(bug_kind: StringName) -> void:
	var stream: AudioStream = level_3_bug_death_streams.get(bug_kind)
	if stream == null:
		return

	_play_stream(stream)


func play_fart_sound_3() -> void:
	_play_stream(preload("res://Audio/fart_sound3.mp3"))


func play_final_pressure() -> AudioStreamPlayer:
	return _play_stream(FINAL_PRESSURE)


func play_final_toilet_flush() -> AudioStreamPlayer:
	return _play_stream(FINAL_TOILET_FLUSH)


func play_zipper() -> AudioStreamPlayer:
	return _play_stream(ZIPPER)


func play_level_2_run() -> AudioStreamPlayer:
	return _play_stream(LEVEL_2_RUN, LEVEL_2_RUN_VOLUME)


func play_level_2_station_railway_station() -> AudioStreamPlayer:
	var station_stream := LEVEL_2_STATION_RAILWAY_STATION.duplicate() as AudioStreamMP3
	if station_stream == null:
		return _play_stream(LEVEL_2_STATION_RAILWAY_STATION, LEVEL_2_RAILWAY_VOLUME)

	station_stream.loop = true
	return _play_stream(station_stream, LEVEL_2_RAILWAY_VOLUME)


func play_level_2_informator_railway() -> AudioStreamPlayer:
	return _play_stream(LEVEL_2_INFORMATOR_RAILWAY, LEVEL_2_RAILWAY_VOLUME)


func play_level_2_train_inside(volume_linear: float = LEVEL_2_TRAIN_INSIDE_VOLUME) -> AudioStreamPlayer:
	var train_inside_stream := LEVEL_2_TRAIN_INSIDE.duplicate() as AudioStreamMP3
	if train_inside_stream == null:
		return _play_stream(LEVEL_2_TRAIN_INSIDE, volume_linear)

	train_inside_stream.loop = true
	return _play_stream(train_inside_stream, volume_linear)


func play_level_2_announcement_station() -> AudioStreamPlayer:
	return _play_stream(LEVEL_2_ANNOUNCEMENT_STATION, LEVEL_2_ANNOUNCEMENT_STATION_VOLUME)


func play_level_2_zipper_close_new() -> AudioStreamPlayer:
	var zipper_close_stream := LEVEL_2_ZIPPER_CLOSE_NEW.duplicate() as AudioStreamMP3
	if zipper_close_stream == null:
		return _play_stream(LEVEL_2_ZIPPER_CLOSE_NEW, LEVEL_2_ZIPPER_CLOSE_NEW_VOLUME)

	zipper_close_stream.loop = true
	return _play_stream(zipper_close_stream, LEVEL_2_ZIPPER_CLOSE_NEW_VOLUME)


func play_you_died() -> AudioStreamPlayer:
	return _play_stream(YOU_DIED, YOU_DIED_VOLUME)


func play_win() -> AudioStreamPlayer:
	return _play_stream(WIN)


func _play_random_stream(streams: Array[AudioStream]) -> void:
	if streams.is_empty():
		return

	_play_stream(streams[randi() % streams.size()])


func _play_stream(stream: AudioStream, volume_linear: float = 1.0) -> AudioStreamPlayer:
	if stream == null:
		return null

	var player := AudioStreamPlayer.new()
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	player.bus = SFX_BUS
	player.stream = stream
	player.volume_db = linear_to_db(volume_linear)
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
	return player


func _play_music(stream: AudioStream, should_restart_on_finish: bool = false, volume_linear: float = 1.0) -> void:
	if music_player == null or stream == null:
		return

	_stop_music_fade_tween()
	restart_music_on_finish = should_restart_on_finish
	var target_volume_db := linear_to_db(volume_linear)

	if music_player.stream == stream and music_player.playing:
		music_player.volume_db = target_volume_db
		return

	music_player.stream = stream
	music_player.volume_db = target_volume_db
	music_player.play()


func _on_music_finished() -> void:
	if minigame_music_loop_enabled:
		_restart_minigame_music_with_fade()
		return

	if not restart_music_on_finish:
		return

	if music_player == null or music_player.stream == null:
		return

	music_player.play()


func _process(_delta: float) -> void:
	if not _should_prepare_minigame_music_loop():
		return

	var stream_length := music_player.stream.get_length()
	if stream_length <= 0.0:
		return

	var remaining_time := stream_length - music_player.get_playback_position()
	if remaining_time > MINIGAME_MUSIC_LOOP_FADE_DURATION:
		return

	_restart_minigame_music_with_fade()


func _should_prepare_minigame_music_loop() -> bool:
	if not minigame_music_loop_enabled or minigame_music_loop_transitioning:
		return false

	if music_player == null or music_player.stream != MINIGAME_MUSIC:
		return false

	return music_player.playing


func _restart_minigame_music_with_fade() -> void:
	if minigame_music_loop_transitioning:
		return

	minigame_music_loop_transitioning = true
	_restart_minigame_music_with_fade_async()


func _restart_minigame_music_with_fade_async() -> void:
	if music_player == null or music_player.stream != MINIGAME_MUSIC:
		minigame_music_loop_transitioning = false
		return

	_stop_music_fade_tween()
	music_fade_tween = create_tween()
	music_fade_tween.tween_property(music_player, "volume_db", -80.0, MINIGAME_MUSIC_LOOP_FADE_DURATION)
	await music_fade_tween.finished

	if not minigame_music_loop_enabled or music_player == null:
		minigame_music_loop_transitioning = false
		return

	music_player.play(0.0)
	music_player.volume_db = -80.0
	music_fade_tween = create_tween()
	music_fade_tween.tween_property(music_player, "volume_db", 0.0, MINIGAME_MUSIC_LOOP_FADE_DURATION)
	await music_fade_tween.finished

	music_fade_tween = null
	minigame_music_loop_transitioning = false


func _stop_music_fade_tween() -> void:
	if music_fade_tween == null:
		return

	if music_fade_tween.is_valid():
		music_fade_tween.kill()

	music_fade_tween = null


func _on_level_3_intro_ambience_finished() -> void:
	if not level_3_intro_ambience_should_loop:
		return

	if level_3_intro_ambience_player == null:
		return

	level_3_intro_ambience_player.play()


func _create_looping_typewriter_stream() -> AudioStream:
	var typewriter_stream := TYPEWRITER_SFX.duplicate() as AudioStreamMP3
	if typewriter_stream == null:
		return TYPEWRITER_SFX

	typewriter_stream.loop = true
	return typewriter_stream
