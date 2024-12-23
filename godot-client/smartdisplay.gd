extends Node2D

# This is the main scene & script of this application. It is responsible for the following tasks:
# - Load the slide_manager and animator scenes
# - Handle input & swipe events
# - Move slides

var _slide_manager: Node2D = null
var _animator: Node2D = null
var _active_slide: Object = null
var _last_slide_change_timestamp: int = -1

@onready var _slide_manager_scene = preload("res://slide_manager.tscn")
@onready var _animator_scene = preload("res://animator/animator.tscn")

func _ready():
	Logger.debug("smartdisplay._ready()")

	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

	_slide_manager = _slide_manager_scene.instantiate()
	add_child(_slide_manager)
	_slide_manager.connect("slide_fully_loaded", _on_slidemanager_slide_fully_loaded)

	_animator = _animator_scene.instantiate()
	add_child(_animator)

func _process(_delta):
	if _last_slide_change_timestamp < 0:
		return

	var now = int(round(Time.get_unix_time_from_system()))
	var next_update_timestamp = _last_slide_change_timestamp + Config.get_timeframe_between_slide_change()
	if now >= next_update_timestamp:
		Logger.info(str(Config.get_timeframe_between_slide_change()) + " seconds passed, show new slide")
		_show_next_slide()
		_last_slide_change_timestamp = now

func _input(event):
	if _active_slide == null:
		return

	# Keyboard activities
	if Input.is_action_pressed("exit"):
		Logger.debug("Input action exit")
		get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
		get_tree().quit()
	elif Input.is_action_pressed("right"):
		Logger.debug("Input action right")
		_show_next_slide()
	elif Input.is_action_pressed("left"):
		Logger.debug("Input action left")
		_show_last_slide()
	elif Input.is_action_pressed("up"):
		Logger.debug("Input action up")
	elif Input.is_action_pressed("down"):
		Logger.debug("Input action up")

	# Touch activities
	elif event is InputEventScreenTouch: # Called if touch or untouch
		if event.is_pressed(): # Called if touch
			Logger.debug("Input action touch")
			return
		Logger.debug("Input action untouch")
		_handle_swipe_event()
	elif event is InputEventScreenDrag: # Called if swipe
		_move_active_slide(_active_slide.position.x + event.relative.x, Config.get_viewport_center_y(), 0.001)

func _on_slidemanager_slide_fully_loaded(id: int):
	Logger.debug("smartdisplay._on_slidemanager_slide_fully_loaded(" + str(id) + ": int)")

	# FIXME save current position if this slide will be the active_slide (happens only in case of first slide to be loaded)
	#       --> _show_last_slide doesn't work if it's the first slide
	var slide = _slide_manager.get_slide_by_id(id, false)
	if slide == null:
		return

	slide.position.x = Config.get_viewport_center_x() + Config.get_viewport_size().x
	slide.position.y = Config.get_viewport_center_y()
	slide.position_ready = true

	if _active_slide == null:
		_active_slide = slide
		_active_slide.position.x = Config.get_viewport_center_x()
		_active_slide.position.y = Config.get_viewport_center_y()
		_last_slide_change_timestamp = int(round(Time.get_unix_time_from_system()))

func _move_slide(slide: Object, target_x: int, target_y: int, duration: float):
	Logger.debug("smartdisplay._move_slide(slide: Object, " + str(target_x) + ": int, " + str(target_y) + ": int, " + str(duration) + ": float):")

	var tween = get_tree().create_tween()
	tween.tween_property(slide, "position", Vector2(target_x, target_y), duration)

func _move_active_slide(target_x: int, target_y: int, duration: float):
	Logger.debug("smartdisplay._move_active_slide(" + str(target_x) + ": int, " + str(target_y) + ": int, " + str(duration) + ": float)")

	_move_slide(_active_slide, target_x, target_y, duration)

func _handle_swipe_event():
	Logger.debug("smartdisplay._handle_swipe_event()")

	var slide_is_in_tolerance_area = (
		(_active_slide.position.x <= Config.get_viewport_center_x() + Config.get_move_tolerance_area()) and
		(_active_slide.position.x >= Config.get_viewport_center_x() - Config.get_move_tolerance_area())
		)
	var slide_is_right_from_tolerance_area = (
		_active_slide.position.x > Config.get_viewport_center_x() + Config.get_move_tolerance_area()
		)
	var slide_is_left_from_tolerance_area = (
		_active_slide.position.x < Config.get_viewport_center_x() - Config.get_move_tolerance_area()
		)

	if slide_is_in_tolerance_area:
		_move_active_slide(Config.get_viewport_center_x(), Config.get_viewport_center_y(), 1)
	elif slide_is_right_from_tolerance_area:
		_show_last_slide()
	elif slide_is_left_from_tolerance_area:
		_show_next_slide()

func _show_next_slide():
	Logger.debug("smartdisplay._show_next_slide()")

	var next_slide_id = _slide_manager.get_next_slide_id(_active_slide.get_id())
	if next_slide_id == -1:
		return

	var slide = _slide_manager.get_slide_by_id(next_slide_id, true)
	if slide == null:
		return

	_move_active_slide(-Config.get_viewport_size().x, Config.get_viewport_center_y(), 1)
	_active_slide = slide
	_move_active_slide(Config.get_viewport_center_x(), Config.get_viewport_center_y(), 1)

	_last_slide_change_timestamp = int(round(Time.get_unix_time_from_system()))

func _show_last_slide():
	Logger.debug("smartdisplay._show_last_slide()")
	var last_slide_id = _slide_manager.get_last_slide_id(_active_slide.get_id())
	if last_slide_id == -1:
		return

	var slide = _slide_manager.get_slide_by_id(last_slide_id, true)
	if slide == null:
		return

	_move_active_slide(Config.get_viewport_center_x() + Config.get_viewport_size().x, Config.get_viewport_center_y(), 1)
	_active_slide = slide
	_move_active_slide(Config.get_viewport_center_x(), Config.get_viewport_center_y(), 1)

	_last_slide_change_timestamp = int(round(Time.get_unix_time_from_system()))
