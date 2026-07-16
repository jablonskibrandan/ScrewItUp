extends Node
class_name Spawner

signal stack_progress_changed(progress: float)
signal spawn_state_changed(is_spawning: bool)

@export var little_guy_scene: PackedScene

@export_category("Stack")
@export var guy_spacing_y: float = 65.0
@export var stack_wobble_x: float = 6.0

@export_category("Entry Movement")
@export var run_time: float = 0.8
@export var jump_height: float = 180.0
@export var jump_time: float = 0.7

@export_category("Scene Nodes")
@export var stack_root: Node2D
@export var stack_base_point: Marker2D

# Fixed world marker just beyond the original right side of the level.
@export var guy_spawn_point: Marker2D

# Fixed world marker where the guy stops running and begins jumping.
@export var run_target_point: Marker2D

@export var progress_top_point: Marker2D
@export var progress_goal_height: float = 1900.0

# The Little Guy that already exists when the game starts.
@export var starting_little_guy: Node2D

@export var game_manager: GameManager
@export var camera_controller: CameraController
@export var ending_cutscene: EndingCutscene

# Index zero is the starting Little Guy.
var next_stack_index: int = 1

var stack_base_position: Vector2
var highest_stack_y: float = 0.0

# The top Little Guy is idle. Everyone below the top is holding.
var current_top_guy: Node2D = null

# Blocks manual buying and auto-buying while a guy is moving.
var spawn_in_progress: bool = false

# Permanently blocks additional guys once the ending is reserved.
var ending_locked: bool = false


func _enter_tree() -> void:
	add_to_group("spawner")


func _ready() -> void:
	randomize()

	if little_guy_scene == null:
		push_error("Spawner needs Little Guy Scene assigned.")
		return

	if stack_root == null:
		push_error("Spawner needs Stack Root assigned.")
		return

	if guy_spawn_point == null:
		push_error("Spawner needs Guy Spawn Point assigned.")
		return

	if run_target_point == null:
		push_error("Spawner needs Run Target Point assigned.")
		return

	if game_manager == null:
		push_error("Spawner needs Game Manager assigned.")
		return

	if camera_controller == null:
		push_error("Spawner needs Camera Controller assigned.")
		return

	if progress_top_point == null:
		push_error("Spawner needs Progress Top Point assigned.")
		return

	if ending_cutscene == null:
		push_error("Spawner needs Ending Cutscene assigned.")
		return

	if starting_little_guy != null:
		stack_base_position = starting_little_guy.global_position
		current_top_guy = starting_little_guy

		# The starting Little Guy is initially the top of the stack.
		if current_top_guy.has_method("play_idle_animation"):
			current_top_guy.play_idle_animation()

	elif stack_base_point != null:
		stack_base_position = stack_base_point.global_position
	else:
		push_error(
			"Spawner needs either Starting Little Guy "
			+ "or Stack Base Point assigned."
		)
		return

	highest_stack_y = stack_base_position.y
	call_deferred("emit_stack_progress")


# GameManager checks this before charging for manual or automatic purchases.
func can_add_more_guys() -> bool:
	return not ending_locked and not spawn_in_progress


func is_spawning_guy() -> bool:
	return spawn_in_progress


func _set_spawn_in_progress(value: bool) -> void:
	if spawn_in_progress == value:
		return

	spawn_in_progress = value
	spawn_state_changed.emit(spawn_in_progress)


func add_guy_to_stack() -> void:
	if not can_add_more_guys():
		return

	if little_guy_scene == null:
		push_error("Little Guy Scene is not assigned.")
		return

	if guy_spawn_point == null:
		push_error("Guy Spawn Point is not assigned.")
		return

	if run_target_point == null:
		push_error("Run Target Point is not assigned.")
		return

	var stack_index = next_stack_index
	var target_position = get_stack_position(stack_index)
	var reaches_ending = _position_reaches_ending(target_position)

	if reaches_ending:
		target_position.y = progress_top_point.global_position.y
		ending_locked = true

	var guy = little_guy_scene.instantiate() as Node2D

	if guy == null:
		push_error(
			"Little Guy Scene did not instantiate as a Node2D."
		)

		if reaches_ending:
			ending_locked = false

		return

	# This happens before the first await, so the UI and auto-buyer lock
	# immediately when this function is called.
	_set_spawn_in_progress(true)

	stack_root.add_child(guy)

	var is_rare = false

	if game_manager != null:
		is_rare = game_manager.roll_for_rare_guy()

	if guy.has_method("setup"):
		guy.setup(is_rare)

	guy.global_position = guy_spawn_point.global_position
	guy.z_index = 100 + stack_index

	if guy.has_method("play_pop_sfx"):
		guy.play_pop_sfx()

	next_stack_index += 1

	# Stage one: run left from the fixed right-side entry point.
	await run_guy_to_jump_point(guy)

	if not is_instance_valid(guy):
		_cancel_spawn(reaches_ending)
		return

	# Stage two: jump from the fixed jump point to the stack top.
	await jump_guy_to_position(guy, target_position)

	if not is_instance_valid(guy):
		_cancel_spawn(reaches_ending)
		return

	guy.global_position = target_position

	# The previous top Little Guy now has someone standing on it.
	if current_top_guy != null and is_instance_valid(current_top_guy):
		if current_top_guy.has_method("play_holding_animation"):
			current_top_guy.play_holding_animation()

	# The new Little Guy becomes the top and stays idle.
	current_top_guy = guy

	if current_top_guy.has_method("play_idle_animation"):
		current_top_guy.play_idle_animation()

	# Count the exact same rarity value that was used for the appearance.
	if game_manager != null:
		game_manager.add_little_guy_count(is_rare)

	register_stack_position(target_position)

	if camera_controller != null:
		camera_controller.check_camera_page_up(target_position)

	_set_spawn_in_progress(false)

	if reaches_ending:
		check_for_ending(guy)


func _cancel_spawn(reserved_ending: bool) -> void:
	if reserved_ending:
		ending_locked = false

	next_stack_index = maxi(1, next_stack_index - 1)
	_set_spawn_in_progress(false)


func run_guy_to_jump_point(guy: Node2D) -> void:
	if not is_instance_valid(guy):
		return

	if guy.has_method("play_run_animation"):
		guy.play_run_animation()

	var target_position = run_target_point.global_position
	var tween = create_tween()

	tween.tween_property(
		guy,
		"global_position",
		target_position,
		run_time
	).set_trans(Tween.TRANS_LINEAR)

	await tween.finished

	if is_instance_valid(guy):
		guy.global_position = target_position


func jump_guy_to_position(
	guy: Node2D,
	target_position: Vector2
) -> void:
	if not is_instance_valid(guy):
		return

	if guy.has_method("play_jump_animation"):
		guy.play_jump_animation()

	var start_position = guy.global_position
	var peak_position = start_position.lerp(target_position, 0.5)
	peak_position.y -= jump_height

	var tween = create_tween()

	tween.tween_method(
		func(t: float) -> void:
			if not is_instance_valid(guy):
				return

			guy.global_position = quadratic_bezier(
				start_position,
				peak_position,
				target_position,
				t
			),
		0.0,
		1.0,
		jump_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await tween.finished

	if is_instance_valid(guy):
		guy.global_position = target_position


func add_starting_guy() -> void:
	if little_guy_scene == null:
		push_error("Little Guy Scene is not assigned.")
		return

	var stack_index = 0
	var guy = little_guy_scene.instantiate() as Node2D

	if guy == null:
		push_error(
			"Little Guy Scene did not instantiate as a Node2D."
		)
		return

	stack_root.add_child(guy)

	var target_position := get_stack_position(stack_index)

	if guy.has_method("setup"):
		guy.setup(false)

	if guy.has_method("play_idle_animation"):
		guy.play_idle_animation()

	# This dynamically created guy is the initial top of the stack.
	current_top_guy = guy

	guy.global_position = target_position
	guy.z_index = 100 + stack_index

	next_stack_index = 1
	register_stack_position(target_position)


func get_stack_position(index: int) -> Vector2:
	var x = stack_base_position.x + randf_range(
		-stack_wobble_x,
		stack_wobble_x
	)
	var y := stack_base_position.y - index * guy_spacing_y

	return Vector2(x, y)


func _position_reaches_ending(position: Vector2) -> bool:
	if progress_top_point == null:
		return false

	return position.y <= progress_top_point.global_position.y


func register_stack_position(position: Vector2) -> void:
	if highest_stack_y == 0.0 or position.y < highest_stack_y:
		highest_stack_y = position.y

	emit_stack_progress()


func get_stack_progress() -> float:
	var top_y: float

	if progress_top_point != null:
		top_y = progress_top_point.global_position.y
	else:
		top_y = stack_base_position.y - progress_goal_height

	var total_height = stack_base_position.y - top_y

	if total_height <= 0.0:
		return 0.0

	var climbed_height := stack_base_position.y - highest_stack_y

	return clamp(
		climbed_height / total_height,
		0.0,
		1.0
	)


func emit_stack_progress() -> void:
	stack_progress_changed.emit(get_stack_progress())


func quadratic_bezier(
	a: Vector2,
	b: Vector2,
	c: Vector2,
	t: float
) -> Vector2:
	var ab = a.lerp(b, t)
	var bc = b.lerp(c, t)

	return ab.lerp(bc, t)


func check_for_ending(highest_little_guy: Node2D) -> void:
	if ending_cutscene == null or progress_top_point == null:
		return

	if highest_little_guy.global_position.y <= \
		progress_top_point.global_position.y:
		ending_cutscene.start_ending()
