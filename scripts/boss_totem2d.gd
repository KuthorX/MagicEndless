extends StaticBody2D
signal died(score_value: int)

@export var projectile_scene: PackedScene
@export var target_path: NodePath

var max_hp := 120
var hp := 120
var life_left := 12.0
var shoot_cd := 0.7
var windup := 0.0
var _target: Node2D

@onready var poly: Polygon2D = $Polygon2D

func _ready() -> void:
	add_to_group("enemy")
	if target_path != NodePath():
		_target = get_node_or_null(target_path) as Node2D

func set_target(node: Node2D) -> void:
	_target = node

func configure_for_wave(wave: int) -> void:
	max_hp = 90 + wave * 18
	hp = max_hp

func _process(delta: float) -> void:
	life_left -= delta
	if life_left <= 0.0:
		queue_free()
		return
	if _target == null:
		return
	if windup > 0.0:
		windup -= delta
		if windup <= 0.0:
			_shoot_at_target()
	else:
		shoot_cd -= delta
		if shoot_cd <= 0.0:
			shoot_cd = 1.8
			windup = 0.45
	queue_redraw()

func _draw() -> void:
	if windup <= 0.0 or _target == null:
		return
	var dir := (_target.global_position - global_position).normalized()
	var p0 := Vector2.ZERO
	var p1 := to_local(global_position + dir * 300.0)
	draw_line(p0, p1, Color(1.0, 0.75, 0.26, 0.75), 2.0)
	draw_arc(p0, 22.0, 0.0, TAU, 28, Color(1.0, 0.75, 0.26, 0.65), 2.0)

func _shoot_at_target() -> void:
	if projectile_scene == null or _target == null:
		return
	var dir := (_target.global_position - global_position).normalized()
	var b := projectile_scene.instantiate()
	get_tree().current_scene.add_child(b)
	if b is Node2D:
		(b as Node2D).global_position = global_position
	b.setup(dir, 310.0, 16, 8)
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("play_sfx"):
		scene.play_sfx("enemy_shoot")

func take_damage(amount: int) -> void:
	hp -= amount
	if hp <= 0:
		died.emit(22)
		queue_free()
