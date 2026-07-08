extends Control

@export var sway_degrees: float = 4.0
@export var sway_speed: float = 1.5

var time: float = 0.0

func _ready() -> void:
	await get_tree().process_frame
	_update_pivot()
	resized.connect(_update_pivot)

func _process(delta: float) -> void:
	time += delta
	var sway := sin(time * TAU * sway_speed)
	rotation_degrees = sway * sway_degrees

func _update_pivot() -> void:
	pivot_offset = size / 2.0
