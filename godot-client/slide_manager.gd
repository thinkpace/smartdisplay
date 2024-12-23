extends Node2D

# slide_manager manages all slides and has following tasks:
# - Request new slides if needed (also on intialization)
# - Drop old slides if needed
# - Provide next and last slide ID

signal slide_fully_loaded

var _storage = []
# Position in _storage, must be < (Config.get_max_last_slides() + Config.get_max_next_slides())
var _current_position = -1
var _next_id = 0
var _last_storage_update_timestamp: int = -1
var _timeframe_between_storage_updates: int = 1

@onready var _picture_slide_scene = preload("res://picture_slide.tscn")

func _ready():
	Logger.debug("slide_manager._ready()")

	# Initilize slide manager with picture slides
	while (_storage.size() < Config.get_max_next_slides()):
		_add_picture_slide()

func _process(_delta):
	# Limit refresh rate to _timeframe_between_storage_updates
	var now = int(round(Time.get_unix_time_from_system()))
	if now < _last_storage_update_timestamp + _timeframe_between_storage_updates:
		return
	_last_storage_update_timestamp = now

	# Request new slides if needed
	for index in range(_storage.size()):
		if index == _current_position:
			if _storage.size() - index < Config.get_max_next_slides():
				_add_picture_slide()

	# Drop old slides if needed
	if _current_position > Config.get_max_last_slides():
		_storage[0].queue_free()
		_storage.remove_at(0)
		_current_position -= 1

# Instantiate picture_slide_scene, connect signals, set ID and add slide to storage
func _add_picture_slide():
	Logger.debug("slide_manager._add_picture_slide()")
	Logger.info("New picture requested")

	var picture_slide_node = _picture_slide_scene.instantiate()
	add_child(picture_slide_node)
	picture_slide_node.connect("slide_fully_loaded", _on_slide_fully_loaded)
	picture_slide_node.connect("slide_load_failed", _on_slide_load_failed)
	picture_slide_node.set_id(_next_id)
	_next_id += 1
	_storage.append(picture_slide_node)

func _on_slide_fully_loaded(id: int):
	Logger.debug("slide_manager._on_slide_fully_loaded(" + str(id) + ": int)")

	emit_signal("slide_fully_loaded", id)

# Remove slide in case load failed (due to HTTP issues, picture loading or whatever)
func _on_slide_load_failed(id: int):
	Logger.debug("slide_manager._on_slide_load_failed(" + str(id) + ": int)")
	Logger.error("Slide " + str(id) + " load failed, drop slide")
	
	for index in range(_storage.size()):
		var slide = _storage[index]
		var slide_id = slide.get_id()
		
		if (slide_id == id):
			_storage[index].queue_free()
			_storage.remove_at(index)
			return

# Returns ID of the next valid slide which can be showed up to viewer
func get_next_slide_id(current_id: int) -> int:
	Logger.debug("slide_manager.get_next_slide_id(" + str(current_id) + ": int) -> int")

	for index in range(_storage.size()):

		var storage_size = _storage.size()
		var slide_id = _storage[index].get_id()
		var is_last_slide = index >= storage_size - 1
		
		if (slide_id == current_id and
			! is_last_slide):
			var position_ready = _storage[index+1].position_ready
			if position_ready:
				var result = _storage[index+1].get_id()
				return result

	return -1

# Returns ID of the last valid slide which can be showed up to viewer
func get_last_slide_id(current_id: int) -> int:
	Logger.debug("slide_manager.get_last_slide_id(" + str(current_id) + ": int) -> int")

	for index in range(_storage.size()):

		var slide_id = _storage[index].get_id()
		var position_ready = _storage[index].position_ready
		var is_first_slide = index == 0

		if (slide_id == current_id and
			position_ready and
			! is_first_slide):
			var result = _storage[index-1].get_id()
			return result

	return -1

# Returns slide object from storage and saves current position if needed
# FIXME hide IDs and get rid of this function
func get_slide_by_id(id: int, save_position: bool) -> Object:
	Logger.debug("slide_manager.get_slide_by_id(" + str(id) + ": int, " + str(save_position) + ": bool) -> Object")

	var result = null

	for index in range(_storage.size()):
		var current_storage_index_id = _storage[index].get_id()
		if current_storage_index_id == id:
			if save_position:
				_current_position = index
			return _storage[index]

	return result
