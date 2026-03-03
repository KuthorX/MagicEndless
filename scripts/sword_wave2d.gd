extends Area2D

var damage := 28
var radius := 74.0
var speed_mul := 1.0
var _life := 0.18
var _life_max := 0.18
var _hit_map := {}
var _anim_t := 0.0

@onready var shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	var c := shape.shape as CircleShape2D
	if c != null:
		c.radius = radius

func setup(dmg: int, r: float, speed: float = 1.0) -> void:
	damage = dmg
	radius = r
	speed_mul = clampf(speed, 0.5, 3.0)
	_life_max = 0.18 / speed_mul
	_life = _life_max

func _process(delta: float) -> void:
	_life -= delta
	_anim_t += delta * 10.5 * speed_mul
	rotation += delta * 16.0 * speed_mul
	queue_redraw()
	if _life <= 0.0:
		queue_free()

func _draw() -> void:
	var alpha := clampf(_life / _life_max, 0.0, 1.0)
	var ring_color := Color(0.45, 0.92, 1.0, 0.34 * alpha)
	var core_color := Color(0.88, 1.0, 1.0, 0.52 * alpha)
	var wedge_color := Color(0.62, 0.95, 1.0, 0.30 * alpha)

	draw_arc(Vector2.ZERO, radius, 0, TAU, 72, ring_color, 4.0)
	draw_arc(Vector2.ZERO, radius * 0.78, 0, TAU, 72, core_color, 2.0)
	draw_circle(Vector2.ZERO, 8.0, Color(0.85, 1.0, 1.0, 0.45 * alpha))

	var start_a := _anim_t
	var end_a := _anim_t + deg_to_rad(85.0)
	var pts := _sector_points(Vector2.ZERO, radius * 1.04, start_a, end_a, 14)
	draw_colored_polygon(pts, wedge_color)

func _sector_points(center: Vector2, r: float, from_a: float, to_a: float, seg: int) -> PackedVector2Array:
	var arr := PackedVector2Array()
	arr.append(center)
	for i in range(seg + 1):
		var t := float(i) / float(seg)
		var a := lerpf(from_a, to_a, t)
		arr.append(center + Vector2(cos(a), sin(a)) * r)
	return arr

func _apply_damage(target: Node) -> void:
	if _hit_map.has(target):
		return
	_hit_map[target] = true
	if target.has_method("take_damage"):
		target.take_damage(damage)
		var player := get_tree().get_first_node_in_group("player")
		if player != null and player.has_method("on_dealt_damage"):
			player.on_dealt_damage(float(damage))

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy"):
		_apply_damage(body)

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy"):
		_apply_damage(area)
