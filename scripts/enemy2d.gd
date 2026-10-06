extends CharacterBody2D
signal died(score_value: int)

const TYPE_CHASER := 0
const TYPE_SHOOTER := 1
const TYPE_DASHER := 2
const TYPE_SNIPER := 3
const TYPE_ARTILLERY := 4
const TYPE_WARDEN := 5
const TYPE_WARLOCK := 6
const TYPE_BEACON := 7
const TYPE_LANCER := 8
const FACTION_LEGION := 0
const FACTION_ARCANE := 1
const FACTION_VOID := 2
const FACTION_STORM := 3
const ROLE_FRONTLINE := 0
const ROLE_SKIRMISHER := 1
const ROLE_SUPPORT := 2
const ROLE_CONTROLLER := 3
const ROLE_SIEGE := 4
const ARENA_RECT := Rect2(-790.0, -430.0, 1580.0, 860.0)
## How far an elite/mutator colour tints the base pigment (kept low so each type keeps its pigment).
const ELITE_TINT := 0.2
## Every creature is cut from the same indigo block as the title wave; its type pigment shows in its eyes.
const BODY_INK := Ink.INDIGO
const EYE_BONE := Ink.PAPER_LIGHT
## Brushed ink silhouettes, indexed by enemy type (tools/art/gen_creatures.py). Facing +x.
const CREATURE_TEX: Array[Texture2D] = [
	preload("res://assets/art/creatures/chaser.png"), preload("res://assets/art/creatures/shooter.png"),
	preload("res://assets/art/creatures/dasher.png"), preload("res://assets/art/creatures/sniper.png"),
	preload("res://assets/art/creatures/artillery.png"), preload("res://assets/art/creatures/warden.png"),
	preload("res://assets/art/creatures/warlock.png"), preload("res://assets/art/creatures/beacon.png"),
	preload("res://assets/art/creatures/lancer.png"),
]
## World size of the 128px creature sheet; a body radius of ~22 texels lands near the old 18px hull.
const CREATURE_QUAD := 104.0

var enemy_type := TYPE_CHASER
var max_hp := 60.0
var hp := 60.0
var move_speed := 110.0
var contact_damage := 10
var shoot_cd := 0.0
var dash_cd := 0.0
var lunge_cd := 0.0
var projectile_scene: PackedScene
var target: Node2D
var is_active := true
var _impulse := Vector2.ZERO

var elite_name := ""
var elite_summoner := false
var elite_splitter := false
var elite_shield_break := false
var _summon_cd := 0.0
var _is_miniboss := false
var _boss_skill_cd := 0.0
var _boss_skill_toggle := false
var _wave_level := 1
var _anim_phase := 0.0
var _shape_pulse_speed := 2.0
var _shape_pulse_amp := 0.04
var _hex_mark_t := 0.0
var _hex_mark_stack := 0
var _chill_t := 0.0
var _chill_stack := 0
var _support_cd := 0.0
var _temp_guard_t := 0.0
var _temp_guard_ratio := 0.0
var _temp_haste_t := 0.0
var _temp_haste_mul := 1.0
var _faction := FACTION_LEGION
var _role := ROLE_FRONTLINE
var _faction_scan_cd := 0.0
var _near_faction_count := 0
var _near_hazard_count := 0
var _void_step_cd := 0.0
var _role_pulse_cd := 0.0
var _siege_open_lane := false
var _faction_guard_ratio := 0.0
var _faction_time_mul := 1.0
var _projectile_speed_mul := 1.0
var _faction_break_t := 0.0
var _is_anchor := false

var _attack_windup := 0.0
var _attack_windup_total := 0.0
var _pending_attack := ""
var _telegraph_dir := Vector2.RIGHT
var _eye_pigment := Ink.CRIMSON

@onready var body_poly: Polygon2D = $Body
@onready var muzzle: Marker2D = $Muzzle

func _ready() -> void:
	add_to_group("enemy")
	body_poly.color = BODY_INK
	# The body is drawn behind this node's own _draw so eyes and telegraphs sit on top of it.
	body_poly.show_behind_parent = true

func set_target(node: Node2D) -> void:
	target = node

func set_active(active: bool) -> void:
	is_active = active
	set_physics_process(true)
	if active:
		modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		modulate = Color(0.72, 0.82, 1.0, 0.72)

func configure(kind: int, wave: int, proj_scene: PackedScene) -> void:
	enemy_type = kind
	_wave_level = wave
	projectile_scene = proj_scene
	_assign_identity_by_type()
	match enemy_type:
		TYPE_CHASER:
			max_hp = 52.0 + wave * 10.0
			move_speed = 118.0 + wave * 3.0
			contact_damage = 9 + int(wave * 0.8)
			lunge_cd = 2.0
			_eye_pigment = Ink.CRIMSON
			_shape_pulse_speed = 2.1
			_shape_pulse_amp = 0.035
		TYPE_SHOOTER:
			max_hp = 44.0 + wave * 8.0
			move_speed = 82.0 + wave * 1.8
			contact_damage = 6 + int(wave * 0.5)
			shoot_cd = 0.7
			_eye_pigment = Ink.ROKUSHO
			_shape_pulse_speed = 1.9
			_shape_pulse_amp = 0.03
		TYPE_DASHER:
			max_hp = 66.0 + wave * 10.5
			move_speed = 104.0 + wave * 2.2
			contact_damage = 10 + int(wave * 0.8)
			dash_cd = 1.4
			_eye_pigment = Ink.MURASAKI
			_shape_pulse_speed = 3.2
			_shape_pulse_amp = 0.06
		TYPE_SNIPER:
			max_hp = 52.0 + wave * 8.0
			move_speed = 78.0 + wave * 1.5
			contact_damage = 8 + int(wave * 0.6)
			shoot_cd = 0.9
			_eye_pigment = Ink.GAMBOGE
			_shape_pulse_speed = 1.4
			_shape_pulse_amp = 0.025
		TYPE_ARTILLERY:
			max_hp = 70.0 + wave * 10.0
			move_speed = 62.0 + wave * 1.2
			contact_damage = 10 + int(wave * 0.7)
			shoot_cd = 1.2
			_eye_pigment = Ink.PERSIMMON
			_shape_pulse_speed = 1.2
			_shape_pulse_amp = 0.022
		TYPE_WARDEN:
			max_hp = 86.0 + wave * 12.0
			move_speed = 76.0 + wave * 1.6
			contact_damage = 11 + int(wave * 0.85)
			shoot_cd = 1.0
			_eye_pigment = Ink.INDIGO
			_shape_pulse_speed = 1.7
			_shape_pulse_amp = 0.03
		TYPE_WARLOCK:
			max_hp = 78.0 + wave * 11.0
			move_speed = 84.0 + wave * 1.5
			contact_damage = 9 + int(wave * 0.7)
			shoot_cd = 1.2
			_eye_pigment = Ink.WISTERIA
			_shape_pulse_speed = 2.3
			_shape_pulse_amp = 0.045
		TYPE_BEACON:
			max_hp = 112.0 + wave * 13.5
			move_speed = 58.0 + wave * 1.0
			contact_damage = 8 + int(wave * 0.4)
			shoot_cd = 1.8
			_support_cd = 1.5
			_eye_pigment = Ink.AI_TEAL
			_shape_pulse_speed = 1.5
			_shape_pulse_amp = 0.03
		TYPE_LANCER:
			max_hp = 72.0 + wave * 10.2
			move_speed = 132.0 + wave * 2.4
			contact_damage = 12 + int(wave * 0.9)
			dash_cd = 1.0
			_eye_pigment = Ink.PERSIMMON.darkened(0.2)
			_shape_pulse_speed = 2.8
			_shape_pulse_amp = 0.05
	_print_creature()
	var col := $CollisionShape2D as CollisionShape2D
	if col != null and col.shape is CircleShape2D:
		var r := 16.0
		if enemy_type == TYPE_WARDEN:
			r = 18.0
		elif enemy_type == TYPE_WARLOCK:
			r = 17.0
		elif enemy_type == TYPE_BEACON:
			r = 19.0
		(col.shape as CircleShape2D).radius = r
	hp = max_hp

func apply_elite_mod(mod: Dictionary) -> void:
	max_hp *= float(mod.get("hp_mul", 1.0))
	hp = max_hp
	move_speed *= float(mod.get("speed_mul", 1.0))
	contact_damage = int(contact_damage * float(mod.get("dmg_mul", 1.0)))
	var target_color := Color(mod.get("color", body_poly.color))
	body_poly.color = body_poly.color.lerp(target_color, ELITE_TINT)
	var mod_name := str(mod.get("name", ""))
	if mod_name != "":
		if elite_name == "":
			elite_name = mod_name
		else:
			elite_name = "%s+%s" % [elite_name, mod_name]
	elite_summoner = elite_summoner or bool(mod.get("ability_summon", false))
	elite_splitter = elite_splitter or bool(mod.get("ability_split", false))
	elite_shield_break = elite_shield_break or bool(mod.get("ability_shield_break", false))
	if mod_name == "MiniBoss":
		_is_miniboss = true
		_boss_skill_cd = 3.0
	if elite_summoner and _summon_cd <= 0.0:
		_summon_cd = 4.0

func apply_impulse(imp: Vector2) -> void:
	_impulse += imp

func _physics_process(delta: float) -> void:
	if not is_active:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if target == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var to_target: Vector2 = target.global_position - global_position
	var dir: Vector2 = to_target.normalized()
	if dir.length() < 0.001:
		dir = Vector2.RIGHT
	rotation = dir.angle()
	_anim_phase += delta * _shape_pulse_speed
	_update_visual_anim()
	_update_status(delta)
	_update_faction_role_state(delta, to_target)
	_update_temporary_buffs(delta)
	var time_scale := _current_haste_mul() * _faction_time_mul

	if _attack_windup > 0.0:
		_attack_windup -= delta
		velocity = _seek_with_distance(to_target, dir, 280.0) * 0.25
		if _attack_windup <= 0.0:
			_execute_pending_attack()
	else:
		match enemy_type:
			TYPE_CHASER:
				velocity = dir * move_speed * time_scale
				lunge_cd -= delta * time_scale
				if lunge_cd <= 0.0:
					_begin_windup("lunge", 0.28, dir)
					lunge_cd = 2.2
			TYPE_SHOOTER:
				velocity = _seek_with_distance(to_target, dir, 220.0)
				shoot_cd -= delta * time_scale
				if shoot_cd <= 0.0:
					_begin_windup("shoot", 0.24, dir)
					shoot_cd = 1.4
			TYPE_DASHER:
				dash_cd -= delta * time_scale
				if dash_cd <= 0.0:
					velocity = Vector2.ZERO
					_begin_windup("dash", 0.35, dir)
					dash_cd = 2.1
				else:
					velocity = dir * move_speed * 0.9 * time_scale
			TYPE_SNIPER:
				velocity = _seek_with_distance(to_target, dir, 420.0)
				shoot_cd -= delta * time_scale
				if shoot_cd <= 0.0:
					_begin_windup("sniper", 0.65, dir)
					shoot_cd = 2.0
			TYPE_ARTILLERY:
				velocity = _seek_with_distance(to_target, dir, 340.0)
				shoot_cd -= delta * time_scale
				if shoot_cd <= 0.0:
					_begin_windup("burst", 0.8, dir)
					shoot_cd = 2.4
			TYPE_WARDEN:
				velocity = _seek_with_distance(to_target, dir, 270.0)
				shoot_cd -= delta * time_scale
				if shoot_cd <= 0.0:
					_begin_windup("fan", 0.55, dir)
					shoot_cd = 2.3
			TYPE_WARLOCK:
				velocity = _seek_with_distance(to_target, dir, 330.0)
				shoot_cd -= delta * time_scale
				if shoot_cd <= 0.0:
					if randi() % 2 == 0:
						_begin_windup("rift", 0.78, dir)
					else:
						_begin_windup("hex", 0.4, dir)
					shoot_cd = 2.7
			TYPE_BEACON:
				velocity = _seek_with_distance(to_target, dir, 300.0) * 0.7
				_support_cd -= delta * time_scale
				if _support_cd <= 0.0:
					_support_cd = 3.0
					_support_pulse()
				shoot_cd -= delta * time_scale
				if shoot_cd <= 0.0:
					_begin_windup("shoot", 0.26, dir)
					shoot_cd = 2.1
			TYPE_LANCER:
				dash_cd -= delta * time_scale
				if dash_cd <= 0.0:
					velocity = Vector2.ZERO
					_begin_windup("pierce_dash", 0.28, dir)
					dash_cd = 1.7
				else:
					velocity = dir * move_speed * 0.95 * time_scale

	if elite_summoner:
		_summon_cd -= delta
		if _summon_cd <= 0.0:
			_summon_cd = 4.5
			_request_summon()
	if _is_miniboss:
		_boss_skill_cd -= delta
		if _boss_skill_cd <= 0.0:
			_boss_skill_cd = 6.0
			if _boss_skill_toggle:
				_request_boss_barrage()
			else:
				_request_boss_totem()
			_boss_skill_toggle = not _boss_skill_toggle

	if to_target.length() < 20.0 and target.has_method("take_damage"):
		target.take_damage(contact_damage)
		if elite_shield_break and target.has_method("drain_sp"):
			target.drain_sp(6.0)

	velocity *= _status_move_mul()
	velocity += _impulse
	_impulse = _impulse.move_toward(Vector2.ZERO, 900.0 * delta)
	move_and_slide()
	_clamp_inside_arena()
	queue_redraw()

func _begin_windup(kind: String, duration: float, dir: Vector2) -> void:
	_pending_attack = kind
	_attack_windup = duration
	_attack_windup_total = duration
	_telegraph_dir = dir

func _execute_pending_attack() -> void:
	match _pending_attack:
		"shoot":
			_shoot(_telegraph_dir)
		"sniper":
			_shoot_sniper(_telegraph_dir)
		"burst":
			_shoot_burst(_telegraph_dir)
		"dash":
			_impulse += _telegraph_dir * (move_speed * 4.4)
		"lunge":
			_impulse += _telegraph_dir * (move_speed * 3.2)
		"fan":
			_shoot_fan(_telegraph_dir)
		"hex":
			_shoot_hex(_telegraph_dir)
		"rift":
			_request_void_zone()
		"pierce_dash":
			_impulse += _telegraph_dir * (move_speed * 5.1)
	_pending_attack = ""

func _draw() -> void:
	_draw_eyes()
	if _is_anchor:
		var ap := 0.72 + 0.28 * sin(_anim_phase * 2.0)
		_draw_ring(Vector2.ZERO, 25.0 + 1.5 * ap, Color(1.0, 0.86, 0.24, 0.90))
	if _faction_break_t > 0.0:
		var bp := 0.45 + 0.55 * sin(_anim_phase * 3.2)
		_draw_ring(Vector2.ZERO, 22.0, Color(1.0, 0.35, 0.35, 0.35 + 0.4 * bp))
	if _hex_mark_t > 0.0:
		var pulse := 0.65 + 0.35 * sin(_anim_phase * 2.2)
		_draw_ring(Vector2.ZERO, 22.0 + 2.0 * pulse, Color(0.92, 0.56, 1.0, 0.48 + 0.28 * pulse))
		for i in _hex_mark_stack:
			var a := TAU * float(i) / float(maxi(1, _hex_mark_stack)) + _anim_phase
			var p := Vector2(cos(a), sin(a)) * (13.0 + 2.0 * sin(_anim_phase * 1.8))
			draw_circle(p, 2.0, Color(0.96, 0.72, 1.0, 0.95))
	if _chill_t > 0.0:
		var pulse_c := 0.55 + 0.45 * sin(_anim_phase * 1.7)
		_draw_ring(Vector2.ZERO, 20.0 + 1.6 * pulse_c, Color(0.46, 0.82, 1.0, 0.42 + 0.24 * pulse_c))
	if _attack_windup <= 0.0 or _attack_windup_total <= 0.0:
		return
	var t := clampf(1.0 - _attack_windup / _attack_windup_total, 0.0, 1.0)
	var a := 0.35 + 0.55 * t
	var origin := Vector2.ZERO
	match _pending_attack:
		"shoot":
			_draw_telegraph_line(origin, _telegraph_dir, 220.0, Color(0.42, 0.95, 0.42, a))
			_draw_ring(origin + _telegraph_dir * 220.0, 10.0, Color(0.42, 0.95, 0.42, a))
		"sniper":
			_draw_telegraph_line(origin, _telegraph_dir, 420.0, Color(1.0, 0.92, 0.28, a))
			_draw_ring(origin + _telegraph_dir * 420.0, 16.0, Color(1.0, 0.92, 0.28, a))
		"burst":
			for ang in [-14.0, 0.0, 14.0]:
				_draw_telegraph_line(origin, _telegraph_dir.rotated(deg_to_rad(ang)), 270.0, Color(1.0, 0.56, 0.22, a))
		"dash":
			_draw_telegraph_line(origin, _telegraph_dir, 160.0, Color(0.72, 0.52, 1.0, a))
			_draw_ring(origin, 22.0 + 10.0 * t, Color(0.72, 0.52, 1.0, a))
		"lunge":
			_draw_telegraph_line(origin, _telegraph_dir, 120.0, Color(1.0, 0.36, 0.30, a))
			_draw_ring(origin, 18.0 + 8.0 * t, Color(1.0, 0.36, 0.30, a))
		"fan":
			for ang in [-24.0, -12.0, 0.0, 12.0, 24.0]:
				_draw_telegraph_line(origin, _telegraph_dir.rotated(deg_to_rad(ang)), 260.0, Color(0.38, 0.92, 1.0, a))
		"hex":
			_draw_telegraph_line(origin, _telegraph_dir, 260.0, Color(0.88, 0.52, 1.0, a))
			_draw_ring(origin + _telegraph_dir * 120.0, 42.0, Color(0.88, 0.52, 1.0, a))
		"rift":
			_draw_ring(origin, 54.0, Color(0.92, 0.44, 1.0, a))
			_draw_ring(origin, 86.0, Color(0.92, 0.44, 1.0, a * 0.82))
		"pierce_dash":
			_draw_telegraph_line(origin, _telegraph_dir, 220.0, Color(1.0, 0.66, 0.34, a))
			_draw_ring(origin, 20.0 + 9.0 * t, Color(1.0, 0.66, 0.34, a))

func _print_creature() -> void:
	var h := CREATURE_QUAD * 0.5
	body_poly.polygon = PackedVector2Array([Vector2(-h, -h), Vector2(h, -h), Vector2(h, h), Vector2(-h, h)])
	var tex: Texture2D = CREATURE_TEX[clampi(enemy_type, 0, CREATURE_TEX.size() - 1)]
	var ts := tex.get_size()
	body_poly.uv = PackedVector2Array([Vector2.ZERO, Vector2(ts.x, 0.0), ts, Vector2(0.0, ts.y)])
	body_poly.texture = tex

func _draw_eyes() -> void:
	var s := 1.35 if _is_miniboss else 1.0
	for side in [-1.0, 1.0]:
		var c := Vector2(6.0, 6.0 * side) * s
		draw_set_transform(c, 0.0, Vector2(1.0, 0.72))
		draw_circle(Vector2.ZERO, 4.6 * s, EYE_BONE)
		draw_set_transform(Vector2.ZERO)
		draw_circle(c + Vector2(1.6, 0.0) * s, 2.3 * s, _eye_pigment)
	draw_set_transform(Vector2.ZERO)

## Status marks and attack targets are carved rings (the enso belongs to the menu), never ruled circles.
func _draw_ring(center: Vector2, r: float, c: Color) -> void:
	Ink.carved_ring(self, center, r, Color(c.r, c.g, c.b, 1.0), 2.0)

func _draw_telegraph_line(origin: Vector2, dir: Vector2, len: float, c: Color) -> void:
	# A thin brush line that lifts toward its end; solid ink (the print has no translucency).
	var ink := Color(c.r, c.g, c.b, 1.0)
	var steps := 8
	for i in steps:
		var a := origin + dir * len * float(i) / float(steps)
		var b := origin + dir * len * float(i + 1) / float(steps)
		draw_line(a, b, ink, lerpf(3.2, 0.8, float(i) / float(steps - 1)))

func _shoot(dir: Vector2) -> void:
	if projectile_scene == null:
		return
	var from := muzzle.global_position
	var to := from + dir * 190.0
	_spawn_tracer(from, to, Color(0.52, 1.0, 0.56, 0.9), 0.12, 2.6)
	var b := projectile_scene.instantiate()
	get_tree().current_scene.add_child(b)
	b.global_position = from
	var sp_burn := 0
	if elite_shield_break:
		sp_burn = 7
	var dmg := _with_siege_damage(12 + int(contact_damage * 0.5))
	b.setup(dir, 300.0 * _projectile_speed_mul, dmg, sp_burn)
	_play_sfx("enemy_shoot")

func _shoot_sniper(dir: Vector2) -> void:
	if projectile_scene == null:
		return
	var from := muzzle.global_position
	var to := from + dir * 320.0
	_spawn_tracer(from, to, Color(1.0, 0.95, 0.32, 0.95), 0.16, 3.2)
	var b := projectile_scene.instantiate()
	get_tree().current_scene.add_child(b)
	b.global_position = from
	var sp_burn := 0
	if elite_shield_break:
		sp_burn = 12
	var dmg := _with_siege_damage(18 + int(contact_damage * 0.8))
	b.setup(dir, 500.0 * _projectile_speed_mul, dmg, sp_burn)
	_play_sfx("enemy_shoot")

func _shoot_burst(dir: Vector2) -> void:
	if projectile_scene == null:
		return
	for a in [-14.0, 0.0, 14.0]:
		var shot_dir: Vector2 = dir.rotated(deg_to_rad(a))
		var from := muzzle.global_position
		var to := from + shot_dir * 320.0
		_spawn_tracer(from, to, Color(1.0, 0.63, 0.26, 0.85), 0.10, 2.2)
		var b := projectile_scene.instantiate()
		get_tree().current_scene.add_child(b)
		b.global_position = from
		var sp_burn := 0
		if elite_shield_break:
			sp_burn = 5
		var dmg := _with_siege_damage(10 + int(contact_damage * 0.4))
		b.setup(shot_dir, 480.0 * _projectile_speed_mul, dmg, sp_burn)
	_play_sfx("enemy_shoot")

func _shoot_fan(dir: Vector2) -> void:
	if projectile_scene == null:
		return
	for ang in [-24.0, -12.0, 0.0, 12.0, 24.0]:
		var shot_dir := dir.rotated(deg_to_rad(ang))
		var from := muzzle.global_position
		var to := from + shot_dir * 260.0
		_spawn_tracer(from, to, Color(0.36, 0.95, 1.0, 0.88), 0.11, 2.4)
		var b := projectile_scene.instantiate()
		get_tree().current_scene.add_child(b)
		b.global_position = from
		var dmg := _with_siege_damage(10 + int(contact_damage * 0.45))
		b.setup(shot_dir, 360.0 * _projectile_speed_mul, dmg, 3)
	_play_sfx("enemy_shoot")

func _shoot_hex(dir: Vector2) -> void:
	if projectile_scene == null:
		return
	var from := muzzle.global_position
	var to := from + dir * 250.0
	_spawn_tracer(from, to, Color(0.92, 0.52, 1.0, 0.9), 0.15, 3.0)
	var b := projectile_scene.instantiate()
	get_tree().current_scene.add_child(b)
	b.global_position = from
	var dmg := _with_siege_damage(14 + int(contact_damage * 0.62))
	b.setup(dir, 300.0 * _projectile_speed_mul, dmg, 8)
	_play_sfx("enemy_shoot")

func _spawn_tracer(from: Vector2, to: Vector2, color: Color, fade: float, width: float) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var line := Line2D.new()
	line.default_color = color
	line.width = width
	# No z_index: items with their own z escape the battle's print CanvasGroup; tree order layers them.
	line.points = PackedVector2Array([from, to])
	scene.add_child(line)
	var tween := line.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, fade)
	tween.finished.connect(Callable(self, "_on_tracer_tween_finished").bind(line))

func _on_tracer_tween_finished(line: Line2D) -> void:
	if is_instance_valid(line):
		line.queue_free()

func _request_summon() -> void:
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("request_elite_summon"):
		scene.request_elite_summon(global_position)

func _request_boss_totem() -> void:
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("request_spawn_totem"):
		scene.request_spawn_totem(global_position)

func _request_boss_barrage() -> void:
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("request_bullet_hell"):
		scene.request_bullet_hell(global_position)

func _request_void_zone() -> void:
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("request_void_zone"):
		scene.request_void_zone(global_position, _wave_level)

func apply_status(status_name: String, duration: float, stacks: int = 1) -> void:
	if status_name == "hex_mark":
		_hex_mark_t = maxf(_hex_mark_t, duration)
		_hex_mark_stack = mini(4, _hex_mark_stack + maxi(1, stacks))
	elif status_name == "chill":
		_chill_t = maxf(_chill_t, duration)
		_chill_stack = mini(5, _chill_stack + maxi(1, stacks))

func apply_temporary_boost(guard_ratio: float, haste_mul: float, duration: float) -> void:
	_temp_guard_ratio = maxf(_temp_guard_ratio, guard_ratio)
	_temp_guard_t = maxf(_temp_guard_t, duration)
	_temp_haste_mul = maxf(_temp_haste_mul, haste_mul)
	_temp_haste_t = maxf(_temp_haste_t, duration)

func has_status(status_name: String) -> bool:
	if status_name == "hex_mark":
		return _hex_mark_t > 0.0 and _hex_mark_stack > 0
	if status_name == "chill":
		return _chill_t > 0.0 and _chill_stack > 0
	return false

func consume_status_stack(status_name: String) -> int:
	match status_name:
		"hex_mark":
			if _hex_mark_stack <= 0:
				return 0
			var s := _hex_mark_stack
			_hex_mark_stack = 0
			_hex_mark_t = 0.0
			return s
		"chill":
			if _chill_stack <= 0:
				return 0
			var c := _chill_stack
			_chill_stack = 0
			_chill_t = 0.0
			return c
	return 0

func take_damage(amount: int) -> void:
	var final := amount
	var guard_ratio := _faction_guard_ratio
	if _temp_guard_t > 0.0:
		guard_ratio = maxf(guard_ratio, _temp_guard_ratio)
	if guard_ratio > 0.0:
		final = int(round(float(amount) * (1.0 - guard_ratio)))
	hp -= maxi(1, final)
	if hp <= 0.0:
		died.emit(_score_value())
		if elite_splitter:
			var scene := get_tree().current_scene
			if scene != null and scene.has_method("request_split_spawn"):
				scene.request_split_spawn(global_position)
		queue_free()

func _play_sfx(name: String) -> void:
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("play_sfx"):
		scene.play_sfx(name)

func _seek_with_distance(to_target: Vector2, dir: Vector2, desired: float) -> Vector2:
	var d := to_target.length()
	if d > desired + 24.0:
		return dir * move_speed
	if d < desired - 24.0:
		return -dir * move_speed * 0.9
	return Vector2.ZERO

func _clamp_inside_arena() -> void:
	global_position.x = clampf(global_position.x, ARENA_RECT.position.x + 10.0, ARENA_RECT.end.x - 10.0)
	global_position.y = clampf(global_position.y, ARENA_RECT.position.y + 10.0, ARENA_RECT.end.y - 10.0)

func _score_value() -> int:
	var base := 10
	match enemy_type:
		TYPE_CHASER:
			base = 10
		TYPE_SHOOTER:
			base = 12
		TYPE_DASHER:
			base = 14
		TYPE_SNIPER:
			base = 16
		TYPE_ARTILLERY:
			base = 18
		TYPE_WARDEN:
			base = 22
		TYPE_WARLOCK:
			base = 25
		TYPE_BEACON:
			base = 27
		TYPE_LANCER:
			base = 24
	if elite_name != "":
		base += 8
	if _is_miniboss:
		base += 40
	return base

func _update_visual_anim() -> void:
	var pulse := 1.0 + sin(_anim_phase) * _shape_pulse_amp
	body_poly.scale = Vector2.ONE * pulse
	match enemy_type:
		TYPE_DASHER:
			muzzle.position = Vector2(18.0 + 2.0 * sin(_anim_phase * 2.2), 0.0)
		TYPE_SNIPER:
			muzzle.position = Vector2(20.0 + 1.8 * sin(_anim_phase * 1.6), 0.0)
		TYPE_WARLOCK:
			muzzle.position = Vector2(18.0 + 1.4 * sin(_anim_phase * 2.8), 2.0 * sin(_anim_phase))
		TYPE_BEACON:
			muzzle.position = Vector2(17.0 + 1.2 * sin(_anim_phase * 1.4), 0.0)
		TYPE_LANCER:
			muzzle.position = Vector2(20.0 + 1.6 * sin(_anim_phase * 2.6), 0.0)
		_:
			muzzle.position = Vector2(18.0, 0.0)

func _update_status(delta: float) -> void:
	if _hex_mark_t > 0.0:
		_hex_mark_t = maxf(0.0, _hex_mark_t - delta)
		if _hex_mark_t <= 0.0:
			_hex_mark_stack = 0
	if _chill_t > 0.0:
		_chill_t = maxf(0.0, _chill_t - delta)
		if _chill_t <= 0.0:
			_chill_stack = 0
	if _faction_break_t > 0.0:
		_faction_break_t = maxf(0.0, _faction_break_t - delta)

func _update_temporary_buffs(delta: float) -> void:
	if _temp_guard_t > 0.0:
		_temp_guard_t = maxf(0.0, _temp_guard_t - delta)
		if _temp_guard_t <= 0.0:
			_temp_guard_ratio = 0.0
	if _temp_haste_t > 0.0:
		_temp_haste_t = maxf(0.0, _temp_haste_t - delta)
		if _temp_haste_t <= 0.0:
			_temp_haste_mul = 1.0

func _current_haste_mul() -> float:
	if _temp_haste_t > 0.0:
		return _temp_haste_mul
	return 1.0

func _status_move_mul() -> float:
	if _chill_t <= 0.0 or _chill_stack <= 0:
		return 1.0
	return clampf(1.0 - 0.12 * float(_chill_stack), 0.52, 1.0)

func _support_pulse() -> void:
	_play_sfx("enemy_shoot")
	var radius := 230.0
	for e in get_tree().get_nodes_in_group("enemy"):
		if e == self:
			continue
		if not (e is Node2D):
			continue
		var en := e as Node2D
		if en.global_position.distance_to(global_position) > radius:
			continue
		if e.has_method("apply_temporary_boost"):
			e.apply_temporary_boost(0.20, 1.16, 2.8)
	_role_support_link()

func _assign_identity_by_type() -> void:
	_faction = FACTION_LEGION
	_role = ROLE_FRONTLINE
	match enemy_type:
		TYPE_CHASER:
			_faction = FACTION_LEGION
			_role = ROLE_FRONTLINE
		TYPE_SHOOTER:
			_faction = FACTION_LEGION
			_role = ROLE_SKIRMISHER
		TYPE_DASHER:
			_faction = FACTION_STORM
			_role = ROLE_SKIRMISHER
		TYPE_SNIPER:
			_faction = FACTION_ARCANE
			_role = ROLE_SIEGE
		TYPE_ARTILLERY:
			_faction = FACTION_ARCANE
			_role = ROLE_SIEGE
		TYPE_WARDEN:
			_faction = FACTION_LEGION
			_role = ROLE_FRONTLINE
		TYPE_WARLOCK:
			_faction = FACTION_VOID
			_role = ROLE_CONTROLLER
		TYPE_BEACON:
			_faction = FACTION_ARCANE
			_role = ROLE_SUPPORT
		TYPE_LANCER:
			_faction = FACTION_STORM
			_role = ROLE_FRONTLINE
	_void_step_cd = 1.5 + randf() * 1.5
	_role_pulse_cd = 0.8 + randf() * 0.9

func _update_faction_role_state(delta: float, to_target: Vector2) -> void:
	_faction_scan_cd -= delta
	if _faction_scan_cd <= 0.0:
		_faction_scan_cd = 0.40 + randf() * 0.24
		_scan_local_ecology()
		_apply_faction_effects()
	if _faction == FACTION_VOID:
		_void_step_cd -= delta
		if _void_step_cd <= 0.0 and to_target.length() > 110.0 and to_target.length() < 430.0:
			_try_void_step(to_target)
	if _role == ROLE_SUPPORT:
		_role_pulse_cd -= delta
		if _role_pulse_cd <= 0.0:
			_role_pulse_cd = 2.6 + randf() * 0.8
			_role_support_link()
	elif _role == ROLE_CONTROLLER:
		_role_pulse_cd -= delta
		if _role_pulse_cd <= 0.0:
			_role_pulse_cd = 3.1 + randf() * 1.0
			_role_zone_push()
	if _role == ROLE_SIEGE:
		_update_siege_open_lane()
	else:
		_siege_open_lane = false

func _scan_local_ecology() -> void:
	_near_faction_count = 0
	_near_hazard_count = 0
	for n in get_tree().get_nodes_in_group("enemy"):
		if n == self:
			continue
		if not is_instance_valid(n):
			continue
		if not (n is Node2D):
			continue
		if (n as Node2D).global_position.distance_to(global_position) > 240.0:
			continue
		if n.has_method("get_faction"):
			var fac: int = int(n.get_faction())
			if fac == _faction:
				_near_faction_count += 1
	for hz in get_tree().get_nodes_in_group("hazard"):
		if not is_instance_valid(hz):
			continue
		if not (hz is Node2D):
			continue
		if (hz as Node2D).global_position.distance_to(global_position) <= 210.0:
			_near_hazard_count += 1

func _apply_faction_effects() -> void:
	_faction_guard_ratio = 0.0
	_faction_time_mul = 1.0
	_projectile_speed_mul = 1.0
	match _faction:
		FACTION_LEGION:
			_faction_guard_ratio += minf(0.20, 0.04 * float(_near_faction_count))
		FACTION_ARCANE:
			_projectile_speed_mul *= 1.08 + minf(0.14, 0.02 * float(_near_faction_count))
			_faction_time_mul *= 1.02
		FACTION_VOID:
			_faction_time_mul *= 1.06 + minf(0.10, 0.025 * float(_near_hazard_count))
			_faction_guard_ratio += minf(0.16, 0.04 * float(_near_hazard_count))
		FACTION_STORM:
			_faction_time_mul *= 1.06 + minf(0.16, 0.03 * float(maxi(0, 4 - _near_faction_count)))
			_projectile_speed_mul *= 1.05
	match _role:
		ROLE_FRONTLINE:
			_faction_guard_ratio += 0.06
		ROLE_SKIRMISHER:
			_faction_time_mul *= 1.06
		ROLE_SUPPORT:
			_faction_guard_ratio += minf(0.12, 0.03 * float(_near_faction_count))
		ROLE_CONTROLLER:
			_projectile_speed_mul *= 1.07
		ROLE_SIEGE:
			if _siege_open_lane:
				_projectile_speed_mul *= 1.15
	if _faction_break_t > 0.0:
		var ratio := clampf(_faction_break_t / 8.0, 0.25, 1.0)
		_faction_guard_ratio *= 0.35
		_faction_time_mul = lerpf(_faction_time_mul, 0.86, ratio)
		_projectile_speed_mul = lerpf(_projectile_speed_mul, 0.88, ratio)
	_faction_guard_ratio = clampf(_faction_guard_ratio, 0.0, 0.45)
	_faction_time_mul = clampf(_faction_time_mul, 0.85, 1.34)
	_projectile_speed_mul = clampf(_projectile_speed_mul, 0.88, 1.45)

func _try_void_step(to_target: Vector2) -> void:
	_void_step_cd = 2.8 - minf(0.9, 0.20 * float(_near_hazard_count))
	var d: float = to_target.length()
	var dir: Vector2 = to_target.normalized()
	var side: Vector2 = dir.rotated(PI * 0.5 if randf() < 0.5 else -PI * 0.5)
	var offset: Vector2 = (-dir * minf(140.0, d * 0.42)) + side * randf_range(-80.0, 80.0)
	var next: Vector2 = global_position + offset
	next = Vector2(
		clampf(next.x, ARENA_RECT.position.x + 24.0, ARENA_RECT.end.x - 24.0),
		clampf(next.y, ARENA_RECT.position.y + 24.0, ARENA_RECT.end.y - 24.0)
	)
	_spawn_tracer(global_position, next, Color(0.86, 0.46, 1.0, 0.78), 0.18, 2.2)
	global_position = next

func _role_support_link() -> void:
	var linked := 0
	for n in get_tree().get_nodes_in_group("enemy"):
		if n == self:
			continue
		if not is_instance_valid(n):
			continue
		if not (n is Node2D):
			continue
		var en: Node2D = n as Node2D
		if en.global_position.distance_to(global_position) > 250.0:
			continue
		if n.has_method("apply_temporary_boost"):
			n.apply_temporary_boost(0.12, 1.08, 1.8)
			linked += 1
			if linked >= 5:
				break

func _role_zone_push() -> void:
	if _faction_break_t > 0.0:
		return
	var scene: Node = get_tree().current_scene
	if scene == null:
		return
	if not scene.has_method("request_control_zone"):
		return
	var zone_pos := global_position
	if target != null:
		var dir: Vector2 = (target.global_position - global_position).normalized()
		if dir.length() > 0.01:
			zone_pos += dir * 80.0
	scene.request_control_zone(zone_pos, _wave_level)

func _update_siege_open_lane() -> void:
	if target == null:
		_siege_open_lane = false
		return
	var aim: Vector2 = (target.global_position - global_position).normalized()
	if aim.length() < 0.001:
		_siege_open_lane = false
		return
	var blockers := 0
	for n in get_tree().get_nodes_in_group("enemy"):
		if n == self:
			continue
		if not is_instance_valid(n):
			continue
		if not (n is Node2D):
			continue
		var rel: Vector2 = (n as Node2D).global_position - global_position
		var dist := rel.length()
		if dist < 36.0 or dist > 220.0:
			continue
		var angle := absf(aim.angle_to(rel.normalized()))
		if angle < 0.32:
			blockers += 1
			if blockers >= 2:
				break
	_siege_open_lane = blockers < 2

func _with_siege_damage(base_damage: int) -> int:
	if _role == ROLE_SIEGE and _siege_open_lane:
		return int(round(float(base_damage) * 1.22))
	return base_damage

func set_anchor(active: bool) -> void:
	_is_anchor = active

func apply_faction_break(duration: float) -> void:
	_faction_break_t = maxf(_faction_break_t, duration)

func get_faction() -> int:
	return _faction

func get_role() -> int:
	return _role
