extends Node2D

var velocity := Vector2.ZERO
var damage := 52
var radius := 95.0
var _fuse := 1.1
var _exploded := false
var _explosion_t := 0.0
var _trail: Array[Vector2] = []
var knockback_force := 360.0
var cluster_count := 0
var cluster_damage_mul := 0.35
var cluster_radius_mul := 0.46

func setup(v: Vector2, dmg: int, r: float, c_count: int = 0, c_dmg_mul: float = 0.35, c_radius_mul: float = 0.46) -> void:
	velocity = v
	damage = dmg
	radius = r
	cluster_count = maxi(0, c_count)
	cluster_damage_mul = clampf(c_dmg_mul, 0.10, 0.80)
	cluster_radius_mul = clampf(c_radius_mul, 0.20, 0.80)

func _physics_process(delta: float) -> void:
	if _exploded:
		_explosion_t -= delta
		queue_redraw()
		if _explosion_t <= 0.0:
			queue_free()
		return

	global_position += velocity * delta
	velocity = velocity.move_toward(Vector2.ZERO, 340.0 * delta)
	_record_trail()
	_fuse -= delta
	queue_redraw()
	if _fuse <= 0.0:
		_explode()

func _draw() -> void:
	if _exploded:
		var a := clampf(_explosion_t / 0.25, 0.0, 1.0)
		draw_circle(Vector2.ZERO, radius * (1.0 + (1.0 - a) * 0.25), Color(1.0, 0.62, 0.28, 0.16 * a))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 72, Color(1.0, 0.88, 0.42, 0.95 * a), 3.0)
		return

	for i in range(_trail.size()):
		var p: Vector2 = to_local(_trail[i])
		var t: float = float(i + 1) / float(_trail.size())
		draw_circle(p, 2.0 + t * 1.6, Color(1.0, 0.82, 0.35, 0.20 * t))

	draw_circle(Vector2.ZERO, 7.0, Color(0.20, 0.24, 0.30, 1.0))
	draw_circle(Vector2(2.5, -2.0), 2.2, Color(0.95, 0.66, 0.18, 0.95))

func _record_trail() -> void:
	_trail.append(global_position)
	if _trail.size() > 12:
		_trail.pop_front()

func _explode() -> void:
	_exploded = true
	_explosion_t = 0.25
	velocity = Vector2.ZERO
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy is Node2D:
			var dist: float = ((enemy as Node2D).global_position - global_position).length()
			if dist <= radius and enemy.has_method("take_damage"):
				enemy.take_damage(damage)
				if enemy.has_method("apply_impulse"):
					var dir := ((enemy as Node2D).global_position - global_position).normalized()
					enemy.apply_impulse(dir * knockback_force)
				var player := get_tree().get_first_node_in_group("player")
				if player != null and player.has_method("on_dealt_damage"):
					player.on_dealt_damage(float(damage))
	_apply_cluster_payload()
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("play_sfx"):
		scene.play_sfx("grenade_explode")
	queue_redraw()

func _apply_cluster_payload() -> void:
	if cluster_count <= 0:
		return
	var player := get_tree().get_first_node_in_group("player")
	var c_damage := maxi(1, int(round(float(damage) * cluster_damage_mul)))
	var c_radius := maxf(22.0, radius * cluster_radius_mul)
	for i in cluster_count:
		var a := TAU * float(i) / float(maxi(1, cluster_count))
		var pos := global_position + Vector2(cos(a), sin(a)) * (radius * 0.40)
		for enemy in get_tree().get_nodes_in_group("enemy"):
			if not (enemy is Node2D):
				continue
			var d := ((enemy as Node2D).global_position - pos).length()
			if d > c_radius:
				continue
			if enemy.has_method("take_damage"):
				enemy.take_damage(c_damage)
			if enemy.has_method("apply_impulse"):
				var dir := ((enemy as Node2D).global_position - pos).normalized()
				enemy.apply_impulse(dir * knockback_force * 0.55)
			if player != null and player.has_method("on_dealt_damage"):
				player.on_dealt_damage(float(c_damage))
