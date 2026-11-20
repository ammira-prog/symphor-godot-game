extends Area2D

# One obstacle. It is either anchored to the floor (Y = 1280) and grows
# upward, or anchored to the ceiling (Y = 0) and grows downward.
# main.gd decides where it goes, what type it is and how tall it is.
#
# Types:
#   - rectangle (normal)
#   - triangle (ground spike)
#   - "animated" rectangle: a faint outline shows where it will end up, then it
#     drops from the ceiling (falling) or shoots up from the floor (rising)
#     when it gets close to the player.

const FLOOR_Y := 1280.0
const CEILING_Y := 0.0
const TRIGGER_X := 520.0        # animated obstacles spring up when they reach this X
const GROW_TIME := 0.3          # seconds for a falling / rising obstacle to extend
const TRIANGLE_WIDTH := 140.0

@export var obstacle_width: float = 90.0

var active := false
var is_triangle := false
var from_ceiling := false
var animated := false
var triggered := true
var full_height := 400.0
var grow := 1.0

var ghost: Polygon2D

@onready var polygon: Polygon2D = $Polygon2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	# Faint outline used to warn the player about falling / rising obstacles.
	ghost = Polygon2D.new()
	ghost.color = Color(polygon.color.r, polygon.color.g, polygon.color.b, 0.28)
	add_child(ghost)
	ghost.hide()


func configure(triangle: bool, overhead: bool, height: float, animate: bool) -> void:
	is_triangle = triangle
	from_ceiling = overhead
	animated = animate
	full_height = height
	position.y = CEILING_Y if overhead else FLOOR_Y

	# Every obstacle gets its own fresh shape, so resizing one never changes another.
	if triangle:
		collision_shape.shape = ConvexPolygonShape2D.new()
	else:
		collision_shape.shape = RectangleShape2D.new()

	if animate:
		triggered = false
		grow = 0.0
		ghost.polygon = _outline(height)
		ghost.show()
		polygon.hide()
		collision_shape.set_deferred("disabled", true)
		_apply(1.0)
	else:
		triggered = true
		grow = 1.0
		ghost.hide()
		polygon.show()
		collision_shape.set_deferred("disabled", false)
		_apply(height)


func _outline(h: float) -> PackedVector2Array:
	if is_triangle:
		var tw := TRIANGLE_WIDTH / 2.0
		return PackedVector2Array([
			Vector2(-tw, 0.0),
			Vector2(tw, 0.0),
			Vector2(0.0, -h)
		])
	var half := obstacle_width / 2.0
	if from_ceiling:
		return PackedVector2Array([
			Vector2(-half, 0.0),
			Vector2(half, 0.0),
			Vector2(half, h),
			Vector2(-half, h)
		])
	return PackedVector2Array([
		Vector2(-half, -h),
		Vector2(half, -h),
		Vector2(half, 0.0),
		Vector2(-half, 0.0)
	])


func _apply(h: float) -> void:
	polygon.polygon = _outline(h)
	if is_triangle:
		var tri := collision_shape.shape as ConvexPolygonShape2D
		tri.points = _outline(h)
		collision_shape.position = Vector2.ZERO
	else:
		var rect := collision_shape.shape as RectangleShape2D
		rect.size = Vector2(obstacle_width, h)
		if from_ceiling:
			collision_shape.position = Vector2(0.0, h / 2.0)
		else:
			collision_shape.position = Vector2(0.0, -h / 2.0)


func _process(delta: float) -> void:
	if not active or not animated:
		return
	if not get_parent().running:
		return
	if not triggered:
		if position.x <= TRIGGER_X:
			triggered = true
			ghost.hide()
			polygon.show()
			collision_shape.set_deferred("disabled", false)
	elif grow < 1.0:
		grow = minf(grow + delta / GROW_TIME, 1.0)
		_apply(maxf(full_height * grow, 1.0))


func activate() -> void:
	active = true
	show()
	set_deferred("monitoring", true)


func deactivate() -> void:
	active = false
	hide()
	set_deferred("monitoring", false)
