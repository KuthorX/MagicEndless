extends CharacterBody2D

signal stats_changed(hp: float, max_hp: float, sp: float, max_sp: float, bullet_mode: String, dash_cd: float, grenade_cd: float, shield_on: bool)
signal message_sent(text: String)
signal sfx_event(name: String)
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
const ArcaneFxScript := preload("res://scripts/magic_arcane_fx.gd")
const NovaFxScript := preload("res://scripts/magic_nova_fx.gd")

enum BulletMode {
	NORMAL,
	PIERCE,
	BURST
}

const BULLET_MODE_LABEL := {
	BulletMode.NORMAL: "mode_normal",
	BulletMode.PIERCE: "mode_pierce",
	BulletMode.BURST: "mode_burst"
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
var sword_echo_chance := 0.0
var dash_impact_damage := 0
var dash_impact_radius := 64.0
var bullet_mode := BulletMode.NORMAL

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
var _dead := false

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
	if Input.is_action_just_pressed("switch_bullet"):
		bullet_mode = (bullet_mode + 1) % 3
		message_sent.emit(Loc.t("msg_mode_switch") % _bullet_mode_name())
		sfx_event.emit("mode_switch")

func _handle_attacks() -> void:
	if _sword_cd_left <= 0.0:
		_sword_cd_left = BASE_SWORD_CD * sword_cd_mul
		_do_sword_sweep()

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and _shot_cd_left <= 0.0:
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
	var sweep := sword_scene.instantiate()
	get_tree().current_scene.add_child(sweep)
	sweep.global_position = global_position
	sweep.setup(sword_damage, sword_radius, sword_speed_mul)
	if _rng.randf() < sword_echo_chance:
		var echo := sword_scene.instantiate()
		get_tree().current_scene.add_child(echo)
		echo.global_position = global_position
		echo.setup(int(round(float(sword_damage) * 0.65)), sword_radius * 0.85, sword_speed_mul * 1.1)

func _shoot_projectile() -> void:
	if projectile_scene == null:
		return
	var to_mouse_vec: Vector2 = get_global_mouse_position() - global_position
	var to_mouse: Vector2 = to_mouse_vec.normalized()
	if to_mouse.length() < 0.001:
		to_mouse = _fallback_aim_dir()
	match bullet_mode:
		BulletMode.NORMAL:
			_spawn_projectile(to_mouse, shot_pierce_bonus)
		BulletMode.PIERCE:
			_spawn_projectile(to_mouse, 2 + shot_pierce_bonus)
		BulletMode.BURST:
			_spawn_projectile(to_mouse.rotated(deg_to_rad(8)), shot_pierce_bonus)
			_spawn_projectile(to_mouse, shot_pierce_bonus)
			_spawn_projectile(to_mouse.rotated(deg_to_rad(-8)), shot_pierce_bonus)
	_spawn_multishot(to_mouse)

func _spawn_projectile(dir: Vector2, pierce: int) -> void:
	var p := projectile_scene.instantiate()
	get_tree().current_scene.add_child(p)
	p.global_position = global_position
	p.setup(dir, shot_speed, shot_damage, true, pierce)

func _spawn_multishot(base_dir: Vector2) -> void:
	if shot_multishot_add <= 0:
		return
	for i in range(shot_multishot_add):
		var layer: int = i + 1
		var ang: float = 6.0 * float(layer)
		_spawn_projectile(base_dir.rotated(deg_to_rad(ang)), shot_pierce_bonus)
		_spawn_projectile(base_dir.rotated(deg_to_rad(-ang)), shot_pierce_bonus)

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
	g.setup(to_mouse * speed, grenade_damage, grenade_radius)

func _fallback_aim_dir() -> Vector2:
	if velocity.length() > 0.01:
		return velocity.normalized()
	return Vector2.RIGHT

func _bullet_mode_name() -> String:
	var key: String = str(BULLET_MODE_LABEL.get(bullet_mode, "mode_normal"))
	return Loc.t(key)

func _current_shot_mode_cd_mul() -> float:
	match bullet_mode:
		BulletMode.NORMAL:
			return shot_cd_normal_mul
		BulletMode.PIERCE:
			return shot_cd_pierce_mul
		BulletMode.BURST:
			return shot_cd_burst_mul
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
	_emit_stats()

func _handle_magic(delta: float) -> void:
	if _arcane_bolt_unlocked:
		_arcane_cd -= delta
		if _arcane_cd <= 0.0:
			_arcane_cd = maxf(0.35, (2.1 - 0.12 * _magic_power_mul) / _magic_haste_mul)
			_fire_arcane_bolt()
	if _frost_nova_unlocked:
		_frost_cd -= delta
		if _frost_cd <= 0.0:
			_frost_cd = maxf(3.2, (10.0 - 0.3 * _magic_power_mul) / _magic_haste_mul)
			_cast_frost_nova()

func _fire_arcane_bolt() -> void:
	var target: Node2D = _nearest_enemy(620.0)
	if target == null:
		return
	_spawn_arcane_fx(target.global_position)
	if target.has_method("take_damage"):
		var dmg := int(round(22.0 * _magic_power_mul))
		target.take_damage(dmg)

func _cast_frost_nova() -> void:
	var radius := 170.0
	var dmg := int(round(18.0 * _magic_power_mul))
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

func _spawn_arcane_fx(end_pos: Vector2) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var fx := Node2D.new()
	fx.set_script(ArcaneFxScript)
	scene.add_child(fx)
	fx.setup(global_position, end_pos)

func _spawn_nova_fx(radius: float) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var fx := Node2D.new()
	fx.set_script(NovaFxScript)
	scene.add_child(fx)
	fx.setup(global_position, radius)
