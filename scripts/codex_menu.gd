extends Control

func _ready() -> void:
	$Center/Panel/VBox/Title.text = Loc.t("codex_title")
	$Center/Panel/VBox/Tabs.set_tab_title(0, Loc.t("codex_enemy_title"))
	$Center/Panel/VBox/Tabs.set_tab_title(1, Loc.t("codex_skill_title"))

	$Center/Panel/VBox/Tabs/EnemiesTab/Scroll/VBox/Intro.text = Loc.t("codex_enemy_intro")
	$Center/Panel/VBox/Tabs/EnemiesTab/Scroll/VBox/ChaserRow/Text.text = Loc.t("codex_enemy_1")
	$Center/Panel/VBox/Tabs/EnemiesTab/Scroll/VBox/ShooterRow/Text.text = Loc.t("codex_enemy_2")
	$Center/Panel/VBox/Tabs/EnemiesTab/Scroll/VBox/DasherRow/Text.text = Loc.t("codex_enemy_3")
	$Center/Panel/VBox/Tabs/EnemiesTab/Scroll/VBox/SniperRow/Text.text = Loc.t("codex_enemy_4")
	$Center/Panel/VBox/Tabs/EnemiesTab/Scroll/VBox/ArtilleryRow/Text.text = Loc.t("codex_enemy_5")
	$Center/Panel/VBox/Tabs/EnemiesTab/Scroll/VBox/BossRow/Text.text = Loc.t("codex_enemy_6")

	$Center/Panel/VBox/Tabs/EnemiesTab/Scroll/VBox/LegendTitle.text = Loc.t("codex_legend_title")
	$Center/Panel/VBox/Tabs/EnemiesTab/Scroll/VBox/TeleShootRow/Text.text = Loc.t("codex_legend_shoot")
	$Center/Panel/VBox/Tabs/EnemiesTab/Scroll/VBox/TeleDashRow/Text.text = Loc.t("codex_legend_dash")
	$Center/Panel/VBox/Tabs/EnemiesTab/Scroll/VBox/TeleSniperRow/Text.text = Loc.t("codex_legend_sniper")
	$Center/Panel/VBox/Tabs/EnemiesTab/Scroll/VBox/TeleBurstRow/Text.text = Loc.t("codex_legend_burst")
	$Center/Panel/VBox/Tabs/EnemiesTab/Scroll/VBox/TeleTotemRow/Text.text = Loc.t("codex_legend_totem")

	$Center/Panel/VBox/Tabs/SystemsTab/Scroll/VBox/SystemsTitle.text = Loc.t("codex_systems_title")
	$Center/Panel/VBox/Tabs/SystemsTab/Scroll/VBox/Sys1.text = Loc.t("codex_systems_1")
	$Center/Panel/VBox/Tabs/SystemsTab/Scroll/VBox/Sys2.text = Loc.t("codex_systems_2")
	$Center/Panel/VBox/Tabs/SystemsTab/Scroll/VBox/Sys3.text = Loc.t("codex_systems_3")
	$Center/Panel/VBox/Tabs/SystemsTab/Scroll/VBox/Sys4.text = Loc.t("codex_systems_4")
	$Center/Panel/VBox/Tabs/SystemsTab/Scroll/VBox/Sys5.text = Loc.t("codex_systems_5")

	$Center/Panel/VBox/BackButton.text = Loc.t("menu_back")
	$Center/Panel/VBox/BackButton.pressed.connect(_on_back_pressed)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
