extends Area2D

var damage := 28
var radius := 74.0
var speed_mul := 1.0
var _life := 0.18
var _life_max := 0.18
var _hit_map := {}
var _anim_t := 0.0

const ENSO_TEX := preload("res://assets/art/enso.png")
## The enso ring sits at 0.40 of its texture; scale so the ink lands on the hit radius.
const ENSO_OVERSCAN := 1.25

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
	# The light sword is one vermilion enso, spun by the node's rotation: a single brush sweep.
	var r := radius * ENSO_OVERSCAN
	draw_texture_rect(ENSO_TEX, Rect2(-r, -r, r * 2.0, r * 2.0), false, Ink.wash(Ink.VERMILION, alpha))

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
