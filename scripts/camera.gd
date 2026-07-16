extends Node
class_name CameraController

@export var camera: Camera2D

# How close to the top of the visible world before scrolling.
# Smaller = closer to top. Larger = earlier.
@export var top_screen_margin: float = 90.0

# After scrolling, the guy will be this far above the bottom.
@export var bottom_screen_margin: float = 110.0

@export var camera_move_time: float = 0.45

var camera_target_y: float
var camera_is_moving: bool = false


func _ready() -> void:
	if camera == null:
		push_error("CameraController needs a Camera2D assigned.")
		return

	camera.make_current()
	camera_target_y = camera.global_position.y

	print("Camera ready")
	print("Camera zoom: ", camera.zoom)
	print("Visible height: ", get_visible_screen_height_in_world_units())


func check_camera_page_up(new_guy_position: Vector2) -> void:
	if camera == null:
		return

	var visible_height = get_visible_screen_height_in_world_units()

	var camera_top_y = camera_target_y - visible_height / 2.0
	var camera_bottom_y = camera_target_y + visible_height / 2.0
	var trigger_y = camera_top_y + top_screen_margin

	print("--- CAMERA CHECK ---")
	print("Guy Y: ", new_guy_position.y)
	print("Camera target Y: ", camera_target_y)
	print("Visible height: ", visible_height)
	print("Camera top Y: ", camera_top_y)
	print("Camera bottom Y: ", camera_bottom_y)
	print("Trigger Y: ", trigger_y)

	if new_guy_position.y <= trigger_y:
		scroll_camera_so_guy_is_near_bottom(new_guy_position)


func scroll_camera_so_guy_is_near_bottom(guy_position: Vector2) -> void:
	if camera_is_moving:
		return

	var visible_height = get_visible_screen_height_in_world_units()

	var desired_camera_y = guy_position.y + bottom_screen_margin - visible_height / 2.0

	# Important: never scroll downward.
	# In Godot, lower Y means higher up.
	if desired_camera_y >= camera_target_y:
		print("Not scrolling because desired camera Y would move down.")
		print("Desired Y: ", desired_camera_y)
		print("Current target Y: ", camera_target_y)
		return

	camera_target_y = desired_camera_y
	camera_is_moving = true

	print("Scrolling camera to Y: ", camera_target_y)

	var tween = create_tween()
	tween.tween_property(
		camera,
		"global_position:y",
		camera_target_y,
		camera_move_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.finished.connect(
		func():
			camera.global_position.y = camera_target_y
			camera_is_moving = false
	)


func get_visible_screen_height_in_world_units() -> float:
	if camera == null:
		return 0.0

	var viewport_height = get_viewport().get_visible_rect().size.y

	if camera.zoom.y == 0:
		return viewport_height

	return viewport_height / camera.zoom.y
