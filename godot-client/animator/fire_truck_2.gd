extends CharacterBody2D

@onready var _animation_player = $AnimationPlayer

func going_left():
	_animation_player.play("going_left")

func going_right():
	_animation_player.play("going_left")
