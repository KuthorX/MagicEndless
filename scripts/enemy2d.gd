extends CharacterBody2D
signal died(score_value: int)

const TYPE_CHASER := 0
const TYPE_SHOOTER := 1
const TYPE_DASHER := 2
const TYPE_SNIPER := 3
const TYPE_ARTILLERY := 4
const ARENA_RECT := Rect2(-790.0, -430.0, 1580.0, 860.0)

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

var _attack_windup := 0.0
var _attack_windup_total := 0.0
var _pending_attack := ""
var _telegraph_dir := Vector2.RIGHT

@onready var body_poly: Polygon2D = $Body
@onready var muzzle: Marker2D = $Muzzle

func _ready() -> void:
	add_to_group("enemy")

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
	projectile_scene = proj_scene
	match enemy_type:
		TYPE_CHASER:
			max_hp = 52.0 + wave * 10.0
			move_speed = 118.0 + wave * 3.0
			contact_damage = 9 + int(wave * 0.8)
			lunge_cd = 2.0
			body_poly.color = Color(0.93, 0.30, 0.23)
		TYPE_SHOOTER:
			max_hp = 44.0 + wave * 8.0
			move_speed = 82.0 + wave * 1.8
			contact_damage = 6 + int(wave * 0.5)
			shoot_cd = 0.7
			body_poly.color = Color(0.27, 0.86, 0.36)
		TYPE_DASHER:
			max_hp = 66.0 + wave * 10.5
			move_speed = 104.0 + wave * 2.2
			contact_damage = 10 + int(wave * 0.8)
			dash_cd = 1.4
			body_poly.color = Color(0.56, 0.40, 0.98)
		TYPE_SNIPER:
			max_hp = 52.0 + wave * 8.0
			move_speed = 78.0 + wave * 1.5
			contact_damage = 8 + int(wave * 0.6)
			shoot_cd = 0.9
			body_poly.color = Color(0.95, 0.90, 0.28)
		TYPE_ARTILLERY:
			max_hp = 70.0 + wave * 10.0
			move_speed = 62.0 + wave * 1.2
			contact_damage = 10 + int(wave * 0.7)
			shoot_cd = 1.2
			body_poly.color = Color(1.0, 0.54, 0.28)
	hp = max_hp

func apply_elite_mod(mod: Dictionary) -> void:
	max_hp *= float(mod.get("hp_mul", 1.0))
	hp = max_hp
	move_speed *= float(mod.get("speed_mul", 1.0))
	contact_damage = int(contact_damage * float(mod.get("dmg_mul", 1.0)))
	var target_color := Color(mod.get("color", body_poly.color))
	body_poly.color = body_poly.color.lerp(target_color, 0.55)
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

	if _attack_windup > 0.0:
		_attack_windup -= delta
		velocity = _seek_with_distance(to_target, dir, 280.0) * 0.25
		if _attack_windup <= 0.0:
			_execute_pending_attack()
	else:
		match enemy_type:
			TYPE_CHASER:
				velocity = dir * move_speed
				lunge_cd -= delta
				if lunge_cd <= 0.0:
					_begin_windup("lunge", 0.28, dir)
					lunge_cd = 2.2
			TYPE_SHOOTER:
				velocity = _seek_with_distance(to_target, dir, 220.0)
				shoot_cd -= delta
				if shoot_cd <= 0.0:
					_begin_windup("shoot", 0.24, dir)
					shoot_cd = 1.4
			TYPE_DASHER:
				dash_cd -= delta
				if dash_cd <= 0.0:
					velocity = Vector2.ZERO
					_begin_windup("dash", 0.35, dir)
					dash_cd = 2.1
				else:
					velocity = dir * move_speed * 0.9
			TYPE_SNIPER:
				velocity = _seek_with_distance(to_target, dir, 420.0)
				shoot_cd -= delta
				if shoot_cd <= 0.0:
					_begin_windup("sniper", 0.65, dir)
					shoot_cd = 2.0
			TYPE_ARTILLERY:
				velocity = _seek_with_distance(to_target, dir, 340.0)
				shoot_cd -= delta
				if shoot_cd <= 0.0:
					_begin_windup("burst", 0.8, dir)
					shoot_cd = 2.4

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
	_pending_attack = ""

func _draw() -> void:
	if _attack_windup <= 0.0 or _attack_windup_total <= 0.0:
		return
	var t := clampf(1.0 - _attack_windup / _attack_windup_total, 0.0, 1.0)
	var a := 0.35 + 0.55 * t
	var origin := Vector2.ZERO
	match _pending_attack:
		"shoot":
			_draw_telegraph_line(origin, _telegraph_dir, 220.0, Color(0.42, 0.95, 0.42, a))
			draw_arc(origin + _telegraph_dir * 220.0, 10.0, 0.0, TAU, 24, Color(0.42, 0.95, 0.42, a), 2.0)
		"sniper":
			_draw_telegraph_line(origin, _telegraph_dir, 420.0, Color(1.0, 0.92, 0.28, a))
			draw_arc(origin + _telegraph_dir * 420.0, 16.0, 0.0, TAU, 28, Color(1.0, 0.92, 0.28, a), 2.0)
		"burst":
			for ang in [-14.0, 0.0, 14.0]:
				_draw_telegraph_line(origin, _telegraph_dir.rotated(deg_to_rad(ang)), 270.0, Color(1.0, 0.56, 0.22, a))
		"dash":
			_draw_telegraph_line(origin, _telegraph_dir, 160.0, Color(0.72, 0.52, 1.0, a))
			draw_arc(origin, 22.0 + 10.0 * t, 0.0, TAU, 28, Color(0.72, 0.52, 1.0, a), 2.0)
		"lunge":
			_draw_telegraph_line(origin, _telegraph_dir, 120.0, Color(1.0, 0.36, 0.30, a))
			draw_arc(origin, 18.0 + 8.0 * t, 0.0, TAU, 24, Color(1.0, 0.36, 0.30, a), 2.0)

func _draw_telegraph_line(origin: Vector2, dir: Vector2, len: float, c: Color) -> void:
	draw_line(origin, origin + dir * len, c, 2.0)

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
	b.setup(dir, 300.0, 12 + int(contact_damage * 0.5), sp_burn)
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
	b.setup(dir, 500.0, 18 + int(contact_damage * 0.8), sp_burn)
	_play_sfx("enemy_shoot")

func _shoot_burst(dir: Vector2) -> void:
	if projectile_scene == null:
		return
	for a in [-14.0, 0.0, 14.0]:
		var shot_dir: Vector2 = dir.rotated(deg_to_rad(a))
		var from := muzzle.global_position
		var to := from + shot_dir * 160.0
		_spawn_tracer(from, to, Color(1.0, 0.63, 0.26, 0.85), 0.10, 2.2)
		var b := projectile_scene.instantiate()
		get_tree().current_scene.add_child(b)
		b.global_position = from
		var sp_burn := 0
		if elite_shield_break:
			sp_burn = 5
		b.setup(shot_dir, 240.0, 10 + int(contact_damage * 0.4), sp_burn)
	_play_sfx("enemy_shoot")

func _spawn_tracer(from: Vector2, to: Vector2, color: Color, fade: float, width: float) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var line := Line2D.new()
	line.default_color = color
	line.width = width
	line.z_index = 35
	line.points = PackedVector2Array([from, to])
	scene.add_child(line)
	var tween := line.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, fade)
	tween.finished.connect(func() -> void:
		if is_instance_valid(line):
			line.queue_free()
	)

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

func take_damage(amount: int) -> void:
	hp -= amount
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
	if elite_name != "":
		base += 8
	if _is_miniboss:
		base += 40
	return base
