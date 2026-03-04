extends Control

const CHEAT_CODE := "BOOST10000"
const POTENTIAL_CHEAT_CODE := "POT1000"
const CHEAT_BUFFER_MAX := 24

var _cheat_buffer := ""
var _subtitle_default := ""
var _subtitle_restore_t := 0.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$Center/Panel/VBox/Title.text = Loc.t("menu_title")
	$Center/Panel/VBox/Subtitle.text = Loc.t("menu_subtitle")
	_subtitle_default = $Center/Panel/VBox/Subtitle.text
	$Center/Panel/VBox/StartButton.text = Loc.t("menu_start")
	$Center/Panel/VBox/CodexButton.text = Loc.t("menu_codex")
	$Center/Panel/VBox/PotentialButton.text = Loc.t("menu_potential")
	$Center/Panel/VBox/SettingsButton.text = Loc.t("menu_settings")
	$Center/Panel/VBox/QuitButton.text = Loc.t("menu_quit")
	$Center/Panel/VBox/StartButton.pressed.connect(_on_start_pressed)
	$Center/Panel/VBox/CodexButton.pressed.connect(_on_codex_pressed)
	$Center/Panel/VBox/PotentialButton.pressed.connect(_on_potential_pressed)
	$Center/Panel/VBox/SettingsButton.pressed.connect(_on_settings_pressed)
	$Center/Panel/VBox/QuitButton.pressed.connect(_on_quit_pressed)
	if AudioManager != null:
		AudioManager.play_menu()
	else:
		push_error("AudioManager singleton is null in MainMenu.")

func _process(delta: float) -> void:
	if _subtitle_restore_t <= 0.0:
		return
	_subtitle_restore_t = maxf(0.0, _subtitle_restore_t - delta)
	if _subtitle_restore_t <= 0.0:
		$Center/Panel/VBox/Subtitle.text = _subtitle_default

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == KEY_ENTER or key_event.keycode == KEY_KP_ENTER:
		_try_apply_score_cheat()
		_cheat_buffer = ""
		return
	if key_event.keycode == KEY_BACKSPACE:
		if _cheat_buffer.length() > 0:
			_cheat_buffer = _cheat_buffer.substr(0, _cheat_buffer.length() - 1)
		return
	if key_event.unicode <= 0:
		return
	var ch := char(key_event.unicode).to_upper()
	if not _is_cheat_char(ch):
		return
	_cheat_buffer += ch
	if _cheat_buffer.length() > CHEAT_BUFFER_MAX:
		_cheat_buffer = _cheat_buffer.substr(_cheat_buffer.length() - CHEAT_BUFFER_MAX, CHEAT_BUFFER_MAX)

func _is_cheat_char(ch: String) -> bool:
	if ch.length() != 1:
		return false
	var code := ch.unicode_at(0)
	if code >= 48 and code <= 57:
		return true
	if code >= 65 and code <= 90:
		return true
	return false

func _try_apply_score_cheat() -> void:
	if _cheat_buffer == POTENTIAL_CHEAT_CODE:
		_try_apply_potential_cheat()
		return
	if _cheat_buffer != CHEAT_CODE:
		return
	if ProgressionManager == null or not ProgressionManager.has_method("add_cheat_score_from_current"):
		return
	var gained: int = int(ProgressionManager.add_cheat_score_from_current(10000))
	var subtitle: Label = $Center/Panel/VBox/Subtitle
	if gained > 0:
		subtitle.text = Loc.t("menu_cheat_ok") % [gained, ProgressionManager.score_bank]
	else:
		subtitle.text = Loc.t("menu_cheat_zero")
	_subtitle_restore_t = 3.0

func _try_apply_potential_cheat() -> void:
	if ProgressionManager == null or not ProgressionManager.has_method("add_cheat_potential_levels"):
		return
	var add_lv: int = int(ProgressionManager.add_cheat_potential_levels(1000))
	var subtitle: Label = $Center/Panel/VBox/Subtitle
	if add_lv > 0:
		subtitle.text = Loc.t("menu_potential_cheat_ok") % add_lv
	else:
		subtitle.text = Loc.t("menu_potential_cheat_zero")
	_subtitle_restore_t = 3.0

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/EndlessMode2D.tscn")

func _on_codex_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Codex.tscn")

func _on_potential_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/PotentialMenu.tscn")

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/SettingsMenu.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
