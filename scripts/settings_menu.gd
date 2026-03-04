extends Control

@onready var title_label: Label = $Center/Panel/VBox/Title
@onready var master_label: Label = $Center/Panel/VBox/MasterRow/Name
@onready var master_slider: HSlider = $Center/Panel/VBox/MasterRow/Slider
@onready var master_value: Label = $Center/Panel/VBox/MasterRow/Value
@onready var bgm_label: Label = $Center/Panel/VBox/BgmRow/Name
@onready var bgm_slider: HSlider = $Center/Panel/VBox/BgmRow/Slider
@onready var bgm_value: Label = $Center/Panel/VBox/BgmRow/Value
@onready var sfx_label: Label = $Center/Panel/VBox/SfxRow/Name
@onready var sfx_slider: HSlider = $Center/Panel/VBox/SfxRow/Slider
@onready var sfx_value: Label = $Center/Panel/VBox/SfxRow/Value
@onready var back_button: Button = $Center/Panel/VBox/BackButton

func _ready() -> void:
	title_label.text = Loc.t("settings_title")
	master_label.text = Loc.t("settings_master")
	bgm_label.text = Loc.t("settings_bgm")
	sfx_label.text = Loc.t("settings_sfx")
	back_button.text = Loc.t("menu_back")
	back_button.pressed.connect(_on_back_pressed)

	master_slider.value_changed.connect(_on_master_changed)
	bgm_slider.value_changed.connect(_on_bgm_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	_sync_from_audio()

func _sync_from_audio() -> void:
	var master := 1.0
	var bgm := 1.0
	var sfx := 1.0
	if AudioManager != null:
		master = AudioManager.get_master_volume()
		bgm = AudioManager.get_bgm_volume()
		sfx = AudioManager.get_sfx_volume()
	master_slider.value = master * 100.0
	bgm_slider.value = bgm * 100.0
	sfx_slider.value = sfx * 100.0
	_update_value_labels()

func _on_master_changed(value: float) -> void:
	if AudioManager != null:
		AudioManager.set_master_volume(value / 100.0)
	_update_value_labels()

func _on_bgm_changed(value: float) -> void:
	if AudioManager != null:
		AudioManager.set_bgm_volume(value / 100.0)
	_update_value_labels()

func _on_sfx_changed(value: float) -> void:
	if AudioManager != null:
		AudioManager.set_sfx_volume(value / 100.0)
	_update_value_labels()

func _update_value_labels() -> void:
	master_value.text = Loc.t("settings_value") % int(round(master_slider.value))
	bgm_value.text = Loc.t("settings_value") % int(round(bgm_slider.value))
	sfx_value.text = Loc.t("settings_value") % int(round(sfx_slider.value))

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
