extends CharacterBody2D

signal stats_changed(hp: float, max_hp: float, sp: float, max_sp: float, bullet_mode: String, dash_cd: float, grenade_cd: float, shield_on: bool)
signal message_sent(text: String)
signal sfx_event(name: String)
signal damage_dealt(amount: float)
signal died

const BASE_MOVE_SPEED := 220.0
const BASE_SWORD_CD := 0.55
const BASE_SHOT_CD := 0.40
const BASE_DASH_CD := 2.4
const BASE_GRENADE_CD := 3.5
const DASH_DURATION := 0.18
const DASH_SPEED := 620.0
const GRENADE_SPEED := 280.0
const GRENADE_CHARGE_MAX := 1.25
const GRENADE_CHARGE_SPEED_MUL_MAX := 2.5
const OVERDRIVE_MAX := 160.0
const OVERDRIVE_DURATION := 6.0
const SWORD_STYLE_DEFAULT := 0
const SWORD_STYLE_WHIRL := 1
const SWORD_STYLE_EXEC := 2
const SHOT_STYLE_DEFAULT := 0
const SHOT_STYLE_BARRAGE := 1
const SHOT_STYLE_RAIL := 2
const METEOR_STYLE_DEFAULT := 0
const METEOR_STYLE_SHOWER := 1
const METEOR_STYLE_CATA := 2
const ArcaneFxScript := preload("res://scripts/magic_arcane_fx.gd")
const NovaFxScript := preload("res://scripts/magic_nova_fx.gd")
const CombatFxScript := preload("res://scripts/combat_fx2d.gd")

enum BulletMode {
	NORMAL,
	PIERCE,
	BURST,
	RICOCHET,
	HEX
}

const BULLET_MODE_LABEL := {
	BulletMode.NORMAL: "mode_normal",
	BulletMode.PIERCE: "mode_pierce",
	BulletMode.BURST: "mode_burst",
	BulletMode.RICOCHET: "mode_ricochet",
	BulletMode.HEX: "mode_hex"
}
const BULLET_MODE_COUNT := 5

@export var sword_scene: PackedScene
@export var projectile_scene: PackedScene
@export var grenade_scene: PackedScene

var max_hp := 140.0
var hp := 140.0
var max_sp := 100.0
var sp := 100.0
var shield_active := false

var move_speed_mul := 1.0
var sword_damage := 30
var sword_radius := 76.0
var sword_cd_mul := 1.0
var sword_speed_mul := 1.0
var shot_damage := 18
var shot_speed := 520.0
var shot_cd_mul := 1.0
var shot_cd_normal_mul := 1.0
var shot_cd_pierce_mul := 1.8
var shot_cd_burst_mul := 2.6
var grenade_damage := 52
var grenade_radius := 95.0
var grenade_cd_mul := 1.0
var dash_cd_mul := 1.0
var dash_speed_bonus := 0.0
var dash_distance_mul := 1.0
var shield_drain_mul := 1.0
var shield_regen_mul := 1.0
var lifesteal_ratio := 0.0
var shot_multishot_add := 0
var shot_pierce_bonus := 0
var shot_ricochet_bonus := 0
var shot_hex_explode_radius := 0.0
var shot_hex_homing_bonus := 0.0
var shot_hex_chain_bonus := 0
var sword_echo_chance := 0.0
var dash_impact_damage := 0
var dash_impact_radius := 64.0
var bullet_mode := BulletMode.NORMAL
var _sword_style := SWORD_STYLE_DEFAULT
var _shot_style := SHOT_STYLE_DEFAULT

var _dash_cd_left := 0.0
var _grenade_cd_left := 0.0
var _sword_cd_left := 0.0
var _shot_cd_left := 0.0
var _dash_left := 0.0
var _dash_dir := Vector2.ZERO
var _shield_fx_phase := 0.0
var _last_shield_active := false
var _grenade_preview_pos := Vector2.ZERO
var _grenade_preview_points: Array[Vector2] = []
var _grenade_charging := false
var _grenade_charge_t := 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _arcane_bolt_unlocked := false
var _frost_nova_unlocked := false
var _magic_power_mul := 1.0
var _magic_haste_mul := 1.0
var _arcane_cd := 0.0
var _frost_cd := 0.0
var _chain_sigil_unlocked := false
var _meteor_rain_unlocked := false
var _chain_cd := 0.0
var _meteor_cd := 0.0
var _meteor_extra_strikes := 0
var _meteor_radius_bonus := 0.0
var _meteor_delay_mul := 1.0
var _meteor_burst_bonus := 0
var _meteor_echo_count := 0
var _meteor_style := METEOR_STYLE_DEFAULT
var _resonance_stacks := 0
var _resonance_gain_mul := 1.0
const RESONANCE_MAX := 14
var _dead := false
var auto_fire_enabled := true
var _overdrive_charge := 0.0
var _overdrive_left := 0.0
var _overdrive_active := false
var _socket_slots := {"bullet": 0, "spell": 0, "grenade": 0}
var _socket_used := {"bullet": 0, "spell": 0, "grenade": 0}
var _augment_state := {
	"overheat_lens": false,
	"phase_prism": false,
	"mana_weave": false,
	"cluster_payload": false
}
var _augment_shot_spread := 0.0
var _augment_spell_power_mul := 1.0
var _augment_spell_haste_mul := 1.0
var _augment_chain_jump := 0
var _augment_meteor_strike := 0
var _augment_grenade_cluster := 0
var _augment_grenade_cluster_dmg := 0.35
var _augment_grenade_cluster_radius := 0.46
var _combo_state := {
	"overdrive_link": false,
	"shield_empty_link": false,
	"dash_chain_link": false
}
var _combo_dash_times: Array[float] = []
var _combo_dash_chain_left := 0.0

func _ready() -> void:
	add_to_group("player")
	_rng.randomize()
	_emit_stats()

func _process(delta: float) -> void:
	if _dead:
		return
	_update_cooldowns(delta)
	_handle_modes_input()
	_handle_attacks()
	_handle_shield(delta)
	_handle_magic(delta)
	_update_overdrive(delta)
	_update_combo_cards(delta)
	_shield_fx_phase += delta * 5.2
	_update_grenade_preview(_get_current_grenade_speed())
	queue_redraw()
	_emit_stats()

func _physics_process(delta: float) -> void:
	if _dead:
		velocity = Vector2.ZERO
		return
	if _dash_left > 0.0:
		_dash_left -= delta
		velocity = _dash_dir * (DASH_SPEED + dash_speed_bonus)
	else:
		var input_vec := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		velocity = input_vec * (BASE_MOVE_SPEED * move_speed_mul)
		if Input.is_action_just_pressed("dash") and _dash_cd_left <= 0.0 and input_vec.length() > 0.1:
			_dash_cd_left = BASE_DASH_CD * dash_cd_mul
			_dash_left = DASH_DURATION * dash_distance_mul
			_dash_dir = input_vec.normalized()
			_register_combo_dash()
			message_sent.emit(Loc.t("msg_dash"))
			sfx_event.emit("dash")
			_dash_impact()
	move_and_slide()

func _draw() -> void:
	if _grenade_cd_left <= 0.0:
		for i in range(_grenade_preview_points.size() - 1):
			if i % 2 == 0:
				var a := to_local(_grenade_preview_points[i])
				var b := to_local(_grenade_preview_points[i + 1])
				draw_line(a, b, Color(1.0, 0.72, 0.30, 0.72), 2.0)
		var p := to_local(_grenade_preview_pos)
		draw_line(p + Vector2(-6, 0), p + Vector2(6, 0), Color(1.0, 0.82, 0.38, 0.78), 2.0)
		draw_line(p + Vector2(0, -6), p + Vector2(0, 6), Color(1.0, 0.82, 0.38, 0.78), 2.0)

	if not shield_active:
		return
	var pulse := 0.84 + 0.16 * sin(_shield_fx_phase)
	var outer_r := 22.0 + 1.8 * sin(_shield_fx_phase * 1.2)
	var inner_r := 15.0 + 1.0 * sin(_shield_fx_phase * 1.7)
	draw_arc(Vector2.ZERO, outer_r, 0.0, TAU, 48, Color(0.46, 0.82, 1.0, 0.78 * pulse), 3.0)
	draw_arc(Vector2.ZERO, inner_r, 0.0, TAU, 48, Color(0.70, 0.94, 1.0, 0.58 * pulse), 2.0)
	draw_circle(Vector2.ZERO, 7.0, Color(0.82, 0.98, 1.0, 0.22 * pulse))

func take_damage(amount: int) -> void:
	if _dead:
		return
	if shield_active and sp > 0.5:
		sp = maxf(0.0, sp - 10.0)
		sfx_event.emit("shield_hit")
		return
	hp -= amount
	sfx_event.emit("hurt")
	if hp <= 0.0:
		hp = 0.0
		_dead = true
		_emit_stats()
		died.emit()

func drain_sp(amount: float) -> void:
	sp = maxf(0.0, sp - amount)

func heal(amount: float) -> void:
	hp = minf(max_hp, hp + amount)

func restore_sp(amount: float) -> void:
	sp = minf(max_sp, sp + amount)

func on_dealt_damage(amount: float) -> void:
	damage_dealt.emit(amount)
	if lifesteal_ratio <= 0.0:
		pass
	else:
		heal(amount * lifesteal_ratio)
	_overdrive_charge = minf(OVERDRIVE_MAX, _overdrive_charge + amount * 0.22)
	if not _overdrive_active and _overdrive_charge >= OVERDRIVE_MAX:
		_activate_overdrive()

func apply_upgrade(effect: Dictionary) -> void:
	for key in effect.keys():
		var value = effect[key]
		match String(key):
			"max_hp_add":
				max_hp += float(value)
				hp = minf(max_hp, hp + float(value))
			"max_sp_add":
				max_sp += float(value)
				sp = minf(max_sp, sp + float(value))
			"heal_add":
				heal(float(value))
			"sp_add":
				restore_sp(float(value))
			"sword_damage_add":
				sword_damage += int(value)
			"sword_radius_add":
				sword_radius += float(value)
			"sword_cd_mul":
				sword_cd_mul *= float(value)
			"sword_speed_mul":
				sword_speed_mul *= float(value)
			"shot_damage_add":
				shot_damage += int(value)
			"shot_speed_add":
				shot_speed += float(value)
			"shot_cd_mul":
				shot_cd_mul *= float(value)
			"shot_cd_normal_mul":
				shot_cd_normal_mul *= float(value)
			"shot_cd_pierce_mul":
				shot_cd_pierce_mul *= float(value)
			"shot_cd_burst_mul":
				shot_cd_burst_mul *= float(value)
			"shot_multishot_add":
				shot_multishot_add += int(value)
			"shot_pierce_bonus":
				shot_pierce_bonus += int(value)
			"shot_ricochet_add":
				shot_ricochet_bonus += int(value)
			"shot_hex_explode_add":
				shot_hex_explode_radius += float(value)
			"shot_hex_homing_add":
				shot_hex_homing_bonus += float(value)
			"shot_hex_chain_add":
				shot_hex_chain_bonus += int(value)
			"dash_cd_mul":
				dash_cd_mul *= float(value)
			"dash_speed_add":
				dash_speed_bonus += float(value)
			"dash_distance_mul":
				dash_distance_mul *= float(value)
			"dash_impact_add":
				dash_impact_damage += int(value)
			"dash_impact_radius_add":
				dash_impact_radius += float(value)
			"move_speed_mul":
				move_speed_mul *= float(value)
			"shield_drain_mul":
				shield_drain_mul *= float(value)
			"shield_regen_mul":
				shield_regen_mul *= float(value)
			"grenade_damage_add":
				grenade_damage += int(value)
			"grenade_radius_add":
				grenade_radius += float(value)
			"grenade_cd_mul":
				grenade_cd_mul *= float(value)
			"lifesteal_add":
				lifesteal_ratio = minf(0.4, lifesteal_ratio + float(value))
			"sword_echo_add":
				sword_echo_chance = minf(0.85, sword_echo_chance + float(value))
			"unlock_chain_sigil":
				_chain_sigil_unlocked = _chain_sigil_unlocked or bool(value)
			"unlock_meteor_rain":
				_meteor_rain_unlocked = _meteor_rain_unlocked or bool(value)
			"magic_haste_mul":
				_magic_haste_mul *= float(value)
			"magic_power_mul":
				_magic_power_mul *= float(value)
			"meteor_strikes_add":
				_meteor_extra_strikes += int(value)
			"meteor_radius_add":
				_meteor_radius_bonus += float(value)
			"meteor_delay_mul":
				_meteor_delay_mul *= float(value)
			"meteor_damage_add":
				_meteor_burst_bonus += int(value)
			"meteor_echo_add":
				_meteor_echo_count += int(value)
			"resonance_gain_mul":
				_resonance_gain_mul *= float(value)
			"meteor_style_shower":
				if bool(value):
					_meteor_style = METEOR_STYLE_SHOWER
			"meteor_style_cata":
				if bool(value):
					_meteor_style = METEOR_STYLE_CATA
			"sword_style_whirl":
				if bool(value):
					_sword_style = SWORD_STYLE_WHIRL
			"sword_style_exec":
				if bool(value):
					_sword_style = SWORD_STYLE_EXEC
			"shot_style_barrage":
				if bool(value):
					_shot_style = SHOT_STYLE_BARRAGE
			"shot_style_rail":
				if bool(value):
					_shot_style = SHOT_STYLE_RAIL
			"socket_bullet_add":
				_socket_slots["bullet"] = int(_socket_slots["bullet"]) + maxi(0, int(value))
			"socket_spell_add":
				_socket_slots["spell"] = int(_socket_slots["spell"]) + maxi(0, int(value))
			"socket_grenade_add":
				_socket_slots["grenade"] = int(_socket_slots["grenade"]) + maxi(0, int(value))
			"augment_overheat_lens":
				if bool(value):
					_attach_augment("bullet", "overheat_lens")
			"augment_phase_prism":
				if bool(value):
					_attach_augment("bullet", "phase_prism")
			"augment_mana_weave":
				if bool(value):
					_attach_augment("spell", "mana_weave")
			"augment_cluster_payload":
				if bool(value):
					_attach_augment("grenade", "cluster_payload")
			"unlock_combo_overdrive":
				_combo_state["overdrive_link"] = _combo_state["overdrive_link"] or bool(value)
			"unlock_combo_shield_empty":
				_combo_state["shield_empty_link"] = _combo_state["shield_empty_link"] or bool(value)
			"unlock_combo_dash_chain":
				_combo_state["dash_chain_link"] = _combo_state["dash_chain_link"] or bool(value)
	_emit_stats()

func _update_cooldowns(delta: float) -> void:
	_dash_cd_left = maxf(0.0, _dash_cd_left - delta)
	_grenade_cd_left = maxf(0.0, _grenade_cd_left - delta)
	_sword_cd_left = maxf(0.0, _sword_cd_left - delta)
	_shot_cd_left = maxf(0.0, _shot_cd_left - delta)

func _handle_modes_input() -> void:
	if Input.is_action_just_pressed("bullet_mode_1"):
		bullet_mode = BulletMode.NORMAL
		message_sent.emit(Loc.t("msg_mode_switch") % _bullet_mode_name())
		sfx_event.emit("mode_switch")
		return
	if Input.is_action_just_pressed("bullet_mode_2"):
		bullet_mode = BulletMode.PIERCE
		message_sent.emit(Loc.t("msg_mode_switch") % _bullet_mode_name())
		sfx_event.emit("mode_switch")
		return
	if Input.is_action_just_pressed("bullet_mode_3"):
		bullet_mode = BulletMode.BURST
		message_sent.emit(Loc.t("msg_mode_switch") % _bullet_mode_name())
		sfx_event.emit("mode_switch")
		return
	if Input.is_action_just_pressed("bullet_mode_4"):
		bullet_mode = BulletMode.RICOCHET
		message_sent.emit(Loc.t("msg_mode_switch") % _bullet_mode_name())
		sfx_event.emit("mode_switch")
		return
	if Input.is_action_just_pressed("bullet_mode_5"):
		bullet_mode = BulletMode.HEX
		message_sent.emit(Loc.t("msg_mode_switch") % _bullet_mode_name())
		sfx_event.emit("mode_switch")
		return
	if Input.is_action_just_pressed("switch_bullet"):
		bullet_mode = (bullet_mode + 1) % BULLET_MODE_COUNT
		message_sent.emit(Loc.t("msg_mode_switch") % _bullet_mode_name())
		sfx_event.emit("mode_switch")

func _handle_attacks() -> void:
	if _sword_cd_left <= 0.0:
		_sword_cd_left = BASE_SWORD_CD * sword_cd_mul
		_do_sword_sweep()

	if _shot_cd_left <= 0.0 and (auto_fire_enabled or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):
		_shot_cd_left = BASE_SHOT_CD * shot_cd_mul * _current_shot_mode_cd_mul()
		_shoot_projectile()
		sfx_event.emit("shoot")

	if _grenade_cd_left <= 0.0:
		if Input.is_action_just_pressed("throw_grenade"):
			_grenade_charging = true
			_grenade_charge_t = 0.0
		if _grenade_charging and Input.is_action_pressed("throw_grenade"):
			_grenade_charge_t = minf(GRENADE_CHARGE_MAX, _grenade_charge_t + get_process_delta_time())
		if _grenade_charging and Input.is_action_just_released("throw_grenade"):
			_grenade_charging = false
			_grenade_cd_left = BASE_GRENADE_CD * grenade_cd_mul
			_throw_grenade(_get_current_grenade_speed())
			message_sent.emit(Loc.t("msg_grenade_throw"))
			sfx_event.emit("grenade_throw")
			_grenade_charge_t = 0.0
	else:
		_grenade_charging = false
		_grenade_charge_t = 0.0

func _handle_shield(delta: float) -> void:
	if Input.is_action_pressed("shield") and sp > 0.0:
		shield_active = true
		sp = maxf(0.0, sp - 24.0 * shield_drain_mul * delta)
	else:
		shield_active = false
		sp = minf(max_sp, sp + 12.0 * shield_regen_mul * delta)

	if shield_active != _last_shield_active:
		if shield_active:
			message_sent.emit(Loc.t("msg_shield_on"))
			sfx_event.emit("shield_on")
		else:
			message_sent.emit(Loc.t("msg_shield_off"))
			sfx_event.emit("shield_off")
		_last_shield_active = shield_active

func _do_sword_sweep() -> void:
	if sword_scene == null:
		return
	var dmg := sword_damage
	var radius := sword_radius
	var speed := sword_speed_mul
	dmg = int(round(float(dmg) * _combo_sword_damage_mul()))
	if _sword_style == SWORD_STYLE_WHIRL:
		dmg = int(round(float(dmg) * 0.82))
		radius *= 1.22
		speed *= 1.40
	elif _sword_style == SWORD_STYLE_EXEC:
		dmg = int(round(float(dmg) * 1.30))
		radius *= 0.90
		speed *= 0.96
	var sweep := sword_scene.instantiate()
	get_tree().current_scene.add_child(sweep)
	sweep.global_position = global_position
	sweep.setup(dmg, radius, speed)
	if _rng.randf() < sword_echo_chance:
		var echo := sword_scene.instantiate()
		get_tree().current_scene.add_child(echo)
		echo.global_position = global_position
		echo.setup(int(round(float(dmg) * 0.65)), radius * 0.85, speed * 1.1)
	if _sword_style == SWORD_STYLE_WHIRL:
		_spawn_whirl_echo(dmg, radius, speed)
	elif _sword_style == SWORD_STYLE_EXEC:
		_apply_execute_sweep(dmg, radius)

func _shoot_projectile() -> void:
	if projectile_scene == null:
		return
	var to_mouse: Vector2 = _apply_shot_style_spread(_acquire_shot_direction())
	var profile := _mode_projectile_profile()
	_apply_bullet_augments(profile)
	if _shot_style == SHOT_STYLE_RAIL and bullet_mode == BulletMode.BURST:
		_spawn_projectile(to_mouse, 1 + shot_pierce_bonus, profile)
		return
	match bullet_mode:
		BulletMode.NORMAL:
			_spawn_projectile(to_mouse, shot_pierce_bonus, profile)
		BulletMode.PIERCE:
			_spawn_projectile(to_mouse, 2 + shot_pierce_bonus, profile)
		BulletMode.BURST:
			_spawn_projectile(to_mouse.rotated(deg_to_rad(8)), shot_pierce_bonus, profile)
			_spawn_projectile(to_mouse, shot_pierce_bonus, profile)
			_spawn_projectile(to_mouse.rotated(deg_to_rad(-8)), shot_pierce_bonus, profile)
		BulletMode.RICOCHET:
			_spawn_projectile(to_mouse, shot_pierce_bonus, profile)
		BulletMode.HEX:
			_spawn_projectile(to_mouse.rotated(deg_to_rad(4.0)), shot_pierce_bonus, profile)
			_spawn_projectile(to_mouse.rotated(deg_to_rad(-4.0)), shot_pierce_bonus, profile)
	if _shot_style == SHOT_STYLE_BARRAGE:
		_spawn_projectile(to_mouse.rotated(deg_to_rad(_rng.randf_range(-14.0, 14.0))), shot_pierce_bonus, profile)
	_spawn_multishot(to_mouse, profile)

func _spawn_projectile(dir: Vector2, pierce: int, extra: Dictionary = {}) -> void:
	var p := projectile_scene.instantiate()
	get_tree().current_scene.add_child(p)
	p.global_position = global_position
	p.setup(dir, _current_shot_speed(), _current_shot_damage(), true, pierce, extra)

func _spawn_multishot(base_dir: Vector2, profile: Dictionary = {}) -> void:
	if shot_multishot_add <= 0:
		return
	for i in range(shot_multishot_add):
		var layer: int = i + 1
		var ang: float = 6.0 * float(layer)
		_spawn_projectile(base_dir.rotated(deg_to_rad(ang)), shot_pierce_bonus, profile)
		_spawn_projectile(base_dir.rotated(deg_to_rad(-ang)), shot_pierce_bonus, profile)

func _mode_projectile_profile() -> Dictionary:
	match bullet_mode:
		BulletMode.RICOCHET:
			return {
				"ricochet": 1 + shot_ricochet_bonus,
				"trail_color": Color(1.0, 0.92, 0.46, 0.72),
				"core_color": Color(1.0, 0.98, 0.68, 1.0),
				"life_mul": 1.35
			}
		BulletMode.HEX:
			return {
				"homing": 0.95 + shot_hex_homing_bonus,
				"explosion_radius": 34.0 + shot_hex_explode_radius,
				"chain": 1 + shot_hex_chain_bonus,
				"apply_status": "hex_mark",
				"status_duration": 4.6,
				"status_stacks": 1,
				"trail_color": Color(0.68, 0.50, 1.0, 0.76),
				"core_color": Color(0.88, 0.74, 1.0, 1.0),
				"life_mul": 1.25
			}
	return {}

func _throw_grenade(speed: float) -> void:
	if grenade_scene == null:
		return
	var to_mouse_vec: Vector2 = get_global_mouse_position() - global_position
	var to_mouse: Vector2 = to_mouse_vec.normalized()
	if to_mouse.length() < 0.001:
		to_mouse = _fallback_aim_dir()
	var g := grenade_scene.instantiate()
	get_tree().current_scene.add_child(g)
	g.global_position = global_position
	var combo_g_dmg := int(round(float(grenade_damage) * _combo_grenade_damage_mul()))
	g.setup(to_mouse * speed, combo_g_dmg, grenade_radius, _augment_grenade_cluster, _augment_grenade_cluster_dmg, _augment_grenade_cluster_radius)

func _acquire_shot_direction() -> Vector2:
	var target := _nearest_enemy(940.0)
	if target != null:
		var to_enemy := (target.global_position - global_position).normalized()
		if to_enemy.length() > 0.001:
			return to_enemy
	var to_mouse_vec: Vector2 = get_global_mouse_position() - global_position
	var to_mouse: Vector2 = to_mouse_vec.normalized()
	if to_mouse.length() < 0.001:
		return _fallback_aim_dir()
	return to_mouse

func _fallback_aim_dir() -> Vector2:
	if velocity.length() > 0.01:
		return velocity.normalized()
	return Vector2.RIGHT

func _bullet_mode_name() -> String:
	var key: String = str(BULLET_MODE_LABEL.get(bullet_mode, "mode_normal"))
	return Loc.t(key)

func _current_shot_mode_cd_mul() -> float:
	var overdrive_mul := 0.74 if _overdrive_active else 1.0
	var style_mul := 1.0
	if _shot_style == SHOT_STYLE_BARRAGE:
		style_mul = 0.72
	elif _shot_style == SHOT_STYLE_RAIL:
		style_mul = 1.35
	match bullet_mode:
		BulletMode.NORMAL:
			return shot_cd_normal_mul * overdrive_mul * style_mul
		BulletMode.PIERCE:
			return shot_cd_pierce_mul * overdrive_mul * style_mul
		BulletMode.BURST:
			return shot_cd_burst_mul * overdrive_mul * style_mul
		BulletMode.RICOCHET:
			return shot_cd_pierce_mul * 1.15 * overdrive_mul * style_mul
		BulletMode.HEX:
			return shot_cd_burst_mul * 1.28 * overdrive_mul * style_mul
	return 1.0

func _update_grenade_preview(speed: float) -> void:
	var dir: Vector2 = (get_global_mouse_position() - global_position).normalized()
	if dir.length() < 0.001:
		dir = _fallback_aim_dir()
	var pos := global_position
	var vel := dir * speed
	_grenade_preview_points.clear()
	_grenade_preview_points.append(pos)
	var t := 0.0
	var dt := 0.05
	while t < 1.1:
		pos += vel * dt
		vel = vel.move_toward(Vector2.ZERO, 340.0 * dt)
		t += dt
		_grenade_preview_points.append(pos)
	_grenade_preview_pos = pos

func _get_current_grenade_speed() -> float:
	var q := clampf(_grenade_charge_t / GRENADE_CHARGE_MAX, 0.0, 1.0)
	var mul := lerpf(1.0, GRENADE_CHARGE_SPEED_MUL_MAX, q)
	return GRENADE_SPEED * mul

func _dash_impact() -> void:
	if dash_impact_damage <= 0:
		return
	for e in get_tree().get_nodes_in_group("enemy"):
		if e is Node2D:
			var d: float = ((e as Node2D).global_position - global_position).length()
			if d <= dash_impact_radius and e.has_method("take_damage"):
				e.take_damage(dash_impact_damage)
				if e.has_method("apply_impulse"):
					var dir := ((e as Node2D).global_position - global_position).normalized()
					e.apply_impulse(dir * 260.0)

func _emit_stats() -> void:
	stats_changed.emit(hp, max_hp, sp, max_sp, _bullet_mode_name(), _dash_cd_left, _grenade_cd_left, shield_active)

func apply_meta_progression(meta: Dictionary) -> void:
	max_hp += float(meta.get("hp_bonus", 0.0))
	hp = max_hp
	shot_damage += int(meta.get("atk_bonus", 0))
	move_speed_mul *= float(meta.get("speed_mul", 1.0))
	_magic_power_mul = float(meta.get("magic_mul", 1.0))
	sword_damage += int(meta.get("melee_damage_add", 0))
	sword_radius += float(meta.get("melee_radius_add", 0.0))
	shot_damage += int(meta.get("ranged_damage_add", 0))
	shot_speed += float(meta.get("ranged_speed_add", 0.0))
	shot_cd_mul *= float(meta.get("ranged_cd_mul", 1.0))
	_magic_power_mul *= float(meta.get("spell_power_mul", 1.0))
	_magic_haste_mul = float(meta.get("spell_haste_mul", 1.0))
	_arcane_bolt_unlocked = bool(meta.get("arcane_bolt", false))
	_frost_nova_unlocked = bool(meta.get("frost_nova", false))
	_chain_sigil_unlocked = bool(meta.get("chain_sigil", false))
	_meteor_rain_unlocked = bool(meta.get("meteor_rain", false))
	_emit_stats()

func _handle_magic(delta: float) -> void:
	if _arcane_bolt_unlocked:
		_arcane_cd -= delta
		if _arcane_cd <= 0.0:
			_arcane_cd = maxf(0.35, (2.1 - 0.12 * _effective_spell_power()) / _effective_magic_haste())
			_fire_arcane_bolt()
	if _frost_nova_unlocked:
		_frost_cd -= delta
		if _frost_cd <= 0.0:
			_frost_cd = maxf(3.2, (10.0 - 0.3 * _effective_spell_power()) / _effective_magic_haste())
			_cast_frost_nova()
	if _chain_sigil_unlocked:
		_chain_cd -= delta
		if _chain_cd <= 0.0:
			_chain_cd = maxf(0.95, (4.9 - 0.20 * _effective_spell_power()) / _effective_magic_haste())
			_cast_chain_sigil()
	if _meteor_rain_unlocked:
		_meteor_cd -= delta
		if _meteor_cd <= 0.0:
			_meteor_cd = maxf(4.0, (12.2 - 0.25 * _effective_spell_power()) / _effective_magic_haste())
			_cast_meteor_rain()

func _fire_arcane_bolt() -> void:
	var target: Node2D = _nearest_enemy(620.0)
	if target == null:
		return
	_spawn_arcane_fx(target.global_position)
	if target.has_method("take_damage"):
		var dmg := int(round(22.0 * _effective_spell_power()))
		target.take_damage(dmg)

func _cast_frost_nova() -> void:
	var radius := 170.0
	var dmg := int(round(18.0 * _effective_spell_power()))
	_spawn_nova_fx(radius)
	for e in get_tree().get_nodes_in_group("enemy"):
		if e is Node2D:
			var en := e as Node2D
			if en.global_position.distance_to(global_position) <= radius:
				if e.has_method("take_damage"):
					e.take_damage(dmg)
				if e.has_method("apply_impulse"):
					var dir := (en.global_position - global_position).normalized()
					e.apply_impulse(dir * 260.0)

func _cast_chain_sigil() -> void:
	var first: Node2D = _nearest_marked_enemy(760.0)
	if first == null:
		first = _nearest_enemy(760.0)
	if first == null:
		return
	var resonance_jumps := int(_resonance_stacks / 4)
	var resonance_bonus := 1.0 + 0.07 * float(_resonance_stacks)
	var jumps := 3 + int(_effective_spell_power() * 0.32) + resonance_jumps + _augment_chain_jump
	var current := first
	var hit: Array[Node] = []
	var from_pos := global_position
	while current != null and jumps >= 0:
		hit.append(current)
		_spawn_arcane_fx_from(from_pos, current.global_position)
		_spawn_chain_arc_fx(from_pos, current.global_position)
		if current.has_method("take_damage"):
			var bonus := 1.0
			if current.has_method("consume_status_stack"):
				var stacks: int = int(current.consume_status_stack("hex_mark"))
				if stacks > 0:
					bonus += 0.18 * float(stacks)
			var dmg := int(round((18.0 + 2.6 * float(jumps)) * _effective_spell_power() * bonus * resonance_bonus))
			current.take_damage(dmg)
			if current.has_method("apply_impulse"):
				var kick := (current.global_position - from_pos).normalized()
				current.apply_impulse(kick * 120.0)
		from_pos = current.global_position
		current = _nearest_enemy_except(380.0, from_pos, hit)
		jumps -= 1
	_resonance_stacks = maxi(0, _resonance_stacks - 4)

func _cast_meteor_rain() -> void:
	var anchor := _nearest_marked_enemy(860.0)
	var focused := true
	if anchor == null:
		anchor = _nearest_enemy(760.0)
		focused = false
	if anchor == null:
		return
	var strikes := 3 + _meteor_extra_strikes + _augment_meteor_strike
	if focused and anchor.has_method("consume_status_stack"):
		var stacks: int = int(anchor.consume_status_stack("hex_mark"))
		strikes += mini(2, stacks)
	var delay_mul := _meteor_delay_mul
	if _meteor_style == METEOR_STYLE_SHOWER:
		strikes += 3
		delay_mul *= 0.72
	elif _meteor_style == METEOR_STYLE_CATA:
		strikes = maxi(2, int(round(float(strikes) * 0.55)))
		delay_mul *= 1.18
	strikes = mini(12, strikes)
	for i in range(strikes):
		var angle := deg_to_rad(float(120 * i) + _rng.randf_range(-24.0, 24.0))
		var dist := _rng.randf_range(24.0, 84.0)
		if _meteor_style == METEOR_STYLE_SHOWER:
			dist = _rng.randf_range(18.0, 104.0)
		elif _meteor_style == METEOR_STYLE_CATA:
			dist = _rng.randf_range(16.0, 62.0)
		var pos := anchor.global_position + Vector2.RIGHT.rotated(angle) * dist
		_spawn_meteor_strike(pos, (0.42 + 0.18 * float(i)) * delay_mul)

func _spawn_meteor_strike(pos: Vector2, delay_sec: float) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	_spawn_meteor_fall_fx(pos)
	var warn := TelegraphDecal2D.new()
	warn.global_position = pos
	warn.radius = 56.0
	warn.base_color = Color(1.0, 0.42, 0.22, 0.84)
	warn.duration = delay_sec
	scene.add_child(warn)
	var timer := get_tree().create_timer(delay_sec)
	await timer.timeout
	var radius := 56.0 + _meteor_radius_bonus
	if _meteor_style == METEOR_STYLE_SHOWER:
		radius *= 0.84
	elif _meteor_style == METEOR_STYLE_CATA:
		radius *= 1.45
	_spawn_meteor_impact_fx(pos, radius)
	var base_dmg := int(round((26.0 + float(_meteor_burst_bonus)) * _effective_spell_power()))
	if _meteor_style == METEOR_STYLE_SHOWER:
		base_dmg = int(round(float(base_dmg) * 0.74))
	elif _meteor_style == METEOR_STYLE_CATA:
		base_dmg = int(round(float(base_dmg) * 1.68))
	var hits := 0
	for e in get_tree().get_nodes_in_group("enemy"):
		if e is Node2D:
			var en := e as Node2D
			if en.global_position.distance_to(pos) <= radius:
				if e.has_method("take_damage"):
					var dmg := base_dmg
					if e.has_method("consume_status_stack"):
						var stacks: int = int(e.consume_status_stack("hex_mark"))
						if stacks > 0:
							dmg = int(round(float(dmg) * (1.0 + 0.15 * float(stacks))))
					e.take_damage(dmg)
					hits += 1
				if e.has_method("apply_impulse"):
					var dir := (en.global_position - pos).normalized()
					e.apply_impulse(dir * 330.0)
	for i in range(_meteor_echo_count):
		var offset := Vector2(_rng.randf_range(-34.0, 34.0), _rng.randf_range(-34.0, 34.0))
		_spawn_meteor_impact_fx(pos + offset, radius * 0.55)
		_meteor_echo_damage(pos + offset, radius * 0.55, int(round(float(base_dmg) * 0.34)))
	_resonance_stacks = mini(RESONANCE_MAX, _resonance_stacks + int(round(float(hits) * _resonance_gain_mul)))
	if _meteor_style == METEOR_STYLE_CATA and hits >= 2:
		_resonance_stacks = mini(RESONANCE_MAX, _resonance_stacks + 1)

func _meteor_echo_damage(pos: Vector2, radius: float, dmg: int) -> void:
	for e in get_tree().get_nodes_in_group("enemy"):
		if not (e is Node2D):
			continue
		var en := e as Node2D
		if en.global_position.distance_to(pos) <= radius and e.has_method("take_damage"):
			e.take_damage(dmg)

func _nearest_enemy(radius: float) -> Node2D:
	var best: Node2D = null
	var best_d := radius
	for e in get_tree().get_nodes_in_group("enemy"):
		if e is Node2D:
			var en := e as Node2D
			var d := en.global_position.distance_to(global_position)
			if d < best_d:
				best_d = d
				best = en
	return best

func _nearest_enemy_except(radius: float, origin: Vector2, excluded: Array[Node]) -> Node2D:
	var best: Node2D = null
	var best_d := radius
	for e in get_tree().get_nodes_in_group("enemy"):
		if not (e is Node2D):
			continue
		if excluded.has(e):
			continue
		var en := e as Node2D
		var d := en.global_position.distance_to(origin)
		if d < best_d:
			best_d = d
			best = en
	return best

func _nearest_marked_enemy(radius: float) -> Node2D:
	var best: Node2D = null
	var best_d := radius
	for e in get_tree().get_nodes_in_group("enemy"):
		if not (e is Node2D):
			continue
		if not e.has_method("has_status"):
			continue
		if not e.has_status("hex_mark"):
			continue
		var en := e as Node2D
		var d := en.global_position.distance_to(global_position)
		if d < best_d:
			best_d = d
			best = en
	return best

func _spawn_arcane_fx(end_pos: Vector2) -> void:
	_spawn_arcane_fx_from(global_position, end_pos)

func _spawn_arcane_fx_from(start_pos: Vector2, end_pos: Vector2) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var fx := Node2D.new()
	fx.set_script(ArcaneFxScript)
	scene.add_child(fx)
	fx.setup(start_pos, end_pos)

func _spawn_nova_fx(radius: float) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var fx := Node2D.new()
	fx.set_script(NovaFxScript)
	scene.add_child(fx)
	fx.setup(global_position, radius)

func is_spell_unlocked(spell_id: String) -> bool:
	match spell_id:
		"arcane_bolt":
			return _arcane_bolt_unlocked
		"frost_nova":
			return _frost_nova_unlocked
		"chain_sigil":
			return _chain_sigil_unlocked
		"meteor_rain":
			return _meteor_rain_unlocked
		"meteor_style_shower":
			return _meteor_style == METEOR_STYLE_SHOWER
		"meteor_style_cata":
			return _meteor_style == METEOR_STYLE_CATA
		"sword_style_whirl":
			return _sword_style == SWORD_STYLE_WHIRL
		"sword_style_exec":
			return _sword_style == SWORD_STYLE_EXEC
		"shot_style_barrage":
			return _shot_style == SHOT_STYLE_BARRAGE
		"shot_style_rail":
			return _shot_style == SHOT_STYLE_RAIL
	return false

func has_combo_card(combo_id: String) -> bool:
	return bool(_combo_state.get(combo_id, false))

func _spawn_chain_arc_fx(from: Vector2, to: Vector2) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var fx := Node2D.new()
	fx.set_script(CombatFxScript)
	scene.add_child(fx)
	fx.setup_chain_arc(from, to)

func _spawn_meteor_fall_fx(pos: Vector2) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var fx := Node2D.new()
	fx.set_script(CombatFxScript)
	scene.add_child(fx)
	fx.setup_meteor_fall(pos)

func _spawn_meteor_impact_fx(pos: Vector2, radius: float) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var fx := Node2D.new()
	fx.set_script(CombatFxScript)
	scene.add_child(fx)
	fx.setup_meteor_impact(pos, radius)

func _update_overdrive(delta: float) -> void:
	if _overdrive_active:
		_overdrive_left = maxf(0.0, _overdrive_left - delta)
		if _overdrive_left <= 0.0:
			_overdrive_active = false
			message_sent.emit(Loc.t("msg_overdrive_off"))
		return
	_overdrive_charge = maxf(0.0, _overdrive_charge - delta * 3.2)
	_resonance_stacks = maxi(0, _resonance_stacks - int(floor(delta * 1.1)))

func _activate_overdrive() -> void:
	_overdrive_active = true
	_overdrive_left = OVERDRIVE_DURATION
	_overdrive_charge = 0.0
	message_sent.emit(Loc.t("msg_overdrive_on"))

func _effective_magic_haste() -> float:
	var combo_mul := _combo_magic_haste_mul()
	if _overdrive_active:
		return _magic_haste_mul * _augment_spell_haste_mul * combo_mul * 1.40
	return _magic_haste_mul * _augment_spell_haste_mul * combo_mul

func _effective_spell_power() -> float:
	return _magic_power_mul * _augment_spell_power_mul

func _current_shot_damage() -> int:
	var dmg := shot_damage
	if _shot_style == SHOT_STYLE_BARRAGE:
		dmg = int(round(float(dmg) * 0.72))
	elif _shot_style == SHOT_STYLE_RAIL:
		dmg = int(round(float(dmg) * 1.72))
	if _overdrive_active:
		dmg = int(round(float(dmg) * 1.24))
	dmg = int(round(float(dmg) * _combo_shot_damage_mul()))
	return maxi(1, dmg)

func _current_shot_speed() -> float:
	var combo_mul := _combo_shot_speed_mul()
	if _shot_style == SHOT_STYLE_BARRAGE:
		return shot_speed * 0.90 * combo_mul
	if _shot_style == SHOT_STYLE_RAIL:
		return shot_speed * 1.36 * combo_mul
	return shot_speed * combo_mul

func _update_combo_cards(delta: float) -> void:
	_combo_dash_chain_left = maxf(0.0, _combo_dash_chain_left - delta)

func _register_combo_dash() -> void:
	if not bool(_combo_state.get("dash_chain_link", false)):
		return
	var now := float(Time.get_ticks_msec()) * 0.001
	_combo_dash_times.append(now)
	while _combo_dash_times.size() > 0 and (now - _combo_dash_times[0]) > 6.0:
		_combo_dash_times.pop_front()
	if _combo_dash_times.size() >= 3:
		_combo_dash_chain_left = maxf(_combo_dash_chain_left, 4.0)
		_combo_dash_times.clear()
		message_sent.emit(Loc.t("msg_combo_dash_chain_on"))

func _combo_overdrive_link_on() -> bool:
	return bool(_combo_state.get("overdrive_link", false)) and _overdrive_active

func _combo_shield_empty_link_on() -> bool:
	if not bool(_combo_state.get("shield_empty_link", false)):
		return false
	return sp <= maxf(2.0, max_sp * 0.06)

func _combo_dash_chain_on() -> bool:
	return bool(_combo_state.get("dash_chain_link", false)) and _combo_dash_chain_left > 0.0

func _combo_shot_damage_mul() -> float:
	var mul := 1.0
	if _combo_overdrive_link_on():
		mul *= 1.18
	if _combo_dash_chain_on():
		mul *= 1.14
	return mul

func _combo_sword_damage_mul() -> float:
	var mul := 1.0
	if _combo_overdrive_link_on():
		mul *= 1.10
	if _combo_shield_empty_link_on():
		mul *= 1.12
	return mul

func _combo_shot_speed_mul() -> float:
	var mul := 1.0
	if _combo_dash_chain_on():
		mul *= 1.20
	return mul

func _combo_magic_haste_mul() -> float:
	if _combo_shield_empty_link_on():
		return 1.20
	return 1.0

func _combo_grenade_damage_mul() -> float:
	if _combo_dash_chain_on():
		return 1.16
	return 1.0

func _apply_shot_style_spread(dir: Vector2) -> Vector2:
	var aug_spread := _augment_shot_spread
	if _shot_style == SHOT_STYLE_BARRAGE:
		return dir.rotated(deg_to_rad(_rng.randf_range(-7.0 - aug_spread, 7.0 + aug_spread)))
	if _shot_style == SHOT_STYLE_RAIL:
		return dir.rotated(deg_to_rad(_rng.randf_range(-1.2 - aug_spread * 0.28, 1.2 + aug_spread * 0.28)))
	if aug_spread > 0.01:
		return dir.rotated(deg_to_rad(_rng.randf_range(-aug_spread, aug_spread)))
	return dir

func _attach_augment(domain: String, augment_id: String) -> void:
	if bool(_augment_state.get(augment_id, false)):
		return
	if not has_free_socket(domain):
		return
	_socket_used[domain] = int(_socket_used[domain]) + 1
	_augment_state[augment_id] = true
	match augment_id:
		"overheat_lens":
			_augment_shot_spread += 3.6
		"phase_prism":
			pass
		"mana_weave":
			_augment_spell_power_mul *= 1.12
			_augment_spell_haste_mul *= 1.10
			_augment_chain_jump += 1
			_augment_meteor_strike += 1
		"cluster_payload":
			_augment_grenade_cluster += 3
			_augment_grenade_cluster_dmg = 0.38
			_augment_grenade_cluster_radius = 0.48

func _apply_bullet_augments(profile: Dictionary) -> void:
	if bool(_augment_state.get("overheat_lens", false)):
		profile["augment_overheat"] = true
		profile["overheat_tick_damage_mul"] = 0.18
		profile["overheat_ticks"] = 2
		profile["overheat_tick_interval"] = 0.28
	if bool(_augment_state.get("phase_prism", false)):
		profile["augment_phase_prism"] = true
		profile["phase_prism_splits"] = 1

func has_free_socket(domain: String) -> bool:
	return int(_socket_used.get(domain, 0)) < int(_socket_slots.get(domain, 0))

func has_augment(augment_id: String) -> bool:
	return bool(_augment_state.get(augment_id, false))

func get_socket_slots(domain: String) -> int:
	return int(_socket_slots.get(domain, 0))

func get_socket_used(domain: String) -> int:
	return int(_socket_used.get(domain, 0))

func _spawn_whirl_echo(dmg: int, radius: float, speed: float) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var t := get_tree().create_timer(0.07)
	await t.timeout
	if _dead:
		return
	var echo := sword_scene.instantiate()
	scene.add_child(echo)
	echo.global_position = global_position
	echo.setup(int(round(float(dmg) * 0.56)), radius * 0.94, speed * 1.18)

func _apply_execute_sweep(dmg: int, radius: float) -> void:
	for e in get_tree().get_nodes_in_group("enemy"):
		if not (e is Node2D):
			continue
		var en := e as Node2D
		if en.global_position.distance_to(global_position) > radius * 1.06:
			continue
		var hp_val := float(e.get("hp"))
		var max_hp_val := float(e.get("max_hp"))
		if max_hp_val <= 0.1:
			continue
		if hp_val / max_hp_val <= 0.35 and e.has_method("take_damage"):
			e.take_damage(int(round(float(dmg) * 0.92)))
