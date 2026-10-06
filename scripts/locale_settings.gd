extends Node

## Chooses the UI language (zh / en), persists the choice, and keeps the window title in sync.
## Default: Chinese when the OS/browser language is Chinese, English otherwise.

const LANG_ZH := "zh"
const LANG_EN := "en"
const BASE_SETTINGS_FILE := "language.cfg"
const WEB_STORAGE_KEY := "jx_language_cfg"
const SECTION := "language"
const KEY_LOCALE := "locale"

var _settings_path := "user://" + BASE_SETTINGS_FILE

func _ready() -> void:
	_settings_path = _resolve_settings_path()
	var saved := _load_saved_language()
	_apply_language(saved if saved != "" else default_language())

func default_language() -> String:
	return LANG_ZH if OS.get_locale_language() == LANG_ZH else LANG_EN

func current_language() -> String:
	return LANG_ZH if TranslationServer.get_locale().begins_with(LANG_ZH) else LANG_EN

func toggle_language() -> void:
	set_language(LANG_EN if current_language() == LANG_ZH else LANG_ZH)

func set_language(lang: String) -> void:
	if lang != LANG_ZH and lang != LANG_EN:
		push_warning("Unsupported language: %s" % lang)
		return
	_apply_language(lang)
	_save_language(lang)

func _apply_language(lang: String) -> void:
	TranslationServer.set_locale(lang)
	DisplayServer.window_set_title(tr("window_title"))

func _save_language(lang: String) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION, KEY_LOCALE, lang)
	DirAccess.make_dir_recursive_absolute(_settings_path.get_base_dir())
	var err := cfg.save(_settings_path)
	if err != OK:
		push_warning("Failed to save language setting (error %d)." % err)
	_write_web_backup(cfg)

func _load_saved_language() -> String:
	var cfg := ConfigFile.new()
	var err := cfg.load(_settings_path)
	if err != OK and OS.has_feature("web"):
		var text := _read_web_backup()
		if text != "":
			err = cfg.parse(text)
	if err != OK:
		return ""
	var lang := str(cfg.get_value(SECTION, KEY_LOCALE, ""))
	return lang if lang == LANG_ZH or lang == LANG_EN else ""

func _resolve_settings_path() -> String:
	if OS.has_feature("web"):
		return "user://web/" + BASE_SETTINGS_FILE
	if OS.has_feature("mobile"):
		return "user://mobile/" + BASE_SETTINGS_FILE
	return "user://" + BASE_SETTINGS_FILE

func _write_web_backup(cfg: ConfigFile) -> void:
	if not OS.has_feature("web") or not Engine.has_singleton("JavaScriptBridge"):
		return
	var storage = JavaScriptBridge.get_interface("localStorage")
	if storage == null:
		return
	storage.setItem(WEB_STORAGE_KEY, cfg.encode_to_text())

func _read_web_backup() -> String:
	if not OS.has_feature("web") or not Engine.has_singleton("JavaScriptBridge"):
		return ""
	var storage = JavaScriptBridge.get_interface("localStorage")
	if storage == null:
		return ""
	var value: Variant = storage.getItem(WEB_STORAGE_KEY)
	return "" if value == null else str(value)
