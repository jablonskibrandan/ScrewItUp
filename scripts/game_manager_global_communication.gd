extends Node

signal little_guy_idea_lamp
signal little_guy_bright_idea_lamp

var game_manager: GameManager


func _ready() -> void:
	call_deferred("reconnect_to_game_manager")


func reconnect_to_game_manager() -> void:
	var new_game_manager := get_tree().get_first_node_in_group("game_manager") as GameManager

	if new_game_manager == null:
		print("ManagerCommunication could not find GameManager yet")
		return

	game_manager = new_game_manager

	var idea_callable := Callable(self, "on_idea_changed")
	var bright_callable := Callable(self, "on_bright_idea_changed")

	if not game_manager.ideas_added.is_connected(idea_callable):
		game_manager.ideas_added.connect(idea_callable)

	if not game_manager.bright_ideas_added.is_connected(bright_callable):
		game_manager.bright_ideas_added.connect(bright_callable)

	print("ManagerCommunication connected to GameManager")


func on_idea_changed() -> void:
	print("ManagerCommunication received idea signal")
	little_guy_idea_lamp.emit()


func on_bright_idea_changed() -> void:
	print("ManagerCommunication received bright idea signal")
	little_guy_bright_idea_lamp.emit()
