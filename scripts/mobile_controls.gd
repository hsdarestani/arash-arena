extends Control
class_name MobileControls

signal attack_pressed

var movement_vector: Vector2 = Vector2.ZERO
var joystick_touch_id: int = -1
var attack_touch_id: int = -1
var joystick_origin: Vector2 = Vector2.ZERO
var joystick_knob: Vector2 = Vector2.ZERO
var attack_flash: float = 0.0

const JOYSTICK_RADIUS := 88.0
const KNOB_RADIUS := 36.0
const ATTACK_RADIUS := 72.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	queue_redraw()

func get_move_vector() -> Vector2:
	return movement_vector

func _process(delta: float) -> void:
	if attack_flash > 0.0:
		attack_flash = maxf(0.0, attack_flash - delta)
		queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)

func _handle_touch(event: InputEventScreenTouch) -> void:
	var size := get_viewport_rect().size
	var attack_center := Vector2(size.x - 115.0, size.y - 112.0)

	if event.pressed:
		if event.position.x < size.x * 0.55 and joystick_touch_id == -1:
			joystick_touch_id = event.index
			joystick_origin = event.position
			joystick_knob = event.position
			_update_joystick(event.position)
		elif event.position.distance_to(attack_center) <= ATTACK_RADIUS * 1.55 and attack_touch_id == -1:
			attack_touch_id = event.index
			attack_flash = 0.14
			attack_pressed.emit()
			queue_redraw()
	else:
		if event.index == joystick_touch_id:
			joystick_touch_id = -1
			movement_vector = Vector2.ZERO
			joystick_knob = joystick_origin
			queue_redraw()
		elif event.index == attack_touch_id:
			attack_touch_id = -1

func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index == joystick_touch_id:
		_update_joystick(event.position)

func _update_joystick(position: Vector2) -> void:
	var delta := position - joystick_origin
	if delta.length() > JOYSTICK_RADIUS:
		delta = delta.normalized() * JOYSTICK_RADIUS
	joystick_knob = joystick_origin + delta
	movement_vector = delta / JOYSTICK_RADIUS
	if movement_vector.length() < 0.08:
		movement_vector = Vector2.ZERO
	queue_redraw()

func _draw() -> void:
	var size := get_viewport_rect().size
	var base := joystick_origin if joystick_touch_id != -1 else Vector2(115.0, size.y - 112.0)
	var knob := joystick_knob if joystick_touch_id != -1 else base
	var attack_center := Vector2(size.x - 115.0, size.y - 112.0)

	draw_circle(base, JOYSTICK_RADIUS, Color(0.04, 0.035, 0.07, 0.58))
	draw_arc(base, JOYSTICK_RADIUS, 0.0, TAU, 64, Color(0.95, 0.7, 0.23, 0.55), 3.0)
	draw_circle(knob, KNOB_RADIUS, Color(0.95, 0.7, 0.23, 0.72))
	draw_circle(knob, KNOB_RADIUS - 8.0, Color(0.12, 0.08, 0.17, 0.7))

	var attack_alpha := 0.95 if attack_flash > 0.0 else 0.66
	draw_circle(attack_center, ATTACK_RADIUS, Color(0.12, 0.05, 0.07, attack_alpha))
	draw_arc(attack_center, ATTACK_RADIUS, 0.0, TAU, 64, Color(0.95, 0.32, 0.22, 0.9), 4.0)
	draw_line(attack_center + Vector2(-23, 25), attack_center + Vector2(25, -25), Color(1.0, 0.86, 0.55, 1.0), 8.0, true)
	draw_line(attack_center + Vector2(-25, -25), attack_center + Vector2(23, 25), Color(1.0, 0.86, 0.55, 1.0), 8.0, true)
	draw_line(attack_center + Vector2(-31, 17), attack_center + Vector2(-15, 33), Color(0.95, 0.32, 0.22, 1.0), 5.0, true)
	draw_line(attack_center + Vector2(-33, -15), attack_center + Vector2(-17, -31), Color(0.95, 0.32, 0.22, 1.0), 5.0, true)
