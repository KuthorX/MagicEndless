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
	draw_line(_start, _end, Ink.wash(Ink.VERMILION, t), 3.5)
	draw_circle(_end, 7.0 * t + 3.0, Ink.wash(Ink.VERMILION, t))
