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
