extends XROrigin3D

signal reset

@export var move_speed := 5.0  # Meters per second

var move_input: Vector2 = Vector2.ZERO
var debug_label: Label3D
var original_position: Vector3  # Stores spawn point

func _ready():
	Global.debug_enabled = false

	# Create and configure the debug label
	debug_label = Label3D.new()
	debug_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	debug_label.text = ""
	debug_label.visible = false
	debug_label.position = Vector3(0, 0.05, 0.1)  # Offset above and forward from hand
	debug_label.scale = Vector3.ONE * 0.05
	
	$RightHand.add_child(debug_label)

func _on_input_vector_2_changed(vector_name: String, value: Vector2) -> void:
	if vector_name == "primary":
		move_input = value

func _on_left_button_pressed(button: String) -> void:
	if button == "primary_click":
		Global.debug_enabled = !Global.debug_enabled

		if not Global.debug_enabled:
			# Return to spawn when debug is turned off
			global_position = original_position
			move_input = Vector2.ZERO
	elif button == "ax_button":
		emit_signal("reset")

func _on_right_button_pressed(button: StringName) -> void:
	if button == "by_button":
		ButterflyManager.spawn_butterfly(get_parent())
	elif button == "ax_button":
		if ButterflyManager.butterflies.size() > 0:
			var last = ButterflyManager.butterflies.back()
			ButterflyManager.remove_butterfly(last)

func _physics_process(delta):
	# Only move if debug mode is on
	if Global.debug_enabled and move_input.length() > 0.01:
		var camera = $XRCamera3D
		var forward = -camera.global_transform.basis.z
		var right = camera.global_transform.basis.x
		var move_dir = (right * move_input.x + forward * move_input.y).normalized()
		global_translate(move_dir * move_speed * delta)

	# Update debug info for butterfly count
	if debug_label:
		debug_label.visible = Global.debug_enabled
		if ButterflyManager and ButterflyManager.has_method("get_butterfly_count"):
			debug_label.text = "Butterflies: %d" % ButterflyManager.get_butterfly_count()
