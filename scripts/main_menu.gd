extends Control

@onready var background: TextureRect = $TitleBackground
@onready var title_image: TextureRect = $VBoxContainer/TitleImage
@onready var play_button: TextureButton = $VBoxContainer/PlayButton
@onready var quit_button: TextureButton = $VBoxContainer/QuitButton

var _transitioning: bool = false
var _play_tween: Tween
var _quit_tween: Tween

const NORMAL_SCALE := Vector2.ONE
const HOVER_SCALE := Vector2(1.08, 1.08)
const BUTTON_TWEEN_TIME := 0.12

func _ready() -> void:
	# Keep the fullscreen background behind the menu and prevent it from stealing mouse input.
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.z_index = -10

	_setup_button(play_button)
	_setup_button(quit_button)

	play_button.pressed.connect(_on_play_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# Controller/keyboard navigation should work, but START should not look selected immediately.
	play_button.focus_neighbor_bottom = play_button.get_path_to(quit_button)
	quit_button.focus_neighbor_top = quit_button.get_path_to(play_button)

func _setup_button(button: TextureButton) -> void:
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.focus_mode = Control.FOCUS_ALL
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

	# Fallback mouse click handling. This makes the menu still work even if something
	# in the UI accidentally blocks the TextureButton pressed signal.
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			var mouse_pos := get_global_mouse_position()
			if play_button.get_global_rect().has_point(mouse_pos):
				get_viewport().set_input_as_handled()
				_on_play_pressed()
			elif quit_button.get_global_rect().has_point(mouse_pos):
				get_viewport().set_input_as_handled()
				_on_quit_pressed()

	# Do not grab focus on startup. Only focus START after the player actually uses
	# keyboard/controller navigation.
	if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down") or event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
		var focused := get_viewport().gui_get_focus_owner()
		if focused != play_button and focused != quit_button:
			play_button.grab_focus()

	if event.is_action_pressed("ui_accept"):
		var focused := get_viewport().gui_get_focus_owner()
		if focused == null:
			play_button.grab_focus()
		elif focused == play_button:
			_on_play_pressed()
		elif focused == quit_button:
			_on_quit_pressed()

func _animate_button(button: TextureButton, highlighted: bool) -> void:
	var target_scale := HOVER_SCALE if highlighted else NORMAL_SCALE
	var tween_ref: Tween = _play_tween if button == play_button else _quit_tween
	if tween_ref:
		tween_ref.kill()

	var new_tween := create_tween()
	new_tween.tween_property(button, "scale", target_scale, BUTTON_TWEEN_TIME)

	if button == play_button:
		_play_tween = new_tween
	else:
		_quit_tween = new_tween

func _on_play_pressed() -> void:
	if _transitioning:
		return
	_transitioning = true
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_quit_pressed() -> void:
	if _transitioning:
		return
	_transitioning = true
	get_tree().quit()
