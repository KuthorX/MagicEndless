extends Node2D

var _start := Vector2.ZERO
var _end := Vector2.ZERO
var _life := 0.16
var _max_life := 0.16

func setup(start_pos: Vector2, end_pos: Vector2) -> void:
	_start = start_pos
	_end = end_pos
	global_position = Vector2.ZERO
	queue_redraw()

func _process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var t := clampf(_life / _max_life, 0.0, 1.0)
	var c1 := Color(0.48, 0.86, 1.0, 0.78 * t)
	var c2 := Color(0.85, 0.96, 1.0, 0.42 * t)
	draw_line(_start, _end, c1, 3.0)
	draw_line(_start, _end, c2, 7.0)
	draw_circle(_end, 9.0 * t + 4.0, Color(0.72, 0.92, 1.0, 0.65 * t))
