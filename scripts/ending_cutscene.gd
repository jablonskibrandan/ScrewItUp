extends Node
class_name EndingCutscene


@export var first_cutscene_sprite: Sprite2D
@export var second_cutscene_sprite: Sprite2D
@export var progress_top_point: Node2D

@export var time_before_second_sprite: float = 3.0


var ending_started: bool = false


func _ready() -> void:
	# This controller must continue after the game is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS

	first_cutscene_sprite.visible = false
	second_cutscene_sprite.visible = false


func check_for_ending(highest_little_guy: Node2D) -> void:
	if ending_started:
		return

	# Smaller Y values are higher in Godot.
	if highest_little_guy.global_position.y <= \
			progress_top_point.global_position.y:
		start_ending()


func start_ending() -> void:
	if ending_started:
		return

	ending_started = true

	# Show the first image.
	first_cutscene_sprite.visible = true
	second_cutscene_sprite.visible = false

	# Stops spawning, autobuy, idea generation, and button input.
	get_tree().paused = true

	# Continue waiting even though the game is paused.
	await get_tree().create_timer(
		time_before_second_sprite,
		true
	).timeout

	# Replace the first visible sprite with the second.
	first_cutscene_sprite.visible = false
	second_cutscene_sprite.visible = true
