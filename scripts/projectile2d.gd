extends Area2D

var velocity := Vector2.ZERO
var damage := 12
var from_player := true
var pierce_left := 0
var _life := 1.6

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func setup(dir: Vector2, speed: float, dmg: int, is_player: bool, pierce: int = 0) -> void:
	velocity = dir.normalized() * speed
	damage = dmg
	from_player = is_player
	pierce_left = pierce

func _physics_process(delta: float) -> void:
	global_position += velocity * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if from_player:
		if body.is_in_group("enemy") and body.has_method("take_damage"):
			body.take_damage(damage)
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
	if from_player and area.is_in_group("enemy"):
		return
	queue_free()
