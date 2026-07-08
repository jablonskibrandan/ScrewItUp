extends Node2D

@onready var sprite: Sprite2D = $Sprite2D

const idea_lamp: Texture2D = preload("uid://ketwc3ehaks2")
const bright_idea_lamp: Texture2D = preload("uid://cfurqvmpb1o65")

var is_rare: bool = false

@export var little_guy_pop: AudioStreamPlayer
@export var rare_guy_pop: AudioStreamPlayer
@export var pop_sfx_delay: float = 0.35


func _ready() -> void:
	print("LittleGuy ready: ", name)

	var idea_callable := Callable(self, "on_idea_lamp")
	var bright_callable := Callable(self, "on_bright_idea_lamp")

	if not ManagerCommunication.little_guy_idea_lamp.is_connected(idea_callable):
		ManagerCommunication.little_guy_idea_lamp.connect(idea_callable)

	if not ManagerCommunication.little_guy_bright_idea_lamp.is_connected(bright_callable):
		ManagerCommunication.little_guy_bright_idea_lamp.connect(bright_callable)


func setup(rare: bool) -> void:
	is_rare = rare

	if is_rare:
		sprite.modulate = Color(0.2, 0.9, 1.0)
	else:
		sprite.modulate = Color.WHITE


func _spawn_lamp(texture: Texture2D, is_bright: bool = false) -> void:
	if texture == null:
		return

	var lamp_sprite := Sprite2D.new()
	lamp_sprite.texture = texture
	lamp_sprite.centered = true

	# Slight variation so every lamp does not appear in the exact same spot.
	var random_x := randf_range(-4.0, 4.0)
	var random_y := randf_range(-3.0, 2.0)

	# Put it directly above the little guy's head.
	var head_offset := Vector2(random_x, -24.0 + random_y)
	lamp_sprite.global_position = global_position + head_offset

	# Make the lamp about the same visible height as the little guy.
	if sprite.texture != null:
		var little_guy_height := sprite.texture.get_height() * sprite.global_scale.y
		var lamp_texture_height := texture.get_height()

		if lamp_texture_height > 0:
			var target_height := little_guy_height * randf_range(0.85, 1.1)
			var lamp_scale := target_height / lamp_texture_height
			lamp_sprite.global_scale = Vector2(lamp_scale, lamp_scale)
	else:
		lamp_sprite.global_scale = Vector2(0.25, 0.25)

	# Slight visual variation.
	lamp_sprite.rotation_degrees = randf_range(-8.0, 8.0)

	# Make sure it appears in front.
	lamp_sprite.z_as_relative = false
	lamp_sprite.z_index = 1000

	get_tree().current_scene.add_child(lamp_sprite)

	var float_direction := Vector2(randf_range(-4.0, 4.0), -18.0)
	var duration := randf_range(0.45, 0.7)

	var tween := lamp_sprite.create_tween()
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


func on_idea_lamp() -> void:
	_spawn_lamp(idea_lamp, false)


func on_bright_idea_lamp() -> void:
	_spawn_lamp(bright_idea_lamp, true)
