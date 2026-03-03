extends Area2D

var velocity := Vector2.ZERO
var damage := 12
var _life := 2.2

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func setup(dir: Vector2, speed: float, dmg: int) -> void:
	velocity = dir.normalized() * speed
	damage = dmg

func _physics_process(delta: float) -> void:
	global_position += velocity * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
	elif body.is_in_group("world"):
		queue_free()

func _on_area_entered(_area: Area2D) -> void:
	queue_free()
