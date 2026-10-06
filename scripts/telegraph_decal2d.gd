class_name TelegraphDecal2D
extends Node2D

var radius := 120.0
var duration := 0.9
const BLOT_TEX := preload("res://assets/art/blot.png")
## The blot texture's ragged edge sits slightly inside its square; overscan so the edge lands on radius.
const BLOT_OVERSCAN := 1.08

var base_color := Color(1.0, 0.35, 0.35, 0.9)

var _left := 0.0

func _ready() -> void:
	_left = duration
	# No z_index: items with their own z escape the battle's print CanvasGroup; tree order layers them.

func _process(delta: float) -> void:
	_left -= delta
	if _left <= 0.0:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	# A carved ring marks the danger edge; an ink blot spreads from the centre to show the timing.
	var t: float = 1.0 - clampf(_left / maxf(duration, 0.001), 0.0, 1.0)
	var ink := Color(base_color.r, base_color.g, base_color.b, 1.0)
	Ink.carved_ring(self, Vector2.ZERO, radius, ink)
	var b := radius * BLOT_OVERSCAN * lerpf(0.08, 1.0, t * t)
	draw_texture_rect(BLOT_TEX, Rect2(-b, -b, b * 2.0, b * 2.0), false, ink)
