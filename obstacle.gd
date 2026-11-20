extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

@export var respawn_x: float = 770.0
var score = 0
var heights = [400,520,450,600]
var height_index = 0

@onready var polygon = $Polygon2D
@onready var collision_shape =$CollisionShape2D
func change_obstacle_height(height: float) -> void:
	polygon.polygon = PackedVector2Array([
		Vector2(-25,75 - height),
		Vector2(25,75 - height),
		Vector2(25,75),
		Vector2(-25,75)
	])
	var rectangle_shape = collision_shape.shape as RectangleShape2D
	rectangle_shape.size = Vector2( 50, height)
	collision_shape.position.y = 75 - height /2
func _process(delta: float) -> void:
	if get_parent().get_node("CanvasLayer/Control").visible:
		return
	position.x -=100 * delta
	
	if position.x < -50:
		position.x = respawn_x
		get_parent().increase_score()
		height_index = (height_index + 1) % heights.size()
		change_obstacle_height(heights[height_index])
func _on_obstacle_body_entered(body: Node2D) -> void:
	body.game_over = true
