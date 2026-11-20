extends CharacterBody2D

@export var vertical_speed: float = 500.0   # keyboard speed (PC testing)
@export var follow_speed: float = 25.0      # how tightly the diamond follows a finger
@export var min_y: float = 40.0             # top limit (diamond is 40px from centre to tip)
@export var max_y: float = 1240.0           # bottom limit

var game_over = false
var touching = false
var target_y = 640.0


func _input(event: InputEvent) -> void:
	if game_over:
		return
	if event is InputEventScreenTouch:
		touching = event.pressed
		if event.pressed:
			target_y = event.position.y
	elif event is InputEventScreenDrag:
		touching = true
		target_y = event.position.y


func _physics_process(delta):
	if game_over:
		return
	velocity.x = 0
	var vertical_input = Input.get_axis("ui_up", "ui_down")

	if vertical_input != 0.0:
		# Keyboard arrows
		velocity.y = vertical_input * vertical_speed
	elif touching:
		# Touch and drag: follow the finger, no extra velocity
		velocity.y = 0
		position.y = lerpf(position.y, target_y, 1.0 - exp(-follow_speed * delta))
	else:
		# Finger lifted: stay where we are
		velocity.y = 0

	move_and_slide()
	position.y = clampf(position.y, min_y, max_y)


func _on_obstacle_body_entered(body: Node2D) -> void:
	game_over = true
	print("GAME OVER")
	get_node("../CanvasLayer/Control").show()


func _on_button_pressed() -> void:
	get_tree().reload_current_scene()
