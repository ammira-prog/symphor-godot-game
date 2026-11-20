extends CharacterBody2D

@export var vertical_speed: float = 500.0   # keyboard speed (PC testing)
@export var follow_speed: float = 25.0      # how tightly the diamond follows a finger
@export var min_y: float = 40.0             # top limit (diamond is 40px from centre to tip)
@export var max_y: float = 1240.0           # bottom limit

const START_POSITION := Vector2(150.0, 640.0)

var game_over = false
var enabled = false      # main.gd turns this on while a run is in progress
var touching = false
var target_y = 640.0


func reset() -> void:
	game_over = false
	enabled = false
	touching = false
	position = START_POSITION
	target_y = START_POSITION.y
	velocity = Vector2.ZERO


# Touches on the pause button (top right) must not move the player.
func _in_pause_zone(pos: Vector2) -> bool:
	return pos.x >= 580.0 and pos.y <= 120.0


func _input(event: InputEvent) -> void:
	if game_over or not enabled:
		return
	if event is InputEventScreenTouch:
		if _in_pause_zone(event.position):
			return
		touching = event.pressed
		if event.pressed:
			target_y = event.position.y
	elif event is InputEventScreenDrag:
		if _in_pause_zone(event.position):
			return
		touching = true
		target_y = event.position.y


func _physics_process(delta):
	if game_over or not enabled:
		return
	velocity.x = 0
	var vertical_input = Input.get_axis("ui_up", "ui_down")

	if vertical_input != 0.0:
		# Keyboard arrows
		velocity.y = vertical_input * vertical_speed
	elif touching:
		# Touch and drag: follow the finger
		velocity.y = 0
		position.y = lerpf(position.y, target_y, 1.0 - exp(-follow_speed * delta))
	else:
		# Finger lifted: stay where we are
		velocity.y = 0

	move_and_slide()
	position.y = clampf(position.y, min_y, max_y)


func _on_obstacle_body_entered(body: Node2D) -> void:
	if game_over:
		return
	game_over = true
	print("GAME OVER")
	get_parent().on_player_hit()
