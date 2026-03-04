extends Area2D
const CombatFxScript := preload("res://scripts/combat_fx2d.gd")
const ProjectileScene := preload("res://scenes/projectile2d.tscn")

var velocity := Vector2.ZERO
var damage := 12
var from_player := true
var pierce_left := 0
var _life := 1.6
var _trail: Array[Vector2] = []
var _ricochet_left := 0
var _explosion_radius := 0.0
var _homing_strength := 0.0
var _chain_left := 0
var _trail_color := Color(0.44, 0.88, 1.0, 0.85)
var _core_color := Color(0.72, 0.96, 1.0, 1.0)
var _glow_color := Color(0.36, 0.84, 1.0, 0.45)
var _status_name := ""
var _status_duration := 0.0
var _status_stacks := 1
var _damage_mul := 1.0
var _augment_overheat := false
var _overheat_tick_damage_mul := 0.0
var _overheat_ticks := 0
var _overheat_tick_interval := 0.25
var _augment_phase_prism := false
var _phase_prism_splits_left := 0
var _last_pos := Vector2.ZERO

func _ready() -> void:
	z_index = 60
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	_last_pos = global_position

func setup(dir: Vector2, speed: float, dmg: int, is_player: bool, pierce: int = 0, profile: Dictionary = {}) -> void:
	velocity = dir.normalized() * speed
	damage = dmg
	from_player = is_player
	pierce_left = pierce
	_ricochet_left = int(profile.get("ricochet", 0))
	_explosion_radius = float(profile.get("explosion_radius", 0.0))
	_homing_strength = float(profile.get("homing", 0.0))
	_chain_left = int(profile.get("chain", 0))
	_status_name = str(profile.get("apply_status", ""))
	_status_duration = float(profile.get("status_duration", 0.0))
	_status_stacks = int(profile.get("status_stacks", 1))
	_damage_mul = float(profile.get("damage_mul", 1.0))
	_augment_overheat = bool(profile.get("augment_overheat", false))
	_overheat_tick_damage_mul = float(profile.get("overheat_tick_damage_mul", 0.0))
	_overheat_ticks = int(profile.get("overheat_ticks", 0))
	_overheat_tick_interval = float(profile.get("overheat_tick_interval", 0.25))
	_augment_phase_prism = bool(profile.get("augment_phase_prism", false))
	_phase_prism_splits_left = int(profile.get("phase_prism_splits", 0))
	_life *= float(profile.get("life_mul", 1.0))
	if profile.has("trail_color"):
		_trail_color = Color(profile["trail_color"])
	if profile.has("core_color"):
		_core_color = Color(profile["core_color"])
	if profile.has("glow_color"):
		_glow_color = Color(profile["glow_color"])

func _physics_process(delta: float) -> void:
	if from_player and _homing_strength > 0.0:
		_apply_homing(delta)
	_last_pos = global_position
	_trail.append(global_position)
	if _trail.size() > 12:
		_trail.pop_front()
	global_position += velocity * delta
	if from_player and _augment_phase_prism:
		_try_phase_prism_split()
	_life -= delta
	queue_redraw()
	if _life <= 0.0:
		queue_free()

func _draw() -> void:
	for i in range(_trail.size() - 1):
		var t: float = float(i + 1) / float(_trail.size())
		var a := to_local(_trail[i])
		var b := to_local(_trail[i + 1])
		var c := Color(_trail_color.r, _trail_color.g, _trail_color.b, 0.20 + 0.65 * t)
		draw_line(a, b, c, 2.6)
	draw_circle(Vector2.ZERO, 5.5, _glow_color)
	draw_circle(Vector2.ZERO, 3.8, _core_color)

func _on_body_entered(body: Node) -> void:
	if from_player:
		if body.is_in_group("enemy") and body.has_method("take_damage"):
			_hit_enemy(body)
		elif body.is_in_group("world"):
			if not _try_ricochet(null):
				queue_free()
	else:
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(damage)
			queue_free()
		elif body.is_in_group("world"):
			queue_free()

func _on_area_entered(area: Area2D) -> void:
	if from_player:
		# Player bullets ignore generic areas (hazards/telegraphs/etc), only bodies handle hit.
		return
	queue_free()

func _hit_enemy(enemy: Node) -> void:
	var hit_damage := int(round(float(damage) * _damage_mul))
	enemy.take_damage(maxi(1, hit_damage))
	_spawn_hex_hit_fx(global_position)
	if _status_name != "" and _status_duration > 0.0 and enemy.has_method("apply_status"):
		enemy.apply_status(_status_name, _status_duration, _status_stacks)
	if _augment_overheat and _overheat_ticks > 0 and _overheat_tick_damage_mul > 0.0:
		_apply_overheat(enemy, hit_damage)
	_notify_player_damage(hit_damage)
	_play_hit_sfx()
	if _explosion_radius > 1.0:
		_apply_explosion(enemy)
	if _chain_left > 0:
		_apply_chain(enemy)
	var keep_flying := false
	if pierce_left > 0:
		pierce_left -= 1
		keep_flying = true
	if _try_ricochet(enemy):
		keep_flying = true
	if not keep_flying:
		queue_free()

func _apply_homing(delta: float) -> void:
	var target := _nearest_enemy(520.0, [])
	if target == null:
		return
	var desired := (target.global_position - global_position).normalized()
	var speed := velocity.length()
	if speed < 0.1:
		return
	var steer := clampf(delta * (2.2 + _homing_strength * 1.8), 0.0, 1.0)
	var next_dir := velocity.normalized().lerp(desired, steer).normalized()
	velocity = next_dir * speed

func _apply_explosion(primary: Node) -> void:
	_spawn_hex_blast_fx(global_position, _explosion_radius)
	for e in get_tree().get_nodes_in_group("enemy"):
		if not (e is Node2D):
			continue
		if e == primary:
			continue
		var en := e as Node2D
		if en.global_position.distance_to(global_position) <= _explosion_radius and e.has_method("take_damage"):
			var splash := int(round(float(damage) * _damage_mul * 0.55))
			e.take_damage(splash)
			_notify_player_damage(splash)

func _apply_chain(primary: Node) -> void:
	var origin := global_position
	var exclude: Array[Node] = [primary]
	var jumps := _chain_left
	while jumps > 0:
		var target := _nearest_enemy(280.0, exclude, origin)
		if target == null:
			return
		_spawn_chain_arc_fx(origin, target.global_position)
		var d := int(round(float(damage) * _damage_mul * (0.60 + 0.08 * float(jumps - 1))))
		if target.has_method("take_damage"):
			target.take_damage(d)
		_notify_player_damage(d)
		exclude.append(target)
		origin = target.global_position
		jumps -= 1

func _try_ricochet(hit_enemy: Node) -> bool:
	if _ricochet_left <= 0:
		return false
	var exclude: Array[Node] = []
	if hit_enemy != null:
		exclude.append(hit_enemy)
	var target := _nearest_enemy(460.0, exclude)
	if target == null:
		velocity = -velocity
	else:
		var speed := maxf(220.0, velocity.length())
		velocity = (target.global_position - global_position).normalized() * speed
	_ricochet_left -= 1
	return true

func _nearest_enemy(radius: float, excluded: Array[Node], origin: Vector2 = Vector2.INF) -> Node2D:
	var from := global_position
	if origin != Vector2.INF:
		from = origin
	var best: Node2D = null
	var best_d := radius
	for e in get_tree().get_nodes_in_group("enemy"):
		if not (e is Node2D):
			continue
		if excluded.has(e):
			continue
		var en := e as Node2D
		var d := en.global_position.distance_to(from)
		if d < best_d:
			best_d = d
			best = en
	return best

func _notify_player_damage(amount: int) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player != null and player.has_method("on_dealt_damage"):
		player.on_dealt_damage(float(amount))

func _play_hit_sfx() -> void:
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("play_sfx"):
		scene.play_sfx("hit")

func _apply_overheat(enemy: Node, base_damage: int) -> void:
	_apply_overheat_tick(enemy, int(round(float(base_damage) * _overheat_tick_damage_mul)), _overheat_ticks)

func _apply_overheat_tick(enemy: Node, tick_damage: int, ticks_left: int) -> void:
	if ticks_left <= 0:
		return
	var timer := get_tree().create_timer(_overheat_tick_interval)
	timer.timeout.connect(func() -> void:
		if not is_instance_valid(enemy):
			return
		if enemy.has_method("take_damage"):
			enemy.take_damage(maxi(1, tick_damage))
			_notify_player_damage(maxi(1, tick_damage))
		_apply_overheat_tick(enemy, tick_damage, ticks_left - 1)
	)

func _try_phase_prism_split() -> void:
	if _phase_prism_splits_left <= 0:
		return
	var crossed := false
	for h in get_tree().get_nodes_in_group("hazard"):
		if not (h is Node2D):
			continue
		var center := (h as Node2D).global_position
		var d_prev := _last_pos.distance_to(center)
		var d_now := global_position.distance_to(center)
		if d_prev > 78.0 and d_now <= 78.0:
			crossed = true
			break
	if not crossed:
		return
	_phase_prism_splits_left -= 1
	var dir := velocity.normalized()
	var speed := velocity.length()
	_spawn_phase_prism_child(dir.rotated(deg_to_rad(16.0)), speed)
	_spawn_phase_prism_child(dir.rotated(deg_to_rad(-16.0)), speed)

func _spawn_phase_prism_child(dir: Vector2, speed: float) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var p: Node = ProjectileScene.instantiate()
	scene.add_child(p)
	if p is Node2D:
		(p as Node2D).global_position = global_position
	if p.has_method("setup"):
		p.setup(dir, speed * 0.92, int(round(float(damage) * 0.58)), from_player, maxi(0, pierce_left - 1), {
			"life_mul": _life / 1.6,
			"ricochet": 0,
			"damage_mul": _damage_mul,
			"augment_overheat": _augment_overheat,
			"overheat_tick_damage_mul": _overheat_tick_damage_mul,
			"overheat_ticks": maxi(1, _overheat_ticks - 1),
			"overheat_tick_interval": _overheat_tick_interval,
			"augment_phase_prism": false,
			"phase_prism_splits": 0
		})

func _spawn_hex_hit_fx(pos: Vector2) -> void:
	if _status_name != "hex_mark":
		return
	var scene := get_tree().current_scene
	if scene == null:
		return
	var fx := Node2D.new()
	fx.set_script(CombatFxScript)
	scene.add_child(fx)
	fx.setup_hex_hit(pos, 18.0)

func _spawn_hex_blast_fx(pos: Vector2, radius: float) -> void:
	if _status_name != "hex_mark":
		return
	var scene := get_tree().current_scene
	if scene == null:
		return
	var fx := Node2D.new()
	fx.set_script(CombatFxScript)
	scene.add_child(fx)
	fx.setup_hex_blast(pos, maxf(26.0, radius))

func _spawn_chain_arc_fx(from: Vector2, to: Vector2) -> void:
	if _status_name != "hex_mark":
		return
	var scene := get_tree().current_scene
	if scene == null:
		return
	var fx := Node2D.new()
	fx.set_script(CombatFxScript)
	scene.add_child(fx)
	fx.setup_chain_arc(from, to)
