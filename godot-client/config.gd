extends Node

# Possible log levels:
#   Logger.DEBUG
#   Logger.INFO
#   Logger.WARNING
#   Logger.ERROR
@export var _log_level_default: String = Logger.INFO
@export var _picture_provider_url_default: String = "http://smartdisplay-server:4999/random_picture"
@export var _max_last_slides_default: int = 5
@export var _max_next_slides_default: int = 5
@export var _timeframe_between_slide_change_default: int = 60
@export var _timeframe_between_animations_default: int = 180
@export var _move_tolerance_area_default: int = 250
@export var _http_request_timeout_default: float = 30.0

var _config: ConfigFile = ConfigFile.new()
var _config_file_path: String = "user://smartdisplay.cfg"

var _viewport_size: Vector2i = Vector2i.ZERO
var _max_picture_sprite_width: int = -1
var _max_picture_sprite_height: int = -1

func _ready():
	Logger.debug("picture_slide._ready()")
	set_viewport_size(get_viewport().size)

func _init():
	if ! FileAccess.file_exists(_config_file_path):
		_create_new_config_file()
	
	var result = _config.load(_config_file_path)
	if result != OK:
		Logger.error("Config file (" + _config_file_path + ") couldn't be loaded: error " + str(result))

# FIXME Update config file in case new options are introduced
func _create_new_config_file():
	_config.set_value("Smartdisplay", "log_level", _log_level_default)
	_config.set_value("Smartdisplay", "picture_provider_url", _picture_provider_url_default)
	_config.set_value("Smartdisplay", "max_last_slides", _max_last_slides_default)
	_config.set_value("Smartdisplay", "max_next_slides", _max_next_slides_default)
	_config.set_value("Smartdisplay", "timeframe_between_slide_change", _timeframe_between_slide_change_default)
	_config.set_value("Smartdisplay", "timeframe_between_animations", _timeframe_between_animations_default)
	_config.set_value("Smartdisplay", "move_tolerance_area", _move_tolerance_area_default)
	_config.set_value("Smartdisplay", "http_request_timeout", _http_request_timeout_default)
	_config.save(_config_file_path)
	_config.clear()

func set_viewport_size(size: Vector2i) -> void:
	_viewport_size = get_viewport().size
	_max_picture_sprite_width = _viewport_size.x
	_max_picture_sprite_height = _viewport_size.y

func get_viewport_size() -> Vector2i:
	return _viewport_size

func get_viewport_center_x() -> int:
	@warning_ignore("integer_division")
	var result = int(_viewport_size.x/2)
	return result

func get_viewport_center_y() -> int:
	@warning_ignore("integer_division")
	var result = int(_viewport_size.y/2)
	return result

func get_log_level() -> String:
	var result = _config.get_value("Smartdisplay", "log_level")
	return result as String

func get_picture_provider_url() -> String:
	return _config.get_value("Smartdisplay", "picture_provider_url") as String

func get_max_last_slides() -> int:
	return _config.get_value("Smartdisplay", "max_last_slides") as int

func get_max_next_slides() -> int:
	return _config.get_value("Smartdisplay", "max_next_slides") as int

func get_timeframe_between_slide_change() -> int:
	return _config.get_value("Smartdisplay", "timeframe_between_slide_change") as int

func get_timeframe_between_animations() -> int:
	return _config.get_value("Smartdisplay", "timeframe_between_animations") as int

func get_move_tolerance_area() -> int:
	return _config.get_value("Smartdisplay", "move_tolerance_area") as int

func get_http_request_timeout() -> float:
	return _config.get_value("Smartdisplay", "http_request_timeout") as float

func get_max_picture_sprite_width() -> int:
	return _max_picture_sprite_width

func get_max_picture_sprite_height() -> int:
	return _max_picture_sprite_height
