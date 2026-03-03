extends Area2D

var velocity := Vector2.ZERO
var damage := 12
var sp_burn := 0
var _life := 2.2
var _trail: Array[Vector2] = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func setup(dir: Vector2, speed: float, dmg: int, shield_burn: int = 0) -> void:
	velocity = dir.normalized() * speed
	damage = dmg
	sp_burn = shield_burn

func _physics_process(delta: float) -> void:
	_trail.append(global_position)
	if _trail.size() > 10:
		_trail.pop_front()
	global_position += velocity * delta
	_life -= delta
	queue_redraw()
	if _life <= 0.0:
		queue_free()

func _draw() -> void:
	for i in range(_trail.size() - 1):
		var t := float(i + 1) / float(_trail.size())
		var a := to_local(_trail[i])
		var b := to_local(_trail[i + 1])
		draw_line(a, b, Color(0.50, 1.00, 0.56, 0.26 + 0.70 * t), 2.8)
	draw_circle(Vector2.ZERO, 6.5, Color(0.40, 1.0, 0.46, 0.42))
	draw_circle(Vector2.ZERO, 4.6, Color(0.64, 1.0, 0.68, 1.0))

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
		if sp_burn > 0 and body.has_method("drain_sp"):
			body.drain_sp(float(sp_burn))
		queue_free()
	elif body.is_in_group("world"):
		queue_free()

func _on_area_entered(_area: Area2D) -> void:
	queue_free()
