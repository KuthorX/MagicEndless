extends CharacterBody2D

const TYPE_CHASER := 0
const TYPE_SHOOTER := 1
const TYPE_DASHER := 2

var enemy_type := TYPE_CHASER
var max_hp := 60.0
var hp := 60.0
var move_speed := 110.0
var contact_damage := 10
var shoot_cd := 0.0
var dash_cd := 0.0
var projectile_scene: PackedScene
var target: Node2D
var is_active := true

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
	hp = max_hp

func apply_elite_mod(mod: Dictionary) -> void:
	max_hp *= float(mod.get("hp_mul", 1.0))
	hp = max_hp
	move_speed *= float(mod.get("speed_mul", 1.0))
	contact_damage = int(contact_damage * float(mod.get("dmg_mul", 1.0)))
	body_poly.color = mod.get("color", body_poly.color)

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
	rotation = dir.angle()

	match enemy_type:
		TYPE_CHASER:
			velocity = dir * move_speed
		TYPE_SHOOTER:
			velocity = dir * move_speed * 0.5
			shoot_cd -= delta
			if shoot_cd <= 0.0:
				shoot_cd = 1.4
				_shoot(dir)
		TYPE_DASHER:
			dash_cd -= delta
			if dash_cd <= 0.0:
				dash_cd = 2.1
				velocity = dir * (move_speed * 3.2)
			else:
				velocity = dir * move_speed * 0.9

	if to_target.length() < 20.0 and target.has_method("take_damage"):
		target.take_damage(contact_damage)

	move_and_slide()

func _shoot(dir: Vector2) -> void:
	if projectile_scene == null:
		return
	var b := projectile_scene.instantiate()
	get_tree().current_scene.add_child(b)
	b.global_position = muzzle.global_position
	b.setup(dir, 300.0, 12 + int(contact_damage * 0.5))

func take_damage(amount: int) -> void:
	hp -= amount
	if hp <= 0.0:
		queue_free()
