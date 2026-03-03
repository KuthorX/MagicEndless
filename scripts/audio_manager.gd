extends Node

const MENU_BGM := preload("res://assets/audio/menu_bgm.wav")
const BATTLE_BGM := preload("res://assets/audio/battle_bgm.wav")

var _menu_player: AudioStreamPlayer
var _battle_player: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if AudioServer.get_bus_count() > 0:
		AudioServer.set_bus_mute(0, false)
		AudioServer.set_bus_volume_db(0, 0.0)
	_menu_player = _make_player("MenuBgm", MENU_BGM, 0)
	_battle_player = _make_player("BattleBgm", BATTLE_BGM, 0)
	call_deferred("_boot_play_menu")

func play_menu() -> void:
	if _menu_player.stream == null:
		_menu_player.stream = _force_loop(load("res://assets/audio/menu_bgm.wav"))
	if _menu_player.stream == null:
		return
	if _battle_player.playing:
		_battle_player.stop()
	_menu_player.play()

func play_battle() -> void:
	if _battle_player.stream == null:
		_battle_player.stream = _force_loop(load("res://assets/audio/battle_bgm.wav"))
	if _battle_player.stream == null:
		return
	if _menu_player.playing:
		_menu_player.stop()
	_battle_player.play()

func stop_all() -> void:
	_menu_player.stop()
	_battle_player.stop()

func _process(_delta: float) -> void:
	# Keep loop robust even if an imported stream reports playback end.
	if _menu_player.playing and not _menu_player.has_stream_playback():
		_menu_player.play()
	if _battle_player.playing and not _battle_player.has_stream_playback():
		_battle_player.play()

func _make_player(name: String, stream: AudioStream, volume_db: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = name
	player.bus = "Master"
	player.volume_db = volume_db
	player.stream = _force_loop(stream)
	add_child(player)
	return player

func _force_loop(stream: AudioStream) -> AudioStream:
	if stream is AudioStreamWAV:
		var wav := (stream as AudioStreamWAV).duplicate() as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		return wav
	return stream

func _boot_play_menu() -> void:
	if not _menu_player.playing and not _battle_player.playing:
		play_menu()
