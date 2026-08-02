extends Control
class_name SlashTrail

const LIFE := 0.18
var points: Array[Dictionary] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func add_slash_point(point: Vector2) -> void:
	points.append({"position": point, "life": LIFE})
	if points.size() > 28:
		points.pop_front()
	queue_redraw()

func clear_trail() -> void:
	points.clear()
	queue_redraw()

func _process(delta: float) -> void:
	var changed := false
	for item in points:
		item.life = float(item.life) - delta
		changed = true
	while not points.is_empty() and float(points[0].life) <= 0.0:
		points.pop_front()
	if changed:
		queue_redraw()

func _draw() -> void:
	if points.size() < 2:
		return
	for i in range(1, points.size()):
		var a: Dictionary = points[i - 1]
		var b: Dictionary = points[i]
		var alpha := clamp(float(b.life) / LIFE, 0.0, 1.0)
		var p0: Vector2 = a.position
		var p1: Vector2 = b.position
		draw_line(p0, p1, Color(0.18, 0.62, 1.0, alpha * 0.28), 18.0 * alpha, true)
		draw_line(p0, p1, Color(0.72, 0.92, 1.0, alpha * 0.72), 7.0 * alpha, true)
		draw_line(p0, p1, Color(1.0, 1.0, 1.0, alpha), 2.2, true)
