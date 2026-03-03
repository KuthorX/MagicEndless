extends CharacterBody2D

signal stats_changed(hp: float, max_hp: float, sp: float, max_sp: float, bullet_mode: String, dash_cd: float, grenade_cd: float, shield_on: bool)
signal message_sent(text: String)

const BASE_MOVE_SPEED := 220.0
const BASE_SWORD_CD := 0.55
const BASE_SHOT_CD := 0.18
const BASE_DASH_CD := 2.4
const BASE_GRENADE_CD := 3.5
const DASH_DURATION := 0.18
const DASH_SPEED := 620.0

enum BulletMode {
	NORMAL,
	PIERCE,
	BURST
}

const BULLET_MODE_LABEL := {
	BulletMode.NORMAL: "Normal",
	BulletMode.PIERCE: "Pierce",
	BulletMode.BURST: "Burst"
}

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
var grenade_damage := 52
var grenade_radius := 95.0
var grenade_cd_mul := 1.0
var dash_cd_mul := 1.0
var dash_speed_bonus := 0.0
var dash_distance_mul := 1.0
var shield_drain_mul := 1.0
var shield_regen_mul := 1.0
var lifesteal_ratio := 0.0
var bullet_mode := BulletMode.NORMAL

var _dash_cd_left := 0.0
var _grenade_cd_left := 0.0
var _sword_cd_left := 0.0
var _shot_cd_left := 0.0
var _dash_left := 0.0
var _dash_dir := Vector2.ZERO
var _shield_fx_phase := 0.0

func _ready() -> void:
	add_to_group("player")
	_emit_stats()

func _process(delta: float) -> void:
	_update_cooldowns(delta)
	_handle_modes_input()
	_handle_attacks()
	_handle_shield(delta)
	_shield_fx_phase += delta * 5.2
	queue_redraw()
	_emit_stats()

func _physics_process(delta: float) -> void:
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
			message_sent.emit("Dash")
	move_and_slide()

func _draw() -> void:
	if not shield_active:
		return
	var pulse := 0.84 + 0.16 * sin(_shield_fx_phase)
	var outer_r := 22.0 + 1.8 * sin(_shield_fx_phase * 1.2)
	var inner_r := 15.0 + 1.0 * sin(_shield_fx_phase * 1.7)
	draw_arc(Vector2.ZERO, outer_r, 0.0, TAU, 48, Color(0.46, 0.82, 1.0, 0.78 * pulse), 3.0)
	draw_arc(Vector2.ZERO, inner_r, 0.0, TAU, 48, Color(0.70, 0.94, 1.0, 0.58 * pulse), 2.0)
	draw_circle(Vector2.ZERO, 7.0, Color(0.82, 0.98, 1.0, 0.22 * pulse))

func take_damage(amount: int) -> void:
	if shield_active and sp > 0.5:
		sp = maxf(0.0, sp - 10.0)
		return
	hp -= amount
	if hp <= 0.0:
		hp = max_hp
		global_position = Vector2.ZERO
		message_sent.emit("Respawned")

func heal(amount: float) -> void:
	hp = minf(max_hp, hp + amount)

func restore_sp(amount: float) -> void:
	sp = minf(max_sp, sp + amount)

func on_dealt_damage(amount: float) -> void:
	if lifesteal_ratio <= 0.0:
		return
	heal(amount * lifesteal_ratio)

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
			"dash_cd_mul":
				dash_cd_mul *= float(value)
			"dash_speed_add":
				dash_speed_bonus += float(value)
			"dash_distance_mul":
				dash_distance_mul *= float(value)
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
	_emit_stats()

func _update_cooldowns(delta: float) -> void:
	_dash_cd_left = maxf(0.0, _dash_cd_left - delta)
	_grenade_cd_left = maxf(0.0, _grenade_cd_left - delta)
	_sword_cd_left = maxf(0.0, _sword_cd_left - delta)
	_shot_cd_left = maxf(0.0, _shot_cd_left - delta)

func _handle_modes_input() -> void:
	if Input.is_action_just_pressed("switch_bullet"):
		bullet_mode = (bullet_mode + 1) % 3
		message_sent.emit("Bullet Mode: %s" % _bullet_mode_name())

func _handle_attacks() -> void:
	if _sword_cd_left <= 0.0:
		_sword_cd_left = BASE_SWORD_CD * sword_cd_mul
		_do_sword_sweep()

	if Input.is_action_pressed("attack_primary") and _shot_cd_left <= 0.0:
		_shot_cd_left = BASE_SHOT_CD * shot_cd_mul
		_shoot_projectile()

	if Input.is_action_just_pressed("throw_grenade") and _grenade_cd_left <= 0.0:
		_grenade_cd_left = BASE_GRENADE_CD * grenade_cd_mul
		_throw_grenade()
		message_sent.emit("Grenade Thrown")

func _handle_shield(delta: float) -> void:
	if Input.is_action_pressed("shield") and sp > 0.0:
		shield_active = true
		sp = maxf(0.0, sp - 24.0 * shield_drain_mul * delta)
	else:
		shield_active = false
		sp = minf(max_sp, sp + 12.0 * shield_regen_mul * delta)

func _do_sword_sweep() -> void:
	if sword_scene == null:
		return
	var sweep := sword_scene.instantiate()
	get_tree().current_scene.add_child(sweep)
	sweep.global_position = global_position
	sweep.setup(sword_damage, sword_radius, sword_speed_mul)

func _shoot_projectile() -> void:
	if projectile_scene == null:
		return
	var to_mouse_vec: Vector2 = get_global_mouse_position() - global_position
	var to_mouse: Vector2 = to_mouse_vec.normalized()
	if to_mouse.length() < 0.001:
		to_mouse = _fallback_aim_dir()
	match bullet_mode:
		BulletMode.NORMAL:
			_spawn_projectile(to_mouse, 0)
		BulletMode.PIERCE:
			_spawn_projectile(to_mouse, 2)
		BulletMode.BURST:
			_spawn_projectile(to_mouse.rotated(deg_to_rad(8)), 0)
			_spawn_projectile(to_mouse, 0)
			_spawn_projectile(to_mouse.rotated(deg_to_rad(-8)), 0)

func _spawn_projectile(dir: Vector2, pierce: int) -> void:
	var p := projectile_scene.instantiate()
	get_tree().current_scene.add_child(p)
	p.global_position = global_position
	p.setup(dir, shot_speed, shot_damage, true, pierce)

func _throw_grenade() -> void:
	if grenade_scene == null:
		return
	var to_mouse_vec: Vector2 = get_global_mouse_position() - global_position
	var to_mouse: Vector2 = to_mouse_vec.normalized()
	if to_mouse.length() < 0.001:
		to_mouse = _fallback_aim_dir()
	var g := grenade_scene.instantiate()
	get_tree().current_scene.add_child(g)
	g.global_position = global_position
	g.setup(to_mouse * 280.0, grenade_damage, grenade_radius)

func _fallback_aim_dir() -> Vector2:
	if velocity.length() > 0.01:
		return velocity.normalized()
	return Vector2.RIGHT

func _bullet_mode_name() -> String:
	return str(BULLET_MODE_LABEL.get(bullet_mode, "Normal"))

func _emit_stats() -> void:
	stats_changed.emit(hp, max_hp, sp, max_sp, _bullet_mode_name(), _dash_cd_left, _grenade_cd_left, shield_active)
