extends Node2D

signal animation_ended
signal animation_started

const ANIMATION_FLY_LEFT: String = "fly_left"
const ANIMATION_FLY_RIGHT: String = "fly_right"

const INTERNAL_ANIMATION_FLAP_LEFT: String = "flap_left"
const INTERNAL_ANIMATION_FLAP_RIGHT: String = "flap_right"
const INTERNAL_ANIMATION_HOVER_LEFT: String = "hover_left"
const INTERNAL_ANIMATION_HOVER_RIGHT: String = "hover_right"

@export var animation_duration: float = 10.0

@onready var crow = $AnimatedSprite2D

var _selected_animation: String = ""
var _loop_counter: int = 0

func _ready():
	# Initialize random number generator
	randomize()

func get_animations() -> PackedStringArray:
	Logger.debug("crow.get_animations() -> PackedStringArray")
	var result = PackedStringArray()
	result.append(ANIMATION_FLY_LEFT)
	result.append(ANIMATION_FLY_RIGHT)
	return result

func animate(animation: String):
	Logger.debug("crow.animate(" + animation + ": String)")
	if ! get_animations().has(animation):
		return

	_selected_animation = animation
	
	crow.play(_get_flap_animation())
	crow.connect("animation_looped", _on_animation_looped)

	var frames = crow.get_sprite_frames()
	var frame = frames.get_frame_texture(_get_flap_animation(),0)
	var size = frame.get_size()

	@warning_ignore("integer_division")
	var random_offset_y: int = randi_range(0, int(Config.get_viewport_size().y/2))
	var source_x: int = 0
	@warning_ignore("integer_division")
	var source_y: int = int(Config.get_viewport_size().y/8) + int(size.y/2) + random_offset_y
	var target_x: int = 0
	@warning_ignore("integer_division")
	var target_y: int = int(Config.get_viewport_size().y/8) + int(size.y/2) + random_offset_y

	if _get_direction() == "left":
		source_x = Config.get_viewport_size().x + size.x/2
		target_x = 0 - size.x/2
	elif _get_direction() == "right":
		source_x = 0 - size.x/2
		target_x = Config.get_viewport_size().x + size.x/2

	crow.position.x = source_x
	crow.position.y = source_y
	var tween = get_tree().create_tween()
	tween.connect("finished", _on_tween_finished)
	emit_signal("animation_started")
	tween.tween_property(crow, "position", Vector2(target_x, target_y), animation_duration)
	tween.tween_callback(queue_free)

func _get_direction() -> String:
	var animation_string_array = _selected_animation.split("_")
	range(animation_string_array.size())
	var direction = animation_string_array[1]
	return direction

func _get_flap_animation() -> String:
	if _get_direction() == "right":
		return INTERNAL_ANIMATION_FLAP_RIGHT
	return INTERNAL_ANIMATION_FLAP_LEFT

func _get_hover_animation() -> String:
	if _get_direction() == "right":
		return INTERNAL_ANIMATION_HOVER_RIGHT
	return INTERNAL_ANIMATION_HOVER_LEFT

func _on_animation_looped():
	_loop_counter += 1
	if _loop_counter >= randi_range(1, 4):
		if crow.animation == _get_flap_animation():
			crow.play(_get_hover_animation())
		elif crow.animation == _get_hover_animation():
			crow.play(_get_flap_animation())
		_loop_counter = 0

func _on_tween_finished():
	Logger.debug("crow._on_tween_finished()")
	emit_signal("animation_ended")
