extends TextureButton

var normal_scale := Vector2.ONE
var highlighted_scale := Vector2(1.08, 1.08)
var tween: Tween

func _ready() -> void:
	focus_mode = Control.FOCUS_ALL

	await get_tree().process_frame
	pivot_offset = size / 2.0

	focus_entered.connect(_highlight)
	focus_exited.connect(_unhighlight)
	mouse_entered.connect(_highlight)
	mouse_exited.connect(_unhighlight)

func _highlight() -> void:
	if tween:
		tween.kill()

	tween = create_tween()
	tween.tween_property(self, "scale", highlighted_scale, 0.2)

func _unhighlight() -> void:
	if tween:
		tween.kill()

	tween = create_tween()
	tween.tween_property(self, "scale", normal_scale, 0.2)
