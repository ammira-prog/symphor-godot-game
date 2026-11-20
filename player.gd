extends CharacterBody2D

@export var forward_speed: float = 250.0
@export var vertical_speed: float = 350.0
var game_over = false
func _physics_process(delta):
	if game_over:
		return
	velocity.x = 0
	var vertical_input = Input.get_axis("ui_up","ui_down")
	velocity.y = vertical_input * vertical_speed
	move_and_slide()
	position.y = clamp(position.y,80.0,1200.0) 


func _on_obstacle_body_entered(body: Node2D) -> void:
	game_over = true
	print("GAME OVER")
	get_node("../CanvasLayer/Control").show()


func _on_button_pressed() -> void:
	get_tree().reload_current_scene()
