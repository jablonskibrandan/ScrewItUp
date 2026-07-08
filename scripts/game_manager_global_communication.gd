extends Node
@onready var game_manager: GameManager
signal little_guy_idea_lamp
signal little_guy_bright_idea_lamp
func _ready() -> void:
	await get_tree().process_frame
	game_manager = get_tree().get_first_node_in_group("game_manager") as GameManager
	if game_manager != null:
		game_manager.ideas_added.connect(on_idea_changed)
		game_manager.bright_ideas_added.connect(on_bright_idea_changed)
	else:
		print("some problem here")

func on_idea_changed() -> void:
	little_guy_idea_lamp.emit()
func on_bright_idea_changed() -> void:
	little_guy_bright_idea_lamp.emit()
