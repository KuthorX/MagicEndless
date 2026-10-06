extends PanelContainer

## The wave counter as a carved seal (印章), white-character (白文) style: a vermilion block
## whose edge is chipped, a carved inner border with worn breaks, and the labels in paper colour
## as if cut out of the stone. Drawn under the child labels.

const FRAME_INSET := 7.0
const FRAME_WIDTH := 2.5
const EDGE_SEGMENTS := 7
const EDGE_CHIP := 2.2
const WORN_SPECKS := 9

func _ready() -> void:
	resized.connect(queue_redraw)

func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	draw_colored_polygon(_chipped_outline(Rect2(Vector2.ZERO, size), rng), Ink.VERMILION)
	_draw_frame(Rect2(Vector2.ONE * FRAME_INSET, size - Vector2.ONE * FRAME_INSET * 2.0), rng)
	for i in WORN_SPECKS:
		var p := Vector2(rng.randf_range(4.0, size.x - 4.0), rng.randf_range(4.0, size.y - 4.0))
		draw_circle(p, rng.randf_range(0.6, 1.5), Ink.PAPER)

## The stone's edge: each side broken into short runs that dip inward by a chip or two.
func _chipped_outline(r: Rect2, rng: RandomNumberGenerator) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var corners := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	for side in 4:
		var a: Vector2 = corners[side]
		var b: Vector2 = corners[(side + 1) % 4]
		var inward := (b - a).normalized().rotated(PI * 0.5)
		for i in EDGE_SEGMENTS:
			var t := float(i) / float(EDGE_SEGMENTS)
			var chip := 0.0 if i == 0 else rng.randf_range(0.0, EDGE_CHIP)
			pts.append(a.lerp(b, t) + inward * chip)
	return pts

## The carved border: four cuts in paper colour, each with one worn break.
func _draw_frame(r: Rect2, rng: RandomNumberGenerator) -> void:
	var corners := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	for side in 4:
		var a: Vector2 = corners[side]
		var b: Vector2 = corners[(side + 1) % 4]
		var gap_at := rng.randf_range(0.25, 0.75)
		var gap := rng.randf_range(0.04, 0.10)
		draw_line(a, a.lerp(b, gap_at - gap), Ink.PAPER, FRAME_WIDTH)
		draw_line(a.lerp(b, gap_at + gap), b, Ink.PAPER, FRAME_WIDTH)
