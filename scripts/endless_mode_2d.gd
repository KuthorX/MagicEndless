extends Node2D
@export var enemy_scene: PackedScene
@export var projectile_scene: PackedScene
@export var enemy_projectile_scene: PackedScene
@export var sword_scene: PackedScene
@export var grenade_scene: PackedScene
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
	"grenade_throw": preload("res://assets/audio/sfx_grenade_throw.wav"),
	"grenade_explode": preload("res://assets/audio/sfx_grenade_explode.wav"),
	"shield_on": preload("res://assets/audio/sfx_shield_on.wav"),
	"shield_off": preload("res://assets/audio/sfx_shield_off.wav"),
	"card_pick": preload("res://assets/audio/sfx_card_pick.wav"),
	"wave_start": preload("res://assets/audio/sfx_wave_start.wav"),
	"wave_clear": preload("res://assets/audio/sfx_wave_clear.wav"),
	"enemy_shoot": preload("res://assets/audio/sfx_enemy_shoot.wav")
}

const INTERMISSION_SECONDS := 5.0
const PREVIEW_SECONDS := 3.0
const PREVIEW_ENEMY_COUNT := 8
const BASE_SPAWN_INTERVAL := 0.35
const MINI_BOSS_INTERVAL := 5

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
	"common": Color(0.92, 0.92, 0.92, 1.0),
	"rare": Color(0.42, 0.82, 1.0, 1.0),
	"epic": Color(0.94, 0.62, 1.0, 1.0)
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
	{"title":"card_hex_t", "desc":"card_hex_d", "rarity":"common", "effect":{"grenade_damage_add": 16}},
	{"title":"card_frag_t", "desc":"card_frag_d", "rarity":"rare", "effect":{"grenade_radius_add": 20.0}},
	{"title":"card_fuse_t", "desc":"card_fuse_d", "rarity":"rare", "effect":{"grenade_cd_mul": 0.85}},
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
	{"title":"card_shot_style_rail_t", "desc":"card_shot_style_rail_d", "rarity":"epic", "effect":{"shot_style_rail": true}}
]

var wave = 0
var _wave_active = false
var _wave_preview = false
var _preview_left = 0.0
var _intermission_left = INTERMISSION_SECONDS
var _spawn_timer = 0.0
var _spawn_queue: Array[int] = []
var _card_choices: Array[Dictionary] = []
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
var _preview_ecology_summary := ""
var _anchor_enemy: Node = null
var _anchor_faction := -1
var _anchor_active := false
const ARENA_RECT := Rect2(-790.0, -430.0, 1580.0, 860.0)
var _boss_spawned_this_wave = false
var _score = 0
var _kills = 0
var _game_over = false

@onready var terrain_root: Node2D = $World/Terrain
@onready var dynamic_root: Node2D = $World/Dynamic
@onready var hazard_root: Node2D = $World/Hazards
@onready var enemy_root: Node2D = $World/Enemies
@onready var spawn_root: Node2D = $World/Spawns
@onready var player = $World/Player

@onready var wave_label: Label = $HUD/WaveLabel
@onready var status_label: Label = $HUD/StatusLabel
@onready var alive_label: Label = $HUD/AliveLabel
@onready var timer_label: Label = $HUD/TimerLabel
@onready var score_label: Label = $HUD/ScoreLabel
@onready var kills_label: Label = $HUD/KillsLabel
@onready var mul_label: Label = $HUD/MulLabel
@onready var hp_bar: ProgressBar = $HUD/Vitals/HPBar
@onready var sp_bar: ProgressBar = $HUD/Vitals/SPBar
@onready var hp_text: Label = $HUD/Vitals/HPLabel
@onready var sp_text: Label = $HUD/Vitals/SPLabel
@onready var mode_text: Label = $HUD/Vitals/ModeLabel
@onready var cooldown_text: Label = $HUD/Vitals/CooldownLabel
@onready var msg_label: Label = $HUD/Message

@onready var card_shade: ColorRect = $CardUI/Shade
@onready var card_panel: Panel = $CardUI/Shade/Center/Panel
@onready var card_vbox: VBoxContainer = $CardUI/Shade/Center/Panel/VBox
@onready var card_a: Button = $CardUI/Shade/Center/Panel/VBox/CardA
@onready var card_b: Button = $CardUI/Shade/Center/Panel/VBox/CardB
@onready var card_c: Button = $CardUI/Shade/Center/Panel/VBox/CardC
@onready var pause_shade: ColorRect = $PauseUI/Shade
@onready var pause_title: Label = $PauseUI/Shade/Center/Panel/VBox/Title
@onready var pause_resume: Button = $PauseUI/Shade/Center/Panel/VBox/ResumeButton
@onready var pause_restart: Button = $PauseUI/Shade/Center/Panel/VBox/RestartButton
@onready var pause_mainmenu: Button = $PauseUI/Shade/Center/Panel/VBox/MainMenuButton
@onready var pause_quit: Button = $PauseUI/Shade/Center/Panel/VBox/QuitButton
@onready var game_over_shade: ColorRect = $GameOverUI/Shade
@onready var game_over_title: Label = $GameOverUI/Shade/Center/Panel/VBox/Title
@onready var game_over_score: Label = $GameOverUI/Shade/Center/Panel/VBox/ScoreLabel
@onready var game_over_bank: Label = $GameOverUI/Shade/Center/Panel/VBox/BankLabel
@onready var game_over_best: Label = $GameOverUI/Shade/Center/Panel/VBox/BestLabel
@onready var game_over_restart: Button = $GameOverUI/Shade/Center/Panel/VBox/RestartButton
@onready var game_over_mainmenu: Button = $GameOverUI/Shade/Center/Panel/VBox/MainMenuButton

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
	player.sword_scene = sword_scene
	player.projectile_scene = projectile_scene
	player.grenade_scene = grenade_scene
	if ProgressionManager != null:
		player.apply_meta_progression(ProgressionManager.get_player_meta())
	player.stats_changed.connect(_on_player_stats_changed)
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
	_show_message(Loc.t("msg_controls"))
	_set_intermission(INTERMISSION_SECONDS)
	_update_ui()

func _process(delta: float) -> void:
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
		_objective_trigger_left -= delta
		_spawn_timer -= delta
		if _spawn_timer <= 0.0 and _spawn_queue.size() > 0:
			_spawn_timer = maxf(0.12, BASE_SPAWN_INTERVAL - wave * 0.005)
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
		_sanitize_enemies()
		if _spawn_queue.is_empty() and _alive_enemies() == 0:
			_on_wave_clear()
	else:
		_intermission_left -= delta
		if _intermission_left <= 0.0:
			_begin_wave_preview()
	_update_ui()

func play_sfx(name: String) -> void:
	if not SFX.has(name):
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
	_show_message(Loc.t("msg_control_zone"))
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
	_objective_nodes.clear()
	if _rng.randf() < 0.56:
		_objective_type = "pylon_capture"
		_objective_left = 11.0 + minf(4.0, float(wave) * 0.15)
		_objective_pos = _clamp_to_arena(_random_spawn() + Vector2(_rng.randf_range(-80.0, 80.0), _rng.randf_range(-70.0, 70.0)))
		var marker := _spawn_objective_marker(_objective_pos, Color(1.0, 0.90, 0.35, 0.88), 96.0)
		_objective_nodes.append(marker)
		_spawn_ground_warning(_objective_pos, 105.0, Color(1.0, 0.90, 0.35, 0.88), 1.0)
		_show_message("波中目标：占领充能塔（站圈累计进度）")
	else:
		_objective_type = "rift_seal"
		_objective_left = 13.0 + minf(4.0, float(wave) * 0.18)
		for i in 2:
			var p := _clamp_to_arena(_random_spawn() + Vector2(_rng.randf_range(-92.0, 92.0), _rng.randf_range(-84.0, 84.0)))
			var marker := _spawn_objective_marker(p, Color(0.90, 0.40, 1.0, 0.90), 78.0)
			marker.set_meta("seal", 0.0)
			marker.set_meta("sealed", false)
			_objective_nodes.append(marker)
			_spawn_ground_warning(p, 84.0, Color(0.90, 0.40, 1.0, 0.85), 0.9)
		_show_message("波中目标：封印裂隙（接触裂隙累计进度）")

func _update_wave_objective(delta: float) -> void:
	if not _objective_active:
		return
	_objective_left -= delta
	_update_objective_visuals(delta)
	if _objective_type == "pylon_capture":
		_update_objective_pylon(delta)
	elif _objective_type == "rift_seal":
		_update_objective_rift(delta)
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

func _complete_wave_objective() -> void:
	if not _objective_active:
		return
	if _objective_type == "pylon_capture":
		var trim := mini(_spawn_queue.size(), 4 + int(wave * 0.22))
		for i in trim:
			if not _spawn_queue.is_empty():
				_spawn_queue.pop_back()
		_directive_left += 2.4
		player.heal(10.0 + float(wave) * 0.3)
		player.restore_sp(14.0 + float(wave) * 0.35)
		_show_message("目标完成：充能塔稳定，敌方节奏被打断")
	else:
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
		_show_message("目标完成：裂隙封印，场地压力下降")
	_cleanup_objective_state()

func _fail_wave_objective() -> void:
	if not _objective_active:
		return
	if _objective_type == "pylon_capture":
		_show_message("目标失败：充能塔过载，触发惩罚弹幕")
		_spawn_radial_volley(_objective_pos, 12 + int(wave * 0.06), _rng.randf() * TAU)
		for i in range(3 + int(wave * 0.08)):
			_spawn_queue.append(2 if i % 2 == 0 else 8)
	else:
		_show_message("目标失败：裂隙失控，虚空增援抵达")
		for n in _objective_nodes:
			if is_instance_valid(n):
				request_void_zone(n.global_position, wave + 1)
		for i in range(4 + int(wave * 0.10)):
			_spawn_queue.append(6 if i % 2 == 0 else 7)
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

func _spawn_ground_warning(pos: Vector2, radius: float, color: Color, duration: float) -> void:
	var warn = TelegraphDecal2D.new()
	warn.global_position = _clamp_to_arena(pos)
	warn.radius = radius
	warn.base_color = color
	warn.duration = duration
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
		title_label.text = Loc.t("ui_card_title")
	card_a.text = Loc.t("ui_card_a")
	card_b.text = Loc.t("ui_card_b")
	card_c.text = Loc.t("ui_card_c")

func _setup_actions() -> void:
	_set_key("move_forward", KEY_W)
	_set_key("move_back", KEY_S)
	_set_key("move_left", KEY_A)
	_set_key("move_right", KEY_D)
	_set_key("dash", KEY_SHIFT)
	_set_key("throw_grenade", KEY_E)
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
	_create_world_block(Rect2(-860, -500, 1720, 32), Color(0.12, 0.16, 0.21), terrain_root)
	_create_world_block(Rect2(-860, 468, 1720, 32), Color(0.12, 0.16, 0.21), terrain_root)
	_create_world_block(Rect2(-860, -500, 32, 1000), Color(0.12, 0.16, 0.21), terrain_root)
	_create_world_block(Rect2(828, -500, 32, 1000), Color(0.12, 0.16, 0.21), terrain_root)
	_create_world_block(Rect2(-828, -468, 1656, 936), Color(0.16, 0.20, 0.25), terrain_root, false)

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
	_boss_spawned_this_wave = false
	_wave_preview = true
	_wave_active = false
	_preview_left = PREVIEW_SECONDS
	_mutate_terrain()
	_build_spawn_queue()
	_preview_ecology_summary = _build_ecology_summary(_spawn_queue)
	_set_hazards_active(false)
	_spawn_preview_enemies()
	var theme_name = Loc.t(str(TERRAIN_THEME_LABEL.get(_terrain_theme, "terrain_theme_ruins")))
	var mutator_name = Loc.t(str(_wave_mutator.get("label", "mutator_none")))
	var headline := Loc.t("msg_wave_preview_theme") % [wave, PREVIEW_SECONDS, theme_name, mutator_name]
	_show_message("%s\n敌群生态：%s" % [headline, _preview_ecology_summary])

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
	_spawn_timer = 0.2
	_directive_left = 4.4
	_set_hazards_active(true)
	for e in _preview_enemies:
		if is_instance_valid(e) and e.has_method("set_active"):
			e.set_active(true)
	_preview_enemies.clear()
	_try_assign_wave_anchor()
	_objective_trigger_left = 6.6 + _rng.randf_range(0.0, 2.5)
	_spawn_miniboss_if_needed()
	_show_message(Loc.t("msg_wave_start") % wave)
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
	if _rng.randf() > clampf(0.08 + wave * 0.012, 0.0, 0.45):
		return
	_apply_elite_combo(enemy, false)

func _apply_elite_combo(enemy: Node, force_double: bool) -> void:
	if not enemy.has_method("apply_elite_mod"):
		return
	var first_idx: int = _rng.randi_range(0, ELITE_MODS.size() - 1)
	var first: Dictionary = ELITE_MODS[first_idx]
	enemy.apply_elite_mod(first)
	var do_double: bool = force_double or (wave >= 8 and _rng.randf() < clampf(0.08 + wave * 0.01, 0.0, 0.55))
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
	_show_message(Loc.t("msg_miniboss") % wave)

func _on_wave_clear() -> void:
	_wave_active = false
	_cleanup_objective_state()
	player.heal(20.0)
	player.restore_sp(25.0)
	_show_message(Loc.t("msg_wave_clear") % wave)
	play_sfx("wave_clear")
	_show_cards()

func _show_cards() -> void:
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
	if index < 0 or index >= _card_choices.size():
		return
	var card: Dictionary = _card_choices[index]
	player.apply_upgrade(card["effect"])
	_show_message(Loc.t("msg_card_pick") % Loc.t(str(card["title"])))
	play_sfx("card_pick")
	card_shade.visible = false
	_set_intermission(INTERMISSION_SECONDS)

func _set_intermission(sec: float) -> void:
	_intermission_left = sec
	_wave_active = false
	_wave_preview = false
	_cleanup_objective_state()
	_anchor_enemy = null
	_anchor_faction = -1
	_anchor_active = false

func _draw_cards(count: int) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for card in CARD_POOL:
		if _card_is_available(card):
			pool.append(card)
	if pool.size() < count:
		pool = CARD_POOL.duplicate(true)
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
	return true

func _update_card_button(btn: Button, card: Dictionary) -> void:
	var rarity: String = str(card.get("rarity", "common"))
	var rarity_text: String = Loc.t(str(RARITY_LABEL.get(rarity, "rarity_common")))
	btn.text = "[%s] %s\n%s" % [rarity_text, Loc.t(str(card["title"])), Loc.t(str(card["desc"]))]
	var c: Color = Color(RARITY_COLOR.get(rarity, Color(0.92, 0.92, 0.92, 1.0)))
	btn.add_theme_color_override("font_color", c)
	btn.add_theme_color_override("font_hover_color", c.lightened(0.1))
	btn.add_theme_color_override("font_pressed_color", c.darkened(0.1))

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
		_create_world_block(Rect2(x, y, w, h), Color(0.24, 0.29, 0.36), dynamic_root)

	var hazard_count: int = mini(10, 2 + int(wave / 2) + int(_wave_mutator.get("hazard_extra", 0)))
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
			hz.configure_for_wave(wave)

func _build_terrain_layout(terrain_type: int, theme: int) -> void:
	var wall_c = Color(0.22, 0.27, 0.34)
	match theme:
		1:
			wall_c = Color(0.22, 0.34, 0.44)
		2:
			wall_c = Color(0.30, 0.21, 0.36)
		3:
			wall_c = Color(0.32, 0.30, 0.20)
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
	_show_message(Loc.t("msg_directive_surge"))
	for i in range(3 + int(wave * 0.08)):
		var kind := 0 if i % 2 == 0 else 8
		_spawn_queue.append(kind)

func _directive_seismic_ring() -> void:
	if player == null:
		return
	var center := (player as Node2D).global_position
	_show_message(Loc.t("msg_directive_seismic"))
	_spawn_ground_warning(center, 132.0, Color(1.0, 0.48, 0.22, 0.82), 0.68)
	var timer := get_tree().create_timer(0.68)
	await timer.timeout
	_spawn_radial_volley(center, 14 + int(wave * 0.1), 0.0)

func _directive_hazard_flux() -> void:
	_show_message(Loc.t("msg_directive_flux"))
	for hz in hazard_root.get_children():
		if hz.has_method("set_hazard_kind"):
			hz.set_hazard_kind(_rng.randi_range(0, 3))
		if hz.has_method("configure_for_wave"):
			hz.configure_for_wave(wave + 1)
	if _rng.randf() < 0.6 and hazard_scene != null:
		var hz: Node = hazard_scene.instantiate()
		hazard_root.add_child(hz)
		if hz is Node2D:
			(hz as Node2D).global_position = Vector2(_rng.randf_range(-600.0, 600.0), _rng.randf_range(-320.0, 320.0))
		if hz.has_method("set_hazard_kind"):
			hz.set_hazard_kind(_rng.randi_range(0, 3))
		if hz.has_method("configure_for_wave"):
			hz.configure_for_wave(wave + 1)
		if hz.has_method("set_gameplay_active"):
			hz.set_gameplay_active(_wave_active)

func _directive_beacon_drop() -> void:
	_show_message(Loc.t("msg_directive_beacon"))
	var p := _clamp_to_arena(_random_spawn())
	_spawn_ground_warning(p, 86.0, Color(0.36, 1.0, 0.90, 0.84), 0.72)
	var timer := get_tree().create_timer(0.72)
	await timer.timeout
	var b := _spawn_enemy(7, true)
	if b is Node2D:
		(b as Node2D).global_position = p

func _directive_hellburst() -> void:
	if player == null:
		return
	var pos := (player as Node2D).global_position + Vector2(_rng.randf_range(-110.0, 110.0), _rng.randf_range(-80.0, 80.0))
	_show_message(Loc.t("msg_directive_hellburst"))
	await request_bullet_hell(_clamp_to_arena(pos))

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
	var poly = Polygon2D.new()
	poly.polygon = PackedVector2Array([Vector2.ZERO, Vector2(rect.size.x, 0.0), Vector2(rect.size.x, rect.size.y), Vector2(0.0, rect.size.y)])
	poly.color = color
	n.add_child(poly)

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

func _on_player_stats_changed(hp: float, max_hp: float, sp: float, max_sp: float, bullet_mode: String, dash_cd: float, grenade_cd: float, shield_on: bool) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	sp_bar.max_value = max_sp
	sp_bar.value = sp
	hp_text.text = "HP %.0f/%.0f" % [hp, max_hp]
	sp_text.text = "SP %.0f/%.0f" % [sp, max_sp]
	mode_text.text = Loc.t("ui_mode_line") % [bullet_mode, (Loc.t("ui_on") if shield_on else Loc.t("ui_off"))]
	cooldown_text.text = Loc.t("ui_cd_line") % [dash_cd, grenade_cd]

func _show_message(text: String) -> void:
	msg_label.text = text
	var t: SceneTreeTimer = get_tree().create_timer(1.8)
	t.timeout.connect(func() -> void:
		if msg_label.text == text:
			msg_label.text = ""
		)

func _faction_name(id: int) -> String:
	match id:
		0:
			return "Legion"
		1:
			return "Arcane"
		2:
			return "Void"
		3:
			return "Storm"
	return "Unknown"

func _role_name(id: int) -> String:
	match id:
		0:
			return "Frontline"
		1:
			return "Skirmisher"
		2:
			return "Support"
		3:
			return "Controller"
		4:
			return "Siege"
	return "Role?"

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
		fac_text = "None"
	if role_text == "":
		role_text = "None"
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
		enemy.apply_elite_mod({
			"name": "Anchor",
			"hp_mul": 1.28,
			"dmg_mul": 1.0,
			"speed_mul": 1.0,
			"color": Color(1.0, 0.90, 0.35, 1.0)
		})
	_show_message("指挥锚点出现：%s 阵营核心，击破可扰乱联结" % _faction_name(faction))

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
		_show_message("锚点击破：%s 联结失稳 %.1fs" % [_faction_name(faction), duration])

func _update_ui() -> void:
	wave_label.text = Loc.t("ui_wave") % wave
	alive_label.text = Loc.t("ui_enemies") % _alive_enemies()
	score_label.text = Loc.t("ui_score") % _score
	kills_label.text = Loc.t("ui_kills") % _kills
	mul_label.text = Loc.t("ui_mul") % _wave_multiplier()
	if _wave_preview:
		status_label.text = Loc.t("ui_status_preview")
		timer_label.text = Loc.t("ui_preview_timer") % maxf(0.0, _preview_left)
	elif _wave_active:
		status_label.text = Loc.t("ui_status_combat")
		timer_label.text = Loc.t("ui_spawn_left") % _spawn_queue.size()
		if _objective_active:
			if _objective_type == "pylon_capture":
				var pct := int(clampf(_objective_progress / 3.5, 0.0, 1.0) * 100.0)
				timer_label.text += " | 目标: 占领塔 %d%% %.1fs" % [pct, maxf(0.0, _objective_left)]
			elif _objective_type == "rift_seal":
				var total := maxi(1, _objective_nodes.size())
				var done := int(_objective_progress)
				timer_label.text += " | 目标: 封印裂隙 %d/%d %.1fs" % [done, total, maxf(0.0, _objective_left)]
	else:
		status_label.text = Loc.t("ui_status_intermission")
		timer_label.text = Loc.t("ui_next_wave") % maxf(0.0, _intermission_left)

func _on_enemy_died(score_value: int, enemy: Node = null) -> void:
	_kills += 1
	var gained: int = int(round(float(score_value) * _wave_multiplier()))
	_score += maxi(1, gained)
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

func _apply_pause_locale() -> void:
	pause_title.text = Loc.t("menu_pause")
	pause_resume.text = Loc.t("menu_resume")
	pause_restart.text = Loc.t("menu_restart")
	pause_mainmenu.text = Loc.t("menu_mainmenu")
	pause_quit.text = Loc.t("menu_quit")

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
	_cleanup_objective_state()
	_spawn_queue.clear()
	card_shade.visible = false
	pause_shade.visible = false
	var bank = 0
	var best = _score
	if ProgressionManager != null:
		ProgressionManager.add_run_score(_score)
		bank = ProgressionManager.score_bank
		best = ProgressionManager.best_run_score
	game_over_title.text = Loc.t("gameover_title")
	game_over_score.text = Loc.t("gameover_score") % _score
	game_over_bank.text = Loc.t("gameover_bank") % bank
	game_over_best.text = Loc.t("gameover_best") % best
	game_over_restart.text = Loc.t("menu_restart")
	game_over_mainmenu.text = Loc.t("menu_mainmenu")
	game_over_shade.visible = true
	get_tree().paused = true

func _on_game_over_restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_game_over_mainmenu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
