extends Area2D

const TYPE_FIRE := 0
const TYPE_FROST := 1
const TYPE_VOID := 2
const TYPE_STORM := 3

@export var pulse_period := 2.8
@export var active_time := 1.1
@export var tick_damage := 7

var _pulse_t := 0.0
var _active := false
var _player_inside := false
var _tick := 0.0
var _gameplay_active := true
var _hazard_kind := TYPE_FIRE
var _enemy_inside: Array[Node] = []

@onready var poly: Polygon2D = $Polygon2D

func _ready() -> void:
	add_to_group("hazard")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_update_visual()

func configure_for_wave(wave: int) -> void:
	var base_damage := int(7 + wave * 0.7)
	match _hazard_kind:
		TYPE_FIRE:
			tick_damage = base_damage + 2
			pulse_period = maxf(1.2, 2.7 - wave * 0.035)
		TYPE_FROST:
			tick_damage = base_damage
			pulse_period = maxf(1.3, 2.6 - wave * 0.03)
		TYPE_VOID:
			tick_damage = base_damage + 1
			pulse_period = maxf(1.1, 2.4 - wave * 0.04)
		TYPE_STORM:
			tick_damage = base_damage - 1
			pulse_period = maxf(1.0, 2.2 - wave * 0.03)

func set_gameplay_active(active: bool) -> void:
	_gameplay_active = active
	_active = false
	_update_visual()

func set_hazard_kind(kind: int) -> void:
	_hazard_kind = clampi(kind, TYPE_FIRE, TYPE_STORM)
	_update_visual()

func _process(delta: float) -> void:
	if not _gameplay_active:
		return
	_pulse_t += delta
	_tick -= delta
	var phase := fmod(_pulse_t, pulse_period)
	var active_now := phase < active_time
	if active_now != _active:
		_active = active_now
		_update_visual()
	if _active and _tick <= 0.0:
		_tick = 0.35
		if _player_inside:
			var player := get_tree().get_first_node_in_group("player")
			if player != null and player.has_method("take_damage"):
				match _hazard_kind:
					TYPE_FIRE:
						player.take_damage(tick_damage)
					TYPE_FROST:
						player.take_damage(int(round(float(tick_damage) * 0.75)))
						if player.has_method("drain_sp"):
							player.drain_sp(3.0)
					TYPE_VOID:
						player.take_damage(int(round(float(tick_damage) * 0.9)))
						if player.has_method("drain_sp"):
							player.drain_sp(8.0)
					TYPE_STORM:
						player.take_damage(int(round(float(tick_damage) * 0.6)))
		_apply_enemy_hazard_effects()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside = true
	elif body.is_in_group("enemy"):
		if not _enemy_inside.has(body):
			_enemy_inside.append(body)

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside = false
	elif body.is_in_group("enemy"):
		_enemy_inside.erase(body)

func _apply_enemy_hazard_effects() -> void:
	for e in _enemy_inside:
		if not is_instance_valid(e):
			continue
		match _hazard_kind:
			TYPE_FIRE:
				if e.has_method("take_damage"):
					e.take_damage(int(round(float(tick_damage) * 0.45)))
				if e.has_method("consume_status_stack"):
					var stacks: int = int(e.consume_status_stack("hex_mark"))
					if stacks > 0 and e.has_method("take_damage"):
						e.take_damage(int(round(float(tick_damage) * (0.7 + 0.35 * float(stacks)))))
			TYPE_FROST:
				if e.has_method("take_damage"):
					e.take_damage(int(round(float(tick_damage) * 0.22)))
				if e.has_method("apply_status"):
					e.apply_status("chill", 2.2, 1)
			TYPE_VOID:
				if e is Node2D and e.has_method("apply_impulse"):
					var dir := (global_position - (e as Node2D).global_position).normalized()
					e.apply_impulse(dir * 160.0)
				if e.has_method("take_damage"):
					var vdmg := int(round(float(tick_damage) * 0.30))
					if e.has_method("has_status") and e.has_status("hex_mark"):
						vdmg = int(round(float(vdmg) * 1.45))
					e.take_damage(vdmg)
			TYPE_STORM:
				if e.has_method("take_damage"):
					var sdmg := int(round(float(tick_damage) * 0.4))
					if e.has_method("consume_status_stack"):
						var c: int = int(e.consume_status_stack("chill"))
						if c > 0:
							sdmg = int(round(float(sdmg) * (1.35 + 0.22 * float(c))))
					e.take_damage(sdmg)

func _update_visual() -> void:
	var idle := Color(0.28, 0.32, 0.38, 0.35)
	var active := Color(1.0, 0.28, 0.22, 0.62)
	match _hazard_kind:
		TYPE_FIRE:
			idle = Color(0.38, 0.26, 0.22, 0.35)
			active = Color(1.0, 0.32, 0.22, 0.64)
		TYPE_FROST:
			idle = Color(0.24, 0.31, 0.40, 0.35)
			active = Color(0.34, 0.78, 1.0, 0.62)
		TYPE_VOID:
			idle = Color(0.30, 0.22, 0.35, 0.35)
			active = Color(0.80, 0.36, 1.0, 0.62)
		TYPE_STORM:
			idle = Color(0.24, 0.29, 0.34, 0.35)
			active = Color(1.0, 0.92, 0.36, 0.62)
	poly.color = active if _active else idle
