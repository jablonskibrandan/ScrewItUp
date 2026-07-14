extends Node
class_name GameManager

signal ideas_changed(ideas: int)
signal ideas_added

signal bright_ideas_changed(bright_ideas: int)
signal bright_ideas_added

signal costs_changed

signal little_guy_purchased
signal idea_time_reduce_purchased
signal rare_chance_purchased
signal bright_chance_purchased

signal auto_buyer_purchased
signal auto_buy_speed_purchased

signal rare_guy_unlocked
signal bright_idea_unlocked


var ideas: int = 0
var bright_ideas: int = 0

# Game starts with 1 little guy already existing in the scene.
var amt_little_guys: int = 1
var rare_little_guys: int = 0

@export var idea_production_time: float = 5.0

var idea_time_reduce_amount: float = 0.25
var min_idea_production_time: float = 1.5

var bright_idea_chance: float = 0.01
var bright_idea_chance_increase: float = 0.005

var rare_guy_chance: float = 0.01
var rare_guy_chance_increase: float = 0.0025

var has_found_rare_guy: bool = false
var has_found_bright_idea: bool = false

# Little Guy polynomial cost curve.
# This replaces the permanent 25% compound multiplier.
#
# Cost = base + (linear * purchases) + (quadratic * purchases^2)
#
# The absolute price increase gradually becomes larger, but the percentage
# increase between purchases becomes smaller over time. This avoids the
# runaway exponential growth caused by repeatedly multiplying by 1.25.
@export_category("Little Guy Polynomial Cost")
@export var little_guy_base_cost: float = 1.0
@export_range(0.0, 1000.0, 0.01) var little_guy_linear_growth: float = 0.25
@export_range(0.0, 100.0, 0.0001) var little_guy_quadratic_growth: float = 0.01

# This only counts purchased Little Guys.
# The free starting Little Guy is not included.
var little_guys_purchased: int = 0

# Other upgrade costs still use the normal 25% multiplier.
var idea_time_reduce_raw_cost: float = 5.0
var rare_chance_raw_cost: float = 50.0
var bright_chance_raw_cost: float = 50.0

# Auto-buy upgrade.
var has_auto_buyer: bool = false
var auto_buy_unlock_raw_cost: float = 500.0
var auto_buy_speed_raw_cost: float = 250.0

var auto_buy_timer: float = 0.0
var auto_buy_interval: float = 10.0
var auto_buy_interval_reduce_amount: float = 1.0
var min_auto_buy_interval: float = 3.0

# Once a Little Guy costs more than this, auto-buy only pays a percentage
# of the amount above the soft cap.
@export_category("Auto-Buy Little Guy Discount")
@export var auto_buy_little_guy_soft_cap: int = 100_000
@export_range(0.0, 1.0, 0.01) var auto_buy_excess_cost_percent: float = 0.10

var production_timer: float = 0.0

const COST_MULTIPLIER: float = 1.25
const BRIGHT_IDEA_VALUE: int = 5


func _enter_tree() -> void:
	add_to_group("game_manager")


func _ready() -> void:
	if ManagerCommunication.has_method("reconnect_to_game_manager"):
		ManagerCommunication.reconnect_to_game_manager()


func _process(delta: float) -> void:
	_process_idea_production(delta)
	_process_auto_buyer(delta)


func _process_idea_production(delta: float) -> void:
	if amt_little_guys <= 0:
		return

	production_timer += delta

	if production_timer >= idea_production_time:
		production_timer -= idea_production_time
		produce_from_little_guys()


func _process_auto_buyer(delta: float) -> void:
	if not has_auto_buyer:
		return

	# Stop attempting purchases once the final stack position is reserved.
	if not can_buy_more_little_guys():
		return

	auto_buy_timer += delta

	if auto_buy_timer >= auto_buy_interval:
		auto_buy_timer -= auto_buy_interval

		# Auto-buy uses the discounted late-game Little Guy cost.
		# If you still cannot afford it, nothing happens.
		try_buy_little_guy(true)


func produce_from_little_guys() -> void:
	var normal_little_guys: int = max(0, amt_little_guys - rare_little_guys)

	var random_bright_ideas: int = 0
	if roll_for_bright_idea():
		random_bright_ideas = 1

	# Rare guys always produce bright ideas.
	var total_bright_ideas: int = rare_little_guys + random_bright_ideas

	# Keep the existing economy behavior. Lamp visuals are emitted separately
	# so they can be sent to the exact little guy that produced them.
	if normal_little_guys > 0:
		add_ideas(normal_little_guys, false)

	if total_bright_ideas > 0:
		add_bright_ideas(total_bright_ideas)

	_show_production_lamps(random_bright_ideas, total_bright_ideas)


func _show_production_lamps(
	random_bright_ideas: int,
	total_bright_ideas: int
) -> void:
	var all_guys: Array[Node] = get_tree().get_nodes_in_group("little_guys")

	if all_guys.is_empty():
		return

	var normal_guys: Array[Node] = []
	var rare_guys: Array[Node] = []

	for guy: Node in all_guys:
		if not is_instance_valid(guy):
			continue

		if bool(guy.get("is_rare")):
			rare_guys.append(guy)
		else:
			normal_guys.append(guy)

	# Preserve the previous visual rule: when no bright idea happens,
	# every normal guy displays a regular idea lamp.
	if total_bright_ideas == 0:
		for guy: Node in normal_guys:
			ManagerCommunication.show_idea_lamp(guy)
		return

	# Rare guys always produce bright ideas, so each rare guy gets its own lamp.
	for guy: Node in rare_guys:
		ManagerCommunication.show_bright_idea_lamp(guy)

	# A random bright idea belongs to exactly one normal little guy.
	if random_bright_ideas > 0 and not normal_guys.is_empty():
		var bright_producer: Node = normal_guys.pick_random() as Node
		ManagerCommunication.show_bright_idea_lamp(bright_producer)


func get_ideas() -> int:
	return ideas


func get_bright_ideas() -> int:
	return bright_ideas


func get_amt_little_guys() -> int:
	return amt_little_guys


func set_amt_little_guys(amt: int) -> void:
	amt_little_guys = max(0, amt)

	# Keep the cost curve synchronized when loading a saved amount.
	little_guys_purchased = max(0, amt_little_guys - 1)
	costs_changed.emit()


func add_little_guy_count(is_rare: bool = false) -> void:
	amt_little_guys += 1

	if is_rare:
		rare_little_guys += 1
		mark_rare_guy_found()


func get_little_guy_cost() -> int:
	# Quadratic polynomial curve:
	# base + (linear * purchases) + (quadratic * purchases^2)
	#
	# Unlike multiplying the previous cost by 1.25, this calculates every
	# price directly from the purchase count. The effective percentage jump
	# therefore becomes smaller as the player buys more Little Guys.
	var purchases: float = float(little_guys_purchased)
	var calculated_cost: float = (
		little_guy_base_cost
		+ little_guy_linear_growth * purchases
		+ little_guy_quadratic_growth * purchases * purchases
	)

	return maxi(1, int(round(calculated_cost)))


func get_auto_buy_little_guy_cost() -> int:
	var normal_cost: int = get_little_guy_cost()

	if normal_cost <= auto_buy_little_guy_soft_cap:
		return normal_cost

	var amount_above_cap: int = normal_cost - auto_buy_little_guy_soft_cap
	var discounted_excess: int = int(ceil(
		float(amount_above_cap) * auto_buy_excess_cost_percent
	))

	return auto_buy_little_guy_soft_cap + discounted_excess


func get_idea_time_reduce_cost() -> int:
	if idea_production_time <= min_idea_production_time:
		return 0

	return max(1, int(floor(idea_time_reduce_raw_cost)))


func get_time_reduce_cost() -> int:
	return get_idea_time_reduce_cost()


func get_rare_chance_cost() -> int:
	return max(1, int(floor(rare_chance_raw_cost)))


func get_bright_chance_cost() -> int:
	return max(1, int(floor(bright_chance_raw_cost)))


func get_auto_buyer_cost() -> int:
	if has_auto_buyer:
		return 0

	return max(1, int(floor(auto_buy_unlock_raw_cost)))


func get_auto_buy_speed_cost() -> int:
	if not has_auto_buyer:
		return 0

	if auto_buy_interval <= min_auto_buy_interval:
		return 0

	return max(1, int(floor(auto_buy_speed_raw_cost)))


func get_auto_buy_interval() -> float:
	return auto_buy_interval


func get_rare_guy_chance_percent() -> float:
	return rare_guy_chance * 100.0


func get_bright_idea_chance_percent() -> float:
	return bright_idea_chance * 100.0


func can_afford_ideas(cost: int) -> bool:
	return ideas >= cost


func spend_ideas(cost: int) -> bool:
	if ideas < cost:
		return false

	ideas -= cost
	ideas_changed.emit(ideas)

	return true


func add_ideas(amount: int, emit_lamp: bool = true) -> void:
	if amount <= 0:
		return

	ideas += amount
	ideas_changed.emit(ideas)

	if emit_lamp:
		ideas_added.emit()


func add_bright_ideas(amount: int) -> void:
	if amount <= 0:
		return

	bright_ideas += amount
	bright_ideas_changed.emit(bright_ideas)

	# Each bright idea is worth 5 regular ideas.
	add_ideas(amount * BRIGHT_IDEA_VALUE, false)

	bright_ideas_added.emit()

	if not has_found_bright_idea and bright_ideas > 0:
		has_found_bright_idea = true
		bright_idea_unlocked.emit()


func can_buy_more_little_guys() -> bool:
	var spawner := get_tree().get_first_node_in_group("spawner")

	if spawner == null:
		return true

	if spawner.has_method("can_add_more_guys"):
		return bool(spawner.call("can_add_more_guys"))

	return true


func try_buy_little_guy(is_auto_buy: bool = false) -> bool:
	# Check before charging the player. This covers both the manual button
	# and the autobuyer.
	if not can_buy_more_little_guys():
		return false

	var cost: int

	if is_auto_buy:
		cost = get_auto_buy_little_guy_cost()
	else:
		cost = get_little_guy_cost()

	if not spend_ideas(cost):
		return false

	# Advance the curve immediately after a successful purchase.
	little_guys_purchased += 1

	# Do NOT increase amt_little_guys here.
	# The Spawner does that after it knows whether the new guy is rare.
	little_guy_purchased.emit()
	costs_changed.emit()

	return true


func try_pay_for_little_guy() -> bool:
	return try_buy_little_guy(false)


func try_buy_idea_time_reduce() -> bool:
	var cost := get_idea_time_reduce_cost()

	if cost == 0:
		return false

	if not spend_ideas(cost):
		return false

	idea_time_reduce_raw_cost *= COST_MULTIPLIER

	idea_production_time = max(
		min_idea_production_time,
		idea_production_time - idea_time_reduce_amount
	)

	idea_time_reduce_purchased.emit()
	costs_changed.emit()

	return true


func try_buy_time_reduce() -> bool:
	return try_buy_idea_time_reduce()


func try_buy_rare_chance() -> bool:
	var cost := get_rare_chance_cost()

	if not spend_ideas(cost):
		return false

	rare_chance_raw_cost *= COST_MULTIPLIER
	rare_guy_chance += rare_guy_chance_increase

	rare_chance_purchased.emit()
	costs_changed.emit()

	return true


func try_buy_bright_chance() -> bool:
	var cost := get_bright_chance_cost()

	if not spend_ideas(cost):
		return false

	bright_chance_raw_cost *= COST_MULTIPLIER
	bright_idea_chance += bright_idea_chance_increase

	bright_chance_purchased.emit()
	costs_changed.emit()

	return true


func try_buy_auto_buyer() -> bool:
	if has_auto_buyer:
		return false

	var cost := get_auto_buyer_cost()

	if not spend_ideas(cost):
		return false

	has_auto_buyer = true
	auto_buy_timer = 0.0

	auto_buyer_purchased.emit()
	costs_changed.emit()

	return true


func try_buy_auto_buy_speed() -> bool:
	if not has_auto_buyer:
		return false

	var cost := get_auto_buy_speed_cost()

	if cost == 0:
		return false

	if not spend_ideas(cost):
		return false

	auto_buy_speed_raw_cost *= COST_MULTIPLIER

	auto_buy_interval = max(
		min_auto_buy_interval,
		auto_buy_interval - auto_buy_interval_reduce_amount
	)

	auto_buy_speed_purchased.emit()
	costs_changed.emit()

	return true


func mark_rare_guy_found() -> void:
	if has_found_rare_guy:
		return

	has_found_rare_guy = true
	rare_guy_unlocked.emit()


func roll_for_rare_guy() -> bool:
	return randf() < rare_guy_chance


func roll_for_bright_idea() -> bool:
	return randf() < bright_idea_chance
