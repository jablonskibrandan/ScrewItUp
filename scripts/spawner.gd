extends Node
class_name Spawner

@export var little_guy_scene: PackedScene

@export var guy_spacing_y: float = 65.0
@export var stack_wobble_x: float = 14.0
@export var jump_height: float = 180.0
@export var jump_time: float = 0.45

@export var stack_root: Node2D
@export var stack_base_point: Marker2D
@export var guy_spawn_point: Marker2D

@export var game_manager: GameManager
@export var camera_controller: CameraController

var stack_base_position: Vector2
var spawn_position: Vector2


func _ready() -> void:
	randomize()

	if little_guy_scene == null:
		push_error("Spawner needs Little Guy Scene assigned.")

	if stack_root == null:
		push_error("Spawner needs Stack Root assigned.")
		return

	if stack_base_point == null:
		push_error("Spawner needs Stack Base Point assigned.")
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

	stack_base_position = stack_base_point.global_position
	spawn_position = guy_spawn_point.global_position

	print("Spawner ready.")
	print("Stack base position: ", stack_base_position)
	print("Spawn position: ", spawn_position)


func add_guy_to_stack() -> void:
	if little_guy_scene == null:
		push_error("Little Guy Scene is not assigned.")
		return

	if stack_root == null:
		push_error("Stack Root is not assigned.")
		return

	if game_manager == null:
		push_error("Game Manager is not assigned.")
		return

	var current_amount := game_manager.get_amt_little_guys()
	var stack_index := current_amount

	var guy := little_guy_scene.instantiate() as Node2D
	stack_root.add_child(guy)

	var target_position := get_stack_position(stack_index)

	guy.global_position = spawn_position
	guy.z_index = 100 + stack_index

	game_manager.set_amt_little_guys(current_amount + 1)

	print("Spawn position: ", spawn_position)
	print("Target position: ", target_position)
	print("Current camera: ", get_viewport().get_camera_2d().global_position)
	print("Stack children: ", stack_root.get_child_count())

	jump_guy_to_position(guy, target_position)


func add_starting_guy() -> void:
	if little_guy_scene == null:
		push_error("Little Guy Scene is not assigned.")
		return

	if stack_root == null:
		push_error("Stack Root is not assigned.")
		return

	var guy := little_guy_scene.instantiate() as Node2D
	stack_root.add_child(guy)

	var target_position := get_stack_position(0)

	guy.global_position = target_position
	guy.z_index = 100

	if game_manager != null and game_manager.get_amt_little_guys() < 1:
		game_manager.set_amt_little_guys(1)

	print("Starting guy added at: ", target_position)


func jump_guy_to_position(guy: Node2D, target_position: Vector2) -> void:
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

			if camera_controller != null:
				camera_controller.check_camera_page_up(target_position)
	)


func get_stack_position(index: int) -> Vector2:
	var x := stack_base_position.x + randf_range(-stack_wobble_x, stack_wobble_x)
	var y := stack_base_position.y - index * guy_spacing_y

	return Vector2(x, y)


func quadratic_bezier(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	var ab := a.lerp(b, t)
	var bc := b.lerp(c, t)

	return ab.lerp(bc, t)
