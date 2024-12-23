extends Node2D

signal animation_ended
signal animation_started

#const ANIMATION_GOING_LEFT: String = 'going_left'
const ANIMATION_GOING_RIGHT: String = 'going_right'

@export var animation_duration: float = 10.0

@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	# Initialize random number generator
	randomize()

func get_animations() -> PackedStringArray:
	Logger.debug("trash_truck.get_animations() -> PackedStringArray")
	var result = PackedStringArray()
	#result.append(ANIMATION_GOING_LEFT)
	result.append(ANIMATION_GOING_RIGHT)
	return result

func animate(animation: String):
	Logger.debug("trash_truck.animate(" + animation + ": String)")
	animated_sprite.play(animation)

	var frames = animated_sprite.get_sprite_frames()
	var frame = frames.get_frame_texture(animation,0)
	var size = frame.get_size()

	@warning_ignore("integer_division")
	var random_offset_y = randi_range(0, Config.get_viewport_size().y/2)
	var source_x = 0
	@warning_ignore("integer_division")
	var source_y = int(Config.get_viewport_size().y - size.y/2)
	var target_x = 0
	@warning_ignore("integer_division")
	var target_y = int(Config.get_viewport_size().y - size.y/2)

	#if animation == ANIMATION_GOING_LEFT:
	#	source_x = Config.get_viewport_size().x + size.x/2
	#	target_x = 0 - size.x/2
	if animation == ANIMATION_GOING_RIGHT:
		source_x = 0 - size.x/2
		target_x = Config.get_viewport_size().x + size.x/2

	animated_sprite.position.x = source_x
	animated_sprite.position.y = source_y
	var tween = get_tree().create_tween()
	tween.connect("finished", _on_tween_finished)
	emit_signal("animation_started")
	tween.tween_property(animated_sprite, "position", Vector2(target_x, target_y), animation_duration)
	tween.tween_callback(queue_free)

func _on_tween_finished():
	Logger.debug("trash_truck._on_tween_finished()")
	emit_signal("animation_ended")
