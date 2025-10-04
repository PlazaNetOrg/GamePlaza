extends Node

# User Info
var username: String

# PlazaNet
var plazanet_server: String = "http://127.0.0.1:7592" # Default instance (for now local server)

func save_current_config():
	var config := ConfigFile.new()
	
	# User Info
	config.set_value("user", "username", username)
	# PlazaNet
	config.set_value("plazanet", "server", plazanet_server)
	
	# Save the config
	var err = config.save("user://settings.cfg")
	if err != OK:
		push_error("Failed to save config: %s" % err)
