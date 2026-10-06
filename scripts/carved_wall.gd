class_name CarvedWall
extends Node2D

## A wall cut into the woodblock: a heavy sumi keyline whose corners overshoot (the knife runs
## past the corner, as on a real block), filled with diagonal gouge hatching. Line only, no
## grey fill, so terrain reads as carved ink on the same paper as the menu.

const KEYLINE := 3.0
const OVERSHOOT := 6.0
const HATCH_STEP := 9.0
const HATCH_WIDTH := 1.4
const HATCH_INSET := 5.0
const WOBBLE := 1.2
const SEGMENT := 28.0

var size := Vector2.ZERO
var ink := Ink.SUMI
## Arena edges print as solid sumi beyond the page; inner walls are carved.
var solid := false

func setup(block_size: Vector2, color: Color, is_solid: bool) -> CarvedWall:
	size = block_size
	ink = color
	solid = is_solid
	return self

func _draw() -> void:
	if solid:
		draw_rect(Rect2(Vector2.ZERO, size), ink)
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector3(position.x, position.y, size.x * 7.0 + size.y))
	_draw_hatching(rng)
	var corners := [Vector2.ZERO, Vector2(size.x, 0.0), size, Vector2(0.0, size.y)]
	for i in 4:
		_draw_cut(corners[i], corners[(i + 1) % 4], rng)

## One knife cut along an edge: slightly wavering, overshooting both corners.
func _draw_cut(from: Vector2, to: Vector2, rng: RandomNumberGenerator) -> void:
	var dir := (to - from).normalized()
	var normal := Vector2(-dir.y, dir.x)
	var a := from - dir * OVERSHOOT * rng.randf_range(0.4, 1.0)
	var b := to + dir * OVERSHOOT * rng.randf_range(0.4, 1.0)
	var steps := maxi(2, int(a.distance_to(b) / SEGMENT))
	var pts := PackedVector2Array()
	for i in steps + 1:
		var t := float(i) / float(steps)
		var off := 0.0 if i == 0 or i == steps else rng.randf_range(-WOBBLE, WOBBLE)
		pts.append(a.lerp(b, t) + normal * off)
	draw_polyline(pts, ink, KEYLINE)

## 45-degree gouge strokes clipped to the inset rect; each stroke stops a little short at random,
## the way a hand-cut hatch never quite meets the keyline.
func _draw_hatching(rng: RandomNumberGenerator) -> void:
	var inner := Rect2(Vector2.ONE * HATCH_INSET, size - Vector2.ONE * HATCH_INSET * 2.0)
	if inner.size.x <= 0.0 or inner.size.y <= 0.0:
		return
	var span := inner.size.x + inner.size.y
	var k := 0.0
	while k < span:
		var seg := _clip_diagonal(inner, k)
		if seg.size() == 2:
			var seg_len := seg[0].distance_to(seg[1])
			var d: Vector2 = (seg[1] - seg[0]) / maxf(seg_len, 0.001)
			var p0: Vector2 = seg[0] + d * rng.randf_range(0.0, 3.0)
			var p1: Vector2 = seg[1] - d * rng.randf_range(0.0, 3.0)
			if p0.distance_to(p1) > 2.0:
				draw_line(p0, p1, ink, HATCH_WIDTH)
		k += HATCH_STEP

## The segment of the line x + y = inner.position.x + inner.position.y + k inside `inner`.
func _clip_diagonal(inner: Rect2, k: float) -> PackedVector2Array:
	var c := inner.position.x + inner.position.y + k
	var x0 := maxf(inner.position.x, c - inner.end.y)
	var x1 := minf(inner.end.x, c - inner.position.y)
	if x1 <= x0:
		return PackedVector2Array()
	return PackedVector2Array([Vector2(x0, c - x0), Vector2(x1, c - x1)])
