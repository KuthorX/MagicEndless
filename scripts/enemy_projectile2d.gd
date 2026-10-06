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
	# An indigo ink drop with a tapering tail, a paper fleck at its heart so it reads at speed.
	for i in range(_trail.size() - 1):
		var t := float(i + 1) / float(_trail.size())
		draw_line(to_local(_trail[i]), to_local(_trail[i + 1]), Ink.INDIGO, lerpf(0.8, 5.0, t))
	draw_circle(Vector2.ZERO, 5.6, Ink.INDIGO_DEEP)
	draw_circle(Vector2(1.2, -1.2), 1.7, Ink.PAPER_LIGHT)

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
