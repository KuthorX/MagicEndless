extends Node2D

@export var enemy_scene: PackedScene
@export var projectile_scene: PackedScene
@export var enemy_projectile_scene: PackedScene
@export var sword_scene: PackedScene
@export var grenade_scene: PackedScene
@export var hazard_scene: PackedScene

const INTERMISSION_SECONDS := 5.0
const PREVIEW_SECONDS := 3.0
const PREVIEW_ENEMY_COUNT := 8
const BASE_SPAWN_INTERVAL := 0.35

const ENEMY_TYPE_LABEL := {
	0: "Chaser",
	1: "Shooter",
	2: "Dasher"
}

const RARITY_LABEL := {
	"common": "Common",
	"rare": "Rare",
	"epic": "Epic"
}

const RARITY_COLOR := {
	"common": Color(0.92, 0.92, 0.92, 1.0),
	"rare": Color(0.42, 0.82, 1.0, 1.0),
	"epic": Color(0.94, 0.62, 1.0, 1.0)
}

const ELITE_MODS: Array[Dictionary] = [
	{"name": "Titan", "hp_mul": 1.7, "dmg_mul": 1.2, "speed_mul": 0.9, "color": Color(0.90, 0.72, 0.20, 1.0)},
	{"name": "Haste", "hp_mul": 1.1, "dmg_mul": 1.0, "speed_mul": 1.18, "color": Color(0.33, 0.95, 0.92, 1.0)},
	{"name": "Berserk", "hp_mul": 1.25, "dmg_mul": 1.42, "speed_mul": 1.08, "color": Color(0.97, 0.35, 0.35, 1.0)}
]

const CARD_POOL: Array[Dictionary] = [
	{"title":"Blade Temper", "desc":"Sword damage +12", "rarity":"common", "effect":{"sword_damage_add": 12}},
	{"title":"Wide Arc", "desc":"Sword radius +18", "rarity":"common", "effect":{"sword_radius_add": 18.0}},
	{"title":"Rapid Slash", "desc":"Sword interval -14%", "rarity":"rare", "effect":{"sword_cd_mul": 0.86}},
	{"title":"Spin Up", "desc":"Sword spin speed +22%", "rarity":"rare", "effect":{"sword_speed_mul": 1.22}},
	{"title":"Storm Blade", "desc":"Sword spin speed +35%", "rarity":"epic", "effect":{"sword_speed_mul": 1.35}},
	{"title":"Impact Core", "desc":"Bullet damage +8", "rarity":"common", "effect":{"shot_damage_add": 8}},
	{"title":"Rail Coil", "desc":"Bullet speed +80", "rarity":"common", "effect":{"shot_speed_add": 80.0}},
	{"title":"Trigger Rhythm", "desc":"Shot cooldown -12%", "rarity":"rare", "effect":{"shot_cd_mul": 0.88}},
	{"title":"Quick Steps", "desc":"Move speed +10%", "rarity":"common", "effect":{"move_speed_mul": 1.10}},
	{"title":"Blink Module", "desc":"Dash cooldown -18%", "rarity":"rare", "effect":{"dash_cd_mul": 0.82}},
	{"title":"Dash Engine", "desc":"Dash speed +90", "rarity":"rare", "effect":{"dash_speed_add": 90.0}},
	{"title":"Displacement Frame", "desc":"Dash distance +20%", "rarity":"rare", "effect":{"dash_distance_mul": 1.20}},
	{"title":"Warp Core", "desc":"Dash distance +35%", "rarity":"epic", "effect":{"dash_distance_mul": 1.35}},
	{"title":"Deflect Layer", "desc":"Shield drain -18%", "rarity":"rare", "effect":{"shield_drain_mul": 0.82}},
	{"title":"Recharge Coil", "desc":"Shield regen +20%", "rarity":"rare", "effect":{"shield_regen_mul": 1.20}},
	{"title":"High Explosive", "desc":"Grenade damage +16", "rarity":"common", "effect":{"grenade_damage_add": 16}},
	{"title":"Fragment Spread", "desc":"Grenade radius +20", "rarity":"rare", "effect":{"grenade_radius_add": 20.0}},
	{"title":"Fast Fuse", "desc":"Grenade cooldown -15%", "rarity":"rare", "effect":{"grenade_cd_mul": 0.85}},
	{"title":"Vital Alloy", "desc":"Max HP +30, heal +20", "rarity":"common", "effect":{"max_hp_add": 30.0, "heal_add": 20.0}},
	{"title":"Shield Matrix", "desc":"Max SP +25, SP +20", "rarity":"common", "effect":{"max_sp_add": 25.0, "sp_add": 20.0}},
	{"title":"Blood Echo", "desc":"Lifesteal +5%", "rarity":"epic", "effect":{"lifesteal_add": 0.05}}
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
var _next_wave_comp_text := ""

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
@onready var hp_bar: ProgressBar = $HUD/Vitals/HPBar
@onready var sp_bar: ProgressBar = $HUD/Vitals/SPBar
@onready var hp_text: Label = $HUD/Vitals/HPLabel
@onready var sp_text: Label = $HUD/Vitals/SPLabel
@onready var mode_text: Label = $HUD/Vitals/ModeLabel
@onready var cooldown_text: Label = $HUD/Vitals/CooldownLabel
@onready var msg_label: Label = $HUD/Message

@onready var card_shade: ColorRect = $CardUI/Shade
@onready var card_panel: Panel = $CardUI/Shade/Center/Panel
@onready var card_a: Button = $CardUI/Shade/Center/Panel/VBox/CardA
@onready var card_b: Button = $CardUI/Shade/Center/Panel/VBox/CardB
@onready var card_c: Button = $CardUI/Shade/Center/Panel/VBox/CardC

func _ready() -> void:
	_rng.randomize()
	_setup_actions()
	_build_static_arena()
	_setup_spawns()
	player.sword_scene = sword_scene
	player.projectile_scene = projectile_scene
	player.grenade_scene = grenade_scene
	player.stats_changed.connect(_on_player_stats_changed)
	player.message_sent.connect(_show_message)
	card_a.pressed.connect(func() -> void: _pick_card(0))
	card_b.pressed.connect(func() -> void: _pick_card(1))
	card_c.pressed.connect(func() -> void: _pick_card(2))
	_show_message("Auto sword | LMB shoot | RMB shield | E grenade | Shift dash | Q bullet mode")
	_set_intermission(INTERMISSION_SECONDS)
	_update_ui()

func _process(delta: float) -> void:
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
		if _spawn_queue.is_empty() and _alive_enemies() == 0:
			_on_wave_clear()
	else:
		_intermission_left -= delta
		if _intermission_left <= 0.0:
			_begin_wave_preview()

	_update_ui()

func _setup_actions() -> void:
	_set_key("move_forward", KEY_W)
	_set_key("move_back", KEY_S)
	_set_key("move_left", KEY_A)
	_set_key("move_right", KEY_D)
	_set_key("dash", KEY_SHIFT)
	_set_key("throw_grenade", KEY_E)
	_set_key("switch_bullet", KEY_Q)
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
	_wave_preview = true
	_wave_active = false
	_preview_left = PREVIEW_SECONDS
	_mutate_terrain()
	_build_spawn_queue()
	_set_hazards_active(false)
	_spawn_preview_enemies()
	_show_message("Wave %d starts in %.0fs: inspect map + enemies" % [wave, PREVIEW_SECONDS])

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
	_show_message("Wave %d started" % wave)

func _build_spawn_queue() -> void:
	_spawn_queue.clear()
	var chaser: int = 6 + wave * 2
	var shooter: int = 2 + int(wave / 2)
	var dasher: int = int((wave + 2) / 3)
	for i in chaser:
		_spawn_queue.append(0)
	for i in shooter:
		_spawn_queue.append(1)
	for i in dasher:
		_spawn_queue.append(2)
	_spawn_queue.shuffle()
	_next_wave_comp_text = "%s x%d  %s x%d  %s x%d" % [
		str(ENEMY_TYPE_LABEL[0]), chaser,
		str(ENEMY_TYPE_LABEL[1]), shooter,
		str(ENEMY_TYPE_LABEL[2]), dasher
	]

func _spawn_enemy(kind: int, active: bool) -> Node:
	if enemy_scene == null:
		return null
	var e: Node = enemy_scene.instantiate()
	enemy_root.add_child(e)
	if e is Node2D:
		(e as Node2D).global_position = _random_spawn()
	if e.has_method("set_target"):
		e.set_target(player)
	if e.has_method("configure"):
		e.configure(kind, wave, enemy_projectile_scene)
	_try_apply_elite(e)
	if e.has_method("set_active"):
		e.set_active(active)
	return e

func _try_apply_elite(enemy: Node) -> void:
	if wave < 3:
		return
	if _rng.randf() > clampf(0.06 + wave * 0.01, 0.0, 0.42):
		return
	var mod: Dictionary = ELITE_MODS[_rng.randi_range(0, ELITE_MODS.size() - 1)]
	if enemy.has_method("apply_elite_mod"):
		enemy.apply_elite_mod(mod)

func _on_wave_clear() -> void:
	_wave_active = false
	player.heal(20.0)
	player.restore_sp(25.0)
	_show_message("Wave %d cleared" % wave)
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
	_show_message("Picked: %s" % str(card["title"]))
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
	var rarity_text: String = str(RARITY_LABEL.get(rarity, "Common"))
	btn.text = "[%s] %s\n%s" % [rarity_text, str(card["title"]), str(card["desc"])]
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

func _alive_enemies() -> int:
	return enemy_root.get_child_count()

func _on_player_stats_changed(hp: float, max_hp: float, sp: float, max_sp: float, bullet_mode: String, dash_cd: float, grenade_cd: float, shield_on: bool) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	sp_bar.max_value = max_sp
	sp_bar.value = sp
	hp_text.text = "HP %.0f/%.0f" % [hp, max_hp]
	sp_text.text = "SP %.0f/%.0f" % [sp, max_sp]
	mode_text.text = "Bullet: %s | Shield: %s | Grenade: E (to mouse)" % [bullet_mode, ("On" if shield_on else "Off")]
	cooldown_text.text = "Dash %.1fs | Grenade %.1fs" % [dash_cd, grenade_cd]

func _show_message(text: String) -> void:
	msg_label.text = text
	var t: SceneTreeTimer = get_tree().create_timer(1.8)
	t.timeout.connect(func() -> void:
		if msg_label.text == text:
			msg_label.text = ""
	)

func _update_ui() -> void:
	wave_label.text = "Wave: %d" % wave
	alive_label.text = "Enemies: %d" % _alive_enemies()
	if _wave_preview:
		status_label.text = "Status: Preview"
		timer_label.text = "Fight in %.1f | %s" % [maxf(0.0, _preview_left), _next_wave_comp_text]
	elif _wave_active:
		status_label.text = "Status: Combat"
		timer_label.text = "Remaining Spawns: %d" % _spawn_queue.size()
	else:
		status_label.text = "Status: Intermission"
		timer_label.text = "Next wave %.1f | %s" % [maxf(0.0, _intermission_left), _next_wave_comp_text]
