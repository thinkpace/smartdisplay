extends Node2D

# animator manages available animations:
# - trigger next animation
# - handle swipe events to trigger animations manually

# TODO refactor this/animation scenes to avoid code duplication
# TODO this is work in progress

signal animation_started
signal animation_ended

var _last_animation_start_timestamp: int = -1
var _last_animation_end_timestamp: int = -1
var _animation_in_progress: bool = false
var _swipe_event_treshold: int = 0

@onready var _fire_truck_scene = preload("res://animator/fire_truck.tscn")
@onready var _crow_scene = preload("res://animator/crow.tscn")
@onready var _unicorn_scene = preload("res://animator/unicorn.tscn")
@onready var _trash_truck_scene = preload("res://animator/trash_truck.tscn")

func _ready():
	# Initialize random number generator
	randomize()
	_last_animation_end_timestamp = int(round(Time.get_unix_time_from_system()))
	@warning_ignore("integer_division")
	_swipe_event_treshold = int(Config.get_viewport_size().y/2)

func _process(_delta):
	var now = int(round(Time.get_unix_time_from_system()))
	var next_animation_start_timestamp = _last_animation_end_timestamp + Config.get_timeframe_between_animations()
	if ((now >= next_animation_start_timestamp) and
		(! _animation_in_progress)):
		_animation_in_progress = true
		trigger_animation()

var _swipe_event = Vector2.ZERO

func _input(event):
	if Input.is_action_pressed("up"):
		trigger_animation()
	# Touch activities
	elif event is InputEventScreenTouch: # Called if touch or untouch
		if event.is_pressed(): # Called if touch
			Logger.debug("Input action touch")
			return
		Logger.debug("Input action untouch")
		_handle_swipe_event()
	elif event is InputEventScreenDrag: # Called if swipe
		_swipe_event += event.relative

func _handle_swipe_event():
	if _swipe_event.y <= - _swipe_event_treshold:
		trigger_animation()
	_swipe_event = Vector2.ZERO

func trigger_animation():
	Logger.debug("animator.trigger_animation()")
	var animation_scene = _get_random_animation_scene()
	var animation_node = animation_scene.instantiate()
	add_child(animation_node)
	animation_node.connect("animation_started", _on_animation_started)
	animation_node.connect("animation_ended", _on_animation_ended)
	var animation = _get_random_animation(animation_node)
	animation_node.animate(animation)

# TODO only load in case of spritesheet is available
func _get_random_animation_scene() -> Resource:
	var scenes = []
	scenes.append(_fire_truck_scene)
	scenes.append(_crow_scene)
	scenes.append(_unicorn_scene)
	scenes.append(_unicorn_scene)
	scenes.append(_trash_truck_scene)
	scenes.append(_trash_truck_scene)
	var result = scenes[randi() % scenes.size()]
	return result

func _get_random_animation(animation_node: Node) -> String:
	Logger.debug("_get_random_animation(animation_node: Node) -> String")
	var available_animations = animation_node.get_animations()
	var result = available_animations[randi() % available_animations.size()]
	return result

func _on_animation_started():
	Logger.debug("animator._on_animation_started()")
	emit_signal("animation_started")
	_animation_in_progress = true
	_last_animation_start_timestamp = int(round(Time.get_unix_time_from_system()))

func _on_animation_ended():
	Logger.debug("animator._on_animation_ended()")
	emit_signal("animation_ended")
	_animation_in_progress = false
	_last_animation_end_timestamp = int(round(Time.get_unix_time_from_system()))
