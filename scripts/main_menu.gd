extends Control

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$Center/Panel/VBox/Title.text = Loc.t("menu_title")
	$Center/Panel/VBox/Subtitle.text = Loc.t("menu_subtitle")
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
