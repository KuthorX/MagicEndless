extends Node
## Music and sound for the War Grimoire. Score: D yu pentatonic, guzheng / dizi / xiao /
## bianqing / taiko (see docs/audio-direction.md). Music runs on the "Music" bus, effects on "SFX".
## Battle music is two synchronised stems; the taiko stem rises wave by wave.

const MENU_BGM := preload("res://assets/audio/music/menu.ogg")
const BATTLE_BASE := preload("res://assets/audio/music/battle_base.ogg")
const BATTLE_WAR := preload("res://assets/audio/music/battle_war.ogg")
const BOSS_BGM := preload("res://assets/audio/music/boss.ogg")
const GAMEOVER_BGM := preload("res://assets/audio/music/gameover.ogg")
const SFX := {
	"shoot_normal": preload("res://assets/audio/sfx/shoot_normal.wav"),
	"shoot_pierce": preload("res://assets/audio/sfx/shoot_pierce.wav"),
	"shoot_burst": preload("res://assets/audio/sfx/shoot_burst.wav"),
	"shoot_ricochet": preload("res://assets/audio/sfx/shoot_ricochet.wav"),
	"shoot_hex": preload("res://assets/audio/sfx/shoot_hex.wav"),
	"sword": preload("res://assets/audio/sfx/sword.wav"),
	"arcane": preload("res://assets/audio/sfx/arcane.wav"),
	"nova": preload("res://assets/audio/sfx/nova.ogg"),
	"chain": preload("res://assets/audio/sfx/chain.wav"),
	"meteor": preload("res://assets/audio/sfx/meteor.ogg"),
	"hit": preload("res://assets/audio/sfx/hit.wav"),
	"enemy_die": preload("res://assets/audio/sfx/enemy_die.wav"),
	"enemy_shoot": preload("res://assets/audio/sfx/enemy_shoot.wav"),
	"hurt": preload("res://assets/audio/sfx/hurt.wav"),
	"shield_on": preload("res://assets/audio/sfx/shield_on.ogg"),
	"shield_off": preload("res://assets/audio/sfx/shield_off.wav"),
	"shield_hit": preload("res://assets/audio/sfx/shield_hit.wav"),
	"dash": preload("res://assets/audio/sfx/dash.wav"),
	"mode_switch": preload("res://assets/audio/sfx/mode_switch.wav"),
	"card_show": preload("res://assets/audio/sfx/card_show.wav"),
	"card_pick": preload("res://assets/audio/sfx/card_pick.ogg"),
	"wave_start": preload("res://assets/audio/sfx/wave_start.ogg"),
	"respawn": preload("res://assets/audio/sfx/wave_start.ogg"),
	"wave_clear": preload("res://assets/audio/sfx/wave_clear.ogg"),
	"boss_appear": preload("res://assets/audio/sfx/boss_appear.ogg"),
	"objective_success": preload("res://assets/audio/sfx/objective_success.ogg"),
	"objective_fail": preload("res://assets/audio/sfx/objective_fail.ogg"),
	"player_die": preload("res://assets/audio/sfx/player_die.ogg"),
	"ui_hover": preload("res://assets/audio/sfx/ui_hover.wav"),
	"ui_click": preload("res://assets/audio/sfx/ui_click.wav"),
	"ui_confirm": preload("res://assets/audio/sfx/ui_confirm.wav"),
	"ui_success": preload("res://assets/audio/sfx/ui_success.ogg"),
	"ui_fail": preload("res://assets/audio/sfx/ui_fail.wav"),
}
## Sounds that fire many times a second: at most this many voices, this far apart, pitch-jittered.
const SFX_LIMITS := {
	"hit": [4, 0.045], "enemy_shoot": [3, 0.06], "enemy_die": [4, 0.05], "sword": [2, 0.12],
	"shoot_normal": [3, 0.05], "shoot_pierce": [3, 0.05], "shoot_burst": [3, 0.05],
	"shoot_ricochet": [3, 0.05], "shoot_hex": [3, 0.05], "ui_hover": [2, 0.04],
}
const SFX_JITTER := ["hit", "enemy_shoot", "enemy_die", "sword", "shoot_normal", "shoot_pierce",
	"shoot_burst", "shoot_ricochet", "shoot_hex", "ui_hover", "ui_click", "chain", "arcane"]
const SFX_DEFAULT_LIMIT := [3, 0.03]
const SFX_POOL_SIZE := 16
const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"
const CROSSFADE_SEC := 1.2
const SILENT_DB := -60.0
## War-stem level per wave (index = wave, last entry holds); intermission ducks it further.
const WAR_DB_BY_WAVE := [-60.0, -60.0, -14.0, -9.0, -5.0, -2.0, 0.0]
const WAR_INTERMISSION_DUCK_DB := -12.0
const BASE_SETTINGS_FILE := "settings.cfg"
const WEB_STORAGE_KEY := "jx_audio_cfg"
const AUDIO_SECTION := "audio"
const KEY_MASTER := "master_volume"
const KEY_BGM := "bgm_volume"
const KEY_SFX := "sfx_volume"

## Requests per sound name and music cue history; read by tests (also when playback is off).
var sfx_counts := {}
var music_log: Array[String] = []

var _music_players: Array[AudioStreamPlayer] = []
var _active := 0
var _target := "none"
var _battle_stream: AudioStreamSynchronized
var _war_db := SILENT_DB
var _war_tween: Tween
var _fade_tween: Tween
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_last := {}
var _master_volume := 1.0
var _bgm_volume := 1.0
var _sfx_volume := 1.0
var _settings_path := "user://settings.cfg"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_settings_path = _resolve_settings_path()
	_ensure_settings_dir()
	_load_settings()
	_ensure_buses()
	_ensure_players()
	_apply_audio_settings()
	get_tree().node_added.connect(_on_node_added)
	play_menu()

# The headless display pairs with the dummy audio driver, which never mixes, so
# stopped playbacks are never reclaimed and are reported as leaks at exit.
func can_play() -> bool:
	return DisplayServer.get_name() != "headless"

# ---- music ---------------------------------------------------------------------------------

func play_menu() -> void:
	_switch_music("menu", MENU_BGM)

func play_battle() -> void:
	if _target == "battle":
		return
	_war_db = SILENT_DB
	if _battle_stream == null:
		_battle_stream = AudioStreamSynchronized.new()
		_battle_stream.stream_count = 2
		_battle_stream.set_sync_stream(0, BATTLE_BASE)
		_battle_stream.set_sync_stream(1, BATTLE_WAR)
	_battle_stream.set_sync_stream_volume(1, _war_db)
	_switch_music("battle", _battle_stream)

func play_boss() -> void:
	_switch_music("boss", BOSS_BGM)

func play_game_over() -> void:
	_switch_music("gameover", GAMEOVER_BGM)

## Escalates the taiko stem with the wave number; `fighting` is false between waves.
func set_battle_intensity(wave: int, fighting: bool) -> void:
	var idx := clampi(wave, 0, WAR_DB_BY_WAVE.size() - 1)
	var db: float = WAR_DB_BY_WAVE[idx]
	if not fighting and db > SILENT_DB:
		db = maxf(SILENT_DB, db + WAR_INTERMISSION_DUCK_DB)
	music_log.append("intensity:%d:%s:%.0f" % [wave, "fight" if fighting else "rest", db])
	if _battle_stream == null:
		return
	if _war_tween != null:
		_war_tween.kill()
	_war_tween = create_tween()
	_war_tween.tween_method(_set_war_db, _war_db, db, 2.0)

func get_music_target() -> String:
	return _target

func stop_all() -> void:
	_target = "none"
	for p in _music_players:
		p.stop()

func _set_war_db(db: float) -> void:
	_war_db = db
	if _battle_stream != null:
		_battle_stream.set_sync_stream_volume(1, db)

func _switch_music(target: String, stream: AudioStream) -> void:
	_ensure_players()
	if _target == target:
		return
	_target = target
	music_log.append(target)
	if stream == null or not can_play():
		return
	var old := _music_players[_active]
	_active = 1 - _active
	var cur := _music_players[_active]
	cur.stream = stream
	cur.volume_db = SILENT_DB if old.playing else 0.0
	cur.play()
	if _fade_tween != null:
		_fade_tween.kill()
	if not old.playing:
		return
	_fade_tween = create_tween().set_parallel(true)
	_fade_tween.tween_property(cur, "volume_db", 0.0, CROSSFADE_SEC).set_trans(Tween.TRANS_SINE)
	_fade_tween.tween_property(old, "volume_db", SILENT_DB, CROSSFADE_SEC).set_trans(Tween.TRANS_SINE)
	_fade_tween.chain().tween_callback(old.stop)

func _process(_delta: float) -> void:
	# Web builds may refuse playback before the first user gesture: keep retrying loops.
	if _target == "none" or _target == "gameover" or not can_play() or _music_players.is_empty():
		return
	var cur := _music_players[_active]
	if cur.stream_paused:
		cur.stream_paused = false
	if not cur.playing and cur.stream != null:
		cur.volume_db = 0.0
		cur.play()

func _ensure_players() -> void:
	if not _music_players.is_empty():
		return
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.name = "MusicPlayer%d" % i
		p.bus = MUSIC_BUS
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p)
		_music_players.append(p)
	for i in SFX_POOL_SIZE:
		var s := AudioStreamPlayer.new()
		s.name = "Sfx%d" % i
		s.bus = SFX_BUS
		s.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(s)
		_sfx_pool.append(s)

func _ensure_buses() -> void:
	for bus_name in [MUSIC_BUS, SFX_BUS]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.get_bus_count() - 1
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")

# ---- sound effects -------------------------------------------------------------------------

func play_sfx(sfx_name: String) -> void:
	if not SFX.has(sfx_name):
		push_warning("Unknown SFX: %s" % sfx_name)
		return
	sfx_counts[sfx_name] = int(sfx_counts.get(sfx_name, 0)) + 1
	if not can_play():
		return
	var limit: Array = SFX_LIMITS.get(sfx_name, SFX_DEFAULT_LIMIT)
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_sfx_last.get(sfx_name, -10.0)) < float(limit[1]):
		return
	var stream: AudioStream = SFX[sfx_name]
	var voices := 0
	var free_player: AudioStreamPlayer = null
	for p in _sfx_pool:
		if p.playing:
			if p.stream == stream:
				voices += 1
		elif free_player == null:
			free_player = p
	if voices >= int(limit[0]) or free_player == null:
		return
	_sfx_last[sfx_name] = now
	free_player.stream = stream
	free_player.pitch_scale = randf_range(0.94, 1.06) if SFX_JITTER.has(sfx_name) else 1.0
	free_player.play()

## Every button in every menu gets a paper tick on hover and a wood tap on press.
func _on_node_added(node: Node) -> void:
	if not node is BaseButton:
		return
	var btn := node as BaseButton
	btn.mouse_entered.connect(func() -> void:
		if not btn.disabled:
			play_sfx("ui_hover"))
	btn.pressed.connect(play_sfx.bind("ui_click"))

# ---- settings ------------------------------------------------------------------------------

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
	var music_idx := AudioServer.get_bus_index(MUSIC_BUS)
	if music_idx != -1:
		AudioServer.set_bus_volume_db(music_idx, _linear_to_db_safe(_bgm_volume))
	var sfx_idx := AudioServer.get_bus_index(SFX_BUS)
	if sfx_idx != -1:
		AudioServer.set_bus_volume_db(sfx_idx, _linear_to_db_safe(_sfx_volume))

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

