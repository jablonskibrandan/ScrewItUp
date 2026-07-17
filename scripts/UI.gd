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
@export var rare_guys_label: Label
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
	_connect_spawner_signals()

	# Hide the Rare Chance upgrade and stat label until the first Rare Guy.
	if rare_chance_button != null:
		rare_chance_button.visible = game_manager.has_found_rare_guy

	if rare_chance_label != null:
		rare_chance_label.visible = game_manager.has_found_rare_guy

	# Hide the Bright Idea upgrade and stat label until the first Bright Idea.
	if bright_chance_button != null:
		bright_chance_button.visible = game_manager.has_found_bright_idea

	if bright_idea_chance_label != null:
		bright_idea_chance_label.visible = game_manager.has_found_bright_idea

	# Only used if the game is changed to start with zero guys.
	if game_manager.get_amt_little_guys() <= 0:
		spawner.add_starting_guy()

	update_ui()


func _connect_buttons() -> void:
	_connect_button(buy_guy_button, on_buy_guy_pressed)
	_connect_button(
		idea_time_reduce_button,
		on_idea_time_reduce_pressed
	)
	_connect_button(rare_chance_button, on_rare_chance_pressed)
	_connect_button(bright_chance_button, on_bright_chance_pressed)
	_connect_button(auto_buy_button, on_auto_buy_button_pressed)
	_connect_button(
		auto_buy_speed_button,
		on_auto_buy_speed_button_pressed
	)


func _connect_button(button: Button, callable: Callable) -> void:
	if button == null:
		return

	if not button.pressed.is_connected(callable):
		button.pressed.connect(callable)


func _connect_game_manager_signals() -> void:
	if not game_manager.ideas_changed.is_connected(on_ideas_changed):
		game_manager.ideas_changed.connect(on_ideas_changed)

	if not game_manager.bright_ideas_changed.is_connected(
		on_bright_ideas_changed
	):
		game_manager.bright_ideas_changed.connect(
			on_bright_ideas_changed
		)

	if not game_manager.costs_changed.is_connected(on_costs_changed):
		game_manager.costs_changed.connect(on_costs_changed)

	if not game_manager.rare_guy_unlocked.is_connected(
		on_rare_guy_unlocked
	):
		game_manager.rare_guy_unlocked.connect(on_rare_guy_unlocked)

	if not game_manager.bright_idea_unlocked.is_connected(
		on_bright_idea_unlocked
	):
		game_manager.bright_idea_unlocked.connect(
			on_bright_idea_unlocked
		)

	var purchase_callable := Callable(self, "on_little_guy_purchased")

	if not game_manager.little_guy_purchased.is_connected(
		purchase_callable
	):
		game_manager.little_guy_purchased.connect(
			purchase_callable
		)


func _connect_spawner_signals() -> void:
	var spawn_callable := Callable(self, "on_spawn_state_changed")

	if not spawner.spawn_state_changed.is_connected(spawn_callable):
		spawner.spawn_state_changed.connect(spawn_callable)


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


func on_spawn_state_changed(_is_spawning: bool) -> void:
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

	if rare_chance_label != null:
		rare_chance_label.visible = true

	update_ui()


func on_bright_idea_unlocked() -> void:
	if bright_chance_button != null:
		bright_chance_button.visible = true

	if bright_idea_chance_label != null:
		bright_idea_chance_label.visible = true

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
		var has_bright_ideas := game_manager.get_bright_ideas() > 0

		bright_ideas_label.visible = has_bright_ideas

		if has_bright_ideas:
			bright_ideas_label.text = (
				"Bright Ideas: %d"
				% game_manager.get_bright_ideas()
			)
			

	if little_guys_label != null:
		little_guys_label.text = (
			"Little Guys: %d"
			% game_manager.get_amt_little_guys()
		)

	if rare_guys_label != null:
		var has_rare_guys := game_manager.get_amt_rare_guys() > 0

		rare_guys_label.visible = has_rare_guys

		if has_rare_guys:
			rare_guys_label.text = (
				"Rare Guys: %d"
				% game_manager.get_amt_rare_guys()
			)

	if idea_time_label != null:
		idea_time_label.text = (
			"Idea Time: %.2fs"
			% game_manager.idea_production_time
		)

	if rare_chance_label != null:
		rare_chance_label.visible = game_manager.has_found_rare_guy

		if rare_chance_label.visible:
			rare_chance_label.text = (
				"Rare Guy Chance: %.2f %%"
				% game_manager.get_rare_guy_chance_percent()
			)

	if bright_idea_chance_label != null:
		bright_idea_chance_label.visible = (
			game_manager.has_found_bright_idea
		)

		if bright_idea_chance_label.visible:
			bright_idea_chance_label.text = (
				"Bright Idea Chance: %.2f %%"
				% game_manager.get_bright_idea_chance_percent()
			)


func _update_upgrade_buttons() -> void:
	if buy_guy_button != null:
		var guy_cost := game_manager.get_little_guy_cost()
		_set_cost_text(buy_guy_button, guy_cost)

		buy_guy_button.tooltip_text = (
			"Buy a Little Guy\nOwned: %d\nCost: %d ideas"
			% [
				game_manager.get_amt_little_guys(),
				guy_cost
			]
		)

		buy_guy_button.disabled = (
			not game_manager.can_afford_ideas(guy_cost)
			or not spawner.can_add_more_guys()
		)

	if idea_time_reduce_button != null:
		var speed_cost := game_manager.get_idea_time_reduce_cost()

		if speed_cost == 0:
			_set_status_text(idea_time_reduce_button, "MAX")
			idea_time_reduce_button.tooltip_text = (
				"Idea Rate is already at its maximum speed."
			)
			idea_time_reduce_button.disabled = true
		else:
			_set_cost_text(idea_time_reduce_button, speed_cost)
			idea_time_reduce_button.tooltip_text = (
				"Reduce idea time from %.2fs to %.2fs\n"
				+ "Cost: %d ideas"
			) % [
				game_manager.idea_production_time,
				max(
					game_manager.min_idea_production_time,
					game_manager.idea_production_time
						- game_manager.idea_time_reduce_amount
				),
				speed_cost
			]
			idea_time_reduce_button.disabled = (
				not game_manager.can_afford_ideas(speed_cost)
			)

	if rare_chance_button != null:
		var rare_cost := game_manager.get_rare_chance_cost()
		var rare_maxed := game_manager.is_rare_guy_chance_maxed()

		if rare_maxed:
			_set_status_text(rare_chance_button, "MAX")
			rare_chance_button.disabled = true
			rare_chance_button.modulate = Color(
				0.45,
				0.45,
				0.45,
				1.0
			)
			rare_chance_button.tooltip_text = (
				"Rare Guy chance is at the maximum of 50%."
			)
		else:
			_set_cost_text(rare_chance_button, rare_cost)
			rare_chance_button.modulate = Color.WHITE
			rare_chance_button.tooltip_text = (
				"Rare Guy chance: %.2f%% -> %.2f%%\n"
				+ "Cost: %d ideas"
			) % [
				game_manager.get_rare_guy_chance_percent(),
				min(
					50.0,
					game_manager.get_rare_guy_chance_percent() + 1.0
				),
				rare_cost
			]
			rare_chance_button.disabled = (
				not game_manager.can_afford_ideas(rare_cost)
			)

	if bright_chance_button != null:
		var bright_cost := game_manager.get_bright_chance_cost()
		var bright_maxed := game_manager.is_bright_idea_chance_maxed()

		if bright_maxed:
			_set_status_text(bright_chance_button, "MAX")
			bright_chance_button.disabled = true
			bright_chance_button.modulate = Color(
				0.45,
				0.45,
				0.45,
				1.0
			)
			bright_chance_button.tooltip_text = (
				"Bright Idea chance is at the maximum of 50%."
			)
		else:
			_set_cost_text(bright_chance_button, bright_cost)
			bright_chance_button.modulate = Color.WHITE
			bright_chance_button.tooltip_text = (
				"Bright Idea chance: %.2f%% -> %.2f%%\n"
				+ "Cost: %d ideas"
			) % [
				game_manager.get_bright_idea_chance_percent(),
				min(
					50.0,
					game_manager.get_bright_idea_chance_percent() + 1.0
				),
				bright_cost
			]
			bright_chance_button.disabled = (
				not game_manager.can_afford_ideas(bright_cost)
			)


func _update_auto_buy_ui() -> void:
	if auto_buy_button == null or auto_buy_speed_button == null:
		return

	if game_manager.has_auto_buyer:
		# Keep the original Auto Buy button visible so there is no empty slot.
		auto_buy_button.visible = true
		auto_buy_button.disabled = true
		auto_buy_button.modulate = Color(
			0.45,
			0.45,
			0.45,
			1.0
		)

		_set_status_text(auto_buy_button, "MAX")

		auto_buy_button.tooltip_text = (
			"Auto Buyer has already been unlocked."
		)

		# Show the Auto Buy Rate upgrade beneath it.
		auto_buy_speed_button.visible = true

		var speed_cost := game_manager.get_auto_buy_speed_cost()

		if speed_cost == 0:
			_set_status_text(auto_buy_speed_button, "MAX")
			auto_buy_speed_button.disabled = true
			auto_buy_speed_button.modulate = Color(
				0.45,
				0.45,
				0.45,
				1.0
			)

			auto_buy_speed_button.tooltip_text = (
				"Auto Buyer is already at maximum speed."
			)
		else:
			_set_cost_text(auto_buy_speed_button, speed_cost)
			auto_buy_speed_button.disabled = (
				not game_manager.can_afford_ideas(speed_cost)
			)
			auto_buy_speed_button.modulate = Color.WHITE

			auto_buy_speed_button.tooltip_text = (
				"Auto Buyer: %.1fs to %.1fs\nCost: %d ideas"
				% [
					game_manager.get_auto_buy_interval(),
					max(
						game_manager.min_auto_buy_interval,
						game_manager.get_auto_buy_interval()
							- game_manager.auto_buy_interval_reduce_amount
					),
					speed_cost
				]
			)
	else:
		# Auto Buy has not been unlocked yet.
		auto_buy_button.visible = true
		auto_buy_button.disabled = false
		auto_buy_button.modulate = Color.WHITE

		auto_buy_speed_button.visible = false

		var unlock_cost := game_manager.get_auto_buyer_cost()

		_set_cost_text(auto_buy_button, unlock_cost)

		auto_buy_button.tooltip_text = (
			"Unlock automatic Little Guy purchases.\n"
			+ "Cost: %d ideas" % unlock_cost
		)

		auto_buy_button.disabled = (
			not game_manager.can_afford_ideas(unlock_cost)
		)


func _set_cost_text(button: Button, cost: int) -> void:
	_set_status_text(button, "%d" % cost)


func _set_status_text(button: Button, value: String) -> void:
	button.text = ""

	var cost_label := button.get_node_or_null("CostLabel") as Label

	if cost_label != null:
		cost_label.text = value
