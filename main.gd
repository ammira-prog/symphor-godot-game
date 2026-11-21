extends Node2D

enum State { MENU, PLAYING, PAUSED, GAME_OVER }

const SCREEN_W := 720.0
const PLAYER_X := 150.0
const SAVE_PATH := "user://symphor_save.cfg"

# ---------------------------------------------------------------------------
# PROGRESSION (all distances are in metres)
# ---------------------------------------------------------------------------
const OVERHEAD_START := 50.0     # from here ground and overhead obstacles alternate
const CYCLE_LENGTH := 550.0      # the pattern resets every 550m (distance never resets)
const RANDOM_START := 800.0      # random height changes start here...
const RANDOM_CYCLE := 2          # ...or in the third loop, whichever comes first
const TRIANGLE_HEIGHT := 620.0

# Special obstacles, in order. [distance inside the loop, type]
const EVENTS := [
	[350.0, "fall"],
	[400.0, "triangle"],
	[400.0, "fall"],
	[480.0, "fall"],
	[520.0, "rise"],
]

# ---------------------------------------------------------------------------
# SPEED
# ---------------------------------------------------------------------------
const BASE_SPEED := 220.0          # obstacle speed at 0m, pixels per second
const SPEED_PER_METRE := 0.32      # about +8 px/s every 25m
const CYCLE_SPEED_BONUS := 30.0    # extra speed added at each 550m reset
const MAX_SPEED := 560.0
const GAP_TIME_START := 2.05       # seconds between obstacles at the start...
const GAP_TIME_END := 1.5          # ...shrinking to this by 800m
const GAP_TIME_END_DISTANCE := 800.0

var state: State = State.MENU
var running := false

var total_score: int = 0
var distance = 1.0
var distance_speed = 5.0
var obstacle_speed: float = BASE_SPEED

var cycle := 0
var event_index := 0
var ground_index := 0
var ceiling_index := 0
var last_was_overhead := false

var ground_heights: Array[float] = [420.0, 560.0, 700.0, 480.0, 640.0]
var ceiling_heights: Array[float] = [440.0, 600.0, 720.0, 500.0, 660.0]

var obstacles: Array = []

var best_score := 0
var best_distance := 0
var sound_on := true

var music_player: AudioStreamPlayer
var sfx_point: AudioStreamPlayer
var sfx_hit: AudioStreamPlayer
var sfx_click: AudioStreamPlayer
var sfx_logo: AudioStreamPlayer

@onready var ui = $CanvasLayer
@onready var player = $Player
@onready var distance_label = $CanvasLayer/DistanceLabel
@onready var score_label = $CanvasLayer/ScoreLabel


func _ready() -> void:
	randomize()
	obstacles = [$Obstacle, $Obstacle2, $OverheadObstacle]
	_load_save()
	_setup_audio()

	ui.start_pressed.connect(_on_start_pressed)
	ui.restart_pressed.connect(_on_start_pressed)
	ui.menu_pressed.connect(_on_menu_pressed)
	ui.pause_pressed.connect(_on_pause_pressed)
	ui.resume_pressed.connect(_on_resume_pressed)
	ui.sound_pressed.connect(toggle_sound)
	ui.escape_pressed.connect(_on_escape)
	ui.splash_started.connect(_on_splash_started)
	ui.splash_finished.connect(_on_splash_finished)

	go_to_menu()
	ui.show_splash()   # logo animation first; the start screen waits underneath


func _notification(what: int) -> void:
	# Pause automatically if the app goes to the background or loses focus.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		pause_game()


func _process(delta: float) -> void:
	if not running:
		return

	distance += distance_speed * delta
	distance_label.text = "Distance:" + str(int(distance)) + "m"

	obstacle_speed = minf(
		BASE_SPEED + distance * SPEED_PER_METRE + cycle * CYCLE_SPEED_BONUS,
		MAX_SPEED
	)

	if distance >= (cycle + 1) * CYCLE_LENGTH:
		_start_new_cycle()

	for o in obstacles:
		if not o.active:
			continue
		o.position.x -= obstacle_speed * delta
		if o.position.x < -120.0:
			increase_score()
			_place_at_back(o)


# ---------------------------------------------------------------------------
# GAME FLOW
# ---------------------------------------------------------------------------
func go_to_menu() -> void:
	get_tree().paused = false
	state = State.MENU
	running = false
	_reset_world()
	ui.show_menu(best_score, best_distance, sound_on)


func start_game() -> void:
	get_tree().paused = false
	_reset_world()
	state = State.PLAYING
	running = true
	player.enabled = true
	ui.show_playing()


func pause_game() -> void:
	if state != State.PLAYING:
		return
	state = State.PAUSED
	running = false
	get_tree().paused = true
	ui.show_paused(sound_on)


func resume_game() -> void:
	if state != State.PAUSED:
		return
	get_tree().paused = false
	state = State.PLAYING
	running = true
	ui.show_playing()


# Called by the player when it touches an obstacle.
func on_player_hit() -> void:
	if state != State.PLAYING:
		return
	state = State.GAME_OVER
	running = false
	_play(sfx_hit)

	var final_distance := int(distance)
	var new_best := total_score > best_score
	if new_best:
		best_score = total_score
	if final_distance > best_distance:
		best_distance = final_distance
	_write_save()

	ui.show_game_over(total_score, final_distance, best_score, new_best)


func _reset_world() -> void:
	total_score = 0
	distance = 1.0
	obstacle_speed = BASE_SPEED
	cycle = 0
	event_index = 0
	ground_index = 0
	ceiling_index = 0
	last_was_overhead = false
	score_label.text = "Score:0"
	distance_label.text = "Distance:0m"
	player.reset()

	for o in obstacles:
		o.deactivate()
	for o in obstacles:
		o.activate()
		_place_at_back(o)


func increase_score() -> void:
	total_score += 1
	score_label.text = "Score:" + str(total_score)
	_play(sfx_point)


# ---------------------------------------------------------------------------
# OBSTACLE LAYOUT
# ---------------------------------------------------------------------------
func _gap_time() -> float:
	var t := clampf(distance / GAP_TIME_END_DISTANCE, 0.0, 1.0)
	return lerpf(GAP_TIME_START, GAP_TIME_END, t)


func _start_new_cycle() -> void:
	# Pattern resets, speed goes up (see CYCLE_SPEED_BONUS), distance keeps counting.
	cycle += 1
	event_index = 0
	ground_index = 0
	ceiling_index = 0


# Sends an obstacle to the back of the line, one gap behind the right-most one,
# and decides what kind of obstacle it becomes.
func _place_at_back(o) -> void:
	var rightmost: float = 0.0
	for other in obstacles:
		if other != o and other.active:
			rightmost = maxf(rightmost, other.position.x)
	o.position.x = maxf(rightmost + obstacle_speed * _gap_time(), SCREEN_W + 100.0)

	# The distance the player will have reached when this obstacle arrives.
	var eff: float = distance + (o.position.x - PLAYER_X) / maxf(obstacle_speed, 1.0) * distance_speed
	var in_cycle: float = eff - cycle * CYCLE_LENGTH

	var special := ""
	if event_index < EVENTS.size() and in_cycle >= EVENTS[event_index][0]:
		special = EVENTS[event_index][1]
		event_index += 1

	var triangle := false
	var overhead := false
	var animated := false
	match special:
		"fall":
			overhead = true
			animated = true
		"triangle":
			triangle = true
		"rise":
			animated = true
		_:
			overhead = eff >= OVERHEAD_START and not last_was_overhead
	last_was_overhead = overhead

	var height: float
	if triangle:
		height = TRIANGLE_HEIGHT
	elif overhead:
		height = _pick_height(ceiling_heights, ceiling_index, eff)
		ceiling_index += 1
	else:
		height = _pick_height(ground_heights, ground_index, eff)
		ground_index += 1

	o.configure(triangle, overhead, height, animated)


func _pick_height(heights: Array[float], index: int, eff: float) -> float:
	var h: float = heights[index % heights.size()]
	if eff >= RANDOM_START or cycle >= RANDOM_CYCLE:
		h = clampf(h + randf_range(-70.0, 70.0), 360.0, 740.0)
	return h


# ---------------------------------------------------------------------------
# BUTTON HANDLERS
# ---------------------------------------------------------------------------
func _on_start_pressed() -> void:
	_play(sfx_click)
	start_game()


func _on_menu_pressed() -> void:
	_play(sfx_click)
	go_to_menu()


func _on_pause_pressed() -> void:
	_play(sfx_click)
	pause_game()


func _on_resume_pressed() -> void:
	_play(sfx_click)
	resume_game()


func _on_splash_started() -> void:
	_play(sfx_logo)


func _on_splash_finished() -> void:
	if sfx_logo != null and sfx_logo.playing:
		sfx_logo.stop()
	_play_music()


func _on_escape() -> void:
	if state == State.PLAYING:
		pause_game()
	elif state == State.PAUSED:
		resume_game()


func toggle_sound() -> void:
	sound_on = not sound_on
	AudioServer.set_bus_mute(0, not sound_on)
	_write_save()
	ui.set_sound_text(sound_on)
	_play(sfx_click)


# ---------------------------------------------------------------------------
# SAVING
# ---------------------------------------------------------------------------
func _load_save() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		best_score = int(cfg.get_value("best", "score", 0))
		best_distance = int(cfg.get_value("best", "distance", 0))
		sound_on = bool(cfg.get_value("settings", "sound", true))


func _write_save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("best", "score", best_score)
	cfg.set_value("best", "distance", best_distance)
	cfg.set_value("settings", "sound", sound_on)
	cfg.save(SAVE_PATH)


# ---------------------------------------------------------------------------
# AUDIO  (the game still runs if a sound file is missing)
# ---------------------------------------------------------------------------
func _setup_audio() -> void:
	music_player = _make_player("res://audio/music.wav", -12.0, false)
	music_player.finished.connect(music_player.play)
	sfx_point = _make_player("res://audio/point.wav", -8.0, true)
	sfx_hit = _make_player("res://audio/hit.wav", -4.0, true)
	sfx_click = _make_player("res://audio/click.wav", -6.0, true)
	sfx_logo = _make_player("res://audio/logo.wav", -6.0, true)
	AudioServer.set_bus_mute(0, not sound_on)


func _make_player(path: String, volume_db: float, always_on: bool) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.volume_db = volume_db
	if always_on:
		p.process_mode = Node.PROCESS_MODE_ALWAYS
	if ResourceLoader.exists(path):
		p.stream = load(path)
	add_child(p)
	return p


func _play(p: AudioStreamPlayer) -> void:
	if p != null and p.stream != null:
		p.play()


func _play_music() -> void:
	if music_player.stream != null and not music_player.playing:
		music_player.play()
