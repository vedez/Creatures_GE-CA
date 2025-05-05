extends XROrigin3D

@export var move_speed := 3.0  # Meters per second

var move_input: Vector2 = Vector2.ZERO

func _ready():
	Global.debug_enabled = false

func _on_input_vector_2_changed(vector_name: String, value: Vector2) -> void:
	if vector_name == "primary":
		move_input = value

func _on_button_pressed(action_name: String) -> void:
	if action_name == "primary_click":
		Global.debug_enabled = !Global.debug_enabled
		print("🛠 Debug Mode:", Global.debug_enabled)

func _physics_process(delta):
	if move_input.length() > 0.01:
		var camera = $XRCamera3D
		var forward = -camera.global_transform.basis.z
		var right = camera.global_transform.basis.x
		var move_dir = (right * move_input.x + forward * move_input.y).normalized()
		global_translate(move_dir * move_speed * delta)
