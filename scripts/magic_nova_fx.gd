extends Node2D


var _radius := 0.0
var _radius_max := 170.0
var _life := 0.32
var _max_life := 0.32

func setup(center_pos: Vector2, radius_max: float) -> void:
	global_position = center_pos
	_radius_max = radius_max
	_radius = 0.0
	queue_redraw()

func _process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		queue_free()
		return
	var t := 1.0 - clampf(_life / _max_life, 0.0, 1.0)
	_radius = lerpf(10.0, _radius_max, t)
	queue_redraw()

func _draw() -> void:
	var a := clampf(_life / _max_life, 0.0, 1.0)
	# Frost nova: an indigo carved ring thrown outward.
	Ink.carved_ring(self, Vector2.ZERO, _radius, Ink.wash(Ink.INDIGO, a), 3.0)
