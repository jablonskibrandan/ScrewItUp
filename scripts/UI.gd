extends Node

@export var spawner: Spawner
@export var game_manager: GameManager

@export var buy_guy_button: Button
@export var idea_time_reduce_button: Button

@export var rare_chance_button: BaseButton
@export var bright_chance_button: BaseButton

@export var ideas_label: Label
@export var bright_ideas_label: Label
@export var little_guys_label: Label
@export var idea_time_label: Label


func _ready() -> void:
	if spawner == null:
		push_error("Controller needs Spawner assigned.")
		return

	if game_manager == null:
		push_error("Controller needs GameManager assigned.")
		return

	if buy_guy_button != null:
		buy_guy_button.pressed.connect(on_buy_guy_pressed)

	if idea_time_reduce_button != null:
		idea_time_reduce_button.pressed.connect(on_idea_time_reduce_pressed)

	if rare_chance_button != null:
		rare_chance_button.pressed.connect(on_rare_chance_pressed)

	if bright_chance_button != null:
		bright_chance_button.pressed.connect(on_bright_chance_pressed)

	game_manager.ideas_changed.connect(on_ideas_changed)
	game_manager.bright_ideas_changed.connect(on_bright_ideas_changed)
	game_manager.costs_changed.connect(on_costs_changed)
	game_manager.rare_guy_unlocked.connect(on_rare_guy_unlocked)
	game_manager.bright_idea_unlocked.connect(on_bright_idea_unlocked)

	if rare_chance_button != null:
		rare_chance_button.visible = game_manager.has_found_rare_guy

	if bright_chance_button != null:
		bright_chance_button.visible = game_manager.has_found_bright_idea

	# Start with one free normal guy if there are none yet.
	if game_manager.get_amt_little_guys() <= 0:
		spawner.add_starting_guy()

	update_ui()


func on_buy_guy_pressed() -> void:
	if game_manager.try_buy_little_guy():
		spawner.add_guy_to_stack()

	update_ui()


func on_idea_time_reduce_pressed() -> void:
	game_manager.try_buy_idea_time_reduce()
	update_ui()


func on_rare_chance_pressed() -> void:
	game_manager.try_buy_rare_chance()
	update_ui()


func on_bright_chance_pressed() -> void:
	game_manager.try_buy_bright_chance()
	update_ui()


func on_ideas_changed(_new_amount: int) -> void:
	update_ui()


func on_bright_ideas_changed(_new_amount: int) -> void:
	update_ui()


func on_costs_changed() -> void:
	update_ui()


func on_rare_guy_unlocked() -> void:
	if rare_chance_button != null:
		rare_chance_button.visible = true

	update_ui()


func on_bright_idea_unlocked() -> void:
	if bright_chance_button != null:
		bright_chance_button.visible = true

	update_ui()


func update_ui() -> void:
	if ideas_label != null:
		ideas_label.text = "Ideas: %d" % game_manager.get_ideas()

	if bright_ideas_label != null:
		bright_ideas_label.text = "Bright Ideas: %d" % game_manager.get_bright_ideas()

	if little_guys_label != null:
		little_guys_label.text = "Little Guys: %d" % game_manager.get_amt_little_guys()

	if idea_time_label != null:
		idea_time_label.text = "Idea Time: %.2fs" % game_manager.idea_production_time

	if buy_guy_button != null:
		buy_guy_button.text = "Buy Little Guy\nCost: %d" % game_manager.get_little_guy_cost()
		buy_guy_button.disabled = game_manager.get_ideas() < game_manager.get_little_guy_cost()

	if idea_time_reduce_button != null:
		if game_manager.get_idea_time_reduce_cost() == 0:
			idea_time_reduce_button.text = "You have reached max level"
			idea_time_reduce_button.disabled = true
		else:
			idea_time_reduce_button.text = "Reduce Idea Time\nCost: %d" % game_manager.get_idea_time_reduce_cost()
			idea_time_reduce_button.disabled = game_manager.get_ideas() < game_manager.get_idea_time_reduce_cost()

	if rare_chance_button != null:
		rare_chance_button.text = "Rare Guy Chance\n%.2f%%\nCost: %d" % [
			game_manager.get_rare_guy_chance_percent(),
			game_manager.get_rare_chance_cost()
		]
		rare_chance_button.disabled = game_manager.get_ideas() < game_manager.get_rare_chance_cost()

	if bright_chance_button != null:
		bright_chance_button.text = "Bright Idea Chance\n%.2f%%\nCost: %d" % [
			game_manager.get_bright_idea_chance_percent(),
			game_manager.get_bright_chance_cost()
		]
		bright_chance_button.disabled = game_manager.get_ideas() < game_manager.get_bright_chance_cost()
