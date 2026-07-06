extends Node2D

@onready var sprite: Sprite2D = $Sprite2D

var is_rare: bool = false


func setup(rare: bool) -> void:
	is_rare = rare

	if is_rare:
		# Temporary rare guy visual.
		sprite.modulate = Color(0.2, 0.9, 1.0)
	else:
		sprite.modulate = Color.WHITE


func jump_to_stack(target_position: Vector2) -> void:
	var start_position := global_position
	var peak_position := start_position.lerp(target_position, 0.5)
	peak_position.y -= 180.0

	var tween := create_tween()

	tween.tween_method(
		func(t: float):
			global_position = _bezier(start_position, peak_position, target_position, t),
		0.0,
		1.0,
		0.45
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _bezier(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	var ab := a.lerp(b, t)
	var bc := b.lerp(c, t)
	return ab.lerp(bc, t)
