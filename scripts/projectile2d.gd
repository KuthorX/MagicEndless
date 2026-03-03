extends Area2D

var velocity := Vector2.ZERO
var damage := 12
var from_player := true
var pierce_left := 0
var _life := 1.6
var _trail: Array[Vector2] = []

func _ready() -> void:
	z_index = 60
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func setup(dir: Vector2, speed: float, dmg: int, is_player: bool, pierce: int = 0) -> void:
	velocity = dir.normalized() * speed
	damage = dmg
	from_player = is_player
	pierce_left = pierce

func _physics_process(delta: float) -> void:
	_trail.append(global_position)
	if _trail.size() > 12:
		_trail.pop_front()
	global_position += velocity * delta
	_life -= delta
	queue_redraw()
	if _life <= 0.0:
		queue_free()

func _draw() -> void:
	for i in range(_trail.size() - 1):
		var t: float = float(i + 1) / float(_trail.size())
		var a := to_local(_trail[i])
		var b := to_local(_trail[i + 1])
		var c := Color(0.44, 0.88, 1.0, 0.20 + 0.65 * t)
		draw_line(a, b, c, 2.6)
	draw_circle(Vector2.ZERO, 5.5, Color(0.36, 0.84, 1.0, 0.45))
	draw_circle(Vector2.ZERO, 3.8, Color(0.72, 0.96, 1.0, 1.0))

func _on_body_entered(body: Node) -> void:
	if from_player:
		if body.is_in_group("enemy") and body.has_method("take_damage"):
			body.take_damage(damage)
			var scene := get_tree().current_scene
			if scene != null and scene.has_method("play_sfx"):
				scene.play_sfx("hit")
			var player := get_tree().get_first_node_in_group("player")
			if player != null and player.has_method("on_dealt_damage"):
				player.on_dealt_damage(float(damage))
			if pierce_left > 0:
				pierce_left -= 1
			else:
				queue_free()
		elif body.is_in_group("world"):
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
