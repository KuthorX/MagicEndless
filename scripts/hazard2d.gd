extends Area2D

@export var pulse_period := 2.8
@export var active_time := 1.1
@export var tick_damage := 7

var _pulse_t := 0.0
var _active := false
var _player_inside := false
var _tick := 0.0
var _gameplay_active := true

@onready var poly: Polygon2D = $Polygon2D

func _ready() -> void:
	add_to_group("hazard")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_update_visual()

func configure_for_wave(wave: int) -> void:
	tick_damage = int(7 + wave * 0.7)
	pulse_period = maxf(1.4, 2.8 - wave * 0.03)

func set_gameplay_active(active: bool) -> void:
	_gameplay_active = active
	_active = false
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
	if _active and _player_inside and _tick <= 0.0:
		_tick = 0.35
		var player := get_tree().get_first_node_in_group("player")
		if player != null and player.has_method("take_damage"):
			player.take_damage(tick_damage)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside = false

func _update_visual() -> void:
	if _active:
		poly.color = Color(1.0, 0.28, 0.22, 0.62)
	else:
		poly.color = Color(0.28, 0.32, 0.38, 0.35)
