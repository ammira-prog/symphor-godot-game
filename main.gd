extends Node2D

var total_score: int = 0
var distance = 1.0
var distance_speed = 5.0
var overhead_started = false

@onready var distance_label = $CanvasLayer/DistanceLabel
@onready var game_over_screen = $CanvasLayer/Control
@onready var overhead_obstacle = $OverheadObstacle

func _ready() -> void:
	overhead_obstacle.hide()
	overhead_obstacle.set_process(false)
	overhead_obstacle.monitoring = false
	
func _process(delta: float) -> void: 
	if not game_over_screen.visible:
		distance += distance_speed * delta
		distance_label.text = "Distance:" + str(int(distance)) + "m"

		if distance >=200.0 and not overhead_started:
			overhead_started = true
			overhead_obstacle.show()
			overhead_obstacle.set_process(true)
			overhead_obstacle.monitoring =true
			
func increase_score() -> void:
	total_score += 1
	$CanvasLayer/ScoreLabel.text = "Score:" +  str(total_score)
