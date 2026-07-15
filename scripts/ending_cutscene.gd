extends Node
class_name EndingCutscene


@export_category("Cutscene Sprites")
@export var first_cutscene_sprite: Sprite2D
@export var second_cutscene_sprite: Sprite2D

@export_category("Ending Trigger")
@export var progress_top_point: Node2D

@export_category("Timing")
@export var time_before_second_sprite: float = 3.0
@export var time_before_main_menu: float = 3.0

@export_category("Scene")
@export var main_menu_scene: PackedScene


var ending_started: bool = false


func _ready() -> void:
	# This controller must continue running while the game is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS

	if first_cutscene_sprite != null:
		first_cutscene_sprite.visible = false

	if second_cutscene_sprite != null:
		second_cutscene_sprite.visible = false


func check_for_ending(highest_little_guy: Node2D) -> void:
	if ending_started:
		return

	if highest_little_guy == null:
		return

	if progress_top_point == null:
		push_error("EndingCutscene needs Progress Top Point assigned.")
		return

	# Smaller Y values are higher in Godot.
	if highest_little_guy.global_position.y <= \
			progress_top_point.global_position.y:
		start_ending()


func start_ending() -> void:
	if ending_started:
		return

	ending_started = true

	if first_cutscene_sprite != null:
		first_cutscene_sprite.visible = true

	if second_cutscene_sprite != null:
		second_cutscene_sprite.visible = false

	# Stops spawning, auto-buying, production, and gameplay input.
	get_tree().paused = true

	# Wait while the tree is paused.
	await get_tree().create_timer(
		time_before_second_sprite,
		true
	).timeout

	if first_cutscene_sprite != null:
		first_cutscene_sprite.visible = false

	if second_cutscene_sprite != null:
		second_cutscene_sprite.visible = true

	# Leave the second ending image visible for a few seconds.
	await get_tree().create_timer(
		time_before_main_menu,
		true
	).timeout

	_return_to_main_menu()


func _return_to_main_menu() -> void:
	if main_menu_scene == null:
		push_error("EndingCutscene needs Main Menu Scene assigned.")

		# Avoid leaving the game permanently paused after the error.
		get_tree().paused = false
		return

	# Pausing belongs to the SceneTree, so it must be cleared before
	# loading the main menu.
	get_tree().paused = false

	get_tree().change_scene_to_packed(main_menu_scene)
