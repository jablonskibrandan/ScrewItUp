extends CanvasLayer

@export var spawner: Spawner
@export var game_manager: GameManager

@export var buy_guy_button: Button
@export var idea_time_reduce_button: Button
@export var rare_chance_button: Button
@export var bright_chance_button: Button
@export var auto_buy_button: Button
@export var auto_buy_speed_button: Button

@export var ideas_label: Label
@export var bright_ideas_label: Label
@export var little_guys_label: Label
@export var idea_time_label: Label
@export var rare_chance_label: Label
@export var bright_idea_chance_label: Label

@export var button_click_sfx: AudioStreamPlayer


func _ready() -> void:
	if spawner == null:
		push_error("UI needs Spawner assigned.")
		return

	if game_manager == null:
		push_error("UI needs GameManager assigned.")
		return

	_connect_buttons()
	_connect_game_manager_signals()

	if rare_chance_button != null:
		rare_chance_button.visible = game_manager.has_found_rare_guy

	if bright_chance_button != null:
		bright_chance_button.visible = game_manager.has_found_bright_idea

	# Only use this if the game is changed to start with zero guys.
	if game_manager.get_amt_little_guys() <= 0:
		spawner.add_starting_guy()

	update_ui()


func _connect_buttons() -> void:
	if buy_guy_button != null:
		buy_guy_button.pressed.connect(on_buy_guy_pressed)

	if idea_time_reduce_button != null:
		idea_time_reduce_button.pressed.connect(on_idea_time_reduce_pressed)

	if rare_chance_button != null:
		rare_chance_button.pressed.connect(on_rare_chance_pressed)

	if bright_chance_button != null:
		bright_chance_button.pressed.connect(on_bright_chance_pressed)

	if auto_buy_button != null:
		auto_buy_button.pressed.connect(on_auto_buy_button_pressed)

	if auto_buy_speed_button != null:
		auto_buy_speed_button.pressed.connect(on_auto_buy_speed_button_pressed)


func _connect_game_manager_signals() -> void:
	game_manager.ideas_changed.connect(on_ideas_changed)
	game_manager.bright_ideas_changed.connect(on_bright_ideas_changed)
	game_manager.costs_changed.connect(on_costs_changed)
	game_manager.rare_guy_unlocked.connect(on_rare_guy_unlocked)
	game_manager.bright_idea_unlocked.connect(on_bright_idea_unlocked)

	# Manual buying and auto-buying use the same spawn path.
	var purchase_callable := Callable(self, "on_little_guy_purchased")
	if not game_manager.little_guy_purchased.is_connected(purchase_callable):
		game_manager.little_guy_purchased.connect(purchase_callable)


func on_buy_guy_pressed() -> void:
	play_button_sfx()
	game_manager.try_buy_little_guy()
	update_ui()


func on_little_guy_purchased() -> void:
	if spawner != null:
		spawner.add_guy_to_stack()

	update_ui()


func on_idea_time_reduce_pressed() -> void:
	play_button_sfx()
	game_manager.try_buy_idea_time_reduce()
	update_ui()


func on_rare_chance_pressed() -> void:
	play_button_sfx()
	game_manager.try_buy_rare_chance()
	update_ui()


func on_bright_chance_pressed() -> void:
	play_button_sfx()
	game_manager.try_buy_bright_chance()
	update_ui()


func on_auto_buy_button_pressed() -> void:
	play_button_sfx()
	game_manager.try_buy_auto_buyer()
	update_ui()


func on_auto_buy_speed_button_pressed() -> void:
	play_button_sfx()
	game_manager.try_buy_auto_buy_speed()
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


func play_button_sfx() -> void:
	if button_click_sfx != null:
		button_click_sfx.play()


func update_ui() -> void:
	if game_manager == null:
		return

	_update_labels()
	_update_upgrade_buttons()
	_update_auto_buy_ui()


func _update_labels() -> void:
	if ideas_label != null:
		ideas_label.text = "Ideas: %d" % game_manager.get_ideas()

	if bright_ideas_label != null:
		bright_ideas_label.text = "Bright Ideas: %d" % game_manager.get_bright_ideas()

	if little_guys_label != null:
		little_guys_label.text = "Little Guys: %d" % game_manager.get_amt_little_guys()

	if idea_time_label != null:
		idea_time_label.text = "Idea Time: %.2fs" % game_manager.idea_production_time

	if rare_chance_label != null:
		rare_chance_label.text = "Rare Chance Rate: %d %%" % game_manager.get_rare_guy_chance_percent()
	
	if bright_idea_chance_label != null:
		bright_idea_chance_label.text = "Bright Idea Chance: %d %%" % game_manager.get_bright_idea_chance_percent()

func _update_upgrade_buttons() -> void:
	if buy_guy_button != null:
		var guy_cost := game_manager.get_little_guy_cost()
		_set_cost_text(buy_guy_button, guy_cost)
		buy_guy_button.tooltip_text = "Buy a Little Guy\nOwned: %d\nCost: %d ideas" % [
			game_manager.get_amt_little_guys(),
			guy_cost
		]
		buy_guy_button.disabled = not game_manager.can_afford_ideas(guy_cost)

	if idea_time_reduce_button != null:
		var speed_cost := game_manager.get_idea_time_reduce_cost()
		if speed_cost == 0:
			_set_status_text(idea_time_reduce_button, "MAX")
			idea_time_reduce_button.tooltip_text = "Idea Rate is already at its maximum speed."
			idea_time_reduce_button.disabled = true
		else:
			_set_cost_text(idea_time_reduce_button, speed_cost)
			idea_time_reduce_button.tooltip_text = "Reduce idea time from %.2fs to %.2fs\nCost: %d ideas" % [
				game_manager.idea_production_time,
				max(
					game_manager.min_idea_production_time,
					game_manager.idea_production_time - game_manager.idea_time_reduce_amount
				),
				speed_cost
			]
			idea_time_reduce_button.disabled = not game_manager.can_afford_ideas(speed_cost)

	if rare_chance_button != null:
		var rare_cost := game_manager.get_rare_chance_cost()
		_set_cost_text(rare_chance_button, rare_cost)
		rare_chance_button.tooltip_text = "Rare Guy chance: %.2f%%\nCost: %d ideas" % [
			game_manager.get_rare_guy_chance_percent(),
			rare_cost
		]
		rare_chance_button.disabled = not game_manager.can_afford_ideas(rare_cost)

	if bright_chance_button != null:
		var bright_cost := game_manager.get_bright_chance_cost()
		_set_cost_text(bright_chance_button, bright_cost)
		bright_chance_button.tooltip_text = "Bright Idea chance: %.2f%%\nCost: %d ideas" % [
			game_manager.get_bright_idea_chance_percent(),
			bright_cost
		]
		bright_chance_button.disabled = not game_manager.can_afford_ideas(bright_cost)


func _update_auto_buy_ui() -> void:
	if auto_buy_button == null or auto_buy_speed_button == null:
		return

	if game_manager.has_auto_buyer:
		auto_buy_button.visible = false
		auto_buy_speed_button.visible = true

		var speed_cost := game_manager.get_auto_buy_speed_cost()
		if speed_cost == 0:
			_set_status_text(auto_buy_speed_button, "MAX")
			auto_buy_speed_button.tooltip_text = "Auto Buyer is already at maximum speed."
			auto_buy_speed_button.disabled = true
		else:
			_set_cost_text(auto_buy_speed_button, speed_cost)
			auto_buy_speed_button.tooltip_text = "Auto Buyer: %.1fs to %.1fs\nCost: %d ideas" % [
				game_manager.get_auto_buy_interval(),
				max(
					game_manager.min_auto_buy_interval,
					game_manager.get_auto_buy_interval() - game_manager.auto_buy_interval_reduce_amount
				),
				speed_cost
			]
			auto_buy_speed_button.disabled = not game_manager.can_afford_ideas(speed_cost)
	else:
		auto_buy_button.visible = true
		auto_buy_speed_button.visible = false

		var unlock_cost := game_manager.get_auto_buyer_cost()
		_set_cost_text(auto_buy_button, unlock_cost)
		auto_buy_button.tooltip_text = "Unlock automatic Little Guy purchases.\nCost: %d ideas" % unlock_cost
		auto_buy_button.disabled = not game_manager.can_afford_ideas(unlock_cost)


func _set_cost_text(button: Button, cost: int) -> void:
	_set_status_text(button, "%d" % cost)


func _set_status_text(button: Button, value: String) -> void:
	# The artwork remains the Button icon. This child Label overlays the cost
	# without forcing the large source image outside the button bounds.
	button.text = ""

	var cost_label := button.get_node_or_null("CostLabel") as Label
	if cost_label != null:
		cost_label.text = value
