extends Control

var config_path = "user://settings.cfg"

func _ready():
	# Check if the config file exists
	if FileAccess.file_exists(config_path):
		print("Config exists, loading GamePlaza.")
	else:
		print("Config does not exist, loading setup.")
		SceneManager.change_scene("res://scenes/setup/setup.tscn", 1.0)
