extends Control

func _input(event):
	if event.is_action_released("accept"):
		SceneManager.change_scene("res://scenes/setup/username.tscn", 0.5)
