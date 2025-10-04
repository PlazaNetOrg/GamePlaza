extends Node

@onready var shader : ShaderMaterial = GlobalBackground.material

var current_scene : Node = null

func _ready():
	shader.set_shader_parameter("blob_strength", 1.0)

func change_scene(scene_path: String, target_blob_strength: float = 0.8) -> void:
	var duration: float = 0.5
	# Load new scene (invisible)
	var new_scene_res = ResourceLoader.load(scene_path)
	if not new_scene_res:
		printerr("Cannot load scene: %s" % scene_path)
		return
	var new_scene = new_scene_res.instantiate()
	add_child(new_scene)
	new_scene.modulate.a = 0.0

	# Animate blob strength
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(shader, "shader_parameter/blob_strength", target_blob_strength, duration * 2)

	# Fade out old scene
	if current_scene:
		tween.parallel().tween_property(current_scene, "modulate:a", 0.0, duration)
		tween.parallel().tween_callback(Callable(current_scene, "queue_free")).set_delay(duration)

	# Fade in new scene
	tween.tween_property(new_scene, "modulate:a", 1.0, duration)
	current_scene = new_scene
