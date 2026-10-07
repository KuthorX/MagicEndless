extends Control

const CHEAT_CODE := "BOOST10000"
const POTENTIAL_CHEAT_CODE := "POT1000"
const CHEAT_BUFFER_MAX := 24

var _cheat_buffer := ""
var _subtitle_default := ""
var _subtitle_restore_t := 0.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	%Title.text = tr("menu_title_display")
	# The line under the title stays empty; it only carries short feedback (cheat codes).
	%Subtitle.text = ""
	_subtitle_default = ""
	%StartButton.text = tr("menu_start")
	%CodexButton.text = tr("menu_codex")
	%PotentialButton.text = tr("menu_potential")
	%SettingsButton.text = tr("menu_settings")
	%QuitButton.text = tr("menu_quit")
	%LanguageButton.text = tr("menu_language")
	# The web build cannot close its tab, so Quit would do nothing there.
	%QuitButton.visible = not OS.has_feature("web")
	%StartButton.pressed.connect(_on_start_pressed)
	%CodexButton.pressed.connect(_on_codex_pressed)
	%PotentialButton.pressed.connect(_on_potential_pressed)
	%SettingsButton.pressed.connect(_on_settings_pressed)
	%QuitButton.pressed.connect(_on_quit_pressed)
	%LanguageButton.pressed.connect(_on_language_pressed)
	%StartButton.grab_focus.call_deferred()
	if AudioManager != null:
		AudioManager.play_menu()
	else:
		push_error("AudioManager singleton is null in MainMenu.")
	if DebugShot.is_battle_shot():
		_on_start_pressed.call_deferred()
	match DebugShot.mode:
		"codex":
			_on_codex_pressed.call_deferred()
		"potential":
			_on_potential_pressed.call_deferred()
		"settings":
			_on_settings_pressed.call_deferred()

func _process(delta: float) -> void:
	if _subtitle_restore_t <= 0.0:
		return
	_subtitle_restore_t = maxf(0.0, _subtitle_restore_t - delta)
	if _subtitle_restore_t <= 0.0:
		%Subtitle.text = _subtitle_default

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
	var subtitle: Label = %Subtitle
	if gained > 0:
		subtitle.text = tr("menu_cheat_ok") % [gained, ProgressionManager.score_bank]
	else:
		subtitle.text = tr("menu_cheat_zero")
	_subtitle_restore_t = 3.0

func _try_apply_potential_cheat() -> void:
	if ProgressionManager == null or not ProgressionManager.has_method("add_cheat_potential_levels"):
		return
	var add_lv: int = int(ProgressionManager.add_cheat_potential_levels(1000))
	var subtitle: Label = %Subtitle
	if add_lv > 0:
		subtitle.text = tr("menu_potential_cheat_ok") % add_lv
	else:
		subtitle.text = tr("menu_potential_cheat_zero")
	_subtitle_restore_t = 3.0

func _on_start_pressed() -> void:
	if AudioManager != null:
		AudioManager.play_sfx("ui_confirm")
	get_tree().change_scene_to_file("res://scenes/EndlessMode2D.tscn")

func _on_codex_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Codex.tscn")

func _on_potential_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/PotentialMenu.tscn")

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/SettingsMenu.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_language_pressed() -> void:
	LocaleSettings.toggle_language()
	get_tree().reload_current_scene()
