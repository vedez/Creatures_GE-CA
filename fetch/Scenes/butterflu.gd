extends Node3D

var velocity = Vector3.ZERO
var speed = 2.5
var bounds = 240.0
var wall_thickness = 10.0

var wing_speed = 10.0
var wing_angle = 0.0

func _ready():
	velocity = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()

func _physics_process(delta):
	translate(velocity * speed * delta)

	var pos = global_transform.origin

	if pos.x > bounds or pos.x < -bounds:
		velocity.x *= -1
		pos.x = clamp(pos.x, -bounds + wall_thickness, bounds - wall_thickness)

	if pos.z > bounds or pos.z < -bounds:
		velocity.z *= -1
		pos.z = clamp(pos.z, -bounds + wall_thickness, bounds - wall_thickness)

	pos.y = sin(Time.get_ticks_msec() / 400.0) * 0.8 + 1.5
	global_transform.origin = pos

	# flap wings slowly and wider
	wing_angle = sin(Time.get_ticks_msec() / 150.0) * 45.0
	$left.rotation_degrees = Vector3(0, 0, wing_angle)
	$right.rotation_degrees = Vector3(0, 0, -wing_angle)
