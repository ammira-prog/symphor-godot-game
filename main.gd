extends Node2D

const SCREEN_W := 720.0

var total_score: int = 0
var distance = 1.0
var distance_speed = 5.0
var overhead_started = false

# Obstacle layout settings
var obstacle_speed: float = 220.0   # pixels per second, right to left
var spacing: float = 450.0          # distance between neighbouring obstacles
var ground_heights: Array[float] = [420.0, 560.0, 700.0, 480.0, 640.0]
var ceiling_heights: Array[float] = [440.0, 600.0, 720.0, 500.0, 660.0]
var ground_index := 0
var ceiling_index := 0
var last_was_overhead := false

var obstacles: Array = []

@onready var distance_label = $CanvasLayer/DistanceLabel
@onready var game_over_screen = $CanvasLayer/Control
@onready var overhead_obstacle = $OverheadObstacle


func _ready() -> void:
	obstacles = [$Obstacle, $Obstacle2, $OverheadObstacle]
	for o in obstacles:
		o.deactivate()
	# Two ground obstacles at the start. The overhead one joins at 200m.
	for o in [$Obstacle, $Obstacle2]:
		o.activate()
		_place_at_back(o)


func _process(delta: float) -> void:
	if game_over_screen.visible:
		return

	distance += distance_speed * delta
	distance_label.text = "Distance:" + str(int(distance)) + "m"

	if distance >= 200.0 and not overhead_started:
		overhead_started = true
		overhead_obstacle.activate()
		_place_at_back(overhead_obstacle)

	for o in obstacles:
		if not o.active:
			continue
		o.position.x -= obstacle_speed * delta
		if o.position.x < -60.0:
			increase_score()
			_place_at_back(o)


# Sends an obstacle to the back of the line, a fixed spacing behind the
# right-most one, and picks its type and height.
func _place_at_back(o) -> void:
	var rightmost: float = 0.0
	for other in obstacles:
		if other != o and other.active:
			rightmost = maxf(rightmost, other.position.x)
	o.position.x = maxf(rightmost + spacing, SCREEN_W + 80.0)

	# Before 200m: ground only. After 200m: ground and overhead alternate.
	var overhead: bool = overhead_started and not last_was_overhead
	last_was_overhead = overhead

	var height: float
	if overhead:
		height = ceiling_heights[ceiling_index % ceiling_heights.size()]
		ceiling_index += 1
	else:
		height = ground_heights[ground_index % ground_heights.size()]
		ground_index += 1
	o.configure(overhead, height)


func increase_score() -> void:
	total_score += 1
	$CanvasLayer/ScoreLabel.text = "Score:" + str(total_score)
