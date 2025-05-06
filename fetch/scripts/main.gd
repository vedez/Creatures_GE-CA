extends Node3D

var xr_interface: XRInterface

@export var ball_scene: PackedScene

@onready var right_hand = $Player/RightHand
@onready var player = $Player
@onready var dog = $Dog

var current_ball: Node3D = null

func _ready():
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		print("OpenXR initialized successfully")

		# Turn off v-sync
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

		# Change main viewport to output to the HMD
		get_viewport().use_xr = true
	else:
		print("OpenXR not initialized, please check if your headset is connected")
		
	_spawn_ball()

func _on_player_requested_reset():
	# Delete current ball
	if current_ball and current_ball.is_inside_tree():
		current_ball.queue_free()
		current_ball = null

	# Reset dog behavior
	if dog.has_method("reset_to_wander"):
		dog.reset_to_wander()

	# Respawn new ball
	_spawn_ball()

func _spawn_ball():
	var ball = ball_scene.instantiate()
	add_child(ball)
	ball.global_position = player.global_transform.origin + Vector3(0, 1.5, 0.5)
	current_ball = ball

	# Connect the settled signal to the dog
	if ball.has_signal("settled"):
		ball.connect("settled", Callable(dog, "on_ball_landed"))
