extends Control
const MENU_BGM := preload("res://assets/audio/menu_bgm.wav")
@onready var local_bgm: AudioStreamPlayer = $LocalBgm

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$Center/Panel/VBox/Title.text = Loc.t("menu_title")
	$Center/Panel/VBox/Subtitle.text = Loc.t("menu_subtitle")
	$Center/Panel/VBox/StartButton.text = Loc.t("menu_start")
	$Center/Panel/VBox/CodexButton.text = Loc.t("menu_codex")
	$Center/Panel/VBox/QuitButton.text = Loc.t("menu_quit")
	$Center/Panel/VBox/StartButton.pressed.connect(_on_start_pressed)
	$Center/Panel/VBox/CodexButton.pressed.connect(_on_codex_pressed)
	$Center/Panel/VBox/QuitButton.pressed.connect(_on_quit_pressed)
	_init_local_bgm()
	if AudioManager != null:
		AudioManager.play_menu()

func _process(_delta: float) -> void:
	if local_bgm != null and not local_bgm.playing:
		local_bgm.play()

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/EndlessMode2D.tscn")

func _on_codex_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Codex.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _init_local_bgm() -> void:
	if local_bgm == null:
		return
	if AudioServer.get_bus_count() > 0:
		AudioServer.set_bus_mute(0, false)
		AudioServer.set_bus_volume_db(0, 0.0)
	var stream: AudioStream = load("res://assets/audio/menu_bgm.wav") as AudioStream
	if stream == null:
		stream = MENU_BGM
	if stream is AudioStreamWAV:
		var wav := (stream as AudioStreamWAV).duplicate() as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream = wav
	local_bgm.stream = stream
	local_bgm.bus = "Master"
	local_bgm.volume_db = -4.0
	local_bgm.play()
