extends Node2D

const FX_HEX_HIT := "hex_hit"
const FX_HEX_BLAST := "hex_blast"
const FX_CHAIN_ARC := "chain_arc"
const FX_METEOR_FALL := "meteor_fall"
const FX_METEOR_IMPACT := "meteor_impact"

var _fx_type := FX_HEX_HIT
var _life := 0.25
var _max_life := 0.25
var _radius := 26.0
var _start := Vector2.ZERO
var _end := Vector2.ZERO
var _seed := 0.0

func setup_hex_hit(pos: Vector2, radius: float = 18.0) -> void:
	global_position = pos
	_fx_type = FX_HEX_HIT
	_radius = radius
	_life = 0.22
	_max_life = _life
	_seed = randf() * TAU
	queue_redraw()

func setup_hex_blast(pos: Vector2, radius: float = 46.0) -> void:
	global_position = pos
	_fx_type = FX_HEX_BLAST
	_radius = radius
	_life = 0.34
	_max_life = _life
	_seed = randf() * TAU
	queue_redraw()

func setup_chain_arc(from: Vector2, to: Vector2) -> void:
	global_position = Vector2.ZERO
	_fx_type = FX_CHAIN_ARC
	_start = from
	_end = to
	_life = 0.14
	_max_life = _life
	_seed = randf() * TAU
	queue_redraw()

func setup_meteor_fall(pos: Vector2) -> void:
	global_position = pos
	_fx_type = FX_METEOR_FALL
	_life = 0.24
	_max_life = _life
	_radius = 16.0
	_seed = randf() * TAU
	queue_redraw()

func setup_meteor_impact(pos: Vector2, radius: float = 58.0) -> void:
	global_position = pos
	_fx_type = FX_METEOR_IMPACT
	_radius = radius
	_life = 0.38
	_max_life = _life
	_seed = randf() * TAU
	queue_redraw()

func _process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var t := clampf(1.0 - _life / _max_life, 0.0, 1.0)
	var a := clampf(_life / _max_life, 0.0, 1.0)
	match _fx_type:
		FX_HEX_HIT:
			var r := lerpf(6.0, _radius, t)
			draw_circle(Vector2.ZERO, r * 0.8, Color(0.76, 0.46, 1.0, 0.14 * a))
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 36, Color(0.92, 0.62, 1.0, 0.78 * a), 2.0)
			for i in range(5):
				var ang := _seed + TAU * float(i) / 5.0 + t * 1.3
				var p := Vector2(cos(ang), sin(ang)) * (r * 0.7)
				draw_circle(p, 1.7, Color(0.98, 0.82, 1.0, 0.88 * a))
		FX_HEX_BLAST:
			var rr := lerpf(_radius * 0.35, _radius, t)
			draw_circle(Vector2.ZERO, rr, Color(0.78, 0.46, 1.0, 0.12 * a))
			draw_arc(Vector2.ZERO, rr, 0.0, TAU, 52, Color(0.90, 0.56, 1.0, 0.95 * a), 3.0)
			draw_arc(Vector2.ZERO, rr * 0.62, 0.0, TAU, 42, Color(0.70, 0.84, 1.0, 0.72 * a), 2.0)
		FX_CHAIN_ARC:
			var p0 := _start
			var p1 := _end
			var dir := (p1 - p0).normalized()
			var n := Vector2(-dir.y, dir.x)
			var mid := (p0 + p1) * 0.5 + n * 14.0 * sin(_seed + t * 6.0)
			draw_polyline(PackedVector2Array([p0, mid, p1]), Color(0.96, 0.64, 1.0, 0.92 * a), 3.4)
			draw_polyline(PackedVector2Array([p0, mid, p1]), Color(0.82, 0.94, 1.0, 0.52 * a), 6.4)
			draw_circle(p1, 7.5, Color(0.94, 0.74, 1.0, 0.66 * a))
		FX_METEOR_FALL:
			var h := lerpf(190.0, 10.0, t)
			draw_line(Vector2(0.0, -h), Vector2.ZERO, Color(1.0, 0.76, 0.38, 0.80 * a), 4.0)
			draw_line(Vector2(0.0, -h), Vector2.ZERO, Color(1.0, 0.92, 0.70, 0.52 * a), 8.0)
			draw_circle(Vector2.ZERO, lerpf(4.0, 9.0, t), Color(1.0, 0.86, 0.54, 0.95 * a))
		FX_METEOR_IMPACT:
			var m := lerpf(8.0, _radius, t)
			draw_circle(Vector2.ZERO, m * 0.86, Color(1.0, 0.52, 0.22, 0.14 * a))
			draw_arc(Vector2.ZERO, m, 0.0, TAU, 64, Color(1.0, 0.72, 0.34, 0.92 * a), 4.0)
			draw_arc(Vector2.ZERO, m * 0.58, 0.0, TAU, 48, Color(1.0, 0.90, 0.62, 0.70 * a), 2.0)
