extends Node2D
const BATTLE_BGM := preload("res://assets/audio/battle_bgm.wav")

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
	4: "enemy_artillery"
}

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
	{"title":"card_blood_t", "desc":"card_blood_d", "rarity":"epic", "effect":{"lifesteal_add": 0.05}}
]

var wave := 0
var _wave_active := false
var _wave_preview := false
var _preview_left := 0.0
var _intermission_left := INTERMISSION_SECONDS
var _spawn_timer := 0.0
var _spawn_queue: Array[int] = []
var _card_choices: Array[Dictionary] = []
var _preview_enemies: Array[Node] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _terrain_seed := 0
const ARENA_RECT := Rect2(-790.0, -430.0, 1580.0, 860.0)
var _boss_spawned_this_wave := false
var _score := 0
var _kills := 0

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
@onready var local_bgm: AudioStreamPlayer = $LocalBgm

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	_setup_actions()
	_init_local_bgm()
	if AudioManager != null:
		AudioManager.play_battle()
	_build_static_arena()
	_setup_spawns()
	_apply_ui_locale()
	player.sword_scene = sword_scene
	player.projectile_scene = projectile_scene
	player.grenade_scene = grenade_scene
	player.stats_changed.connect(_on_player_stats_changed)
	player.message_sent.connect(_show_message)
	player.sfx_event.connect(play_sfx)
	card_a.pressed.connect(func() -> void: _pick_card(0))
	card_b.pressed.connect(func() -> void: _pick_card(1))
	card_c.pressed.connect(func() -> void: _pick_card(2))
	pause_resume.pressed.connect(_on_pause_resume)
	pause_restart.pressed.connect(_on_pause_restart)
	pause_mainmenu.pressed.connect(_on_pause_mainmenu)
	pause_quit.pressed.connect(_on_pause_quit)
	_apply_pause_locale()
	pause_shade.visible = false
	_show_message(Loc.t("msg_controls"))
	_set_intermission(INTERMISSION_SECONDS)
	_update_ui()

func _process(delta: float) -> void:
	if local_bgm != null and not local_bgm.playing:
		local_bgm.play()
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
		_spawn_timer -= delta
		if _spawn_timer <= 0.0 and _spawn_queue.size() > 0:
			_spawn_timer = maxf(0.12, BASE_SPAWN_INTERVAL - wave * 0.005)
			var enemy_kind: int = int(_spawn_queue.pop_back())
			_spawn_enemy(enemy_kind, true)
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
	var p := AudioStreamPlayer.new()
	p.stream = SFX[name]
	p.bus = "Master"
	p.volume_db = -6.0
	add_child(p)
	p.finished.connect(func() -> void: p.queue_free())
	p.play()

func request_elite_summon(pos: Vector2) -> void:
	if _alive_enemies() > 120:
		return
	var kind := _rng.randi_range(0, 4)
	var child: Node = _spawn_enemy(kind, true)
	if child is Node2D:
		var p := pos + Vector2(_rng.randf_range(-42.0, 42.0), _rng.randf_range(-42.0, 42.0))
		(child as Node2D).global_position = _clamp_to_arena(p)

func request_split_spawn(pos: Vector2) -> void:
	for i in 2:
		var child: Node = _spawn_enemy(0, true)
		if child is Node2D:
			var p := pos + Vector2(_rng.randf_range(-28.0, 28.0), _rng.randf_range(-28.0, 28.0))
			(child as Node2D).global_position = _clamp_to_arena(p)
			if child.has_method("apply_impulse"):
				child.apply_impulse(Vector2(_rng.randf_range(-200.0, 200.0), _rng.randf_range(-200.0, 200.0)))

func request_spawn_totem(pos: Vector2) -> void:
	if boss_totem_scene == null:
		return
	_spawn_ground_warning(pos, 74.0, Color(1.0, 0.70, 0.22, 0.85), 0.70)
	var delay := get_tree().create_timer(0.7)
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
	var delay := get_tree().create_timer(0.95)
	await delay.timeout
	_spawn_radial_volley(pos, 18, 0.0)
	var delay2 := get_tree().create_timer(0.45)
	await delay2.timeout
	_spawn_radial_volley(pos, 18, PI / 18.0)

func _spawn_ground_warning(pos: Vector2, radius: float, color: Color, duration: float) -> void:
	var warn := TelegraphDecal2D.new()
	warn.global_position = _clamp_to_arena(pos)
	warn.radius = radius
	warn.base_color = color
	warn.duration = duration
	dynamic_root.add_child(warn)

func _spawn_radial_volley(pos: Vector2, count: int, angle_offset: float) -> void:
	for i in count:
		var a: float = TAU * float(i) / float(count) + angle_offset
		var dir := Vector2(cos(a), sin(a))
		var b: Node = enemy_projectile_scene.instantiate()
		add_child(b)
		if b is Node2D:
			(b as Node2D).global_position = pos
		if b.has_method("setup"):
			b.setup(dir, 250.0, 11 + int(wave * 0.25), 4)

func _apply_ui_locale() -> void:
	var title_label := card_vbox.get_node("Title") as Label
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
	_set_mouse("attack_primary", MOUSE_BUTTON_LEFT)
	_set_mouse("shield", MOUSE_BUTTON_RIGHT)

func _set_key(action: StringName, code: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	InputMap.action_erase_events(action)
	var ev := InputEventKey.new()
	ev.physical_keycode = code
	InputMap.action_add_event(action, ev)

func _set_mouse(action: StringName, btn: MouseButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	InputMap.action_erase_events(action)
	var ev := InputEventMouseButton.new()
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
		var m := Marker2D.new()
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
	_set_hazards_active(false)
	_spawn_preview_enemies()
	_show_message(Loc.t("msg_wave_preview") % [wave, PREVIEW_SECONDS])

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
	_set_hazards_active(true)
	for e in _preview_enemies:
		if is_instance_valid(e) and e.has_method("set_active"):
			e.set_active(true)
	_preview_enemies.clear()
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
	_try_apply_elite(e)
	if e.has_signal("died"):
		e.connect("died", Callable(self, "_on_enemy_died"))
	if e.has_method("set_active"):
		e.set_active(active)
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
	var guard := 0
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
	var boss_kind: int = _rng.randi_range(2, 4)
	var boss: Node = _spawn_enemy(boss_kind, true)
	if boss == null:
		return
	if boss is Node2D:
		(boss as Node2D).scale = Vector2(1.5, 1.5)
	_apply_elite_combo(boss, true)
	if boss.has_method("apply_elite_mod"):
		boss.apply_elite_mod({"name":"MiniBoss", "hp_mul": 2.8, "dmg_mul": 1.35, "speed_mul": 0.95, "color": Color(1.0, 0.74, 0.18, 1.0)})
	_show_message("绗?%d 娉細灏廈oss鏉ヨ" % wave)

func _on_wave_clear() -> void:
	_wave_active = false
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

func _draw_cards(count: int) -> Array[Dictionary]:
	var pool: Array[Dictionary] = CARD_POOL.duplicate(true)
	pool.shuffle()
	var result: Array[Dictionary] = []
	for i in count:
		result.append(pool[i])
	return result

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

	var obstacle_count: int = 8 + int(wave / 2)
	for i in obstacle_count:
		var x := _rng.randf_range(-650.0, 650.0)
		var y := _rng.randf_range(-360.0, 360.0)
		var w := _rng.randf_range(50.0, 150.0)
		var h := _rng.randf_range(40.0, 120.0)
		_create_world_block(Rect2(x, y, w, h), Color(0.24, 0.29, 0.36), dynamic_root)

	var hazard_count: int = mini(8, 2 + int(wave / 2))
	for i in hazard_count:
		if hazard_scene == null:
			continue
		var hz: Node = hazard_scene.instantiate()
		hazard_root.add_child(hz)
		if hz is Node2D:
			(hz as Node2D).global_position = Vector2(_rng.randf_range(-610.0, 610.0), _rng.randf_range(-330.0, 330.0))
		if hz.has_method("configure_for_wave"):
			hz.configure_for_wave(wave)

func _set_hazards_active(active: bool) -> void:
	for hz in hazard_root.get_children():
		if hz.has_method("set_gameplay_active"):
			hz.set_gameplay_active(active)

func _create_world_block(rect: Rect2, color: Color, parent: Node2D, with_collision: bool = true) -> void:
	var n := Node2D.new()
	n.position = rect.position
	parent.add_child(n)
	if with_collision:
		var b := StaticBody2D.new()
		b.add_to_group("world")
		n.add_child(b)
		var cs := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = rect.size
		cs.shape = shape
		cs.position = rect.size * 0.5
		b.add_child(cs)
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([Vector2.ZERO, Vector2(rect.size.x, 0.0), Vector2(rect.size.x, rect.size.y), Vector2(0.0, rect.size.y)])
	poly.color = color
	n.add_child(poly)

func _random_spawn() -> Vector2:
	if spawn_root.get_child_count() == 0:
		return Vector2.ZERO
	var idx: int = _rng.randi_range(0, spawn_root.get_child_count() - 1)
	var m := spawn_root.get_child(idx) as Marker2D
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
			var e := n as Node2D
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
	else:
		status_label.text = Loc.t("ui_status_intermission")
		timer_label.text = Loc.t("ui_next_wave") % maxf(0.0, _intermission_left)

func _on_enemy_died(score_value: int) -> void:
	_kills += 1
	var gained: int = int(round(float(score_value) * _wave_multiplier()))
	_score += maxi(1, gained)

func _wave_multiplier() -> float:
	return 1.0 + float(maxi(1, wave) - 1) * 0.15

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if card_shade.visible:
			return
		_toggle_pause()
		get_viewport().set_input_as_handled()

func _toggle_pause() -> void:
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

func _init_local_bgm() -> void:
	if local_bgm == null:
		return
	if AudioServer.get_bus_count() > 0:
		AudioServer.set_bus_mute(0, false)
		AudioServer.set_bus_volume_db(0, 0.0)
	var stream: AudioStream = load("res://assets/audio/battle_bgm.wav") as AudioStream
	if stream == null:
		stream = BATTLE_BGM
	if stream is AudioStreamWAV:
		var wav := (stream as AudioStreamWAV).duplicate() as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream = wav
	local_bgm.stream = stream
	local_bgm.bus = "Master"
	local_bgm.volume_db = -3.0
	local_bgm.play()
