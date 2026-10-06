extends Node

const MENU_BGM := preload("res://assets/audio/menu_bgm.ogg")
const BATTLE_BGM := preload("res://assets/audio/battle_bgm.ogg")
const BASE_SETTINGS_FILE := "settings.cfg"
const WEB_STORAGE_KEY := "jx_audio_cfg"
const AUDIO_SECTION := "audio"
const KEY_MASTER := "master_volume"
const KEY_BGM := "bgm_volume"
const KEY_SFX := "sfx_volume"

var _bgm_player: AudioStreamPlayer
var _target := "none"
var _master_volume := 1.0
var _bgm_volume := 1.0
var _sfx_volume := 1.0
var _settings_path := "user://settings.cfg"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_settings_path = _resolve_settings_path()
	_ensure_settings_dir()
	_load_settings()
	_ensure_player()
	_apply_audio_settings()
	play_menu()

# The headless display pairs with the dummy audio driver, which never mixes, so
# stopped playbacks are never reclaimed and are reported as leaks at exit.
func can_play() -> bool:
	return DisplayServer.get_name() != "headless"

func play_menu() -> void:
	_target = "menu"
	_play_target_stream(MENU_BGM)

func play_battle() -> void:
	_target = "battle"
	_play_target_stream(BATTLE_BGM)

func stop_all() -> void:
	_target = "none"
	if _bgm_player != null:
		_bgm_player.stop()

func _process(_delta: float) -> void:
	if _target == "none" or not can_play():
		return
	if _bgm_player == null:
		_ensure_player()
	if _bgm_player.stream_paused:
		_bgm_player.stream_paused = false
	if not _bgm_player.playing:
		_bgm_player.play()

func _ensure_player() -> void:
	if _bgm_player != null:
		return
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.name = "BgmPlayer"
	_bgm_player.bus = "Master"
	_bgm_player.volume_db = 0.0
	_bgm_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_bgm_player)

func _play_target_stream(stream: AudioStream) -> void:
	_ensure_player()
	if stream == null or not can_play():
		return
	if stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	if _bgm_player.stream != stream:
		_bgm_player.stream = stream
	_bgm_player.stream_paused = false
	_bgm_player.play()

func set_master_volume(value: float) -> void:
	_master_volume = clampf(value, 0.0, 1.0)
	_apply_audio_settings()
	_save_settings()

func set_bgm_volume(value: float) -> void:
	_bgm_volume = clampf(value, 0.0, 1.0)
	_apply_audio_settings()
	_save_settings()

func set_sfx_volume(value: float) -> void:
	_sfx_volume = clampf(value, 0.0, 1.0)
	_apply_audio_settings()
	_save_settings()

func get_master_volume() -> float:
	return _master_volume

func get_bgm_volume() -> float:
	return _bgm_volume

func get_sfx_volume() -> float:
	return _sfx_volume

func get_sfx_volume_db() -> float:
	return _linear_to_db_safe(_sfx_volume)

func export_snapshot() -> Dictionary:
	return {
		KEY_MASTER: _master_volume,
		KEY_BGM: _bgm_volume,
		KEY_SFX: _sfx_volume
	}

func import_snapshot(data: Dictionary) -> bool:
	if data.is_empty():
		return false
	_master_volume = clampf(float(data.get(KEY_MASTER, _master_volume)), 0.0, 1.0)
	_bgm_volume = clampf(float(data.get(KEY_BGM, _bgm_volume)), 0.0, 1.0)
	_sfx_volume = clampf(float(data.get(KEY_SFX, _sfx_volume)), 0.0, 1.0)
	_apply_audio_settings()
	_save_settings()
	return true

func _apply_audio_settings() -> void:
	if AudioServer.get_bus_count() > 0:
		AudioServer.set_bus_mute(0, false)
		AudioServer.set_bus_volume_db(0, _linear_to_db_safe(_master_volume))
	if _bgm_player != null:
		_bgm_player.volume_db = _linear_to_db_safe(_bgm_volume)

func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(AUDIO_SECTION, KEY_MASTER, _master_volume)
	cfg.set_value(AUDIO_SECTION, KEY_BGM, _bgm_volume)
	cfg.set_value(AUDIO_SECTION, KEY_SFX, _sfx_volume)
	cfg.save(_settings_path)
	_write_web_backup(cfg)

func _load_settings() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(_settings_path)
	if err != OK and OS.has_feature("web"):
		var text := _read_web_backup()
		if text != "":
			err = cfg.parse(text)
	if err != OK:
		return
	_master_volume = clampf(float(cfg.get_value(AUDIO_SECTION, KEY_MASTER, 1.0)), 0.0, 1.0)
	_bgm_volume = clampf(float(cfg.get_value(AUDIO_SECTION, KEY_BGM, 1.0)), 0.0, 1.0)
	_sfx_volume = clampf(float(cfg.get_value(AUDIO_SECTION, KEY_SFX, 1.0)), 0.0, 1.0)

func _resolve_settings_path() -> String:
	if OS.has_feature("web"):
		return "user://web/" + BASE_SETTINGS_FILE
	if OS.has_feature("mobile"):
		return "user://mobile/" + BASE_SETTINGS_FILE
	return "user://" + BASE_SETTINGS_FILE

func _ensure_settings_dir() -> void:
	var sep := _settings_path.rfind("/")
	if sep <= 0:
		return
	var dir_path := _settings_path.substr(0, sep)
	DirAccess.make_dir_recursive_absolute(dir_path)

func _write_web_backup(cfg: ConfigFile) -> void:
	if not OS.has_feature("web"):
		return
	if not Engine.has_singleton("JavaScriptBridge"):
		return
	var storage = JavaScriptBridge.get_interface("localStorage")
	if storage == null:
		return
	storage.setItem(WEB_STORAGE_KEY, cfg.encode_to_text())

func _read_web_backup() -> String:
	if not OS.has_feature("web"):
		return ""
	if not Engine.has_singleton("JavaScriptBridge"):
		return ""
	var storage = JavaScriptBridge.get_interface("localStorage")
	if storage == null:
		return ""
	var value: Variant = storage.getItem(WEB_STORAGE_KEY)
	if value == null:
		return ""
	return str(value)

func _linear_to_db_safe(value: float) -> float:
	if value <= 0.0001:
		return -80.0
	return linear_to_db(value)

