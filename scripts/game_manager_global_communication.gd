extends Node

# Lamp events now include the instance ID of the little guy that produced it.
# Every LittleGuy still listens, but only the matching instance responds.
signal little_guy_idea_lamp(producer_id: int)
signal little_guy_bright_idea_lamp(producer_id: int)

var game_manager: GameManager


func _ready() -> void:
	call_deferred("reconnect_to_game_manager")


func reconnect_to_game_manager() -> void:
	var new_game_manager := get_tree().get_first_node_in_group("game_manager") as GameManager

	if new_game_manager == null:
		print("ManagerCommunication could not find GameManager yet")
		return

	game_manager = new_game_manager
	print("ManagerCommunication connected to GameManager")


func show_idea_lamp(producer: Node) -> void:
	if producer == null or not is_instance_valid(producer):
		return

	little_guy_idea_lamp.emit(producer.get_instance_id())


func show_bright_idea_lamp(producer: Node) -> void:
	if producer == null or not is_instance_valid(producer):
		return

	little_guy_bright_idea_lamp.emit(producer.get_instance_id())
