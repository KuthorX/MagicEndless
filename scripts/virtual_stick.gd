extends Control

signal vector_changed(vec: Vector2)

@export var stick_radius := 72.0
@export var knob_radius := 28.0
@export var dead_zone := 0.08

var _active := false
var _touch_id := -1
var _vec := Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(stick_radius * 2.0 + 24.0, stick_radius * 2.0 + 24.0)
	size = custom_minimum_size
	queue_redraw()

func get_vector() -> Vector2:
	if _vec.length() < dead_zone:
		return Vector2.ZERO
	return _vec

func reset_vector() -> void:
	_active = false
	_touch_id = -1
	_set_vec(Vector2.ZERO)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var e := event as InputEventScreenTouch
		if e.pressed:
			if _active:
				return
			_active = true
			_touch_id = e.index
			_update_from_local(e.position)
		else:
			if _active and e.index == _touch_id:
				reset_vector()
	elif event is InputEventScreenDrag:
		var e := event as InputEventScreenDrag
		if _active and e.index == _touch_id:
			_update_from_local(e.position)
	elif event is InputEventMouseButton:
		var e := event as InputEventMouseButton
		if e.button_index != MOUSE_BUTTON_LEFT:
			return
		if e.pressed:
			_active = true
			_touch_id = -2
			_update_from_local(e.position)
		elif _active and _touch_id == -2:
			reset_vector()
	elif event is InputEventMouseMotion:
		var e := event as InputEventMouseMotion
		if _active and _touch_id == -2:
			_update_from_local(e.position)

func _update_from_local(pos: Vector2) -> void:
	var center := size * 0.5
	var delta := pos - center
	var clamped := delta
	if clamped.length() > stick_radius:
		clamped = clamped.normalized() * stick_radius
	_set_vec(clamped / stick_radius)

func _set_vec(v: Vector2) -> void:
	_vec = v.clampf(-1.0, 1.0)
	vector_changed.emit(get_vector())
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	var base_color := Ink.wash(Ink.PAPER, 0.55)
	var ring_color := Ink.wash(Ink.SUMI, 0.8)
	var knob_color := Ink.wash(Ink.VERMILION, 0.85)
	draw_circle(center, stick_radius, base_color)
	draw_arc(center, stick_radius, 0.0, TAU, 48, ring_color, 3.0)
	var knob_center := center + _vec * stick_radius
	draw_circle(knob_center, knob_radius, knob_color)
