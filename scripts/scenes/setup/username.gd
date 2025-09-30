extends Control

@export var name_input: LineEdit
@export var error_label: Label

func _ready():
	name_input.grab_focus()

func _on_continue_button_pressed() -> void:
	if name_input.text.is_empty():
		printerr("Username is empty")
		error_label.text = "Username can't be empty"
		error_label.show()
		name_input.grab_focus()
	elif name_input.text.length() > 16:
		printerr("Username is longer than 16 characters")
		error_label.text = "Username can't be longer than 16 characters"
		error_label.show()
		name_input.grab_focus()
	else:
		var username = name_input.text
		Config.username = username
		print("Username set to: " + username)
		#SceneManager.change_scene("res://scenes/setup/plazanet.tscn")
		SceneManager.change_scene("res://scenes/menus/home.tscn")
