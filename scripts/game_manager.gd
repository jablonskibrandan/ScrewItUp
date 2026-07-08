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

signal rare_guy_unlocked
signal bright_idea_unlocked


var ideas: int = 0
var bright_ideas: int = 0

# Game starts with 1 little guy.
# Game starts with 1 little guy.
var amt_little_guys: int = 1

@export var idea_production_time: float = 5.0

var idea_time_reduce_amount: float = 0.25
var min_idea_production_time: float = 1.5

var bright_idea_chance: float = 0.01
var bright_idea_chance_increase: float = 0.005

var rare_guy_chance: float = 0.01
var rare_guy_chance_increase: float = 0.0025

var has_found_rare_guy: bool = false
var has_found_bright_idea: bool = false

var little_guy_raw_cost: float = 1.0
var idea_time_reduce_raw_cost: float = 5.0
var rare_chance_raw_cost: float = 50.0
var bright_chance_raw_cost: float = 50.0

var production_timer: float = 0.0
var rare_little_guys: int = 0

const COST_MULTIPLIER: float = 1.25
func _enter_tree() -> void:
	add_to_group("game_manager")


func _ready() -> void:
	if ManagerCommunication.has_method("reconnect_to_game_manager"):
		ManagerCommunication.reconnect_to_game_manager()
		
func _process(delta: float) -> void:
	if amt_little_guys <= 0:
		return

	production_timer += delta

	if production_timer >= idea_production_time:
		production_timer -= idea_production_time
		produce_from_little_guys()


func produce_from_little_guys() -> void:
	var normal_little_guys = max(0, amt_little_guys - rare_little_guys)

	if normal_little_guys > 0:
		add_ideas(normal_little_guys)

	if rare_little_guys > 0:
		add_bright_ideas(rare_little_guys)

	if roll_for_bright_idea():
		add_bright_ideas(1)
	
func get_ideas() -> int:
	return ideas


func get_bright_ideas() -> int:
	return bright_ideas


func get_amt_little_guys() -> int:
	return amt_little_guys


func set_amt_little_guys(amt: int) -> void:
	amt_little_guys = max(0, amt)


func get_little_guy_cost() -> int:
	return max(1, int(floor(little_guy_raw_cost)))


func get_idea_time_reduce_cost() -> int:
	if idea_production_time == 0.5:
		return 0
	return max(1, int(floor(idea_time_reduce_raw_cost)))


func get_time_reduce_cost() -> int:
	return get_idea_time_reduce_cost()


func get_rare_chance_cost() -> int:
	return max(1, int(floor(rare_chance_raw_cost)))


func get_bright_chance_cost() -> int:
	return max(1, int(floor(bright_chance_raw_cost)))


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


func add_ideas(amount: int) -> void:
	ideas += amount
	ideas_changed.emit(ideas)
	ideas_added.emit()

func add_bright_ideas(amount: int) -> void:
	bright_ideas += amount
	bright_ideas_changed.emit(bright_ideas)
	bright_ideas_added.emit()
	if not has_found_bright_idea and bright_ideas > 0:
		has_found_bright_idea = true
		bright_idea_unlocked.emit()


func try_buy_little_guy() -> bool:
	var cost := get_little_guy_cost()

	if not spend_ideas(cost):
		return false

	little_guy_raw_cost *= COST_MULTIPLIER

	little_guy_purchased.emit()
	costs_changed.emit()

	return true

func try_pay_for_little_guy() -> bool:
	return try_buy_little_guy()


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


func mark_rare_guy_found() -> void:
	if has_found_rare_guy:
		return

	has_found_rare_guy = true
	rare_guy_unlocked.emit()


func roll_for_rare_guy() -> bool:
	return randf() < rare_guy_chance


func roll_for_bright_idea() -> bool:
	return randf() < bright_idea_chance
