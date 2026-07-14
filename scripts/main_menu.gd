extends Control


@onready var background: TextureRect = $TitleBackground

@onready var menu_content: Control = $MenuContent

@onready var title_animation: AnimatedSprite2D = \
	$Titlecard

@onready var play_button: TextureButton = \
	$MenuContent/VBoxContainer/PlayButton

@onready var quit_button: TextureButton = \
	$MenuContent/VBoxContainer/QuitButton

@onready var credits_button: Button = \
	$MenuContent/CreditsButton

@onready var credits_overlay: Control = $CreditsOverlay

@onready var close_credits_button: Button = \
	$CreditsOverlay/CloseButton


@export var title_animation_name: StringName = &"default"


var _transitioning: bool = false
var _credits_open: bool = false

# Stores the currently running hover tween for each button.
var _button_tweens: Dictionary = {}

# Stores each button's original Inspector scale.
# This prevents scaled-down buttons from jumping back to full size.
var _button_normal_scales: Dictionary = {}


const HOVER_SCALE_MULTIPLIER := 1.08
const BUTTON_TWEEN_TIME := 0.12


func _ready() -> void:
	# Keep the fullscreen background behind the menu.
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.z_index = -10

	# Start with the credits screen hidden and disabled.
	credits_overlay.visible = false
	credits_overlay.process_mode = Node.PROCESS_MODE_DISABLED
	credits_overlay.z_index = 100
	credits_overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	# Play the title animation.
	if title_animation.sprite_frames != null:
		if title_animation.sprite_frames.has_animation(
			title_animation_name
		):
			title_animation.play(title_animation_name)
		else:
			push_warning(
				"Title animation '%s' does not exist."
				% title_animation_name
			)

	# Set up hover and focus animation for every button.
	_setup_button(play_button)
	_setup_button(quit_button)
	_setup_button(credits_button)
	_setup_button(close_credits_button)

	# Connect button presses.
	play_button.pressed.connect(_on_play_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	credits_button.pressed.connect(_open_credits)
	close_credits_button.pressed.connect(_close_credits)

	_setup_focus_neighbors()


func _setup_focus_neighbors() -> void:
	# Controller and keyboard focus navigation.
	play_button.focus_neighbor_top = \
		play_button.get_path_to(credits_button)

	play_button.focus_neighbor_bottom = \
		play_button.get_path_to(quit_button)

	quit_button.focus_neighbor_top = \
		quit_button.get_path_to(play_button)

	quit_button.focus_neighbor_bottom = \
		quit_button.get_path_to(credits_button)

	credits_button.focus_neighbor_top = \
		credits_button.get_path_to(quit_button)

	credits_button.focus_neighbor_bottom = \
		credits_button.get_path_to(play_button)


func _setup_button(button: BaseButton) -> void:
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.focus_mode = Control.FOCUS_ALL

	# Save the scale currently assigned in the Inspector.
	_button_normal_scales[button] = button.scale

	button.pivot_offset = button.size / 2.0

	button.resized.connect(func() -> void:
		button.pivot_offset = button.size / 2.0
	)

	button.mouse_entered.connect(func() -> void:
		_animate_button(button, true)
	)

	button.mouse_exited.connect(func() -> void:
		_animate_button(button, false)
	)

	button.focus_entered.connect(func() -> void:
		_animate_button(button, true)
	)

	button.focus_exited.connect(func() -> void:
		_animate_button(button, false)
	)


func _input(event: InputEvent) -> void:
	if _transitioning:
		return

	# While credits are open, prevent the normal menu from receiving input.
	if _credits_open:
		if event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			_close_credits()

		return

	# Fallback mouse click handling.
	if event is InputEventMouseButton:
		if (
			event.button_index == MOUSE_BUTTON_LEFT
			and not event.pressed
		):
			var mouse_pos := get_global_mouse_position()

			if play_button.get_global_rect().has_point(mouse_pos):
				get_viewport().set_input_as_handled()
				_on_play_pressed()

			elif quit_button.get_global_rect().has_point(mouse_pos):
				get_viewport().set_input_as_handled()
				_on_quit_pressed()

			elif credits_button.get_global_rect().has_point(mouse_pos):
				get_viewport().set_input_as_handled()
				_open_credits()

	# Focus the first button when keyboard or controller navigation starts.
	if (
		event.is_action_pressed("ui_up")
		or event.is_action_pressed("ui_down")
		or event.is_action_pressed("ui_left")
		or event.is_action_pressed("ui_right")
	):
		var focused := get_viewport().gui_get_focus_owner()

		if (
			focused != play_button
			and focused != quit_button
			and focused != credits_button
		):
			play_button.grab_focus()

	if event.is_action_pressed("ui_accept"):
		var focused := get_viewport().gui_get_focus_owner()

		if focused == null:
			play_button.grab_focus()
		elif focused == play_button:
			_on_play_pressed()
		elif focused == quit_button:
			_on_quit_pressed()
		elif focused == credits_button:
			_open_credits()


func _animate_button(
	button: BaseButton,
	highlighted: bool
) -> void:
	var normal_scale: Vector2 = _button_normal_scales.get(
		button,
		Vector2.ONE
	)

	var target_scale := normal_scale

	if highlighted:
		target_scale = normal_scale * HOVER_SCALE_MULTIPLIER

	# Stop the previous tween for this button.
	if _button_tweens.has(button):
		var current_tween: Tween = _button_tweens[button]

		if current_tween != null:
			current_tween.kill()

	var new_tween := create_tween()

	new_tween.tween_property(
		button,
		"scale",
		target_scale,
		BUTTON_TWEEN_TIME
	)

	_button_tweens[button] = new_tween


func _set_menu_enabled(enabled: bool) -> void:
	# Hide or show everything under MenuContent.
	menu_content.visible = enabled

	# Disable or enable processing for everything under MenuContent.
	menu_content.process_mode = (
		Node.PROCESS_MODE_INHERIT
		if enabled
		else Node.PROCESS_MODE_DISABLED
	)

	play_button.disabled = not enabled
	quit_button.disabled = not enabled
	credits_button.disabled = not enabled

	# Restore every button to its original Inspector scale.
	if not enabled:
		_reset_button_scale(play_button)
		_reset_button_scale(quit_button)
		_reset_button_scale(credits_button)


func _reset_button_scale(button: BaseButton) -> void:
	if _button_tweens.has(button):
		var current_tween: Tween = _button_tweens[button]

		if current_tween != null:
			current_tween.kill()

	button.scale = _button_normal_scales.get(
		button,
		Vector2.ONE
	)


func _open_credits() -> void:
	if _credits_open or _transitioning:
		return

	_credits_open = true

	# Hide and disable the normal menu.
	_set_menu_enabled(false)

	# Show and enable the credits overlay.
	credits_overlay.visible = true
	credits_overlay.process_mode = Node.PROCESS_MODE_INHERIT

	close_credits_button.disabled = false
	close_credits_button.grab_focus()


func _close_credits() -> void:
	if not _credits_open:
		return

	_credits_open = false

	_reset_button_scale(close_credits_button)

	credits_overlay.visible = false
	credits_overlay.process_mode = Node.PROCESS_MODE_DISABLED

	# Restore the normal menu.
	_set_menu_enabled(true)
	credits_button.grab_focus()


func _on_play_pressed() -> void:
	if _transitioning or _credits_open:
		return

	_transitioning = true
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_quit_pressed() -> void:
	if _transitioning or _credits_open:
		return

	_transitioning = true
	get_tree().quit()
