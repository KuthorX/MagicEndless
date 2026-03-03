class_name TelegraphDecal2D
extends Node2D

var radius := 120.0
var duration := 0.9
var base_color := Color(1.0, 0.35, 0.35, 0.9)

var _left := 0.0

func _ready() -> void:
	_left = duration
	z_index = 30

func _process(delta: float) -> void:
	_left -= delta
	if _left <= 0.0:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var t: float = 1.0 - clampf(_left / maxf(duration, 0.001), 0.0, 1.0)
	var flash: float = 0.45 + 0.55 * absf(sin(float(Time.get_ticks_msec()) * 0.02))
	var ring_color := Color(base_color.r, base_color.g, base_color.b, 0.35 + 0.45 * flash)
	var fill_color := Color(base_color.r, base_color.g, base_color.b, 0.08 + 0.16 * t)
	draw_circle(Vector2.ZERO, radius, fill_color)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, ring_color, 3.0)
	draw_arc(Vector2.ZERO, radius * (0.62 + 0.30 * t), 0.0, TAU, 64, Color(ring_color.r, ring_color.g, ring_color.b, ring_color.a * 0.7), 2.0)
