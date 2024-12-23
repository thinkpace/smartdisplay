extends Node2D

# picture_slide is a single slide which contains a picture and takes care of its management

signal slide_fully_loaded
signal slide_load_failed

# FIXME test if slide&picture management works in all error cases (network issue, pic corrupted, etc.)

# position_ready means position of slide is ready (is done in smartdisplay scene)
var position_ready: bool = false

var _id: int = -1
# fully_loaded means the picture is available as sprite but positioning might not yet be finished
var _fully_loaded: bool = false
# Some data about the picture itself
var _filename: String = ""
var _extension: String = ""
var _path: String = ""
var _raw: PackedByteArray = PackedByteArray()
var _exif_has_exif: bool = false
var _exif_datetime_original: String = ""
var _exif_make: String = ""
var _exif_model: String = ""
var _exif_orientation = -1
# Thread object which will take care of image processing
var _thread: Thread = null

@onready var _http_request = $HTTPRequest
@onready var _sprite = $Sprite2D
@onready var _image_texture = ImageTexture.new()
@onready var _image = Image.new()
@onready var _id_label = RichTextLabel.new() # Only shown for debugging

# TODO Would be great to find a good way to set the ID in _ready or at least as early as possible, see also: https://www.reddit.com/r/godot/comments/13pm5o5/instantiating_a_scene_with_constructor_parameters/
func _ready():
	Logger.debug("picture_slide._ready()")

	add_child(_http_request)
	add_child(_sprite)
	add_child(_id_label)

	_http_request.name = "request"
	# FIXME it seems timeout isn't implemented, so I need to implement my own timeout and check if the request is fully loaded after e.g. 60 seconds, if not slide will be dropped
	_http_request.timeout = Config.get_http_request_timeout()
	_http_request.request_completed.connect(_on_picture_request_completed.bind(_http_request))
	var error = _http_request.request(Config.get_picture_provider_url())
	if error != OK:
		Logger.error("picture_slide._ready(): HTTP Request failed!")
		# FIXME _id not yet set in ready
		emit_signal("slide_load_failed", _id)

	_id_label.size = Vector2(200,50)
	_id_label.visible = Config.get_log_level() == Logger.DEBUG
	_id_label.position.x = 0
	_id_label.position.y = 0

func _process(_delta: float):
	pass

func _exit_tree():
	Logger.debug("picture_slide._exit_tree()")
	
	if _thread != null:
		_thread.wait_to_finish()

func set_id(id: int):
	Logger.debug("picture_slide.set_id(" + str(id) + ": int)")

	_id = id
	_id_label.text = str(id)
	name = "slide" + str(_id)

func get_id() -> int:
	return _id

func is_fully_loaded() -> bool:
	return _fully_loaded

# Result of HTTP request
func _on_picture_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, http_request: HTTPRequest):
	Logger.debug("_on_picture_request_completed(" + str(result) + ": int, " + str(response_code) + ": int, _headers: PackedStringArray, body: PackedByteArray, http_request: HTTPRequest)")

	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		var json_string = body.get_string_from_utf8()

		if (json_string != null and
			json_string != ""):
			var json = JSON.parse_string(json_string)

			if json != null:
				_load_json(json)
				_thread = Thread.new()
				_thread.start(_load_picture)
			else:
				# JSON object invalid, load failed
				emit_signal("slide_load_failed", _id)
		else:
			# JSON string invalid, load failed
			emit_signal("slide_load_failed", _id)
	else:
		# HTTP request failed, load failed
		emit_signal("slide_load_failed", _id)

	http_request.queue_free()

# Process picture meta data provided by picture_provider
func _load_json(json: Variant):
	Logger.debug("picture_slide._load_json(json: Variant)")

	_filename = json["filename"]
	_extension = json["extension"]
	_path = json["path"]
	_raw = Marshalls.base64_to_raw(json["content_base64"])

	if json["exif_has_exif"] != null:
		_exif_has_exif = json["exif_has_exif"]

	if json["exif_datetime_original"] != null:
		_exif_datetime_original = json["exif_datetime_original"]

	if json["exif_make"] != null:
		_exif_make = json["exif_make"]

	if json["exif_model"] != null:
		_exif_model = json["exif_model"]

	if json["exif_orientation"] != null:
		_exif_orientation = json["exif_orientation"]

# Load picture itself, very costly in terms of performance and therefore done in a thread
func _load_picture():
	Logger.debug("picture_slide._load_picture()")

	# TODO double check thread handling in detail (see also https://godotlearn.com/godot-3-1-how-to-destroy-object-node/ )
	var mutex = Mutex.new()
	mutex.lock()

	var image_error = _image.load_jpg_from_buffer(_raw)  # Costly in terms of performance
	if image_error == OK:
		_resize_picture(_image) # Costly in terms of performance
		_image_texture.set_image(_image)
		_sprite.call_deferred("set_texture", _image_texture)
		_apply_exif_orientation() # TODO call earlier?

	mutex.unlock()

	if image_error != OK:
		# Image load JPG from buffer failed, load failed
		call_deferred("emit_signal", "slide_load_failed", _id)
		return

	_fully_loaded = true
	Logger.info("New picture (" + str(_id) + ") fully loaded")
	call_deferred("emit_signal", "slide_fully_loaded", _id)

# TODO Implement more exif orientations
# In some cases, picture rotation is only in EXIF data and rotations needs to be done manually
func _apply_exif_orientation():
	Logger.debug("picture_slide._apply_exif_orientation()")

	if _exif_orientation == 6:
		_sprite.call_deferred("set_rotation_degrees", 90)
	elif _exif_orientation == 3:
		_sprite.call_deferred("set_rotation_degrees", 180)
	elif _exif_orientation == 8:
		_sprite.call_deferred("set_rotation_degrees", -90)

# TODO change size if rotation needs to be done
#        if exif_orientation == 6 or exif_orientation == 8 or exif_orientation == 3:
# Picture needs to get resized so it fits into screen
func _resize_picture(image: Image):
	Logger.debug("picture_slide._resize_picture(image: Image)")

	var image_width = image.get_width()
	var image_height = image.get_height()
	
	# Check invalid input
	if image_width == 0 or image_height == 0:
		# Probably invalid input, drop slide
		emit_signal("slide_load_failed", _id)
		return
	
	var new_image_width = -1
	var new_image_height = -1
	
	# Ratio > 1 = Landscape; Ratio < 1 = Portrait
	var max_ratio = float(Config.get_max_picture_sprite_width()) / float(Config.get_max_picture_sprite_height())
	var image_ratio = float(image_width) / float(image_height)

	if image_ratio > max_ratio:
		new_image_width = int(Config.get_max_picture_sprite_width())
		new_image_height = int(float(image_height) * (float(Config.get_max_picture_sprite_width()) / float(image_width)))
	if image_ratio <= max_ratio:
		new_image_width = int(float(image_width) * (float(Config.get_max_picture_sprite_height()) / float(image_height)))
		new_image_height = int(Config.get_max_picture_sprite_height())

	if new_image_width != -1 and new_image_height != -1:
		image.resize(new_image_width, new_image_height, Image.INTERPOLATE_LANCZOS)
	else:
		# Invalid input, resize to default
		image.resize(Config.get_max_picture_sprite_width(), Config.get_max_picture_sprite_height(), Image.INTERPOLATE_LANCZOS)
