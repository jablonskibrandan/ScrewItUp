extends Node2D
@onready var sprite: Sprite2D = $Sprite2D
const idea_lamp = preload("uid://ketwc3ehaks2")
const bright_idea_lamp= preload("uid://cfurqvmpb1o65")
var is_rare: bool = false
@export var little_guy_pop: AudioStreamPlayer
@export var rare_guy_pop: AudioStreamPlayer
@export var pop_sfx_delay: float = 0.35

func _ready() -> void:
	ManagerCommunication.little_guy_idea_lamp.connect(on_idea_lamp)
	ManagerCommunication.little_guy_bright_idea_lamp.connect(on_bright_idea_lamp)
func setup(rare: bool) -> void:
	is_rare = rare

	if is_rare:
		sprite.modulate = Color(0.2, 0.9, 1.0)
	else:
		sprite.modulate = Color.WHITE


func play_pop_sfx() -> void:
	#Otherwise we play right away which doesn't feel right.
	await get_tree().create_timer(pop_sfx_delay).timeout

	var player: AudioStreamPlayer

	if is_rare:
		player = rare_guy_pop
	else:
		player = little_guy_pop

	if player == null:
		print("Pop sound player is null.")
		return

	if player.stream == null:
		print("Pop sound player has no stream assigned.")
		return

	player.stop()
	player.play()


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
	
	if is_rare:
		rare_guy_pop.play()
	else:
		little_guy_pop.play()


func _bezier(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	var ab := a.lerp(b, t)
	var bc := b.lerp(c, t)
	return ab.lerp(bc, t)
func _spawn_lamp(texture: Texture2D) -> void:
	var lamp_sprite := Sprite2D.new()
	lamp_sprite.texture = texture
	if texture == idea_lamp:
		lamp_sprite.position = position + Vector2(23, -10)
	elif texture == bright_idea_lamp:
		lamp_sprite.position = position + Vector2(-23, -10)
	lamp_sprite.scale = Vector2(0.03, 0.03)
	get_parent().add_child(lamp_sprite)

	var tween := create_tween()
	tween.tween_property(lamp_sprite, "modulate:a", 0.0, 0.6) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN)
	tween.tween_callback(lamp_sprite.queue_free)


func on_idea_lamp() -> void:
	_spawn_lamp(idea_lamp)


func on_bright_idea_lamp() -> void:
	_spawn_lamp(bright_idea_lamp)
