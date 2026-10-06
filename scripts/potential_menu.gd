extends Control

@onready var title_label: Label = $Center/Panel/Scroll/VBox/Title
@onready var bank_label: Label = $Center/Panel/Scroll/VBox/BankLabel
@onready var total_label: Label = $Center/Panel/Scroll/VBox/TotalLabel
@onready var best_label: Label = $Center/Panel/Scroll/VBox/BestLabel
@onready var hp_button: Button = $Center/Panel/Scroll/VBox/HpButton
@onready var atk_button: Button = $Center/Panel/Scroll/VBox/AtkButton
@onready var speed_button: Button = $Center/Panel/Scroll/VBox/SpeedButton
@onready var magic_button: Button = $Center/Panel/Scroll/VBox/MagicButton
@onready var tree_title: Label = $Center/Panel/Scroll/VBox/TreeTitle
@onready var melee_branch_button: Button = $Center/Panel/Scroll/VBox/MeleeBranchButton
@onready var ranged_branch_button: Button = $Center/Panel/Scroll/VBox/RangedBranchButton
@onready var spell_branch_button: Button = $Center/Panel/Scroll/VBox/SpellBranchButton
@onready var arcane_button: Button = $Center/Panel/Scroll/VBox/ArcaneButton
@onready var frost_button: Button = $Center/Panel/Scroll/VBox/FrostButton
@onready var tip_label: Label = $Center/Panel/Scroll/VBox/TipLabel
@onready var desc_title: Label = $Center/Panel/Scroll/VBox/DescTitle
@onready var desc_label: Label = $Center/Panel/Scroll/VBox/DescLabel
@onready var back_button: Button = $Center/Panel/Scroll/VBox/BackButton
var _default_desc := ""
var _tooltip_panel: PanelContainer
var _tooltip_label: Label

func _ready() -> void:
	title_label.text = tr("potential_title")
	back_button.text = tr("menu_back")
	back_button.pressed.connect(_on_back_pressed)
	hp_button.pressed.connect(_buy_hp)
	atk_button.pressed.connect(_buy_atk)
	speed_button.pressed.connect(_buy_speed)
	magic_button.pressed.connect(_buy_magic)
	melee_branch_button.pressed.connect(_buy_melee_branch)
	ranged_branch_button.pressed.connect(_buy_ranged_branch)
	spell_branch_button.pressed.connect(_buy_spell_branch)
	arcane_button.pressed.connect(_buy_arcane)
	frost_button.pressed.connect(_buy_frost)
	desc_title.text = tr("potential_desc_title")
	_default_desc = tr("potential_desc_body")
	desc_label.text = _default_desc
	_init_tooltip()
	_bind_hover_desc(hp_button, "potential_desc_hp")
	_bind_hover_desc(atk_button, "potential_desc_atk")
	_bind_hover_desc(speed_button, "potential_desc_speed")
	_bind_hover_desc(magic_button, "potential_desc_magic")
	_bind_hover_desc(melee_branch_button, "potential_desc_tree_melee")
	_bind_hover_desc(ranged_branch_button, "potential_desc_tree_ranged")
	_bind_hover_desc(spell_branch_button, "potential_desc_tree_spell")
	_bind_hover_desc(arcane_button, "potential_desc_arcane")
	_bind_hover_desc(frost_button, "potential_desc_frost")
	_refresh()

func _refresh() -> void:
	if ProgressionManager == null:
		return
	bank_label.text = tr("potential_bank") % ProgressionManager.score_bank
	total_label.text = tr("potential_total") % ProgressionManager.total_earned
	best_label.text = tr("potential_best") % ProgressionManager.best_run_score
	hp_button.text = tr("potential_hp") % [ProgressionManager.hp_level, ProgressionManager.hp_cost()]
	atk_button.text = tr("potential_atk") % [ProgressionManager.atk_level, ProgressionManager.atk_cost()]
	speed_button.text = tr("potential_speed") % [ProgressionManager.speed_level, ProgressionManager.speed_cost()]
	magic_button.text = tr("potential_magic") % [ProgressionManager.magic_level, ProgressionManager.magic_cost()]
	tree_title.text = tr("potential_tree_title")
	melee_branch_button.text = tr("potential_tree_melee") % [ProgressionManager.melee_branch_level, ProgressionManager.melee_branch_cost()]
	ranged_branch_button.text = tr("potential_tree_ranged") % [ProgressionManager.ranged_branch_level, ProgressionManager.ranged_branch_cost()]
	spell_branch_button.text = tr("potential_tree_spell") % [ProgressionManager.spell_branch_level, ProgressionManager.spell_branch_cost()]
	if ProgressionManager.unlock_arcane_bolt:
		arcane_button.text = tr("potential_skill_arcane_owned")
		arcane_button.disabled = true
	else:
		arcane_button.text = tr("potential_skill_arcane_locked") % ProgressionManager.arcane_bolt_cost()
		arcane_button.disabled = false
	if ProgressionManager.unlock_frost_nova:
		frost_button.text = tr("potential_skill_frost_owned")
		frost_button.disabled = true
	else:
		frost_button.text = tr("potential_skill_frost_locked") % ProgressionManager.frost_nova_cost()
		frost_button.disabled = false

func _set_tip(ok: bool) -> void:
	tip_label.text = tr("potential_done") if ok else tr("potential_not_enough")

func _buy_hp() -> void:
	var ok := ProgressionManager != null and ProgressionManager.buy_hp()
	_set_tip(ok)
	_refresh()

func _buy_atk() -> void:
	var ok := ProgressionManager != null and ProgressionManager.buy_atk()
	_set_tip(ok)
	_refresh()

func _buy_speed() -> void:
	var ok := ProgressionManager != null and ProgressionManager.buy_speed()
	_set_tip(ok)
	_refresh()

func _buy_magic() -> void:
	var ok := ProgressionManager != null and ProgressionManager.buy_magic()
	_set_tip(ok)
	_refresh()

func _buy_melee_branch() -> void:
	var ok := ProgressionManager != null and ProgressionManager.buy_melee_branch()
	_set_tip(ok)
	_refresh()

func _buy_ranged_branch() -> void:
	var ok := ProgressionManager != null and ProgressionManager.buy_ranged_branch()
	_set_tip(ok)
	_refresh()

func _buy_spell_branch() -> void:
	var ok := ProgressionManager != null and ProgressionManager.buy_spell_branch()
	_set_tip(ok)
	_refresh()

func _buy_arcane() -> void:
	var ok := ProgressionManager != null and ProgressionManager.buy_arcane_bolt()
	_set_tip(ok)
	_refresh()

func _buy_frost() -> void:
	var ok := ProgressionManager != null and ProgressionManager.buy_frost_nova()
	_set_tip(ok)
	_refresh()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _bind_hover_desc(btn: BaseButton, desc_key: String) -> void:
	btn.mouse_entered.connect(func() -> void:
		_show_tooltip(tr(desc_key))
	)
	btn.mouse_exited.connect(func() -> void:
		_hide_tooltip()
	)

func _process(_delta: float) -> void:
	if _tooltip_panel == null or not _tooltip_panel.visible:
		return
	var mouse := get_viewport().get_mouse_position()
	var offset := Vector2(18.0, 16.0)
	var desired := mouse + offset
	var vp := get_viewport_rect().size
	var tip_size := _tooltip_panel.size
	if desired.x + tip_size.x > vp.x - 8.0:
		desired.x = mouse.x - tip_size.x - 12.0
	if desired.y + tip_size.y > vp.y - 8.0:
		desired.y = mouse.y - tip_size.y - 12.0
	_tooltip_panel.position = desired

func _init_tooltip() -> void:
	_tooltip_panel = PanelContainer.new()
	_tooltip_panel.visible = false
	_tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_panel.custom_minimum_size = Vector2(360.0, 0.0)
	_tooltip_panel.z_index = 200
	_tooltip_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	add_child(_tooltip_panel)

	_tooltip_label = Label.new()
	_tooltip_label.autowrap_mode = 3
	_tooltip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_label.custom_minimum_size = Vector2(360.0, 0.0)
	_tooltip_panel.add_child(_tooltip_label)

func _show_tooltip(text: String) -> void:
	if _tooltip_panel == null or _tooltip_label == null:
		return
	_tooltip_label.text = text
	_tooltip_panel.visible = true

func _hide_tooltip() -> void:
	if _tooltip_panel == null:
		return
	_tooltip_panel.visible = false
