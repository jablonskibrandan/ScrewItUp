extends Control
class_name StackProgressBar

@export var spawner: Spawner

@export var top_padding: float = 10.0
@export var bottom_padding: float = 14.0

@onready var progress_bar_image: TextureRect = $ProgressBarImage
@onready var progress_guy_marker: TextureRect = $ProgressGuyMarker


func _ready() -> void:
	await get_tree().process_frame

	if spawner == null:
		spawner = get_tree().get_first_node_in_group("spawner") as Spawner

	if spawner == null:
		print("StackProgressBar could not find Spawner")
		return

	var progress_callable := Callable(self, "set_progress")
	if not spawner.stack_progress_changed.is_connected(progress_callable):
		spawner.stack_progress_changed.connect(progress_callable)

	set_progress(spawner.get_stack_progress())


func set_progress(progress: float) -> void:
	if progress_bar_image == null or progress_guy_marker == null:
		return

	progress = clamp(progress, 0.0, 1.0)

	var bar_top := progress_bar_image.position.y + top_padding
	var bar_bottom := progress_bar_image.position.y + progress_bar_image.size.y - bottom_padding
	var marker_y = lerp(bar_bottom, bar_top, progress)

	progress_guy_marker.position.x = progress_bar_image.position.x + (progress_bar_image.size.x - progress_guy_marker.size.x) / 2.0
	progress_guy_marker.position.y = marker_y - progress_guy_marker.size.y / 2.0
