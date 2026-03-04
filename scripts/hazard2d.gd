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
var _wave_level := 1

# Hazard network state
var _link_scan_cd := 0.0
var _linked_hazards: Array[Node] = []
var _chain_emit_cd := 0.0
var _chain_lock_t := 0.0
var _reaction_t := 0.0

# Decay/re-ignition state
var _decay_level := 0.0
var _reignite_boost_t := 0.0

@onready var poly: Polygon2D = $Polygon2D

func _ready() -> void:
	add_to_group("hazard")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_update_visual()

func configure_for_wave(wave: int) -> void:
	_wave_level = maxi(1, wave)
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
	_chain_emit_cd = 0.0
	_chain_lock_t = 0.0
	_reaction_t = 0.0
	_update_visual()

func set_hazard_kind(kind: int) -> void:
	_hazard_kind = clampi(kind, TYPE_FIRE, TYPE_STORM)
	_update_visual()

func get_hazard_kind() -> int:
	return _hazard_kind

func is_hazard_active() -> bool:
	return _active

func _process(delta: float) -> void:
	if not _gameplay_active:
		return
	_update_network_links(delta)
	_chain_emit_cd = maxf(0.0, _chain_emit_cd - delta)
	_chain_lock_t = maxf(0.0, _chain_lock_t - delta)
	_reaction_t = maxf(0.0, _reaction_t - delta)
	_reignite_boost_t = maxf(0.0, _reignite_boost_t - delta)
	_update_decay_state(delta)

	_pulse_t += delta
	_tick -= delta
	var period := maxf(0.9, pulse_period - (_reignite_boost_t * 0.16))
	var phase := fmod(_pulse_t, period)
	var active_window := _effective_active_time(period)
	var active_now := phase < active_window
	if active_now != _active:
		_active = active_now
		if _active:
			_emit_chain_pulse()
		_update_visual()
	if _active and _tick <= 0.0:
		_tick = 0.35
		if _player_inside:
			var player := get_tree().get_first_node_in_group("player")
			if player != null and player.has_method("take_damage"):
				var dmg_mul := _hazard_damage_multiplier()
				match _hazard_kind:
					TYPE_FIRE:
						player.take_damage(int(round(float(tick_damage) * dmg_mul)))
					TYPE_FROST:
						player.take_damage(int(round(float(tick_damage) * 0.75 * dmg_mul)))
						if player.has_method("drain_sp"):
							player.drain_sp(3.0)
					TYPE_VOID:
						player.take_damage(int(round(float(tick_damage) * 0.9 * dmg_mul)))
						if player.has_method("drain_sp"):
							player.drain_sp(8.0)
					TYPE_STORM:
						player.take_damage(int(round(float(tick_damage) * 0.6 * dmg_mul)))
				if _reaction_t > 0.0:
					player.take_damage(int(round((2.0 + float(_wave_level) * 0.16) * dmg_mul)))
					if player.has_method("drain_sp"):
						player.drain_sp(2.5 + float(_wave_level) * 0.08)
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
	var dmg_mul := _hazard_damage_multiplier()
	for e in _enemy_inside:
		if not is_instance_valid(e):
			continue
		match _hazard_kind:
			TYPE_FIRE:
				if e.has_method("take_damage"):
					e.take_damage(int(round(float(tick_damage) * 0.45 * dmg_mul)))
				if e.has_method("consume_status_stack"):
					var stacks: int = int(e.consume_status_stack("hex_mark"))
					if stacks > 0 and e.has_method("take_damage"):
						e.take_damage(int(round(float(tick_damage) * (0.7 + 0.35 * float(stacks)) * dmg_mul)))
			TYPE_FROST:
				if e.has_method("take_damage"):
					e.take_damage(int(round(float(tick_damage) * 0.22 * dmg_mul)))
				if e.has_method("apply_status"):
					e.apply_status("chill", 2.2, 1)
			TYPE_VOID:
				if e is Node2D and e.has_method("apply_impulse"):
					var dir := (global_position - (e as Node2D).global_position).normalized()
					e.apply_impulse(dir * 160.0)
				if e.has_method("take_damage"):
					var vdmg := int(round(float(tick_damage) * 0.30 * dmg_mul))
					if e.has_method("has_status") and e.has_status("hex_mark"):
						vdmg = int(round(float(vdmg) * 1.45))
					e.take_damage(vdmg)
			TYPE_STORM:
				if e.has_method("take_damage"):
					var sdmg := int(round(float(tick_damage) * 0.4 * dmg_mul))
					if e.has_method("consume_status_stack"):
						var c: int = int(e.consume_status_stack("chill"))
						if c > 0:
							sdmg = int(round(float(sdmg) * (1.35 + 0.22 * float(c))))
					e.take_damage(sdmg)
		if _reaction_t > 0.0 and e.has_method("take_damage"):
			e.take_damage(int(round((1.0 + float(_wave_level) * 0.08) * dmg_mul)))
			if e.has_method("apply_status"):
				e.apply_status("burn", 1.3, 1)

func _update_network_links(delta: float) -> void:
	_link_scan_cd -= delta
	if _link_scan_cd > 0.0:
		return
	_link_scan_cd = 0.45 + randf() * 0.20
	_linked_hazards.clear()
	for h in get_tree().get_nodes_in_group("hazard"):
		if h == self:
			continue
		if not is_instance_valid(h):
			continue
		if not (h is Node2D):
			continue
		if global_position.distance_to((h as Node2D).global_position) > 220.0:
			continue
		_linked_hazards.append(h)

func _emit_chain_pulse() -> void:
	if _chain_emit_cd > 0.0 or _chain_lock_t > 0.0:
		return
	_chain_emit_cd = 0.95
	for h in _linked_hazards:
		if not is_instance_valid(h):
			continue
		if h.has_method("receive_chain_pulse"):
			h.receive_chain_pulse(_hazard_kind, 1.0)

func receive_chain_pulse(source_kind: int, power: float = 1.0) -> void:
	if not _gameplay_active:
		return
	_chain_lock_t = maxf(_chain_lock_t, 0.35)
	_pulse_t = 0.0
	_tick = minf(_tick, 0.06)
	_decay_level = maxf(0.0, _decay_level - (0.45 * power))
	_reignite_boost_t = maxf(_reignite_boost_t, 1.1 + 0.45 * power)
	if _is_shockburn_pair(source_kind, _hazard_kind):
		_reaction_t = maxf(_reaction_t, 2.0 + 0.4 * power)
	_update_visual()

func _is_shockburn_pair(a: int, b: int) -> bool:
	return (a == TYPE_FIRE and b == TYPE_STORM) or (a == TYPE_STORM and b == TYPE_FIRE)

func _update_decay_state(delta: float) -> void:
	if _active:
		_decay_level = maxf(0.0, _decay_level - delta * 0.16)
	else:
		_decay_level = minf(1.0, _decay_level + delta * 0.07)

func _hazard_damage_multiplier() -> float:
	var mul := 1.0
	if _decay_level > 0.72:
		mul *= 0.64
	elif _decay_level > 0.45:
		mul *= 0.82
	if _reignite_boost_t > 0.0:
		mul *= 1.14
	if _reaction_t > 0.0:
		mul *= 1.10
	return clampf(mul, 0.55, 1.35)

func _effective_active_time(period: float) -> float:
	var t := active_time
	if _decay_level > 0.72:
		t *= 0.58
	elif _decay_level > 0.45:
		t *= 0.78
	if _reignite_boost_t > 0.0:
		t *= 1.14
	return clampf(t, 0.30, period * 0.9)

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
	if _decay_level > 0.72:
		idle = idle.darkened(0.36)
		active = active.darkened(0.22)
	elif _decay_level > 0.45:
		idle = idle.darkened(0.22)
		active = active.darkened(0.12)
	if _reignite_boost_t > 0.0:
		idle = idle.lightened(0.10)
		active = active.lightened(0.14)
	if _reaction_t > 0.0:
		active = active.lerp(Color(1.0, 0.62, 0.24, 0.82), 0.55)
	poly.color = active if _active else idle
