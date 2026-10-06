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
@onready var backup_title: Label = $Center/Panel/VBox/BackupTitle
@onready var backup_text: TextEdit = $Center/Panel/VBox/BackupText
@onready var export_button: Button = $Center/Panel/VBox/BackupButtons/ExportButton
@onready var import_button: Button = $Center/Panel/VBox/BackupButtons/ImportButton
@onready var backup_status: Label = $Center/Panel/VBox/BackupStatus
@onready var back_button: Button = $Center/Panel/VBox/BackButton

const BACKUP_VERSION := 1

func _ready() -> void:
	title_label.text = tr("settings_title")
	master_label.text = tr("settings_master")
	bgm_label.text = tr("settings_bgm")
	sfx_label.text = tr("settings_sfx")
	backup_title.text = tr("settings_backup_title")
	backup_text.placeholder_text = tr("settings_backup_placeholder")
	export_button.text = tr("settings_backup_export")
	import_button.text = tr("settings_backup_import")
	backup_status.text = ""
	back_button.text = tr("menu_back")
	back_button.pressed.connect(_on_back_pressed)
	export_button.pressed.connect(_on_export_pressed)
	import_button.pressed.connect(_on_import_pressed)

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
	master_value.text = tr("settings_value") % int(round(master_slider.value))
	bgm_value.text = tr("settings_value") % int(round(bgm_slider.value))
	sfx_value.text = tr("settings_value") % int(round(sfx_slider.value))

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_export_pressed() -> void:
	var payload := {
		"version": BACKUP_VERSION,
		"progression": {},
		"audio": {}
	}
	if ProgressionManager != null:
		payload["progression"] = ProgressionManager.export_snapshot()
	if AudioManager != null:
		payload["audio"] = AudioManager.export_snapshot()
	backup_text.text = JSON.stringify(payload, "\t")
	backup_status.text = tr("settings_backup_export_ok")

func _on_import_pressed() -> void:
	var raw := backup_text.text.strip_edges()
	if raw == "":
		backup_status.text = tr("settings_backup_import_empty")
		return
	var parsed: Variant = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		backup_status.text = tr("settings_backup_import_fail")
		return
	var root := parsed as Dictionary
	var imported_any := false
	var progression_data: Variant = root.get("progression", null)
	if progression_data is Dictionary and ProgressionManager != null:
		imported_any = ProgressionManager.import_snapshot(progression_data) or imported_any
	var audio_data: Variant = root.get("audio", null)
	if audio_data is Dictionary and AudioManager != null:
		imported_any = AudioManager.import_snapshot(audio_data) or imported_any
	if not imported_any:
		backup_status.text = tr("settings_backup_import_fail")
		return
	_sync_from_audio()
	backup_status.text = tr("settings_backup_import_ok")
