extends Node2D
@export var enemy_scene: PackedScene
@export var projectile_scene: PackedScene
@export var enemy_projectile_scene: PackedScene
@export var sword_scene: PackedScene
@export var hazard_scene: PackedScene
@export var boss_totem_scene: PackedScene

const SFX := {
	"shoot": preload("res://assets/audio/sfx_shoot.wav"),
	"sword": preload("res://assets/audio/sfx_sword_soft.wav"),
	"hit": preload("res://assets/audio/sfx_hit.wav"),
	"hurt": preload("res://assets/audio/sfx_hit.wav"),
	"shield_hit": preload("res://assets/audio/sfx_hit.wav"),
	"dash": preload("res://assets/audio/sfx_dash.wav"),
	"mode_switch": preload("res://assets/audio/sfx_card_pick.wav"),
	"respawn": preload("res://assets/audio/sfx_wave_start.wav"),
	"shield_on": preload("res://assets/audio/sfx_shield_on.wav"),
	"shield_off": preload("res://assets/audio/sfx_shield_off.wav"),
	"card_pick": preload("res://assets/audio/sfx_card_pick.wav"),
	"wave_start": preload("res://assets/audio/sfx_wave_start.wav"),
	"wave_clear": preload("res://assets/audio/sfx_wave_clear.wav"),
	"enemy_shoot": preload("res://assets/audio/sfx_enemy_shoot.wav")
}
const VirtualStickScript := preload("res://scripts/virtual_stick.gd")
const DISPLAY_FONT_PATH := "res://assets/fonts/display.tres"
const WALL_STROKES: Array[Texture2D] = [
	preload("res://assets/art/brush/stroke_0.png"), preload("res://assets/art/brush/stroke_1.png"),
	preload("res://assets/art/brush/stroke_2.png"), preload("res://assets/art/brush/stroke_3.png"),
	preload("res://assets/art/brush/stroke_4.png"), preload("res://assets/art/brush/stroke_5.png"),
]
const WALL_DAUBS: Array[Texture2D] = [
	preload("res://assets/art/brush/daub_0.png"), preload("res://assets/art/brush/daub_1.png"),
	preload("res://assets/art/brush/daub_2.png"),
]
## Blocks longer than this (length / thickness) are cut as one brush stroke, shorter ones as a daub.
const STROKE_MIN_ASPECT := 2.2
const DEBUG_SHOT_START_WAVE := 4
const DEBUG_SHOT_BATTLE_SECONDS := 4.0
const WALL_PALE_INK := 0.55
## A cool neutral grey: the print shader keeps neutrals as ink, so pale walls stay grey, not brown.
const WALL_WASH := Color(0.6, 0.6, 0.62)
const CARD_MIN_HEIGHT := 200.0
const CARD_MAX_HEIGHT := 360.0
const CARD_TEXT_PADDING := 64.0
const MESSAGE_MIN_SECONDS := 1.8
const MESSAGE_MAX_SECONDS := 4.5
const MESSAGE_SECONDS_PER_CHAR := 0.05

const INTERMISSION_SECONDS := 5.0
const PREVIEW_SECONDS := 3.0
const PREVIEW_ENEMY_COUNT := 8
const BASE_SPAWN_INTERVAL := 0.35
const MINI_BOSS_INTERVAL := 5
const AFFLICTION_INTERVAL := 4
const ARCHETYPE_THRESHOLD := 12.0
const ARCHETYPE_MAX := 24.0
const ARCHETYPES: Array[String] = ["blade", "ballistic", "arcane", "tactical"]

const ENEMY_TYPE_LABEL := {
	0: "enemy_chaser",
	1: "enemy_shooter",
	2: "enemy_dasher",
	3: "enemy_sniper",
	4: "enemy_artillery",
	5: "enemy_warden",
	6: "enemy_warlock",
	7: "enemy_beacon",
	8: "enemy_lancer"
}
const ENEMY_FACTION := {
	0: 0, 1: 0, 2: 3, 3: 1, 4: 1, 5: 0, 6: 2, 7: 1, 8: 3
}
const ENEMY_ROLE := {
	0: 0, 1: 1, 2: 1, 3: 4, 4: 4, 5: 0, 6: 3, 7: 2, 8: 0
}
const TERRAIN_THEME_LABEL := {
	0: "terrain_theme_ruins",
	1: "terrain_theme_frost",
	2: "terrain_theme_void",
	3: "terrain_theme_storm"
}
const MUTATOR_POOL: Array[Dictionary] = [
	{
		"id": "none",
		"label": "mutator_none",
		"spawn_mul": 1.0,
		"enemy_hp_mul": 1.0,
		"enemy_speed_mul": 1.0,
		"hazard_extra": 0
	},
	{
		"id": "swarm",
		"label": "mutator_swarm",
		"spawn_mul": 1.35,
		"enemy_hp_mul": 0.92,
		"enemy_speed_mul": 1.08,
		"hazard_extra": 1
	},
	{
		"id": "fortified",
		"label": "mutator_fortified",
		"spawn_mul": 0.9,
		"enemy_hp_mul": 1.32,
		"enemy_speed_mul": 0.95,
		"hazard_extra": 0
	},
	{
		"id": "hunters",
		"label": "mutator_hunters",
		"spawn_mul": 1.0,
		"enemy_hp_mul": 1.08,
		"enemy_speed_mul": 1.08,
		"hazard_extra": 1
	},
	{
		"id": "cataclysm",
		"label": "mutator_cataclysm",
		"spawn_mul": 1.12,
		"enemy_hp_mul": 1.12,
		"enemy_speed_mul": 1.02,
		"hazard_extra": 2
	}
]

const RARITY_LABEL := {
	"common": "rarity_common",
	"rare": "rarity_rare",
	"epic": "rarity_epic"
}

const RARITY_COLOR := {
	"common": Ink.SUMI,
	"rare": Ink.INDIGO,
	"epic": Ink.VERMILION
}

const ELITE_MODS: Array[Dictionary] = [
	{"name": "Titan", "hp_mul": 1.8, "dmg_mul": 1.2, "speed_mul": 0.9, "color": Color(0.90, 0.72, 0.20, 1.0)},
	{"name": "Haste", "hp_mul": 1.1, "dmg_mul": 1.0, "speed_mul": 1.2, "color": Color(0.33, 0.95, 0.92, 1.0)},
	{"name": "Berserk", "hp_mul": 1.3, "dmg_mul": 1.45, "speed_mul": 1.08, "color": Color(0.97, 0.35, 0.35, 1.0)},
	{"name": "Summoner", "hp_mul": 1.25, "dmg_mul": 1.0, "speed_mul": 0.95, "ability_summon": true, "color": Color(0.95, 0.78, 0.40, 1.0)},
	{"name": "Splitter", "hp_mul": 1.15, "dmg_mul": 1.0, "speed_mul": 1.05, "ability_split": true, "color": Color(0.83, 0.52, 1.0, 1.0)},
	{"name": "ShieldBreak", "hp_mul": 1.2, "dmg_mul": 1.15, "speed_mul": 1.0, "ability_shield_break": true, "color": Color(0.42, 0.90, 0.98, 1.0)}
]

const CARD_POOL: Array[Dictionary] = [
	{"title":"card_blade_temper_t", "desc":"card_blade_temper_d", "rarity":"common", "effect":{"sword_damage_add": 12}},
	{"title":"card_wide_arc_t", "desc":"card_wide_arc_d", "rarity":"common", "effect":{"sword_radius_add": 18.0}},
	{"title":"card_rapid_slash_t", "desc":"card_rapid_slash_d", "rarity":"rare", "effect":{"sword_cd_mul": 0.86}},
	{"title":"card_spin_up_t", "desc":"card_spin_up_d", "rarity":"rare", "effect":{"sword_speed_mul": 1.22}},
	{"title":"card_storm_blade_t", "desc":"card_storm_blade_d", "rarity":"epic", "effect":{"sword_speed_mul": 1.35}},
	{"title":"card_impact_core_t", "desc":"card_impact_core_d", "rarity":"common", "effect":{"shot_damage_add": 8}},
	{"title":"card_rail_coil_t", "desc":"card_rail_coil_d", "rarity":"common", "effect":{"shot_speed_add": 80.0}},
	{"title":"card_trigger_rhythm_t", "desc":"card_trigger_rhythm_d", "rarity":"rare", "effect":{"shot_cd_mul": 0.88}},
	{"title":"card_splitshot_t", "desc":"card_splitshot_d", "rarity":"rare", "effect":{"shot_multishot_add": 1}},
	{"title":"card_drill_t", "desc":"card_drill_d", "rarity":"rare", "effect":{"shot_pierce_bonus": 1}},
	{"title":"card_quick_steps_t", "desc":"card_quick_steps_d", "rarity":"common", "effect":{"move_speed_mul": 1.10}},
	{"title":"card_blink_module_t", "desc":"card_blink_module_d", "rarity":"rare", "effect":{"dash_cd_mul": 0.82}},
	{"title":"card_dash_engine_t", "desc":"card_dash_engine_d", "rarity":"rare", "effect":{"dash_speed_add": 90.0}},
	{"title":"card_displacement_t", "desc":"card_displacement_d", "rarity":"rare", "effect":{"dash_distance_mul": 1.20}},
	{"title":"card_warp_core_t", "desc":"card_warp_core_d", "rarity":"epic", "effect":{"dash_distance_mul": 1.35}},
	{"title":"card_impact_dash_t", "desc":"card_impact_dash_d", "rarity":"rare", "effect":{"dash_impact_add": 22, "dash_impact_radius_add": 18.0}},
	{"title":"card_deflect_t", "desc":"card_deflect_d", "rarity":"rare", "effect":{"shield_drain_mul": 0.82}},
	{"title":"card_recharge_t", "desc":"card_recharge_d", "rarity":"rare", "effect":{"shield_regen_mul": 1.20}},
	{"title":"card_echo_t", "desc":"card_echo_d", "rarity":"epic", "effect":{"sword_echo_add": 0.22}},
	{"title":"card_vital_t", "desc":"card_vital_d", "rarity":"common", "effect":{"max_hp_add": 30.0, "heal_add": 20.0}},
	{"title":"card_shield_t", "desc":"card_shield_d", "rarity":"common", "effect":{"max_sp_add": 25.0, "sp_add": 20.0}},
	{"title":"card_blood_t", "desc":"card_blood_d", "rarity":"epic", "effect":{"lifesteal_add": 0.05}},
	{"title":"card_ricochet_t", "desc":"card_ricochet_d", "rarity":"rare", "effect":{"shot_ricochet_add": 1}},
	{"title":"card_hex_amplifier_t", "desc":"card_hex_amplifier_d", "rarity":"epic", "effect":{"shot_hex_explode_add": 14.0, "shot_hex_chain_add": 1}},
	{"title":"card_hex_guidance_t", "desc":"card_hex_guidance_d", "rarity":"rare", "effect":{"shot_hex_homing_add": 0.35}},
	{"title":"card_chain_sigil_t", "desc":"card_chain_sigil_d", "rarity":"epic", "effect":{"unlock_chain_sigil": true, "magic_haste_mul": 1.08}},
	{"title":"card_meteor_rain_t", "desc":"card_meteor_rain_d", "rarity":"epic", "effect":{"unlock_meteor_rain": true, "magic_power_mul": 1.12}},
	{"title":"card_meteor_shards_t", "desc":"card_meteor_shards_d", "rarity":"rare", "effect":{"meteor_strikes_add": 1}},
	{"title":"card_meteor_crater_t", "desc":"card_meteor_crater_d", "rarity":"rare", "effect":{"meteor_radius_add": 10.0}},
	{"title":"card_meteor_rush_t", "desc":"card_meteor_rush_d", "rarity":"rare", "effect":{"meteor_delay_mul": 0.86}},
	{"title":"card_meteor_core_t", "desc":"card_meteor_core_d", "rarity":"epic", "effect":{"meteor_damage_add": 9, "magic_power_mul": 1.06}},
	{"title":"card_meteor_echo_t", "desc":"card_meteor_echo_d", "rarity":"epic", "effect":{"meteor_echo_add": 1}},
	{"title":"card_resonance_t", "desc":"card_resonance_d", "rarity":"epic", "effect":{"resonance_gain_mul": 1.28}},
	{"title":"card_meteor_style_shower_t", "desc":"card_meteor_style_shower_d", "rarity":"epic", "effect":{"meteor_style_shower": true}},
	{"title":"card_meteor_style_cata_t", "desc":"card_meteor_style_cata_d", "rarity":"epic", "effect":{"meteor_style_cata": true}},
	{"title":"card_sword_style_whirl_t", "desc":"card_sword_style_whirl_d", "rarity":"epic", "effect":{"sword_style_whirl": true}},
	{"title":"card_sword_style_exec_t", "desc":"card_sword_style_exec_d", "rarity":"epic", "effect":{"sword_style_exec": true}},
	{"title":"card_shot_style_barrage_t", "desc":"card_shot_style_barrage_d", "rarity":"epic", "effect":{"shot_style_barrage": true}},
	{"title":"card_shot_style_rail_t", "desc":"card_shot_style_rail_d", "rarity":"epic", "effect":{"shot_style_rail": true}},
	{"title":"card_combo_overdrive_t", "desc":"card_combo_overdrive_d", "rarity":"epic", "effect":{"unlock_combo_overdrive": true}},
	{"title":"card_combo_shield_empty_t", "desc":"card_combo_shield_empty_d", "rarity":"epic", "effect":{"unlock_combo_shield_empty": true}},
	{"title":"card_combo_dash_chain_t", "desc":"card_combo_dash_chain_d", "rarity":"epic", "effect":{"unlock_combo_dash_chain": true}}
]
const KEYSTONE_CARD_POOL: Array[Dictionary] = [
	{
		"title":"card_keystone_blade_t",
		"desc":"card_keystone_blade_d",
		"rarity":"epic",
		"keystone": true,
		"requires_archetype": "blade",
		"effect":{"sword_damage_add": 24, "sword_speed_mul": 1.18, "sword_radius_add": 16.0, "shot_cd_mul": 1.16}
	},
	{
		"title":"card_keystone_ballistic_t",
		"desc":"card_keystone_ballistic_d",
		"rarity":"epic",
		"keystone": true,
		"requires_archetype": "ballistic",
		"effect":{"shot_damage_add": 14, "shot_speed_add": 130.0, "shot_cd_mul": 0.78, "sword_cd_mul": 1.16, "shield_drain_mul": 1.14}
	},
	{
		"title":"card_keystone_arcane_t",
		"desc":"card_keystone_arcane_d",
		"rarity":"epic",
		"keystone": true,
		"requires_archetype": "arcane",
		"effect":{"unlock_chain_sigil": true, "unlock_meteor_rain": true, "magic_power_mul": 1.22, "magic_haste_mul": 1.14, "shot_damage_add": -6}
	},
	{
		"title":"card_keystone_tactical_t",
		"desc":"card_keystone_tactical_d",
		"rarity":"epic",
		"keystone": true,
		"requires_archetype": "tactical",
		"effect":{"dash_cd_mul": 0.68, "dash_distance_mul": 1.22, "dash_impact_add": 20, "dash_impact_radius_add": 20.0, "sword_damage_add": -8, "move_speed_mul": 1.10}
	}
]
const AUGMENT_CARD_POOL: Array[Dictionary] = [
	{
		"title":"card_socket_bullet_t",
		"desc":"card_socket_bullet_d",
		"rarity":"common",
		"effect":{"socket_bullet_add": 1}
	},
	{
		"title":"card_socket_spell_t",
		"desc":"card_socket_spell_d",
		"rarity":"common",
		"effect":{"socket_spell_add": 1}
	},
	{
		"title":"card_augment_overheat_t",
		"desc":"card_augment_overheat_d",
		"rarity":"rare",
		"augment": true,
		"augment_id": "overheat_lens",
		"requires_socket": "bullet",
		"effect":{"augment_overheat_lens": true}
	},
	{
		"title":"card_augment_prism_t",
		"desc":"card_augment_prism_d",
		"rarity":"rare",
		"augment": true,
		"augment_id": "phase_prism",
		"requires_socket": "bullet",
		"effect":{"augment_phase_prism": true}
	},
	{
		"title":"card_augment_manaweave_t",
		"desc":"card_augment_manaweave_d",
		"rarity":"rare",
		"augment": true,
		"augment_id": "mana_weave",
		"requires_socket": "spell",
		"effect":{"augment_mana_weave": true}
	}
]

var wave = 0
var _wave_active = false
var _wave_preview = false
var _preview_left = 0.0
var _intermission_left = INTERMISSION_SECONDS
var _spawn_timer = 0.0
var _spawn_queue: Array[int] = []
var _card_choices: Array[Dictionary] = []
var _mitigation_choices: Array[Dictionary] = []
var _preview_enemies: Array[Node] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _terrain_seed = 0
var _terrain_theme = 0
var _wave_mutator: Dictionary = MUTATOR_POOL[0]
var _wave_directive := "none"
var _directive_left := 0.0
var _directive_interval := 8.6
var _objective_active := false
var _objective_type := ""
var _objective_left := 0.0
var _objective_trigger_left := 0.0
var _objective_progress := 0.0
var _objective_pos := Vector2.ZERO
var _objective_nodes: Array[Node2D] = []
var _objective_convoy_hits := 0
var _wave_elapsed := 0.0
var _wave_kills_start := 0
var _wave_enemy_budget := 1
var _mid_mutation_stage := 0
var _mutation_time_1 := 0.0
var _mutation_time_2 := 0.0
var _directive_pool: Array[String] = []
var _archetype_meter := {
	"blade": 0.0,
	"ballistic": 0.0,
	"arcane": 0.0,
	"tactical": 0.0
}
var _keystone_ready := {
	"blade": false,
	"ballistic": false,
	"arcane": false,
	"tactical": false
}
var _keystone_picked := false
var _keystone_school := ""
var _preview_ecology_summary := ""
var _anchor_enemy: Node = null
var _anchor_faction := -1
var _anchor_active := false
const ARENA_RECT := Rect2(-790.0, -430.0, 1580.0, 860.0)
var _boss_spawned_this_wave = false
var _score = 0
var _kills = 0
var _game_over = false
var _choice_mode := "card"
var _active_affliction := ""
var _pending_affliction := ""
var _affliction_start_wave := 0
var _affliction_mitigation := ""
var _affliction_tick_left := 0.0
var _affliction_warning_mul := 1.0
var _affliction_mana_drain_mul := 1.0
var _affliction_tide_interval_mul := 1.0
var _affliction_tide_damage_mul := 1.0
var _affliction_tide_radius_mul := 1.0
var _director_level := 0.0
var _director_spawn_mul := 1.0
var _director_directive_mul := 1.0
var _director_elite_bonus := 0.0
var _director_eval_left := 0.0
var _director_hint_cd := 0.0
var _wave_damage_dealt := 0.0
var _wave_damage_taken := 0.0
var _wave_hazard_kills := 0
var _wave_directive_count := 0
var _wave_position_bins: Dictionary = {}
var _wave_position_samples := 0
var _wave_kill_times: Array[float] = []
var _wave_telemetry_history: Array[Dictionary] = []
var _card_pick_order: Array[String] = []
var _archetype_trace: Array[Dictionary] = []
var _last_hp := 0.0
var _last_sp := 0.0
var _pos_sample_left := 0.0
var _run_objective_success := 0
var _run_anchor_breaks := 0
var _run_hazard_kills_total := 0
var _run_affliction_wave_count := 0
var _run_director_peak := 0.0
var _run_relic_id := ""
var _run_relic_pack: Dictionary = {}
var _virtual_stick: Control = null
var _virtual_move := Vector2.ZERO
var _virtual_input_enabled := false
var _virtual_ui_layer: CanvasLayer = null
var _virtual_shield_button: Button = null
var _virtual_dash_button: Button = null
var _virtual_shield_hold := false
var _wall_brush_index := 0

@onready var terrain_root: Node2D = $World/Terrain
@onready var dynamic_root: Node2D = $World/Dynamic
@onready var hazard_root: Node2D = $World/Hazards
@onready var enemy_root: Node2D = $World/Enemies
@onready var spawn_root: Node2D = $World/Spawns
@onready var player = $World/Player

@onready var hud: CanvasLayer = $HUD
@onready var wave_caption: Label = $HUD/Ledger/Box/WaveSeal/VBox/WaveCaption
@onready var wave_label: Label = $HUD/Ledger/Box/WaveSeal/VBox/WaveLabel
@onready var timer_label: Label = $HUD/Ledger/Box/TimerLabel
@onready var score_caption: Label = $HUD/Ledger/Box/ScoreCaption
@onready var score_label: Label = $HUD/Ledger/Box/ScoreLabel
@onready var threat_caption: Label = $HUD/Threat/ThreatCaption
@onready var threat_bar: TextureProgressBar = $HUD/Threat/ThreatBar
@onready var affliction_label: Label = $HUD/AfflictionLabel
@onready var hp_bar: TextureProgressBar = $HUD/Vitals/Box/HPRow/HPBar
@onready var sp_bar: TextureProgressBar = $HUD/Vitals/Box/SPRow/SPBar
@onready var hp_text: Label = $HUD/Vitals/Box/HPRow/HPLabel
@onready var sp_text: Label = $HUD/Vitals/Box/SPRow/SPLabel
@onready var mode_text: Label = $HUD/Vitals/Box/ModeLabel
@onready var cooldown_text: Label = $HUD/Vitals/Box/CooldownLabel
@onready var msg_box: PanelContainer = $HUD/MessageBox
@onready var msg_label: Label = $HUD/MessageBox/Message

@onready var card_shade: ColorRect = $CardUI/Shade
@onready var card_panel: Control = $CardUI/Shade/Center/Panel
@onready var card_vbox: VBoxContainer = $CardUI/Shade/Center/Panel/VBox
@onready var card_a: Button = $CardUI/Shade/Center/Panel/VBox/Cards/CardA
@onready var card_b: Button = $CardUI/Shade/Center/Panel/VBox/Cards/CardB
@onready var card_c: Button = $CardUI/Shade/Center/Panel/VBox/Cards/CardC
@onready var pause_shade: ColorRect = $PauseUI/Shade
@onready var pause_title: Label = $PauseUI/Shade/Center/Panel/VBox/Title
@onready var pause_stats: Label = $PauseUI/Shade/Center/Panel/VBox/StatsLabel
@onready var pause_build: Label = $PauseUI/Shade/Center/Panel/VBox/BuildLabel
@onready var pause_resume: Button = $PauseUI/Shade/Center/Panel/VBox/ResumeButton
@onready var pause_restart: Button = $PauseUI/Shade/Center/Panel/VBox/RestartButton
@onready var pause_mainmenu: Button = $PauseUI/Shade/Center/Panel/VBox/MainMenuButton
@onready var pause_quit: Button = $PauseUI/Shade/Center/Panel/VBox/QuitButton
@onready var game_over_shade: ColorRect = $GameOverUI/Shade
@onready var game_over_title: Label = $GameOverUI/Shade/Center/Column/Title
@onready var game_over_score_caption: Label = $GameOverUI/Shade/Center/Column/Seal/VBox/ScoreCaption
@onready var game_over_score: Label = $GameOverUI/Shade/Center/Column/Seal/VBox/ScoreLabel
@onready var game_over_bank: Label = $GameOverUI/Shade/Center/Column/Stats/BankLabel
@onready var game_over_best: Label = $GameOverUI/Shade/Center/Column/Stats/BestLabel
@onready var game_over_restart: Button = $GameOverUI/Shade/Center/Column/Buttons/RestartButton
@onready var game_over_mainmenu: Button = $GameOverUI/Shade/Center/Column/Buttons/MainMenuButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	_setup_actions()
	if AudioManager != null:
		AudioManager.play_battle()
	else:
		push_error("AudioManager singleton is null in EndlessMode2D.")
	_build_static_arena()
	_setup_spawns()
	_apply_ui_locale()
	wave_caption.text = tr("ui_wave_caption")
	score_caption.text = tr("ui_score_caption")
	threat_caption.text = tr("ui_threat_caption")
	player.sword_scene = sword_scene
	player.projectile_scene = projectile_scene
	if ProgressionManager != null:
		player.apply_meta_progression(ProgressionManager.get_player_meta())
	_init_run_relic()
	player.stats_changed.connect(_on_player_stats_changed)
	if player.has_signal("damage_dealt"):
		player.damage_dealt.connect(_on_player_damage_dealt)
	player.message_sent.connect(_show_message)
	player.sfx_event.connect(play_sfx)
	player.died.connect(_on_player_died)
	card_a.pressed.connect(func() -> void: _pick_card(0))
	card_b.pressed.connect(func() -> void: _pick_card(1))
	card_c.pressed.connect(func() -> void: _pick_card(2))
	pause_resume.pressed.connect(_on_pause_resume)
	pause_restart.pressed.connect(_on_pause_restart)
	pause_mainmenu.pressed.connect(_on_pause_mainmenu)
	pause_quit.pressed.connect(_on_pause_quit)
	game_over_restart.pressed.connect(_on_game_over_restart)
	game_over_mainmenu.pressed.connect(_on_game_over_mainmenu)
	_apply_pause_locale()
	pause_shade.visible = false
	game_over_shade.visible = false
	_show_message(tr("msg_controls"))
	_setup_virtual_input()
	_set_intermission(INTERMISSION_SECONDS)
	_last_hp = float(player.hp)
	_last_sp = float(player.sp)
	_update_ui()
	_apply_debug_shot()

## Fast-forwards to a fixed state for headless screenshots (see debug_shot.gd).
func _apply_debug_shot() -> void:
	if not DebugShot.is_battle_shot():
		return
	wave = DEBUG_SHOT_START_WAVE - 1
	_set_intermission(0.2)
	var battle_seconds := DEBUG_SHOT_BATTLE_SECONDS * (3.0 if DebugShot.mode == "gameover" else 1.0)
	var tm := get_tree().create_timer(PREVIEW_SECONDS + battle_seconds)
	match DebugShot.mode:
		"cards":
			tm.timeout.connect(_show_cards)
		"gameover":
			tm.timeout.connect(_on_player_died)
		_:
			tm.timeout.connect(func() -> void: get_tree().paused = true)

func _process(delta: float) -> void:
	# Anchor the print shader's paper grain to the world so the ink texture doesn't swim.
	(material as ShaderMaterial).set_shader_parameter("grain_origin", get_viewport().get_canvas_transform().origin)
	_update_virtual_input_state()
	if _game_over:
		_update_ui()
		return
	if get_tree().paused:
		_update_ui()
		return
	if card_shade.visible:
		_update_ui()
		return
	if _wave_preview:
		_preview_left -= delta
		if _preview_left <= 0.0:
			_activate_wave_from_preview()
	elif _wave_active:
		_wave_elapsed += delta
		_update_affliction_runtime(delta)
		_director_eval_left -= delta
		_director_hint_cd = maxf(0.0, _director_hint_cd - delta)
		_objective_trigger_left -= delta
		_spawn_timer -= delta
		_track_position_entropy(delta)
		if _director_eval_left <= 0.0:
			_director_eval_left = 1.0
			_evaluate_threat_director()
		if _spawn_timer <= 0.0 and _spawn_queue.size() > 0:
			_spawn_timer = _current_spawn_interval()
			var enemy_kind: int = int(_spawn_queue.pop_back())
			_spawn_enemy(enemy_kind, true)
		_directive_left -= delta
		if _directive_left <= 0.0:
			_directive_left = _directive_interval
			_trigger_wave_directive()
		if not _objective_active and wave >= 4 and _objective_trigger_left <= 0.0:
			_start_wave_objective()
		if _objective_active:
			_update_wave_objective(delta)
		_update_midwave_mutation()
		_sanitize_enemies()
		if _spawn_queue.is_empty() and _alive_enemies() == 0:
			_on_wave_clear()
	else:
		_intermission_left -= delta
		if _intermission_left <= 0.0:
			_begin_wave_preview()
	_update_ui()

func _setup_virtual_input() -> void:
	_virtual_input_enabled = _should_enable_virtual_input()
	if not _virtual_input_enabled:
		return
	_virtual_ui_layer = CanvasLayer.new()
	_virtual_ui_layer.layer = 20
	add_child(_virtual_ui_layer)
	_virtual_stick = VirtualStickScript.new()
	_virtual_stick.anchor_left = 0.0
	_virtual_stick.anchor_right = 0.0
	_virtual_stick.anchor_top = 1.0
	_virtual_stick.anchor_bottom = 1.0
	_virtual_stick.offset_left = 22.0
	_virtual_stick.offset_top = -218.0
	_virtual_stick.offset_right = 190.0
	_virtual_stick.offset_bottom = -20.0
	if _virtual_stick.has_signal("vector_changed"):
		_virtual_stick.connect("vector_changed", Callable(self, "_on_virtual_move_changed"))
	_virtual_ui_layer.add_child(_virtual_stick)
	_setup_virtual_action_buttons()

func _on_virtual_move_changed(vec: Vector2) -> void:
	_virtual_move = vec

func _update_virtual_input_state() -> void:
	if not _virtual_input_enabled:
		return
	var block := _game_over or get_tree().paused or card_shade.visible
	if block:
		_virtual_move = Vector2.ZERO
		_virtual_shield_hold = false
		if player != null and player.has_method("set_virtual_shield_hold"):
			player.set_virtual_shield_hold(false)
		if _virtual_stick != null and _virtual_stick.has_method("reset_vector"):
			_virtual_stick.reset_vector()
	_apply_virtual_move_actions(_virtual_move)

func _setup_virtual_action_buttons() -> void:
	if _virtual_ui_layer == null:
		return
	_virtual_shield_button = _create_virtual_action_button(tr("ui_touch_shield"), 1)
	_virtual_dash_button = _create_virtual_action_button(tr("ui_touch_dash"), 0)
	_virtual_ui_layer.add_child(_virtual_shield_button)
	_virtual_ui_layer.add_child(_virtual_dash_button)
	_virtual_shield_button.button_down.connect(_on_virtual_shield_down)
	_virtual_shield_button.button_up.connect(_on_virtual_shield_up)
	_virtual_dash_button.button_down.connect(_on_virtual_dash_down)

func _create_virtual_action_button(label: String, slot: int) -> Button:
	var margin_right := 24.0
	var margin_bottom := 24.0
	var width := 104.0
	var height := 80.0
	var gap := 14.0
	var x_from_right := margin_right + float(slot) * (width + gap)
	var btn := Button.new()
	btn.anchor_left = 1.0
	btn.anchor_right = 1.0
	btn.anchor_top = 1.0
	btn.anchor_bottom = 1.0
	btn.offset_left = -(x_from_right + width)
	btn.offset_right = -x_from_right
	btn.offset_top = -(margin_bottom + height)
	btn.offset_bottom = -margin_bottom
	btn.text = label
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.add_theme_font_size_override("font_size", 24)
	btn.theme_type_variation = &"TouchButton"
	return btn

func _on_virtual_shield_down() -> void:
	_virtual_shield_hold = true
	if player != null and player.has_method("set_virtual_shield_hold"):
		player.set_virtual_shield_hold(true)

func _on_virtual_shield_up() -> void:
	_virtual_shield_hold = false
	if player != null and player.has_method("set_virtual_shield_hold"):
		player.set_virtual_shield_hold(false)

func _on_virtual_dash_down() -> void:
	if player != null and player.has_method("trigger_virtual_dash"):
		player.trigger_virtual_dash()

func _should_enable_virtual_input() -> bool:
	if OS.has_feature("mobile"):
		return true
	if not OS.has_feature("web"):
		return false
	if not Engine.has_singleton("JavaScriptBridge"):
		return false
	var ua_value: Variant = JavaScriptBridge.eval("navigator.userAgent || ''", true)
	var ua := str(ua_value).to_lower()
	if ua.find("android") >= 0:
		return true
	if ua.find("iphone") >= 0:
		return true
	if ua.find("ipad") >= 0:
		return true
	if ua.find("ipod") >= 0:
		return true
	if ua.find("mobile") >= 0:
		return true
	if ua.find("harmonyos") >= 0:
		return true
	return false

func _apply_virtual_move_actions(vec: Vector2) -> void:
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("move_forward")
	Input.action_release("move_back")
	if vec.length() < 0.04:
		return
	Input.action_press("move_left", maxf(0.0, -vec.x))
	Input.action_press("move_right", maxf(0.0, vec.x))
	Input.action_press("move_forward", maxf(0.0, -vec.y))
	Input.action_press("move_back", maxf(0.0, vec.y))

func play_sfx(name: String) -> void:
	if not SFX.has(name) or (AudioManager != null and not AudioManager.can_play()):
		return
	var p = AudioStreamPlayer.new()
	p.stream = SFX[name]
	p.bus = "Master"
	var sfx_db = 0.0
	if AudioManager != null:
		sfx_db = AudioManager.get_sfx_volume_db()
	p.volume_db = -6.0 + sfx_db
	add_child(p)
	p.finished.connect(func() -> void: p.queue_free())
	p.play()

func request_elite_summon(pos: Vector2) -> void:
	if _alive_enemies() > 120:
		return
	var kind = _rng.randi_range(0, 8)
	var child: Node = _spawn_enemy(kind, true)
	if child is Node2D:
		var p = pos + Vector2(_rng.randf_range(-42.0, 42.0), _rng.randf_range(-42.0, 42.0))
		(child as Node2D).global_position = _clamp_to_arena(p)

func request_split_spawn(pos: Vector2) -> void:
	for i in 2:
		var child: Node = _spawn_enemy(0, true)
		if child is Node2D:
			var p = pos + Vector2(_rng.randf_range(-28.0, 28.0), _rng.randf_range(-28.0, 28.0))
			(child as Node2D).global_position = _clamp_to_arena(p)
			if child.has_method("apply_impulse"):
				child.apply_impulse(Vector2(_rng.randf_range(-200.0, 200.0), _rng.randf_range(-200.0, 200.0)))

func request_spawn_totem(pos: Vector2) -> void:
	if boss_totem_scene == null:
		return
	_spawn_ground_warning(pos, 74.0, Color(1.0, 0.70, 0.22, 0.85), 0.70)
	var delay = get_tree().create_timer(0.7)
	await delay.timeout
	var t: Node = boss_totem_scene.instantiate()
	dynamic_root.add_child(t)
	if t is Node2D:
		(t as Node2D).global_position = _clamp_to_arena(pos + Vector2(_rng.randf_range(-64.0, 64.0), _rng.randf_range(-64.0, 64.0)))
	if t.has_method("set_target"):
		t.set_target(player)
	if t.has_method("configure_for_wave"):
		t.configure_for_wave(wave)
	if t.has_signal("died"):
		t.connect("died", Callable(self, "_on_enemy_died"))

func request_bullet_hell(pos: Vector2) -> void:
	if enemy_projectile_scene == null:
		return
	_spawn_ground_warning(pos, 150.0, Color(1.0, 0.34, 0.34, 0.9), 0.95)
	var delay = get_tree().create_timer(0.95)
	await delay.timeout
	_spawn_radial_volley(pos, 18, 0.0)
	var delay2 = get_tree().create_timer(0.45)
	await delay2.timeout
	_spawn_radial_volley(pos, 18, PI / 18.0)

func request_void_zone(pos: Vector2, wave_level: int) -> void:
	if hazard_scene == null:
		return
	_spawn_ground_warning(pos, 84.0, Color(0.90, 0.42, 1.0, 0.86), 0.7)
	var delay = get_tree().create_timer(0.68)
	await delay.timeout
	var hz: Node = hazard_scene.instantiate()
	hazard_root.add_child(hz)
	if hz is Node2D:
		(hz as Node2D).global_position = _clamp_to_arena(pos)
	if hz.has_method("set_hazard_kind"):
		hz.set_hazard_kind(2)
	if hz.has_method("configure_for_wave"):
		hz.configure_for_wave(maxi(wave, wave_level + 1))
	if hz.has_method("set_gameplay_active"):
		hz.set_gameplay_active(_wave_active)

func request_control_zone(pos: Vector2, wave_level: int) -> void:
	if player == null:
		return
	var center := _clamp_to_arena(pos + Vector2(_rng.randf_range(-26.0, 26.0), _rng.randf_range(-26.0, 26.0)))
	var radius := 100.0 + float(mini(48, wave_level * 2))
	_show_message(tr("msg_control_zone"))
	_spawn_ground_warning(center, radius, Color(0.96, 0.42, 1.0, 0.82), 0.60)
	var delay = get_tree().create_timer(0.60)
	await delay.timeout
	if player != null:
		var p := (player as Node2D).global_position
		if p.distance_to(center) <= radius:
			if player.has_method("take_damage"):
				player.take_damage(7 + int(wave_level * 0.5))
			if player.has_method("drain_sp"):
				player.drain_sp(8.0 + float(wave_level) * 0.6)
	_spawn_radial_volley(center, 10 + int(wave_level * 0.08), _rng.randf() * TAU)

func _start_wave_objective() -> void:
	if _objective_active:
		return
	_objective_active = true
	_objective_progress = 0.0
	_objective_convoy_hits = 0
	_objective_nodes.clear()
	var roll := _rng.randf()
	if roll < 0.40:
		_objective_type = "pylon_capture"
		_objective_left = 11.0 + minf(4.0, float(wave) * 0.15)
		_objective_pos = _clamp_to_arena(_random_spawn() + Vector2(_rng.randf_range(-80.0, 80.0), _rng.randf_range(-70.0, 70.0)))
		var marker := _spawn_objective_marker(_objective_pos, Color(1.0, 0.90, 0.35, 0.88), 96.0)
		_objective_nodes.append(marker)
		_spawn_ground_warning(_objective_pos, 105.0, Color(1.0, 0.90, 0.35, 0.88), 1.0)
		_show_message(tr("msg_objective_pylon_start"))
	elif roll < 0.74:
		_objective_type = "rift_seal"
		_objective_left = 13.0 + minf(4.0, float(wave) * 0.18)
		for i in 2:
			var p := _clamp_to_arena(_random_spawn() + Vector2(_rng.randf_range(-92.0, 92.0), _rng.randf_range(-84.0, 84.0)))
			var marker := _spawn_objective_marker(p, Color(0.90, 0.40, 1.0, 0.90), 78.0)
			marker.set_meta("seal", 0.0)
			marker.set_meta("sealed", false)
			_objective_nodes.append(marker)
			_spawn_ground_warning(p, 84.0, Color(0.90, 0.40, 1.0, 0.85), 0.9)
		_show_message(tr("msg_objective_rift_start"))
	else:
		_objective_type = "convoy_fracture"
		_objective_left = 12.0 + minf(4.0, float(wave) * 0.16)
		_start_objective_convoy()
		_show_message(tr("msg_objective_convoy_start"))

func _update_wave_objective(delta: float) -> void:
	if not _objective_active:
		return
	_objective_left -= delta
	_update_objective_visuals(delta)
	if _objective_type == "pylon_capture":
		_update_objective_pylon(delta)
	elif _objective_type == "rift_seal":
		_update_objective_rift(delta)
	elif _objective_type == "convoy_fracture":
		_update_objective_convoy(delta)
	if _objective_left <= 0.0:
		_fail_wave_objective()

func _update_objective_pylon(delta: float) -> void:
	if player == null:
		return
	var near := (player as Node2D).global_position.distance_to(_objective_pos) <= 106.0
	if near:
		_objective_progress += delta
	else:
		_objective_progress = maxf(0.0, _objective_progress - delta * 0.70)
	if _objective_progress >= 3.5:
		_complete_wave_objective()

func _update_objective_rift(delta: float) -> void:
	if player == null:
		return
	var sealed_count := 0
	var p := (player as Node2D).global_position
	for n in _objective_nodes:
		if not is_instance_valid(n):
			continue
		var sealed: bool = bool(n.get_meta("sealed", false))
		if sealed:
			sealed_count += 1
			continue
		if p.distance_to(n.global_position) <= 84.0:
			var seal: float = float(n.get_meta("seal", 0.0))
			seal += delta
			n.set_meta("seal", seal)
			if seal >= 1.5:
				n.set_meta("sealed", true)
				sealed_count += 1
	_objective_progress = float(sealed_count)
	if sealed_count >= _objective_nodes.size() and _objective_nodes.size() > 0:
		_complete_wave_objective()

func _start_objective_convoy() -> void:
	var dir := Vector2(1.0, _rng.randf_range(-0.36, 0.36)).normalized()
	var speed := 162.0 + minf(68.0, float(wave) * 2.1)
	var perp := Vector2(-dir.y, dir.x)
	var base := _clamp_to_arena(_random_spawn() + perp * _rng.randf_range(-70.0, 70.0))
	for i in 3:
		var spacing := 88.0
		var spawn_pos := _clamp_to_arena(base - dir * (spacing * float(i)))
		var segment := _spawn_objective_marker(spawn_pos, Color(0.98, 0.44, 0.32, 0.88), 54.0)
		segment.set_meta("vel", dir * speed)
		segment.set_meta("fracture", 0.0)
		segment.set_meta("fractured", false)
		segment.set_meta("warn_cd", _rng.randf_range(0.40, 0.95))
		_objective_nodes.append(segment)
		_spawn_ground_warning(spawn_pos, 62.0, Color(0.98, 0.44, 0.32, 0.80), 0.55)

func _update_objective_convoy(delta: float) -> void:
	if player == null:
		return
	var fractured_count := 0
	var p := (player as Node2D).global_position
	for n in _objective_nodes:
		if not is_instance_valid(n):
			continue
		var vel: Vector2 = n.get_meta("vel", Vector2.ZERO)
		n.global_position = _clamp_to_arena(n.global_position + vel * delta)
		var warn_cd: float = float(n.get_meta("warn_cd", 0.0)) - delta
		if warn_cd <= 0.0:
			_spawn_ground_warning(n.global_position, 54.0, Color(0.98, 0.44, 0.32, 0.65), 0.34)
			warn_cd = 0.50 + _rng.randf_range(0.0, 0.30)
		n.set_meta("warn_cd", warn_cd)
		var fractured: bool = bool(n.get_meta("fractured", false))
		if fractured:
			fractured_count += 1
			continue
		if p.distance_to(n.global_position) <= 74.0:
			var fracture: float = float(n.get_meta("fracture", 0.0)) + delta
			n.set_meta("fracture", fracture)
			if fracture >= 1.2:
				n.set_meta("fractured", true)
				fractured_count += 1
				_objective_convoy_hits += 1
				_spawn_radial_volley(n.global_position, 7 + int(wave * 0.04), _rng.randf() * TAU)
	_objective_progress = float(fractured_count)
	if fractured_count >= _objective_nodes.size() and _objective_nodes.size() > 0:
		_complete_wave_objective()

func _complete_wave_objective() -> void:
	if not _objective_active:
		return
	_run_objective_success += 1
	if _objective_type == "pylon_capture":
		var trim := mini(_spawn_queue.size(), 4 + int(wave * 0.22))
		for i in trim:
			if not _spawn_queue.is_empty():
				_spawn_queue.pop_back()
		_directive_left += 2.4
		player.heal(10.0 + float(wave) * 0.3)
		player.restore_sp(14.0 + float(wave) * 0.35)
		_show_message(tr("msg_objective_pylon_done"))
	elif _objective_type == "rift_seal":
		var removed := 0
		for hz in hazard_root.get_children():
			if hz == null:
				continue
			hz.queue_free()
			removed += 1
			if removed >= 2:
				break
		_directive_left += 1.8
		player.restore_sp(16.0 + float(wave) * 0.45)
		_show_message(tr("msg_objective_rift_done"))
	else:
		var trim_convoy := mini(_spawn_queue.size(), 3 + _objective_convoy_hits + int(wave * 0.08))
		for i in trim_convoy:
			if not _spawn_queue.is_empty():
				_spawn_queue.pop_back()
		player.restore_sp(12.0 + float(wave) * 0.40)
		_directive_left += 2.0
		_show_message(tr("msg_objective_convoy_done"))
	_cleanup_objective_state()

func _fail_wave_objective() -> void:
	if not _objective_active:
		return
	if _objective_type == "pylon_capture":
		_show_message(tr("msg_objective_pylon_fail"))
		_spawn_radial_volley(_objective_pos, 12 + int(wave * 0.06), _rng.randf() * TAU)
		for i in range(3 + int(wave * 0.08)):
			_spawn_queue.append(2 if i % 2 == 0 else 8)
	elif _objective_type == "rift_seal":
		_show_message(tr("msg_objective_rift_fail"))
		for n in _objective_nodes:
			if is_instance_valid(n):
				request_void_zone(n.global_position, wave + 1)
		for i in range(4 + int(wave * 0.10)):
			_spawn_queue.append(6 if i % 2 == 0 else 7)
	else:
		_show_message(tr("msg_objective_convoy_fail"))
		for n in _objective_nodes:
			if is_instance_valid(n) and not bool(n.get_meta("fractured", false)):
				_spawn_radial_volley(n.global_position, 8 + int(wave * 0.06), _rng.randf() * TAU)
				request_control_zone(n.global_position, wave + 1)
		for i in range(4 + int(wave * 0.10)):
			_spawn_queue.append(4 if i % 2 == 0 else 8)
	_cleanup_objective_state()

func _cleanup_objective_state() -> void:
	for n in _objective_nodes:
		if is_instance_valid(n):
			n.queue_free()
	_objective_nodes.clear()
	_objective_active = false
	_objective_type = ""
	_objective_left = 0.0
	_objective_progress = 0.0
	_objective_pos = Vector2.ZERO
	_objective_trigger_left = 0.0
	_objective_convoy_hits = 0

func _spawn_objective_marker(pos: Vector2, color: Color, radius: float) -> Node2D:
	var node := Node2D.new()
	node.global_position = _clamp_to_arena(pos)
	var poly := Polygon2D.new()
	var pts: Array[Vector2] = []
	for i in 24:
		var a := TAU * float(i) / 24.0
		pts.append(Vector2(cos(a), sin(a)) * radius)
	poly.polygon = PackedVector2Array(pts)
	poly.color = Color(color.r, color.g, color.b, 0.18)
	node.add_child(poly)
	var line := Line2D.new()
	line.width = 2.4
	line.default_color = Color(color.r, color.g, color.b, 0.88)
	var ring_pts: Array[Vector2] = []
	for i in 25:
		var a := TAU * float(i) / 24.0
		ring_pts.append(Vector2(cos(a), sin(a)) * radius)
	line.points = PackedVector2Array(ring_pts)
	node.add_child(line)
	dynamic_root.add_child(node)
	return node

func _update_objective_visuals(delta: float) -> void:
	if _objective_nodes.is_empty():
		return
	var pulse := 0.78 + 0.22 * sin(float(Time.get_ticks_msec()) * 0.008)
	for n in _objective_nodes:
		if not is_instance_valid(n):
			continue
		n.scale = n.scale.lerp(Vector2.ONE * pulse, minf(1.0, delta * 8.0))
		if _objective_type == "rift_seal":
			var sealed: bool = bool(n.get_meta("sealed", false))
			if sealed and n.get_child_count() >= 2:
				var p := n.get_child(0) as Polygon2D
				var l := n.get_child(1) as Line2D
				if p != null:
					p.color = Color(0.52, 1.0, 0.86, 0.20)
				if l != null:
					l.default_color = Color(0.52, 1.0, 0.86, 0.94)
		elif _objective_type == "convoy_fracture":
			var fractured: bool = bool(n.get_meta("fractured", false))
			if fractured and n.get_child_count() >= 2:
				var p2 := n.get_child(0) as Polygon2D
				var l2 := n.get_child(1) as Line2D
				if p2 != null:
					p2.color = Color(1.0, 0.74, 0.30, 0.20)
				if l2 != null:
					l2.default_color = Color(1.0, 0.74, 0.30, 0.96)

func _spawn_ground_warning(pos: Vector2, radius: float, color: Color, duration: float) -> void:
	var warn = TelegraphDecal2D.new()
	warn.global_position = _clamp_to_arena(pos)
	warn.radius = radius
	warn.base_color = color
	warn.duration = maxf(0.2, duration * _affliction_warning_mul)
	dynamic_root.add_child(warn)

func _spawn_radial_volley(pos: Vector2, count: int, angle_offset: float) -> void:
	for i in count:
		var a: float = TAU * float(i) / float(count) + angle_offset
		var dir = Vector2(cos(a), sin(a))
		var b: Node = enemy_projectile_scene.instantiate()
		add_child(b)
		if b is Node2D:
			(b as Node2D).global_position = pos
		if b.has_method("setup"):
			b.setup(dir, 250.0, 11 + int(wave * 0.25), 4)

func _apply_ui_locale() -> void:
	var title_label = card_vbox.get_node("Title") as Label
	if title_label != null:
		if _choice_mode == "mitigation":
			title_label.text = tr("ui_mitigation_title")
		else:
			title_label.text = tr("ui_card_title")
	_set_card_body(card_a, tr("ui_card_a"), Ink.SUMI)
	_set_card_body(card_b, tr("ui_card_b"), Ink.SUMI)
	_set_card_body(card_c, tr("ui_card_c"), Ink.SUMI)

func _set_card_body(btn: Button, bbcode: String, band: Color) -> void:
	var body := btn.get_node("Body") as RichTextLabel
	if body != null:
		body.text = bbcode
	var band_rect := btn.get_node("Band") as ColorRect
	if band_rect != null:
		band_rect.color = band
	_fit_cards.call_deferred()

## Cards share one height, just tall enough for the longest text, so short cards aren't empty.
func _fit_cards() -> void:
	var text_h := 0.0
	for btn in [card_a, card_b, card_c]:
		var body := (btn as Button).get_node("Body") as RichTextLabel
		text_h = maxf(text_h, float(body.get_content_height()))
	var card_h := clampf(text_h + CARD_TEXT_PADDING, CARD_MIN_HEIGHT, CARD_MAX_HEIGHT)
	for btn in [card_a, card_b, card_c]:
		(btn as Button).custom_minimum_size.y = card_h

## A reward card set like a printed page: rarity in its pigment, brush title, plain description.
func _card_bbcode(rarity_text: String, title: String, desc: String, c: Color) -> String:
	return "[center][font_size=15][color=#%s]%s[/color][/font_size]\n[font=%s][font_size=26]%s[/font_size][/font]\n%s[/center]" % [
		c.to_html(false), rarity_text, DISPLAY_FONT_PATH, title, desc
	]

func _setup_actions() -> void:
	_set_key("move_forward", KEY_W)
	_set_key("move_back", KEY_S)
	_set_key("move_left", KEY_A)
	_set_key("move_right", KEY_D)
	_set_key("dash", KEY_SHIFT)
	_set_key("switch_bullet", KEY_Q)
	_set_key("bullet_mode_1", KEY_1)
	_set_key("bullet_mode_2", KEY_2)
	_set_key("bullet_mode_3", KEY_3)
	_set_key("bullet_mode_4", KEY_4)
	_set_key("bullet_mode_5", KEY_5)
	_set_mouse("attack_primary", MOUSE_BUTTON_LEFT)
	_set_mouse("shield", MOUSE_BUTTON_RIGHT)

func _set_key(action: StringName, code: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	InputMap.action_erase_events(action)
	var ev = InputEventKey.new()
	ev.physical_keycode = code
	InputMap.action_add_event(action, ev)

func _set_mouse(action: StringName, btn: MouseButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	InputMap.action_erase_events(action)
	var ev = InputEventMouseButton.new()
	ev.button_index = btn
	InputMap.action_add_event(action, ev)

func _build_static_arena() -> void:
	# The page edge: solid sumi bars. The paper itself is drawn by Floor/Page (arena_print.gd).
	_create_world_block(Rect2(-860, -500, 1720, 32), Ink.SUMI, terrain_root)
	_create_world_block(Rect2(-860, 468, 1720, 32), Ink.SUMI, terrain_root)
	_create_world_block(Rect2(-860, -500, 32, 1000), Ink.SUMI, terrain_root)
	_create_world_block(Rect2(828, -500, 32, 1000), Ink.SUMI, terrain_root)

func _setup_spawns() -> void:
	var points: Array[Vector2] = [
		Vector2(730, 360), Vector2(-730, 360), Vector2(730, -360), Vector2(-730, -360),
		Vector2(0, 400), Vector2(0, -400), Vector2(760, 0), Vector2(-760, 0),
		Vector2(520, 280), Vector2(-520, -280), Vector2(-520, 280), Vector2(520, -280)
	]
	for p in points:
		var m = Marker2D.new()
		m.position = p
		spawn_root.add_child(m)

func _begin_wave_preview() -> void:
	wave += 1
	_activate_pending_affliction_if_any()
	_boss_spawned_this_wave = false
	_wave_preview = true
	_wave_active = false
	_preview_left = PREVIEW_SECONDS
	_mutate_terrain()
	_build_spawn_queue()
	_preview_ecology_summary = _build_ecology_summary(_spawn_queue)
	_set_hazards_active(false)
	_spawn_preview_enemies()
	var theme_name = tr(str(TERRAIN_THEME_LABEL.get(_terrain_theme, "terrain_theme_ruins")))
	var mutator_name = tr(str(_wave_mutator.get("label", "mutator_none")))
	var headline := tr("msg_wave_preview_theme") % [wave, PREVIEW_SECONDS, theme_name, mutator_name]
	_show_message("%s\n%s" % [headline, tr("msg_wave_ecology") % _preview_ecology_summary])

func _spawn_preview_enemies() -> void:
	_preview_enemies.clear()
	var count: int = mini(PREVIEW_ENEMY_COUNT, _spawn_queue.size())
	for i in count:
		var kind: int = int(_spawn_queue.pop_back())
		var e: Node = _spawn_enemy(kind, false)
		if e != null:
			_preview_enemies.append(e)

func _activate_wave_from_preview() -> void:
	_wave_preview = false
	_wave_active = true
	_reset_wave_telemetry()
	_spawn_timer = _current_spawn_interval()
	_directive_left = 4.4
	_set_hazards_active(true)
	for e in _preview_enemies:
		if is_instance_valid(e) and e.has_method("set_active"):
			e.set_active(true)
	_preview_enemies.clear()
	_wave_elapsed = 0.0
	_wave_kills_start = _kills
	_wave_enemy_budget = maxi(1, _spawn_queue.size() + _alive_enemies())
	_mid_mutation_stage = 0
	var mutation_mul := float(_run_relic_pack.get("mutation_time_mul", 1.0))
	_mutation_time_1 = (9.5 + minf(5.0, float(wave) * 0.22)) * mutation_mul
	_mutation_time_2 = (20.0 + minf(7.0, float(wave) * 0.35)) * mutation_mul
	_directive_pool = _build_directive_pool(0)
	_director_eval_left = 0.25
	_directive_interval *= float(_run_relic_pack.get("directive_interval_mul", 1.0))
	_try_assign_wave_anchor()
	_objective_trigger_left = (6.6 + _rng.randf_range(0.0, 2.5)) * float(_run_relic_pack.get("objective_trigger_mul", 1.0))
	if bool(_run_relic_pack.get("force_anchor_early", false)):
		_objective_trigger_left = minf(_objective_trigger_left, 4.2)
		_try_assign_wave_anchor()
	_spawn_miniboss_if_needed()
	_show_message(tr("msg_wave_start") % wave)
	play_sfx("wave_start")

func _build_spawn_queue() -> void:
	_spawn_queue.clear()
	var chaser: int = 6 + wave * 2
	var shooter: int = 2 + int(wave / 2)
	var dasher: int = int((wave + 2) / 3)
	var sniper: int = maxi(0, int((wave - 2) / 2))
	var artillery: int = maxi(0, int((wave - 4) / 3))
	var warden: int = maxi(0, int((wave - 5) / 2))
	var warlock: int = maxi(0, int((wave - 7) / 2))
	var beacon: int = maxi(0, int((wave - 6) / 3))
	var lancer: int = maxi(0, int((wave - 4) / 2))
	var mutator_id = str(_wave_mutator.get("id", "none"))
	if mutator_id == "swarm":
		chaser += 3 + int(wave * 0.6)
		shooter += 1 + int(wave * 0.25)
	elif mutator_id == "hunters":
		sniper += 1 + int(wave * 0.22)
		warlock += 1 + int(maxi(0, wave - 6) * 0.18)
	elif mutator_id == "fortified":
		chaser = maxi(1, int(round(float(chaser) * 0.82)))
		shooter = maxi(1, int(round(float(shooter) * 0.88)))
	elif mutator_id == "cataclysm":
		artillery += 1 + int(maxi(0, wave - 4) * 0.25)
		warden += 1 + int(maxi(0, wave - 5) * 0.20)
		lancer += 1 + int(maxi(0, wave - 6) * 0.16)
	var spawn_mul = float(_wave_mutator.get("spawn_mul", 1.0))
	chaser = maxi(1, int(round(float(chaser) * spawn_mul)))
	shooter = maxi(1, int(round(float(shooter) * spawn_mul)))
	dasher = maxi(0, int(round(float(dasher) * spawn_mul)))
	sniper = maxi(0, int(round(float(sniper) * spawn_mul)))
	artillery = maxi(0, int(round(float(artillery) * spawn_mul)))
	warden = maxi(0, int(round(float(warden) * spawn_mul)))
	warlock = maxi(0, int(round(float(warlock) * spawn_mul)))
	beacon = maxi(0, int(round(float(beacon) * spawn_mul)))
	lancer = maxi(0, int(round(float(lancer) * spawn_mul)))
	for i in chaser:
		_spawn_queue.append(0)
	for i in shooter:
		_spawn_queue.append(1)
	for i in dasher:
		_spawn_queue.append(2)
	for i in sniper:
		_spawn_queue.append(3)
	for i in artillery:
		_spawn_queue.append(4)
	for i in warden:
		_spawn_queue.append(5)
	for i in warlock:
		_spawn_queue.append(6)
	for i in beacon:
		_spawn_queue.append(7)
	for i in lancer:
		_spawn_queue.append(8)
	_spawn_queue.shuffle()

func _spawn_enemy(kind: int, active: bool) -> Node:
	if enemy_scene == null:
		return null
	var e: Node = enemy_scene.instantiate()
	enemy_root.add_child(e)
	if e is Node2D:
		(e as Node2D).global_position = _clamp_to_arena(_random_spawn())
	if e.has_method("set_target"):
		e.set_target(player)
	if e.has_method("configure"):
		e.configure(kind, wave, enemy_projectile_scene)
	_apply_wave_mutator_to_enemy(e)
	_try_apply_elite(e)
	if e.has_signal("died"):
		e.connect("died", Callable(self, "_on_enemy_died").bind(e))
	if e.has_method("set_active"):
		e.set_active(active)
	if active and _wave_active:
		_try_assign_wave_anchor()
	return e

func _try_apply_elite(enemy: Node) -> void:
	if wave < 3:
		return
	var elite_chance := clampf(0.08 + wave * 0.012 + _director_elite_bonus, 0.0, 0.70)
	if _rng.randf() > elite_chance:
		return
	_apply_elite_combo(enemy, false)

func _apply_elite_combo(enemy: Node, force_double: bool) -> void:
	if not enemy.has_method("apply_elite_mod"):
		return
	var first_idx: int = _rng.randi_range(0, ELITE_MODS.size() - 1)
	var first: Dictionary = ELITE_MODS[first_idx]
	enemy.apply_elite_mod(first)
	var double_chance := clampf(0.08 + wave * 0.01 + _director_elite_bonus * 0.85, 0.0, 0.75)
	var do_double: bool = force_double or (wave >= 8 and _rng.randf() < double_chance)
	if not do_double:
		return
	var second_idx: int = _rng.randi_range(0, ELITE_MODS.size() - 1)
	var guard = 0
	while second_idx == first_idx and guard < 12:
		second_idx = _rng.randi_range(0, ELITE_MODS.size() - 1)
		guard += 1
	var second: Dictionary = ELITE_MODS[second_idx]
	enemy.apply_elite_mod(second)

func _spawn_miniboss_if_needed() -> void:
	if _boss_spawned_this_wave:
		return
	if wave % MINI_BOSS_INTERVAL != 0:
		return
	_boss_spawned_this_wave = true
	var boss_kind: int = _rng.randi_range(2, 8)
	var boss: Node = _spawn_enemy(boss_kind, true)
	if boss == null:
		return
	if boss is Node2D:
		(boss as Node2D).scale = Vector2(1.5, 1.5)
	_apply_elite_combo(boss, true)
	if boss.has_method("apply_elite_mod"):
		boss.apply_elite_mod({"name":"MiniBoss", "hp_mul": 2.8, "dmg_mul": 1.35, "speed_mul": 0.95, "color": Color(1.0, 0.74, 0.18, 1.0)})
	_show_message(tr("msg_miniboss") % wave)

func _on_wave_clear() -> void:
	_wave_active = false
	_mid_mutation_stage = 0
	_wave_elapsed = 0.0
	_directive_pool.clear()
	_cleanup_objective_state()
	_commit_wave_telemetry()
	player.heal(20.0)
	player.restore_sp(25.0)
	_show_message(tr("msg_wave_clear") % wave)
	play_sfx("wave_clear")
	_show_cards()

func _show_cards() -> void:
	_choice_mode = "card"
	_apply_ui_locale()
	_card_choices = _draw_cards(3)
	_update_card_button(card_a, _card_choices[0])
	_update_card_button(card_b, _card_choices[1])
	_update_card_button(card_c, _card_choices[2])
	_set_card_buttons(false)
	_prepare_card_intro_visual()
	card_shade.visible = true
	_play_card_intro()

func _pick_card(index: int) -> void:
	if card_a.disabled or card_b.disabled or card_c.disabled:
		return
	if _choice_mode == "mitigation":
		_pick_mitigation(index)
		return
	if index < 0 or index >= _card_choices.size():
		return
	var card: Dictionary = _card_choices[index]
	_card_pick_order.append(str(card.get("title", "card_unknown")))
	player.apply_upgrade(card["effect"])
	var ready_list: Array[String] = _apply_archetype_progress(card)
	var pick_msg := tr("msg_card_pick") % tr(str(card["title"]))
	for school in ready_list:
		pick_msg += "\n" + (tr("msg_keystone_ready") % _archetype_name(school))
	if bool(card.get("keystone", false)):
		_keystone_picked = true
		_keystone_school = str(card.get("requires_archetype", ""))
		pick_msg = "%s\n%s" % [pick_msg, tr("msg_keystone_commit") % _archetype_name(_keystone_school)]
	_show_message(pick_msg)
	play_sfx("card_pick")
	card_shade.visible = false
	if _should_offer_affliction_for_next_wave():
		_prepare_next_affliction()
		_show_mitigation_choices()
	else:
		_set_intermission(INTERMISSION_SECONDS)

func _set_intermission(sec: float) -> void:
	_intermission_left = sec
	_wave_active = false
	_wave_preview = false
	_cleanup_objective_state()
	_anchor_enemy = null
	_anchor_faction = -1
	_anchor_active = false
	_director_spawn_mul = 1.0
	_director_directive_mul = 1.0
	_director_elite_bonus = 0.0

func _draw_cards(count: int) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for card in CARD_POOL:
		if _card_is_available(card):
			pool.append(card)
	for card in KEYSTONE_CARD_POOL:
		if _card_is_available(card):
			pool.append(card)
	for card in AUGMENT_CARD_POOL:
		if _card_is_available(card):
			pool.append(card)
	if pool.size() < count:
		pool = CARD_POOL.duplicate(true)
		for card in KEYSTONE_CARD_POOL:
			if _card_is_available(card):
				pool.append(card)
		for card in AUGMENT_CARD_POOL:
			if _card_is_available(card):
				pool.append(card)
	pool.shuffle()
	var result: Array[Dictionary] = []
	var cap = mini(count, pool.size())
	for i in cap:
		result.append(pool[i])
	while result.size() < count and CARD_POOL.size() > 0:
		result.append(CARD_POOL[_rng.randi_range(0, CARD_POOL.size() - 1)])
	return result

func _card_is_available(card: Dictionary) -> bool:
	if player == null:
		return true
	if bool(card.get("keystone", false)):
		var school := str(card.get("requires_archetype", ""))
		if school == "" or not bool(_keystone_ready.get(school, false)):
			return false
		if _keystone_picked:
			return false
	if bool(card.get("augment", false)):
		var augment_id := str(card.get("augment_id", ""))
		var socket := str(card.get("requires_socket", ""))
		if augment_id == "" or socket == "":
			return false
		if player.has_method("has_augment") and player.has_augment(augment_id):
			return false
		if player.has_method("has_free_socket") and not player.has_free_socket(socket):
			return false
	var effect: Variant = card.get("effect", {})
	if not (effect is Dictionary):
		return true
	var e: Dictionary = effect
	if e.has("unlock_chain_sigil"):
		if player.has_method("is_spell_unlocked") and player.is_spell_unlocked("chain_sigil"):
			return false
	if e.has("unlock_meteor_rain"):
		if player.has_method("is_spell_unlocked") and player.is_spell_unlocked("meteor_rain"):
			return false
	var need_meteor := e.has("meteor_strikes_add") or e.has("meteor_radius_add") or e.has("meteor_delay_mul") or e.has("meteor_damage_add") or e.has("meteor_echo_add")
	if need_meteor:
		if player.has_method("is_spell_unlocked") and not player.is_spell_unlocked("meteor_rain"):
			return false
	if e.has("meteor_style_shower"):
		if player.has_method("is_spell_unlocked"):
			if not player.is_spell_unlocked("meteor_rain"):
				return false
			if player.is_spell_unlocked("meteor_style_cata"):
				return false
			if player.is_spell_unlocked("meteor_style_shower"):
				return false
	if e.has("meteor_style_cata"):
		if player.has_method("is_spell_unlocked"):
			if not player.is_spell_unlocked("meteor_rain"):
				return false
			if player.is_spell_unlocked("meteor_style_shower"):
				return false
			if player.is_spell_unlocked("meteor_style_cata"):
				return false
	if e.has("resonance_gain_mul"):
		if player.has_method("is_spell_unlocked"):
			if not player.is_spell_unlocked("meteor_rain") or not player.is_spell_unlocked("chain_sigil"):
				return false
	if e.has("sword_style_whirl"):
		if player.has_method("is_spell_unlocked"):
			if player.is_spell_unlocked("sword_style_exec") or player.is_spell_unlocked("sword_style_whirl"):
				return false
	if e.has("sword_style_exec"):
		if player.has_method("is_spell_unlocked"):
			if player.is_spell_unlocked("sword_style_whirl") or player.is_spell_unlocked("sword_style_exec"):
				return false
	if e.has("shot_style_barrage"):
		if player.has_method("is_spell_unlocked"):
			if player.is_spell_unlocked("shot_style_rail") or player.is_spell_unlocked("shot_style_barrage"):
				return false
	if e.has("shot_style_rail"):
		if player.has_method("is_spell_unlocked"):
			if player.is_spell_unlocked("shot_style_barrage") or player.is_spell_unlocked("shot_style_rail"):
				return false
	if e.has("unlock_combo_overdrive"):
		if player.has_method("has_combo_card") and player.has_combo_card("overdrive_link"):
			return false
	if e.has("unlock_combo_shield_empty"):
		if player.has_method("has_combo_card") and player.has_combo_card("shield_empty_link"):
			return false
	if e.has("unlock_combo_dash_chain"):
		if player.has_method("has_combo_card") and player.has_combo_card("dash_chain_link"):
			return false
	return true

func _archetype_name(id: String) -> String:
	return tr("archetype_" + id)

func _archetype_base_gain(card: Dictionary) -> float:
	var rarity := str(card.get("rarity", "common"))
	match rarity:
		"rare":
			return 1.6
		"epic":
			return 2.3
		_:
			return 1.0

func _effect_to_archetype(key: String) -> String:
	if key.begins_with("sword_"):
		return "blade"
	if key.begins_with("shot_"):
		return "ballistic"
	if key.begins_with("magic_") or key.begins_with("meteor_") or key.begins_with("resonance_"):
		return "arcane"
	if key.begins_with("dash_") or key.begins_with("shield_"):
		return "tactical"
	if key == "move_speed_mul":
		return "tactical"
	if key == "unlock_chain_sigil" or key == "unlock_meteor_rain":
		return "arcane"
	return ""

func _apply_archetype_progress(card: Dictionary) -> Array[String]:
	var unlocked: Array[String] = []
	if bool(card.get("keystone", false)):
		return unlocked
	var effect: Variant = card.get("effect", {})
	if not (effect is Dictionary):
		return unlocked
	var e: Dictionary = effect
	var weights := {
		"blade": 0.0,
		"ballistic": 0.0,
		"arcane": 0.0,
		"tactical": 0.0
	}
	for k in e.keys():
		var school := _effect_to_archetype(str(k))
		if school == "":
			continue
		weights[school] = float(weights[school]) + 1.0
	var sum := float(weights["blade"]) + float(weights["ballistic"]) + float(weights["arcane"]) + float(weights["tactical"])
	if sum <= 0.0:
		return unlocked
	var base_gain := _archetype_base_gain(card)
	for school in ARCHETYPES:
		var add := base_gain * (float(weights[school]) / sum)
		_archetype_meter[school] = minf(ARCHETYPE_MAX, float(_archetype_meter[school]) + add)
		if not bool(_keystone_ready[school]) and float(_archetype_meter[school]) >= ARCHETYPE_THRESHOLD:
			_keystone_ready[school] = true
			unlocked.append(school)
	_archetype_trace.append({
		"wave": wave,
		"pick": _card_pick_order.size(),
		"blade": float(_archetype_meter["blade"]),
		"ballistic": float(_archetype_meter["ballistic"]),
		"arcane": float(_archetype_meter["arcane"]),
		"tactical": float(_archetype_meter["tactical"])
	})
	return unlocked

func _update_card_button(btn: Button, card: Dictionary) -> void:
	var rarity: String = str(card.get("rarity", "common"))
	var rarity_text: String = tr(str(RARITY_LABEL.get(rarity, "rarity_common")))
	var c: Color = Color(RARITY_COLOR.get(rarity, Ink.SUMI))
	_set_card_body(btn, _card_bbcode(rarity_text, tr(str(card["title"])), tr(str(card["desc"])), c), c)

func _should_offer_affliction_for_next_wave() -> bool:
	return wave >= AFFLICTION_INTERVAL and wave % AFFLICTION_INTERVAL == 0

func _prepare_next_affliction() -> void:
	var pool: Array[String] = ["low_visibility", "mana_static", "rupture_tides"]
	if _active_affliction != "" and pool.has(_active_affliction):
		pool.erase(_active_affliction)
	if pool.is_empty():
		pool.append("low_visibility")
	_pending_affliction = pool[_rng.randi_range(0, pool.size() - 1)]
	_mitigation_choices = _build_mitigation_choices(_pending_affliction)

func _show_mitigation_choices() -> void:
	_choice_mode = "mitigation"
	_apply_ui_locale()
	if _mitigation_choices.size() < 3:
		_mitigation_choices = _build_mitigation_choices(_pending_affliction)
	_update_choice_button(card_a, _mitigation_choices[0])
	_update_choice_button(card_b, _mitigation_choices[1])
	_update_choice_button(card_c, _mitigation_choices[2])
	_set_card_buttons(false)
	_prepare_card_intro_visual()
	card_shade.visible = true
	_play_card_intro()
	_show_message(tr("msg_affliction_incoming") % tr("affliction_" + _pending_affliction))

func _update_choice_button(btn: Button, choice: Dictionary) -> void:
	var rarity: String = str(choice.get("rarity", "rare"))
	var rarity_text: String = tr(str(RARITY_LABEL.get(rarity, "rarity_rare")))
	var c: Color = Color(RARITY_COLOR.get(rarity, Ink.INDIGO))
	_set_card_body(btn, _card_bbcode(rarity_text, tr(str(choice.get("title", ""))), tr(str(choice.get("desc", ""))), c), c)

func _pick_mitigation(index: int) -> void:
	if index < 0 or index >= _mitigation_choices.size():
		return
	var choice: Dictionary = _mitigation_choices[index]
	var effect: Dictionary = choice.get("effect", {})
	_apply_mitigation_effect(effect)
	if choice.has("grant_upgrade"):
		player.apply_upgrade(choice["grant_upgrade"])
	_affliction_mitigation = str(choice.get("title", ""))
	_show_message(tr("msg_affliction_mitigated") % [tr("affliction_" + _pending_affliction), tr(_affliction_mitigation)])
	play_sfx("card_pick")
	card_shade.visible = false
	_set_intermission(INTERMISSION_SECONDS)

func _build_mitigation_choices(affliction_id: String) -> Array[Dictionary]:
	match affliction_id:
		"low_visibility":
			return [
				{"title":"mitigation_visibility_beacon_t", "desc":"mitigation_visibility_beacon_d", "rarity":"rare", "effect":{"warning_mul_add": 0.22}},
				{"title":"mitigation_visibility_scout_t", "desc":"mitigation_visibility_scout_d", "rarity":"rare", "effect":{"warning_mul_add": 0.12}, "grant_upgrade":{"move_speed_mul": 1.08}},
				{"title":"mitigation_visibility_lens_t", "desc":"mitigation_visibility_lens_d", "rarity":"rare", "effect":{"warning_mul_add": 0.08}, "grant_upgrade":{"shot_speed_add": 70.0}}
			]
		"mana_static":
			return [
				{"title":"mitigation_mana_ground_t", "desc":"mitigation_mana_ground_d", "rarity":"rare", "effect":{"mana_drain_mul_mul": 0.58}},
				{"title":"mitigation_mana_flux_t", "desc":"mitigation_mana_flux_d", "rarity":"rare", "effect":{"mana_drain_mul_mul": 0.74}, "grant_upgrade":{"magic_haste_mul": 1.08}},
				{"title":"mitigation_mana_reserve_t", "desc":"mitigation_mana_reserve_d", "rarity":"rare", "effect":{"mana_drain_mul_mul": 0.80}, "grant_upgrade":{"max_sp_add": 20.0, "sp_add": 20.0}}
			]
		"rupture_tides":
			return [
				{"title":"mitigation_tide_anchor_t", "desc":"mitigation_tide_anchor_d", "rarity":"rare", "effect":{"tide_interval_mul_mul": 1.28}},
				{"title":"mitigation_tide_weave_t", "desc":"mitigation_tide_weave_d", "rarity":"rare", "effect":{"tide_damage_mul_mul": 0.72}, "grant_upgrade":{"dash_cd_mul": 0.90}},
				{"title":"mitigation_tide_kinetic_t", "desc":"mitigation_tide_kinetic_d", "rarity":"rare", "effect":{"tide_radius_mul_mul": 0.82}, "grant_upgrade":{"dash_cd_mul": 0.88}}
			]
	return [
		{"title":"mitigation_visibility_beacon_t", "desc":"mitigation_visibility_beacon_d", "rarity":"rare", "effect":{"warning_mul_add": 0.18}},
		{"title":"mitigation_mana_ground_t", "desc":"mitigation_mana_ground_d", "rarity":"rare", "effect":{"mana_drain_mul_mul": 0.70}},
		{"title":"mitigation_tide_anchor_t", "desc":"mitigation_tide_anchor_d", "rarity":"rare", "effect":{"tide_interval_mul_mul": 1.20}}
	]

func _apply_mitigation_effect(effect: Dictionary) -> void:
	if effect.has("warning_mul_add"):
		_affliction_warning_mul += float(effect["warning_mul_add"])
	if effect.has("mana_drain_mul_mul"):
		_affliction_mana_drain_mul *= float(effect["mana_drain_mul_mul"])
	if effect.has("tide_interval_mul_mul"):
		_affliction_tide_interval_mul *= float(effect["tide_interval_mul_mul"])
	if effect.has("tide_damage_mul_mul"):
		_affliction_tide_damage_mul *= float(effect["tide_damage_mul_mul"])
	if effect.has("tide_radius_mul_mul"):
		_affliction_tide_radius_mul *= float(effect["tide_radius_mul_mul"])

func _activate_pending_affliction_if_any() -> void:
	if _pending_affliction == "":
		return
	_active_affliction = _pending_affliction
	_run_affliction_wave_count += 1
	_pending_affliction = ""
	_affliction_start_wave = wave
	match _active_affliction:
		"low_visibility":
			_affliction_warning_mul = 0.72
			_affliction_tick_left = 0.0
		"mana_static":
			_affliction_mana_drain_mul = 1.0
			_affliction_tick_left = 0.45
		"rupture_tides":
			_affliction_tide_interval_mul = 1.0
			_affliction_tide_damage_mul = 1.0
			_affliction_tide_radius_mul = 1.0
			_affliction_tick_left = 1.2
	_show_message(tr("msg_affliction_active") % tr("affliction_" + _active_affliction))

func _update_affliction_runtime(delta: float) -> void:
	if _active_affliction == "":
		return
	_affliction_tick_left -= delta
	match _active_affliction:
		"mana_static":
			if _affliction_tick_left <= 0.0:
				_affliction_tick_left = 1.0
				if player != null and player.has_method("drain_sp"):
					player.drain_sp((6.0 + float(wave) * 0.12) * _affliction_mana_drain_mul)
		"rupture_tides":
			if _affliction_tick_left <= 0.0:
				_affliction_tick_left = maxf(2.4, (5.8 - float(wave) * 0.05) * _affliction_tide_interval_mul)
				if player != null:
					var center := _clamp_to_arena((player as Node2D).global_position + Vector2(_rng.randf_range(-120.0, 120.0), _rng.randf_range(-90.0, 90.0)))
					var radius := (112.0 + float(wave) * 0.7) * _affliction_tide_radius_mul
					_spawn_ground_warning(center, radius, Color(1.0, 0.34, 0.66, 0.84), 0.66)
					var damage_val := int(round((8.0 + float(wave) * 0.18) * _affliction_tide_damage_mul))
					var timer := get_tree().create_timer(0.66)
					timer.timeout.connect(func() -> void:
						if not _wave_active or _active_affliction != "rupture_tides":
							return
						_spawn_radial_volley(center, 10 + int(wave * 0.08), _rng.randf() * TAU)
						if player != null and player.has_method("take_damage") and (player as Node2D).global_position.distance_to(center) <= radius:
							player.take_damage(damage_val)
					)

func _affliction_summary() -> String:
	if _active_affliction == "":
		return tr("affliction_none")
	return tr("affliction_" + _active_affliction)

func _prepare_card_intro_visual() -> void:
	var c: Color = card_shade.color
	c.a = 0.0
	card_shade.color = c
	card_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	card_panel.scale = Vector2(0.94, 0.94)
	card_a.modulate = Color(1.0, 1.0, 1.0, 0.0)
	card_b.modulate = Color(1.0, 1.0, 1.0, 0.0)
	card_c.modulate = Color(1.0, 1.0, 1.0, 0.0)

func _play_card_intro() -> void:
	var t: Tween = create_tween()
	t.set_trans(Tween.TRANS_CUBIC)
	t.set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(card_shade, "color:a", 0.62, 0.2)
	t.parallel().tween_property(card_panel, "modulate:a", 1.0, 0.25)
	t.parallel().tween_property(card_panel, "scale", Vector2.ONE, 0.25)
	t.chain().tween_property(card_a, "modulate:a", 1.0, 0.1)
	t.tween_property(card_b, "modulate:a", 1.0, 0.1)
	t.tween_property(card_c, "modulate:a", 1.0, 0.1)
	t.finished.connect(func() -> void:
		var tm: SceneTreeTimer = get_tree().create_timer(0.25)
		tm.timeout.connect(func() -> void:
			_set_card_buttons(true)
		)
	)

func _set_card_buttons(enabled: bool) -> void:
	card_a.disabled = not enabled
	card_b.disabled = not enabled
	card_c.disabled = not enabled

func _init_run_relic() -> void:
	_run_relic_id = ""
	_run_relic_pack.clear()
	if ProgressionManager == null:
		return
	if not ProgressionManager.has_method("get_unlocked_relics"):
		return
	var relics: Array[String] = ProgressionManager.get_unlocked_relics()
	if relics.is_empty():
		return
	_run_relic_id = relics[_rng.randi_range(0, relics.size() - 1)]
	if ProgressionManager.has_method("get_relic_rule_pack"):
		_run_relic_pack = ProgressionManager.get_relic_rule_pack(_run_relic_id)
	if not _run_relic_pack.is_empty():
		var relic_title := tr(str(_run_relic_pack.get("title", "relic_none")))
		_show_message(tr("msg_relic_active") % relic_title)

func _relic_summary() -> String:
	if _run_relic_pack.is_empty():
		return tr("relic_none")
	return tr(str(_run_relic_pack.get("title", "relic_none")))

func _mutate_terrain() -> void:
	for n in dynamic_root.get_children():
		n.queue_free()
	for n in hazard_root.get_children():
		n.queue_free()
	_terrain_seed += 73 + wave * 11
	_rng.seed = Time.get_ticks_msec() + _terrain_seed

	_terrain_theme = _choose_terrain_theme()
	_wave_mutator = _choose_wave_mutator()
	_wave_directive = _choose_wave_directive()
	var terrain_type = _pick_layout_for_theme(_terrain_theme)
	_build_terrain_layout(terrain_type, _terrain_theme)
	var obstacle_count: int = 4 + int(wave / 3)
	for i in obstacle_count:
		var x = _rng.randf_range(-650.0, 650.0)
		var y = _rng.randf_range(-360.0, 360.0)
		var w = _rng.randf_range(36.0, 112.0)
		var h = _rng.randf_range(28.0, 94.0)
		_create_world_block(Rect2(x, y, w, h), _theme_wall_color(_terrain_theme), dynamic_root)

	var relic_hazard_add := int(_run_relic_pack.get("extra_hazard_add", 0))
	var hazard_count: int = mini(12, 2 + int(wave / 2) + int(_wave_mutator.get("hazard_extra", 0)) + relic_hazard_add)
	for i in hazard_count:
		if hazard_scene == null:
			continue
		var hz: Node = hazard_scene.instantiate()
		hazard_root.add_child(hz)
		if hz is Node2D:
			(hz as Node2D).global_position = Vector2(_rng.randf_range(-610.0, 610.0), _rng.randf_range(-330.0, 330.0))
		if hz.has_method("set_hazard_kind"):
			hz.set_hazard_kind(_pick_hazard_kind_for_theme(_terrain_theme))
		if hz.has_method("configure_for_wave"):
			hz.configure_for_wave(wave + int(_run_relic_pack.get("hazard_extra_wave", 0)))

func _build_terrain_layout(terrain_type: int, theme: int) -> void:
	var wall_c := _theme_wall_color(theme)
	match terrain_type:
		0:
			for i in 5:
				var x = -560.0 + float(i) * 235.0
				var offset = 60.0 if i % 2 == 0 else -60.0
				_create_world_block(Rect2(x, -18.0 + offset, 110.0, 36.0), wall_c, dynamic_root)
		1:
			_create_world_block(Rect2(-620.0, -36.0, 1240.0, 72.0), wall_c, dynamic_root)
			_create_world_block(Rect2(-40.0, -290.0, 80.0, 580.0), wall_c, dynamic_root)
		2:
			_create_world_block(Rect2(-310.0, -230.0, 620.0, 28.0), wall_c, dynamic_root)
			_create_world_block(Rect2(-310.0, 202.0, 620.0, 28.0), wall_c, dynamic_root)
			_create_world_block(Rect2(-310.0, -230.0, 28.0, 460.0), wall_c, dynamic_root)
			_create_world_block(Rect2(282.0, -230.0, 28.0, 460.0), wall_c, dynamic_root)
		3:
			for i in 4:
				var y = -280.0 + float(i) * 170.0
				_create_world_block(Rect2(-700.0 + 120.0 * float(i % 2), y, 520.0, 24.0), wall_c, dynamic_root)
				_create_world_block(Rect2(180.0 - 120.0 * float(i % 2), y + 60.0, 520.0, 24.0), wall_c, dynamic_root)

func _choose_terrain_theme() -> int:
	var roll = _rng.randi_range(1, 100)
	if wave <= 4:
		if roll <= 55:
			return 0
		if roll <= 78:
			return 1
		if roll <= 90:
			return 3
		return 2
	if wave <= 9:
		if roll <= 30:
			return 0
		if roll <= 55:
			return 1
		if roll <= 80:
			return 3
		return 2
	if roll <= 18:
		return 0
	if roll <= 40:
		return 1
	if roll <= 68:
		return 3
	return 2

func _pick_layout_for_theme(theme: int) -> int:
	match theme:
		1:
			return [0, 2, 3][_rng.randi_range(0, 2)]
		2:
			return [1, 2, 3][_rng.randi_range(0, 2)]
		3:
			return [0, 1, 3][_rng.randi_range(0, 2)]
		_:
			return _rng.randi_range(0, 3)

func _pick_hazard_kind_for_theme(theme: int) -> int:
	var roll = _rng.randi_range(1, 100)
	match theme:
		1:
			if roll <= 65:
				return 1
			if roll <= 85:
				return 0
			return 3
		2:
			if roll <= 62:
				return 2
			if roll <= 82:
				return 3
			return 0
		3:
			if roll <= 68:
				return 3
			if roll <= 84:
				return 1
			return 2
		_:
			if roll <= 58:
				return 0
			if roll <= 76:
				return 1
			if roll <= 90:
				return 3
			return 2

func _choose_wave_mutator() -> Dictionary:
	if wave <= 2:
		return MUTATOR_POOL[0]
	var roll = _rng.randi_range(1, 100)
	if wave <= 5:
		if roll <= 36:
			return MUTATOR_POOL[0]
		if roll <= 58:
			return MUTATOR_POOL[1]
		if roll <= 78:
			return MUTATOR_POOL[3]
		return MUTATOR_POOL[2]
	if wave <= 10:
		if roll <= 20:
			return MUTATOR_POOL[0]
		if roll <= 44:
			return MUTATOR_POOL[1]
		if roll <= 65:
			return MUTATOR_POOL[3]
		if roll <= 85:
			return MUTATOR_POOL[2]
		return MUTATOR_POOL[4]
	if roll <= 12:
		return MUTATOR_POOL[0]
	if roll <= 32:
		return MUTATOR_POOL[1]
	if roll <= 54:
		return MUTATOR_POOL[3]
	if roll <= 72:
		return MUTATOR_POOL[2]
	return MUTATOR_POOL[4]

func _apply_wave_mutator_to_enemy(enemy: Node) -> void:
	if not enemy.has_method("apply_elite_mod"):
		return
	var id = str(_wave_mutator.get("id", "none"))
	if id == "none":
		return
	var hp_mul = float(_wave_mutator.get("enemy_hp_mul", 1.0))
	var speed_mul = float(_wave_mutator.get("enemy_speed_mul", 1.0))
	var color = Color(1.0, 1.0, 1.0, 1.0)
	match id:
		"swarm":
			color = Color(0.82, 1.0, 0.86, 1.0)
		"fortified":
			color = Color(1.0, 0.88, 0.60, 1.0)
		"hunters":
			color = Color(0.82, 0.92, 1.0, 1.0)
		"cataclysm":
			color = Color(1.0, 0.76, 0.88, 1.0)
		_:
			color = Color(1.0, 1.0, 1.0, 1.0)
	enemy.apply_elite_mod({
		"name": "",
		"hp_mul": hp_mul,
		"speed_mul": speed_mul,
		"dmg_mul": 1.0,
		"color": color
	})

func _update_midwave_mutation() -> void:
	if not _wave_active:
		return
	if _mid_mutation_stage >= 2:
		return
	var kill_progress := float(maxi(0, _kills - _wave_kills_start)) / float(maxi(1, _wave_enemy_budget))
	if _mid_mutation_stage == 0:
		if _wave_elapsed >= _mutation_time_1 or kill_progress >= 0.36:
			_trigger_midwave_mutation(1)
	elif _mid_mutation_stage == 1:
		if _wave_elapsed >= _mutation_time_2 or kill_progress >= 0.72:
			_trigger_midwave_mutation(2)

func _trigger_midwave_mutation(stage: int) -> void:
	_mid_mutation_stage = clampi(stage, 1, 2)
	_apply_layout_mutation(_mid_mutation_stage)
	_rotate_hazards_for_mutation(_mid_mutation_stage)
	_directive_pool = _build_directive_pool(_mid_mutation_stage)
	if _mid_mutation_stage == 1:
		_show_message(tr("msg_mutation_stage1"))
	else:
		_show_message(tr("msg_mutation_stage2"))
	_objective_trigger_left = minf(_objective_trigger_left, 2.2)

func _build_directive_pool(stage: int) -> Array[String]:
	var pool: Array[String] = []
	pool.append_array(["surge", "surge", "seismic", "flux"])
	if wave >= 4:
		pool.append("beacon_drop")
	if wave >= 7:
		pool.append("hellburst")
	if stage >= 1:
		pool.append_array(["seismic", "flux", "beacon_drop"])
	if stage >= 2:
		pool.append_array(["hellburst", "hellburst", "flux"])
	if bool(_run_relic_pack.get("force_flux_directive", false)):
		pool.append("flux")
		if stage >= 1:
			pool.append("flux")
	return pool

func _pick_runtime_directive() -> String:
	if _directive_pool.is_empty():
		_directive_pool = _build_directive_pool(_mid_mutation_stage)
	var idx := _rng.randi_range(0, _directive_pool.size() - 1)
	return _directive_pool[idx]

func _collect_dynamic_blocks() -> Array[Node2D]:
	var blocks: Array[Node2D] = []
	for n in dynamic_root.get_children():
		if not (n is Node2D):
			continue
		var has_world := false
		for c in n.get_children():
			if c is StaticBody2D and (c as StaticBody2D).is_in_group("world"):
				has_world = true
				break
		if has_world:
			blocks.append(n as Node2D)
	return blocks

func _apply_layout_mutation(stage: int) -> void:
	var blocks := _collect_dynamic_blocks()
	if stage == 1:
		var remove_n := mini(4, blocks.size())
		for i in remove_n:
			var best_idx := -1
			var best_score := INF
			for j in blocks.size():
				var p := blocks[j].global_position
				var score := absf(p.x) + absf(p.y) * 0.85
				if score < best_score:
					best_score = score
					best_idx = j
			if best_idx >= 0:
				var pick := blocks[best_idx]
				if is_instance_valid(pick):
					pick.queue_free()
				blocks.remove_at(best_idx)
	else:
		var wall_c := _theme_wall_color(_terrain_theme)
		var rects: Array[Rect2] = []
		if _rng.randf() < 0.5:
			rects = [Rect2(-310.0, -120.0, 620.0, 26.0), Rect2(-310.0, 96.0, 620.0, 26.0)]
		else:
			rects = [Rect2(-120.0, -250.0, 26.0, 500.0), Rect2(94.0, -250.0, 26.0, 500.0)]
		for r in rects:
			_create_world_block(r, wall_c, dynamic_root, true)

func _rotate_hazards_for_mutation(stage: int) -> void:
	for hz in hazard_root.get_children():
		if not hz.has_method("set_hazard_kind"):
			continue
		if stage == 1:
			var k1: Array[int] = [_pick_hazard_kind_for_theme(_terrain_theme), _rng.randi_range(0, 3)]
			hz.set_hazard_kind(k1[_rng.randi_range(0, k1.size() - 1)])
		else:
			var k2: Array[int] = [0, 2, 3]
			hz.set_hazard_kind(k2[_rng.randi_range(0, k2.size() - 1)])
		if hz.has_method("configure_for_wave"):
			hz.configure_for_wave(wave + stage)
		if hz.has_method("receive_chain_pulse"):
			hz.receive_chain_pulse(3 if stage == 2 else 1, 1.0 + float(stage) * 0.3)
	if stage >= 2 and hazard_scene != null and _rng.randf() < 0.75:
		var extra_n := 1 + int(_rng.randf() < 0.45)
		for i in extra_n:
			var h: Node = hazard_scene.instantiate()
			hazard_root.add_child(h)
			if h is Node2D:
				(h as Node2D).global_position = Vector2(_rng.randf_range(-620.0, 620.0), _rng.randf_range(-330.0, 330.0))
			if h.has_method("set_hazard_kind"):
				h.set_hazard_kind([0, 2, 3][_rng.randi_range(0, 2)])
			if h.has_method("configure_for_wave"):
				h.configure_for_wave(wave + 2)
			if h.has_method("set_gameplay_active"):
				h.set_gameplay_active(_wave_active)

func _choose_wave_directive() -> String:
	var roll := _rng.randi_range(1, 100)
	if wave <= 3:
		if roll <= 50:
			return "surge"
		return "flux"
	if wave <= 8:
		if roll <= 34:
			return "surge"
		if roll <= 64:
			return "seismic"
		if roll <= 84:
			return "flux"
		return "beacon_drop"
	if roll <= 24:
		return "surge"
	if roll <= 48:
		return "seismic"
	if roll <= 70:
		return "flux"
	if roll <= 86:
		return "beacon_drop"
	return "hellburst"

func _trigger_wave_directive() -> void:
	if not _wave_active:
		return
	_wave_directive_count += 1
	_wave_directive = _pick_runtime_directive()
	match _wave_directive:
		"surge":
			_directive_surge_pack()
		"seismic":
			_directive_seismic_ring()
		"flux":
			_directive_hazard_flux()
		"beacon_drop":
			_directive_beacon_drop()
		"hellburst":
			_directive_hellburst()
		_:
			_directive_surge_pack()

func _directive_surge_pack() -> void:
	_show_message(tr("msg_directive_surge"))
	var n := int(round((3.0 + float(wave) * 0.08) * _director_directive_mul))
	for i in range(maxi(2, n)):
		var kind := 0 if i % 2 == 0 else 8
		_spawn_queue.append(kind)

func _directive_seismic_ring() -> void:
	if player == null:
		return
	var center := (player as Node2D).global_position
	_show_message(tr("msg_directive_seismic"))
	var radius := 132.0 * (0.92 + 0.20 * _director_directive_mul)
	_spawn_ground_warning(center, radius, Color(1.0, 0.48, 0.22, 0.82), 0.68)
	var timer := get_tree().create_timer(0.68)
	await timer.timeout
	var volley_count := int(round((14.0 + float(wave) * 0.1) * _director_directive_mul))
	_spawn_radial_volley(center, maxi(10, volley_count), 0.0)

func _directive_hazard_flux() -> void:
	_show_message(tr("msg_directive_flux"))
	for hz in hazard_root.get_children():
		if hz.has_method("set_hazard_kind"):
			hz.set_hazard_kind(_rng.randi_range(0, 3))
		if hz.has_method("configure_for_wave"):
			hz.configure_for_wave(wave + 1)
	if hazard_scene != null:
		var extra_chance := clampf(0.45 + (_director_directive_mul - 1.0) * 0.55, 0.25, 0.92)
		var extra_count := 1 if _rng.randf() < extra_chance else 0
		if _director_directive_mul >= 1.55 and _rng.randf() < 0.45:
			extra_count += 1
		for i in range(extra_count):
			var hz: Node = hazard_scene.instantiate()
			hazard_root.add_child(hz)
			if hz is Node2D:
				(hz as Node2D).global_position = Vector2(_rng.randf_range(-600.0, 600.0), _rng.randf_range(-320.0, 320.0))
			if hz.has_method("set_hazard_kind"):
				hz.set_hazard_kind(_rng.randi_range(0, 3))
			if hz.has_method("configure_for_wave"):
				hz.configure_for_wave(wave + 1 + i)
			if hz.has_method("set_gameplay_active"):
				hz.set_gameplay_active(_wave_active)

func _directive_beacon_drop() -> void:
	_show_message(tr("msg_directive_beacon"))
	var p := _clamp_to_arena(_random_spawn())
	_spawn_ground_warning(p, 86.0, Color(0.36, 1.0, 0.90, 0.84), 0.72)
	var timer := get_tree().create_timer(0.72)
	await timer.timeout
	var beacon_count := 1
	if _director_directive_mul >= 1.45 and _rng.randf() < 0.55:
		beacon_count = 2
	for i in range(beacon_count):
		var b := _spawn_enemy(7, true)
		if b is Node2D:
			var jitter := Vector2(_rng.randf_range(-52.0, 52.0), _rng.randf_range(-48.0, 48.0))
			(b as Node2D).global_position = _clamp_to_arena(p + jitter)

func _directive_hellburst() -> void:
	if player == null:
		return
	var pos := (player as Node2D).global_position + Vector2(_rng.randf_range(-110.0, 110.0), _rng.randf_range(-80.0, 80.0))
	_show_message(tr("msg_directive_hellburst"))
	await request_bullet_hell(_clamp_to_arena(pos))
	if _director_directive_mul >= 1.42 and _rng.randf() < 0.42:
		var pos2 := (player as Node2D).global_position + Vector2(_rng.randf_range(-150.0, 150.0), _rng.randf_range(-120.0, 120.0))
		await request_bullet_hell(_clamp_to_arena(pos2))

func _current_spawn_interval() -> float:
	var base := maxf(0.12, BASE_SPAWN_INTERVAL - wave * 0.005)
	return clampf(base / clampf(_director_spawn_mul, 0.72, 1.9), 0.08, 0.55)

func _track_position_entropy(delta: float) -> void:
	if player == null:
		return
	_pos_sample_left -= delta
	if _pos_sample_left > 0.0:
		return
	_pos_sample_left = 0.24
	var p := (player as Node2D).global_position
	var gx := int(floor((p.x - ARENA_RECT.position.x) / 160.0))
	var gy := int(floor((p.y - ARENA_RECT.position.y) / 120.0))
	var key := "%d:%d" % [gx, gy]
	_wave_position_bins[key] = int(_wave_position_bins.get(key, 0)) + 1
	_wave_position_samples += 1

func _compute_position_entropy() -> float:
	if _wave_position_samples <= 0 or _wave_position_bins.is_empty():
		return 0.0
	var total := float(_wave_position_samples)
	var entropy := 0.0
	for c in _wave_position_bins.values():
		var p := float(c) / total
		if p > 0.0001:
			entropy -= p * (log(p) / log(2.0))
	var max_entropy := maxf(1.0, log(float(maxi(2, _wave_position_bins.size()))) / log(2.0))
	return clampf(entropy / max_entropy, 0.0, 1.0)

func _evaluate_threat_director() -> void:
	if not _wave_active:
		return
	var elapsed := maxf(1.0, _wave_elapsed)
	var dps := _wave_damage_dealt / elapsed
	var intake := _wave_damage_taken / elapsed
	var entropy := _compute_position_entropy()
	var kills_now := maxi(1, _wave_kill_times.size())
	var hazard_eff := float(_wave_hazard_kills) / float(kills_now)
	var dps_norm := clampf(dps / (42.0 + float(wave) * 2.4), 0.0, 1.8)
	var intake_norm := clampf(intake / (16.0 + float(wave) * 0.9), 0.0, 1.8)
	var hazard_norm := clampf(hazard_eff / 0.32, 0.0, 1.5)
	var raw := 0.46 * dps_norm + 0.20 * entropy + 0.20 * hazard_norm - 0.24 * intake_norm
	var target_level := clampf(0.5 + (raw - 0.35) * 0.95, 0.0, 1.0)
	_director_level = lerpf(_director_level, target_level, 0.38)
	_run_director_peak = maxf(_run_director_peak, _director_level)
	_director_spawn_mul = lerpf(0.82, 1.62, _director_level)
	_director_directive_mul = lerpf(0.86, 1.75, _director_level)
	_director_elite_bonus = lerpf(-0.02, 0.18, _director_level)
	_directive_interval = clampf(8.6 / _director_directive_mul, 4.2, 11.5)
	if _director_hint_cd <= 0.0:
		if _director_level >= 0.78:
			_show_message(tr("msg_director_rise"))
			_director_hint_cd = 13.0
		elif _director_level <= 0.24:
			_show_message(tr("msg_director_fall"))
			_director_hint_cd = 13.0

func _is_kill_near_active_hazard(pos: Vector2) -> bool:
	for hz in hazard_root.get_children():
		if not (hz is Node2D):
			continue
		if hz.has_method("is_hazard_active") and not bool(hz.is_hazard_active()):
			continue
		if (hz as Node2D).global_position.distance_to(pos) <= 126.0:
			return true
	return false

func _on_player_damage_dealt(amount: float) -> void:
	if not _wave_active:
		return
	_wave_damage_dealt += maxf(0.0, amount)

func _reset_wave_telemetry() -> void:
	_wave_damage_dealt = 0.0
	_wave_damage_taken = 0.0
	_wave_hazard_kills = 0
	_wave_directive_count = 0
	_wave_position_bins.clear()
	_wave_position_samples = 0
	_wave_kill_times.clear()
	_pos_sample_left = 0.0
	_last_hp = float(player.hp)
	_last_sp = float(player.sp)

func _commit_wave_telemetry() -> void:
	_run_hazard_kills_total += _wave_hazard_kills
	var telemetry := {
		"wave": wave,
		"clear_time": _wave_elapsed,
		"kill_time_distribution": _wave_kill_times.duplicate(),
		"hazard_deaths": _wave_hazard_kills,
		"directive_trigger_outcome": {
			"count": _wave_directive_count,
			"director_level": _director_level,
			"directive_mul": _director_directive_mul
		},
		"damage_source_breakdown": {
			"player_total": _wave_damage_dealt,
			"intake_total": _wave_damage_taken
		},
		"position_entropy": _compute_position_entropy(),
		"hazard_efficiency": float(_wave_hazard_kills) / float(maxi(1, _wave_kill_times.size())),
		"card_pick_order": _card_pick_order.duplicate(),
		"archetype_meter_trajectory": _archetype_trace.duplicate(true)
	}
	_wave_telemetry_history.append(telemetry)
	if _wave_telemetry_history.size() > 24:
		_wave_telemetry_history.pop_front()

## Walls are sumi ink; each terrain theme only tints the ink slightly (frost indigo, void murasaki, storm ochre).
## Walls are pale ink (dan-mo), so the fight itself carries the darkest ink on the page.
func _theme_wall_color(theme: int) -> Color:
	var ink := Ink.SUMI
	match theme:
		1:
			ink = Ink.SUMI.lerp(Ink.INDIGO, 0.45)
		2:
			ink = Ink.SUMI.lerp(Ink.MURASAKI, 0.35)
		3:
			ink = Ink.SUMI.lerp(Ink.ROKUSHO, 0.3)
	return ink.lerp(WALL_WASH, WALL_PALE_INK)

func _set_hazards_active(active: bool) -> void:
	for hz in hazard_root.get_children():
		if hz.has_method("set_gameplay_active"):
			hz.set_gameplay_active(active)

func _create_world_block(rect: Rect2, color: Color, parent: Node2D, with_collision: bool = true) -> void:
	var n = Node2D.new()
	n.position = rect.position
	parent.add_child(n)
	if with_collision:
		var b = StaticBody2D.new()
		b.add_to_group("world")
		n.add_child(b)
		var cs = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = rect.size
		cs.shape = shape
		cs.position = rect.size * 0.5
		b.add_child(cs)
	n.add_child(_brush_block(rect.size, color))

## A wall printed as one brush stroke (long blocks) or a square daub (short ones); the ragged
## ink slightly overhangs the collision rect, like a stroke laid over a pencilled box.
func _brush_block(size: Vector2, color: Color) -> Polygon2D:
	var horizontal := size.x >= size.y
	var aspect := maxf(size.x, size.y) / maxf(1.0, minf(size.x, size.y))
	var is_stroke := aspect >= STROKE_MIN_ASPECT
	_wall_brush_index += 1
	var tex: Texture2D = WALL_STROKES[_wall_brush_index % WALL_STROKES.size()] if is_stroke else WALL_DAUBS[_wall_brush_index % WALL_DAUBS.size()]
	# The brush covers ~60% of its texture across the stroke; a small overhang keeps the ink lean.
	var grow := size * Vector2(0.06, 0.18)
	if is_stroke:
		grow = Vector2(size.x * 0.03, size.y * 0.18) if horizontal else Vector2(size.x * 0.18, size.y * 0.03)
	var r := Rect2(-grow, size + grow * 2.0)
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	var ts := tex.get_size()
	if horizontal or not is_stroke:
		poly.uv = PackedVector2Array([Vector2.ZERO, Vector2(ts.x, 0.0), ts, Vector2(0.0, ts.y)])
	else:
		# Vertical stroke: the brush travels top to bottom.
		poly.uv = PackedVector2Array([Vector2.ZERO, Vector2(0.0, ts.y), ts, Vector2(ts.x, 0.0)])
	poly.texture = tex
	poly.color = color
	return poly

func _random_spawn() -> Vector2:
	if spawn_root.get_child_count() == 0:
		return Vector2.ZERO
	var idx: int = _rng.randi_range(0, spawn_root.get_child_count() - 1)
	var m = spawn_root.get_child(idx) as Marker2D
	return m.global_position

func _clamp_to_arena(p: Vector2) -> Vector2:
	return Vector2(
		clampf(p.x, ARENA_RECT.position.x + 16.0, ARENA_RECT.end.x - 16.0),
		clampf(p.y, ARENA_RECT.position.y + 16.0, ARENA_RECT.end.y - 16.0)
	)

func _alive_enemies() -> int:
	return enemy_root.get_child_count()

func _sanitize_enemies() -> void:
	for n in enemy_root.get_children():
		if n is Node2D:
			var e = n as Node2D
			if not ARENA_RECT.has_point(e.global_position):
				e.global_position = _clamp_to_arena(e.global_position)
			if player != null and e.global_position.distance_to(player.global_position) > 2400.0:
				e.global_position = _clamp_to_arena(_random_spawn())

func _on_player_stats_changed(hp: float, max_hp: float, sp: float, max_sp: float, bullet_mode: String, dash_cd: float, shield_on: bool) -> void:
	if _wave_active:
		var hp_loss := maxf(0.0, _last_hp - hp)
		var sp_loss := maxf(0.0, _last_sp - sp)
		_wave_damage_taken += hp_loss + sp_loss * (0.40 if shield_on else 0.18)
	_last_hp = hp
	_last_sp = sp
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	sp_bar.max_value = max_sp
	sp_bar.value = sp
	hp_text.text = "%.0f" % hp
	sp_text.text = "%.0f" % sp
	# Only the bullet name: the shield already shows as the indigo ring around the mage.
	mode_text.text = bullet_mode
	# Dash readiness is only worth ink while it is recharging.
	cooldown_text.text = tr("ui_cd_line") % [dash_cd] if dash_cd > 0.05 else ""

func _show_message(text: String) -> void:
	msg_label.text = text
	msg_box.visible = text != ""
	msg_box.reset_size()
	var hold := clampf(float(text.length()) * MESSAGE_SECONDS_PER_CHAR, MESSAGE_MIN_SECONDS, MESSAGE_MAX_SECONDS)
	var t: SceneTreeTimer = get_tree().create_timer(hold)
	t.timeout.connect(func() -> void:
		if msg_label.text == text:
			msg_label.text = ""
			msg_box.visible = false
		)

func _faction_name(id: int) -> String:
	match id:
		0:
			return tr("faction_legion")
		1:
			return tr("faction_arcane")
		2:
			return tr("faction_void")
		3:
			return tr("faction_storm")
	return tr("faction_unknown")

func _role_name(id: int) -> String:
	match id:
		0:
			return tr("role_frontline")
		1:
			return tr("role_skirmisher")
		2:
			return tr("role_support")
		3:
			return tr("role_controller")
		4:
			return tr("role_siege")
	return tr("role_unknown")

func _build_ecology_summary(queue: Array[int]) -> String:
	var faction_counts: Dictionary = {}
	var role_counts: Dictionary = {}
	for kind in queue:
		var k: int = int(kind)
		var fac: int = int(ENEMY_FACTION.get(k, 0))
		var role: int = int(ENEMY_ROLE.get(k, 0))
		faction_counts[fac] = int(faction_counts.get(fac, 0)) + 1
		role_counts[role] = int(role_counts.get(role, 0)) + 1
	var top_faction: Array[int] = _pick_top_two_ids(faction_counts)
	var top_role: Array[int] = _pick_top_two_ids(role_counts)
	var fac_text := ""
	for i in top_faction.size():
		var id: int = int(top_faction[i])
		var c: int = int(faction_counts.get(id, 0))
		if i > 0:
			fac_text += ", "
		fac_text += "%s(%d)" % [_faction_name(id), c]
	var role_text := ""
	for i in top_role.size():
		var id: int = int(top_role[i])
		var c: int = int(role_counts.get(id, 0))
		if i > 0:
			role_text += ", "
		role_text += "%s(%d)" % [_role_name(id), c]
	if fac_text == "":
		fac_text = tr("ecology_none")
	if role_text == "":
		role_text = tr("ecology_none")
	return "%s | %s" % [fac_text, role_text]

func _pick_top_two_ids(counts: Dictionary) -> Array[int]:
	var best_id := -1
	var best_count := -1
	var second_id := -1
	var second_count := -1
	for key in counts.keys():
		var id: int = int(key)
		var c: int = int(counts[key])
		if c > best_count:
			second_id = best_id
			second_count = best_count
			best_id = id
			best_count = c
		elif c > second_count:
			second_id = id
			second_count = c
	var out: Array[int] = []
	if best_id >= 0:
		out.append(best_id)
	if second_id >= 0:
		out.append(second_id)
	return out

func _try_assign_wave_anchor() -> void:
	if _anchor_active or wave < 4:
		return
	if _alive_enemies() < 6:
		return
	var faction_counts: Dictionary = {}
	for n in enemy_root.get_children():
		if not n.has_method("get_faction"):
			continue
		var f: int = int(n.get_faction())
		faction_counts[f] = int(faction_counts.get(f, 0)) + 1
	var top_faction := -1
	var top_count := 0
	for key in faction_counts.keys():
		var id: int = int(key)
		var c: int = int(faction_counts[key])
		if c > top_count:
			top_count = c
			top_faction = id
	if top_faction < 0 or top_count < 3:
		return
	var candidates: Array[Node] = []
	for n in enemy_root.get_children():
		if not n.has_method("get_faction"):
			continue
		if int(n.get_faction()) != top_faction:
			continue
		candidates.append(n)
	if candidates.is_empty():
		return
	var pick: Node = candidates[_rng.randi_range(0, candidates.size() - 1)]
	_set_wave_anchor(pick, top_faction)

func _set_wave_anchor(enemy: Node, faction: int) -> void:
	if enemy == null:
		return
	_anchor_enemy = enemy
	_anchor_faction = faction
	_anchor_active = true
	if enemy.has_method("set_anchor"):
		enemy.set_anchor(true)
	if enemy.has_method("apply_elite_mod"):
		var anchor_mul := float(_run_relic_pack.get("anchor_buff_mul", 1.0))
		enemy.apply_elite_mod({
			"name": "Anchor",
			"hp_mul": 1.28 * anchor_mul,
			"dmg_mul": 1.0,
			"speed_mul": 1.0 + (anchor_mul - 1.0) * 0.35,
			"color": Color(1.0, 0.90, 0.35, 1.0)
		})
	_show_message(tr("msg_anchor_spawn") % _faction_name(faction))

func _break_faction_links(faction: int, duration: float) -> void:
	var hit := 0
	for n in enemy_root.get_children():
		if not n.has_method("get_faction"):
			continue
		if int(n.get_faction()) != faction:
			continue
		if n.has_method("apply_faction_break"):
			n.apply_faction_break(duration)
			hit += 1
	if hit > 0:
		_run_anchor_breaks += 1
		_show_message(tr("msg_anchor_break") % [_faction_name(faction), duration])

func _archetype_meter_summary() -> String:
	var blade := int(round(float(_archetype_meter["blade"])))
	var ballistic := int(round(float(_archetype_meter["ballistic"])))
	var arcane := int(round(float(_archetype_meter["arcane"])))
	var tactical := int(round(float(_archetype_meter["tactical"])))
	return "%s:%d %s:%d %s:%d %s:%d" % [
		tr("archetype_blade_short"), blade,
		tr("archetype_ballistic_short"), ballistic,
		tr("archetype_arcane_short"), arcane,
		tr("archetype_tactical_short"), tactical
	]

func _socket_summary() -> String:
	if player == null:
		return tr("ui_socket_fmt") % [0, 0, 0, 0]
	var bu := 0
	var bs := 0
	var su := 0
	var ss := 0
	if player.has_method("get_socket_used"):
		bu = int(player.get_socket_used("bullet"))
		su = int(player.get_socket_used("spell"))
	if player.has_method("get_socket_slots"):
		bs = int(player.get_socket_slots("bullet"))
		ss = int(player.get_socket_slots("spell"))
	return tr("ui_socket_fmt") % [bu, bs, su, ss]

func _update_ui() -> void:
	wave_label.text = str(wave)
	score_label.text = str(_score)
	if _wave_preview:
		timer_label.text = tr("ui_preview_timer") % maxf(0.0, _preview_left)
	elif _wave_active:
		# In combat the ledger stays quiet: only an active objective is written under the seal.
		timer_label.text = ""
		if _objective_active:
			if _objective_type == "pylon_capture":
				var pct := int(clampf(_objective_progress / 3.5, 0.0, 1.0) * 100.0)
				timer_label.text += " | " + (tr("ui_objective_pylon") % [pct, maxf(0.0, _objective_left)])
			elif _objective_type == "rift_seal":
				var total := maxi(1, _objective_nodes.size())
				var done := int(_objective_progress)
				timer_label.text += " | " + (tr("ui_objective_rift") % [done, total, maxf(0.0, _objective_left)])
			elif _objective_type == "convoy_fracture":
				var total_convoy := maxi(1, _objective_nodes.size())
				var done_convoy := int(_objective_progress)
				timer_label.text += " | " + (tr("ui_objective_convoy") % [done_convoy, total_convoy, maxf(0.0, _objective_left)])
	else:
		timer_label.text = tr("ui_next_wave") % maxf(0.0, _intermission_left)
	timer_label.text = timer_label.text.trim_prefix(" | ")
	threat_bar.value = clampf(_director_level, 0.0, 1.0) * 100.0
	threat_bar.tint_progress = Ink.SUMI.lerp(Ink.VERMILION, clampf(_director_level, 0.0, 1.0))
	affliction_label.visible = _active_affliction != ""
	if affliction_label.visible:
		affliction_label.text = tr("ui_affliction_line") % _affliction_summary()
	if pause_shade.visible:
		_refresh_pause_page()

func _refresh_pause_page() -> void:
	pause_stats.text = "\n".join([
		tr("ui_score") % _score,
		tr("ui_kills") % _kills,
		tr("ui_enemies") % _alive_enemies(),
		tr("ui_mul") % _wave_multiplier(),
		tr("ui_threat_line") % int(round(_director_level * 100.0)),
	])
	pause_build.text = _build_summary()

## The run's build, shown on the pause page (schools, sockets, relic, affliction).
func _build_summary() -> String:
	return "\n".join([
		tr("ui_archetype_line") % _archetype_meter_summary(),
		tr("ui_socket_line") % _socket_summary(),
		tr("ui_relic_line") % _relic_summary(),
		tr("ui_affliction_line") % _affliction_summary(),
	])

func _on_enemy_died(score_value: int, enemy: Node = null) -> void:
	_kills += 1
	var gained: int = int(round(float(score_value) * _wave_multiplier()))
	_score += maxi(1, gained)
	if _wave_active:
		_wave_kill_times.append(_wave_elapsed)
		if enemy is Node2D and _is_kill_near_active_hazard((enemy as Node2D).global_position):
			_wave_hazard_kills += 1
	if enemy != null and enemy == _anchor_enemy:
		var faction: int = _anchor_faction
		_anchor_enemy = null
		_anchor_faction = -1
		_anchor_active = false
		if faction >= 0:
			_break_faction_links(faction, 8.0 + float(wave) * 0.25)

func _wave_multiplier() -> float:
	return 1.0 + float(maxi(1, wave) - 1) * 0.15

func _unhandled_input(event: InputEvent) -> void:
	if _game_over:
		return
	if event.is_action_pressed("ui_cancel"):
		if card_shade.visible:
			return
		_toggle_pause()
		get_viewport().set_input_as_handled()

func _toggle_pause() -> void:
	if _game_over:
		return
	var next_paused: bool = not get_tree().paused
	get_tree().paused = next_paused
	pause_shade.visible = next_paused
	_refresh_pause_page()

func _apply_pause_locale() -> void:
	pause_title.text = tr("menu_pause")
	pause_resume.text = tr("menu_resume")
	pause_restart.text = tr("menu_restart")
	pause_mainmenu.text = tr("menu_mainmenu")
	pause_quit.text = tr("menu_quit")
	pause_quit.visible = not OS.has_feature("web")

func _on_pause_resume() -> void:
	get_tree().paused = false
	pause_shade.visible = false

func _on_pause_restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_pause_mainmenu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_pause_quit() -> void:
	get_tree().quit()

func _on_player_died() -> void:
	if _game_over:
		return
	_game_over = true
	_wave_active = false
	_wave_preview = false
	_commit_wave_telemetry()
	_cleanup_objective_state()
	_spawn_queue.clear()
	card_shade.visible = false
	pause_shade.visible = false
	var bank = 0
	var best = _score
	var unlocked_relics: Array[String] = []
	var run_report := {
		"wave_reached": wave,
		"director_peak": _run_director_peak,
		"objective_success": _run_objective_success,
		"anchor_breaks": _run_anchor_breaks,
		"hazard_kills": _run_hazard_kills_total,
		"affliction_waves": _run_affliction_wave_count
	}
	if ProgressionManager != null:
		if ProgressionManager.has_method("register_run_report"):
			unlocked_relics = ProgressionManager.register_run_report(run_report)
		ProgressionManager.add_run_score(_score)
		bank = ProgressionManager.score_bank
		best = ProgressionManager.best_run_score
	game_over_title.text = tr("gameover_title")
	game_over_score_caption.text = tr("gameover_score_caption")
	game_over_score.text = str(_score)
	game_over_bank.text = tr("gameover_bank") % bank
	if not unlocked_relics.is_empty():
		var names: Array[String] = []
		for relic_id in unlocked_relics:
			names.append(tr("relic_" + relic_id + "_t"))
		game_over_bank.text += "\n" + (tr("msg_relic_unlock") % ", ".join(names))
	game_over_best.text = tr("gameover_best") % best
	game_over_restart.text = tr("menu_restart")
	game_over_mainmenu.text = tr("menu_mainmenu")
	game_over_shade.visible = true
	hud.visible = false
	get_tree().paused = true

func _on_game_over_restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_game_over_mainmenu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
