class_name Ink
extends RefCounted

## Woodblock-print palette shared by the world, entities, FX and UI (see docs/art-direction.md).

const PAPER := Color(0.929, 0.890, 0.800)
const PAPER_LIGHT := Color(0.957, 0.925, 0.847)
const SUMI := Color(0.118, 0.106, 0.094)
const VERMILION := Color(0.847, 0.271, 0.169)
const INDIGO := Color(0.153, 0.275, 0.420)
const INDIGO_DEEP := Color(0.102, 0.173, 0.271)
## Enemy and telegraph pigments: one traditional pigment per attack family.
const CRIMSON := Color(0.690, 0.157, 0.247)
const ROKUSHO := Color(0.243, 0.490, 0.353)
const MURASAKI := Color(0.420, 0.298, 0.604)
const GAMBOGE := Color(0.784, 0.588, 0.118)
const PERSIMMON := Color(0.878, 0.478, 0.180)
const AI_TEAL := Color(0.176, 0.478, 0.502)
const WISTERIA := Color(0.584, 0.361, 0.627)

static func wash(c: Color, alpha: float) -> Color:
	return Color(c.r, c.g, c.b, alpha)

## A ring cut into the block, not brushed: three gouged arcs with chipped gaps and short
## outward gouge ticks. Used for every in-battle circle (the enso belongs to the menu only).
static func carved_ring(ci: CanvasItem, center: Vector2, r: float, c: Color, width: float = 2.5) -> void:
	const ARCS := 3
	const GAP := 0.16
	const TICKS := 8
	# Each cut is a little off the last: uneven spans, radii and widths, so it reads cut by hand.
	const JITTER := [0.0, 0.31, -0.22]
	var step := TAU / float(ARCS)
	for i in ARCS:
		var j: float = JITTER[i]
		var a0 := float(i) * step + GAP + j * 0.4
		var rr := r * (1.0 + j * 0.08)
		ci.draw_arc(center, rr, a0, a0 + step - GAP * 2.0 - absf(j) * 0.3, 18, c, width * (1.0 + j))
	for i in TICKS:
		var a := (float(i) + 0.5) * TAU / float(TICKS)
		var d := Vector2.from_angle(a)
		ci.draw_line(center + d * r, center + d * (r + width * 2.2), c, width * 0.7)

## A single carved crescent: a vermilion cut that swells in the middle and tapers to points.
static func carved_crescent(ci: CanvasItem, r: float, sweep: float, thickness: float, c: Color) -> void:
	const STEPS := 24
	var outer := PackedVector2Array()
	var inner := PackedVector2Array()
	for i in STEPS + 1:
		var t := float(i) / float(STEPS)
		var a := -sweep * 0.5 + sweep * t
		outer.append(Vector2.from_angle(a) * r)
		if i > 0 and i < STEPS:
			inner.append(Vector2.from_angle(a) * (r - thickness * sin(PI * t)))
	inner.reverse()
	ci.draw_colored_polygon(outer + inner, c)
