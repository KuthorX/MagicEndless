extends Control

func _ready() -> void:
	$Center/Panel/VBox/Title.text = Loc.t("codex_title")
	$Center/Panel/VBox/EnemyTitle.text = Loc.t("codex_enemy_title")
	$Center/Panel/VBox/Enemy1.text = Loc.t("codex_enemy_1")
	$Center/Panel/VBox/Enemy2.text = Loc.t("codex_enemy_2")
	$Center/Panel/VBox/Enemy3.text = Loc.t("codex_enemy_3")
	$Center/Panel/VBox/Enemy4.text = Loc.t("codex_enemy_4")
	$Center/Panel/VBox/Enemy5.text = Loc.t("codex_enemy_5")
	$Center/Panel/VBox/Enemy6.text = Loc.t("codex_enemy_6")
	$Center/Panel/VBox/SkillTitle.text = Loc.t("codex_skill_title")
	$Center/Panel/VBox/Skill1.text = Loc.t("codex_skill_1")
	$Center/Panel/VBox/Skill2.text = Loc.t("codex_skill_2")
	$Center/Panel/VBox/Skill3.text = Loc.t("codex_skill_3")
	$Center/Panel/VBox/Skill4.text = Loc.t("codex_skill_4")
	$Center/Panel/VBox/Skill5.text = Loc.t("codex_skill_5")
	$Center/Panel/VBox/BackButton.text = Loc.t("menu_back")
	$Center/Panel/VBox/BackButton.pressed.connect(_on_back_pressed)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
