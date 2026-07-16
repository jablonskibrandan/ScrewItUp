extends AnimatedSprite2D

@export var sway_degrees: float = 4.0
@export var sway_speed: float = 1.5

var time: float = 0.0

func _ready() -> void:
	await get_tree().process_frame

func _process(delta: float) -> void:
	time += delta

	var sway = sin(time * TAU * sway_speed)
	rotation_degrees = sway * sway_degrees
