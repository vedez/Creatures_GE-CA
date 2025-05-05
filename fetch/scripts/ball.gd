extends RigidBody3D

signal settled(ball: Node3D)

var was_thrown := false
var has_settled := false
const SETTLE_THRESHOLD := 0.05  # Movement speed under which we consider the ball to be still

func _ready():
	sleeping = true

func _physics_process(delta):
	if was_thrown and not has_settled:
		if sleeping or linear_velocity.length() < SETTLE_THRESHOLD:
			has_settled = true
			emit_signal("settled", self)
			print("Ball settled at:", global_position)

func mark_as_thrown():
	was_thrown = true
	sleeping = false
