extends Node
class_name Spawner

signal stack_progress_changed(progress: float)

@export var little_guy_scene: PackedScene

@export var guy_spacing_y: float = 65.0
@export var stack_wobble_x: float = 6.0
@export var jump_height: float = 180.0
@export var jump_time: float = 0.45

@export var stack_root: Node2D
@export var stack_base_point: Marker2D
@export var guy_spawn_point: Marker2D
@export var progress_top_point: Marker2D
@export var progress_goal_height: float = 1900.0

# Assign the little guy that already exists when the game starts.
# This makes the first bought guy stack directly above him.
@export var starting_little_guy: Node2D

@export var game_manager: GameManager
@export var camera_controller: CameraController
@export var ending_cutscene: EndingCutscene

# Index 0 is the starting little guy.
# First purchased little guy goes to index 1.
var next_stack_index: int = 1

var stack_base_position: Vector2
var spawn_position: Vector2
var highest_stack_y: float = 0.0

# Becomes true as soon as the final Little Guy is reserved.
# This blocks clicks and autobuy while that final guy is still jumping.
var ending_locked: bool = false


func _enter_tree() -> void:
	add_to_group("spawner")


func _ready() -> void:
	randomize()

	if little_guy_scene == null:
		push_error("Spawner needs Little Guy Scene assigned.")

	if stack_root == null:
		push_error("Spawner needs Stack Root assigned.")
		return

	if guy_spawn_point == null:
		push_error("Spawner needs Guy Spawn Point assigned.")
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
	elif stack_base_point != null:
		stack_base_position = stack_base_point.global_position
	else:
		push_error("Spawner needs either Starting Little Guy or Stack Base Point assigned.")
		return

	spawn_position = guy_spawn_point.global_position
	highest_stack_y = stack_base_position.y
	call_deferred("emit_stack_progress")

	print("Spawner ready.")
	print("Stack base position: ", stack_base_position)
	print("Spawn position: ", spawn_position)


# GameManager calls this before charging for either a manual or automatic guy.
func can_add_more_guys() -> bool:
	return not ending_locked


func add_guy_to_stack() -> void:
	if ending_locked:
		return

	if little_guy_scene == null:
		push_error("Little Guy Scene is not assigned.")
		return

	var stack_index := next_stack_index
	var target_position := get_stack_position(stack_index)
	var reaches_ending := _position_reaches_ending(target_position)

	# The normal spacing may put the final guy slightly above the marker.
	# Clamp that final guy to the marker so the stack never passes it.
	if reaches_ending:
		target_position.y = progress_top_point.global_position.y

		# Lock immediately, before the jump finishes. This prevents another
		# click or autobuy tick from adding an extra guy during the animation.
		ending_locked = true

	var guy := little_guy_scene.instantiate() as Node2D
	stack_root.add_child(guy)

	var is_rare := false

	if game_manager != null:
		is_rare = game_manager.roll_for_rare_guy()

	if guy.has_method("setup"):
		guy.setup(is_rare)

	# The Spawner knows whether the new guy is rare, so it updates the count.
	if game_manager != null:
		game_manager.add_little_guy_count(is_rare)

	if guy.has_method("play_pop_sfx"):
		guy.play_pop_sfx()

	guy.global_position = spawn_position
	guy.z_index = 100 + stack_index

	next_stack_index += 1

	jump_guy_to_position(guy, target_position, reaches_ending)


func add_starting_guy() -> void:
	if little_guy_scene == null:
		push_error("Little Guy Scene is not assigned.")
		return

	var stack_index := 0

	var guy := little_guy_scene.instantiate() as Node2D
	stack_root.add_child(guy)

	var target_position := get_stack_position(stack_index)

	if guy.has_method("setup"):
		guy.setup(false)

	guy.global_position = target_position
	guy.z_index = 100 + stack_index

	next_stack_index = 1
	register_stack_position(target_position)

	print("Starting guy added at: ", target_position)


func jump_guy_to_position(
	guy: Node2D,
	target_position: Vector2,
	starts_ending: bool = false
) -> void:
	var start_position := guy.global_position
	var peak_position := start_position.lerp(target_position, 0.5)
	peak_position.y -= jump_height

	var tween := create_tween()

	tween.tween_method(
		func(t: float):
			guy.global_position = quadratic_bezier(
				start_position,
				peak_position,
				target_position,
				t
			),
		0.0,
		1.0,
		jump_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	tween.finished.connect(
		func():
			guy.global_position = target_position
			register_stack_position(target_position)

			if camera_controller != null:
				camera_controller.check_camera_page_up(target_position)

			# Only check after the guy has actually reached the stack.
			if starts_ending:
				check_for_ending(guy)
	)


func get_stack_position(index: int) -> Vector2:
	var x := stack_base_position.x + randf_range(
		-stack_wobble_x,
		stack_wobble_x
	)
	var y := stack_base_position.y - index * guy_spacing_y

	return Vector2(x, y)


func _position_reaches_ending(position: Vector2) -> bool:
	if progress_top_point == null:
		return false

	# Smaller Y values are higher in Godot.
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

	var total_height := stack_base_position.y - top_y

	if total_height <= 0.0:
		return 0.0

	var climbed_height := stack_base_position.y - highest_stack_y
	return clamp(climbed_height / total_height, 0.0, 1.0)


func emit_stack_progress() -> void:
	stack_progress_changed.emit(get_stack_progress())


func quadratic_bezier(
	a: Vector2,
	b: Vector2,
	c: Vector2,
	t: float
) -> Vector2:
	var ab := a.lerp(b, t)
	var bc := b.lerp(c, t)

	return ab.lerp(bc, t)


func check_for_ending(highest_little_guy: Node2D) -> void:
	if ending_cutscene == null or progress_top_point == null:
		return

	if highest_little_guy.global_position.y <= \
		progress_top_point.global_position.y:
		ending_cutscene.start_ending()
