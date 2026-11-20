extends Area2D

# One obstacle. It is either anchored to the floor (Y = 1280) and grows
# upward, or anchored to the ceiling (Y = 0) and grows downward.
# main.gd decides where it goes and how tall it is.

const FLOOR_Y := 1280.0
const CEILING_Y := 0.0

@export var obstacle_width: float = 90.0

var active := true

@onready var polygon: Polygon2D = $Polygon2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	# Give every obstacle its own shape so resizing one never changes another.
	collision_shape.shape = RectangleShape2D.new()


func configure(from_ceiling: bool, height: float) -> void:
	var half := obstacle_width / 2.0
	var rect := collision_shape.shape as RectangleShape2D
	rect.size = Vector2(obstacle_width, height)
	if from_ceiling:
		position.y = CEILING_Y
		polygon.polygon = PackedVector2Array([
			Vector2(-half, 0.0),
			Vector2(half, 0.0),
			Vector2(half, height),
			Vector2(-half, height)
		])
		collision_shape.position = Vector2(0.0, height / 2.0)
	else:
		position.y = FLOOR_Y
		polygon.polygon = PackedVector2Array([
			Vector2(-half, -height),
			Vector2(half, -height),
			Vector2(half, 0.0),
			Vector2(-half, 0.0)
		])
		collision_shape.position = Vector2(0.0, -height / 2.0)


func activate() -> void:
	active = true
	show()
	set_deferred("monitoring", true)


func deactivate() -> void:
	active = false
	hide()
	set_deferred("monitoring", false)
