extends Node2D

## The printed page under the battle: kozo paper inside the arena, sumi ink beyond its edge,
## and kento registration marks at the corners. The page stays bare so the fight is the only ink.
## Lives on a CanvasLayer below the world (follows the camera), so the world's print shader
## composites ink over it.

const PAPER_TEX := preload("res://assets/art/paper.png")
const PAGE := Rect2(-828.0, -468.0, 1656.0, 936.0)
const BEYOND := Rect2(-4000.0, -4000.0, 8000.0, 8000.0)
const KENTO_ARM := 46.0

func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	queue_redraw()

func _draw() -> void:
	draw_rect(BEYOND, Ink.SUMI)
	draw_texture_rect(PAPER_TEX, PAGE, true)
	_draw_kento()

func _draw_kento() -> void:
	# Kagi (corner) mark bottom-left, hikitsuke (straight) mark bottom-right, as on a real block.
	var inset := 26.0
	var bl := Vector2(PAGE.position.x + inset, PAGE.end.y - inset)
	var br := Vector2(PAGE.end.x - inset, PAGE.end.y - inset)
	var ink := Ink.wash(Ink.SUMI, 0.55)
	draw_line(bl, bl + Vector2(KENTO_ARM, 0.0), ink, 2.0)
	draw_line(bl, bl + Vector2(0.0, -KENTO_ARM * 0.6), ink, 2.0)
	draw_line(br, br + Vector2(-KENTO_ARM, 0.0), ink, 2.0)
