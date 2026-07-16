extends Node2D

@onready var sprite: AnimatedSprite2D = $Sprite2D

const IDEA_LAMP: Texture2D = preload("uid://ketwc3ehaks2")
const BRIGHT_IDEA_LAMP: Texture2D = preload("uid://cfurqvmpb1o65")

const IDLE_ANIMATION: StringName = &"idle"
const RUNNING_ANIMATION: StringName = &"running"
const JUMPING_ANIMATION: StringName = &"jumping"
const HOLDING_ANIMATION: StringName = &"holding"

# Every animation is resized to this displayed height.
@export var target_sprite_height: float = 32.0

@export var little_guy_pop: AudioStreamPlayer
@export var rare_guy_pop: AudioStreamPlayer
@export var pop_sfx_delay: float = 0.35

var is_rare: bool = false


func _ready() -> void:
	# Keep the root at normal world scale.
	scale = Vector2.ONE

	add_to_group("little_guys")
	_configure_animation_loops()
	play_idle_animation()

	var idea_callable = Callable(self, "on_idea_lamp")
	var bright_callable = Callable(self, "on_bright_idea_lamp")

	if not ManagerCommunication.little_guy_idea_lamp.is_connected(
		idea_callable
	):
		ManagerCommunication.little_guy_idea_lamp.connect(
			idea_callable
		)

	if not ManagerCommunication.little_guy_bright_idea_lamp.is_connected(
		bright_callable
	):
		ManagerCommunication.little_guy_bright_idea_lamp.connect(
			bright_callable
		)


func _exit_tree() -> void:
	var idea_callable = Callable(self, "on_idea_lamp")
	var bright_callable = Callable(self, "on_bright_idea_lamp")

	if ManagerCommunication.little_guy_idea_lamp.is_connected(
		idea_callable
	):
		ManagerCommunication.little_guy_idea_lamp.disconnect(
			idea_callable
		)

	if ManagerCommunication.little_guy_bright_idea_lamp.is_connected(
		bright_callable
	):
		ManagerCommunication.little_guy_bright_idea_lamp.disconnect(
			bright_callable
		)


func setup(rare: bool) -> void:
	is_rare = rare

	if is_rare:
		sprite.modulate = Color(0.2, 0.9, 1.0)
	else:
		sprite.modulate = Color.WHITE


func _configure_animation_loops() -> void:
	if sprite == null or sprite.sprite_frames == null:
		return

	if sprite.sprite_frames.has_animation(IDLE_ANIMATION):
		sprite.sprite_frames.set_animation_loop(
			IDLE_ANIMATION,
			true
		)

	if sprite.sprite_frames.has_animation(RUNNING_ANIMATION):
		sprite.sprite_frames.set_animation_loop(
			RUNNING_ANIMATION,
			true
		)

	if sprite.sprite_frames.has_animation(JUMPING_ANIMATION):
		sprite.sprite_frames.set_animation_loop(
			JUMPING_ANIMATION,
			false
		)

	if sprite.sprite_frames.has_animation(HOLDING_ANIMATION):
		sprite.sprite_frames.set_animation_loop(
			HOLDING_ANIMATION,
			true
		)


func play_idle_animation() -> void:
	_play_animation_at_target_height(IDLE_ANIMATION)


func play_run_animation() -> void:
	_play_animation_at_target_height(RUNNING_ANIMATION)


func play_jump_animation() -> void:
	_play_animation_at_target_height(JUMPING_ANIMATION)


func play_holding_animation() -> void:
	_play_animation_at_target_height(HOLDING_ANIMATION)


func _play_animation_at_target_height(
	animation_name: StringName
) -> void:
	if sprite == null or sprite.sprite_frames == null:
		return

	if not sprite.sprite_frames.has_animation(animation_name):
		push_warning(
			"Little Guy is missing animation: %s"
			% animation_name
		)
		return

	sprite.play(animation_name)
	sprite.frame = 0

	var frame_texture = sprite.sprite_frames.get_frame_texture(
		animation_name,
		0
	)

	if frame_texture == null:
		return

	var source_height = float(frame_texture.get_height())

	if source_height <= 0.0:
		return

	var correct_scale = target_sprite_height / source_height
	sprite.scale = Vector2(correct_scale, correct_scale)


func _spawn_lamp(
	texture: Texture2D,
	_is_bright: bool = false
) -> void:
	if texture == null:
		return

	var lamp_sprite = Sprite2D.new()
	lamp_sprite.texture = texture
	lamp_sprite.centered = true
	lamp_sprite.z_as_relative = false
	lamp_sprite.z_index = 1000

	get_tree().current_scene.add_child(lamp_sprite)

	var random_x = randf_range(-4.0, 4.0)
	var random_y = randf_range(-3.0, 2.0)
	var head_offset = Vector2(
		random_x,
		-(target_sprite_height * 0.7) + random_y
	)

	lamp_sprite.global_position = global_position + head_offset

	var lamp_texture_height = float(texture.get_height())

	if lamp_texture_height > 0.0:
		var target_lamp_height = (
			target_sprite_height
			* randf_range(0.85, 1.1)
		)
		var lamp_scale = target_lamp_height / lamp_texture_height
		lamp_sprite.scale = Vector2(lamp_scale, lamp_scale)
	else:
		lamp_sprite.scale = Vector2(0.25, 0.25)

	lamp_sprite.rotation_degrees = randf_range(-8.0, 8.0)

	var float_direction = Vector2(
		randf_range(-4.0, 4.0),
		-18.0
	)
	var duration = randf_range(0.45, 0.7)

	var tween = lamp_sprite.create_tween()

	tween.tween_property(
		lamp_sprite,
		"global_position",
		lamp_sprite.global_position + float_direction,
		duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	tween.parallel().tween_property(
		lamp_sprite,
		"modulate:a",
		0.0,
		duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	tween.tween_callback(lamp_sprite.queue_free)


func on_idea_lamp(producer_id: int) -> void:
	if producer_id != get_instance_id():
		return

	_spawn_lamp(IDEA_LAMP, false)


func on_bright_idea_lamp(producer_id: int) -> void:
	if producer_id != get_instance_id():
		return

	_spawn_lamp(BRIGHT_IDEA_LAMP, true)


func play_pop_sfx() -> void:
	await get_tree().create_timer(pop_sfx_delay).timeout

	if not is_inside_tree():
		return

	if is_rare:
		if rare_guy_pop != null:
			rare_guy_pop.play()
		else:
			print("Rare guy pop sound is not assigned.")
	else:
		if little_guy_pop != null:
			little_guy_pop.play()
		else:
			print("Little guy pop sound is not assigned.")
