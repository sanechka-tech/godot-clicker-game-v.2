extends Node

const ENGLISH_EXPORT_FEATURE := "default_locale_en"
const RUSSIAN_EXPORT_FEATURE := "default_locale_ru"


func _enter_tree() -> void:
	if OS.has_feature(RUSSIAN_EXPORT_FEATURE):
		TranslationServer.set_locale("ru")
		return

	if OS.has_feature(ENGLISH_EXPORT_FEATURE):
		TranslationServer.set_locale("en")
