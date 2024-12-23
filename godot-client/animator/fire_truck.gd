extends Node2D

signal animation_ended
signal animation_started

const ANIMATION_GOING_LEFT: String = 'going_left'
const ANIMATION_GOING_RIGHT: String = 'going_right'

@export var animation_duration: float = 10.0

@onready var fire_truck = $AnimatedSprite2D

func get_animations() -> PackedStringArray:
	Logger.debug("fire_truck.get_animations() -> PackedStringArray")
	var result = PackedStringArray()
	result.append(ANIMATION_GOING_LEFT)
	result.append(ANIMATION_GOING_RIGHT)
	return result

func animate(animation: String):
	Logger.debug("fire_truck.animate(" + animation + ": String)")
	@warning_ignore("integer_division")
	fire_truck.play(animation)

	var frames = fire_truck.get_sprite_frames()
	var frame = frames.get_frame_texture(animation,0)
	var size = frame.get_size()

	var source_x = 0
	var source_y = Config.get_viewport_size().y - size.y/2
	var target_x = 0
	var target_y = Config.get_viewport_size().y - size.y/2

	if animation == ANIMATION_GOING_LEFT:
		source_x = Config.get_viewport_size().x + size.x/2
		target_x = 0 - size.x/2
	elif animation == ANIMATION_GOING_RIGHT:
		source_x = 0 - size.x/2
		target_x = Config.get_viewport_size().x + size.x/2

	fire_truck.position.x = source_x
	fire_truck.position.y = source_y
	var tween = get_tree().create_tween()
	tween.connect("finished", _on_tween_finished)
	emit_signal("animation_started")
	tween.tween_property(fire_truck, "position", Vector2(target_x, target_y), animation_duration)
	tween.tween_callback(queue_free)

func _on_tween_finished():
	Logger.debug("fire_truck._on_tween_finished()")
	emit_signal("animation_ended")
