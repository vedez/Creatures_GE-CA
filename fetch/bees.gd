extends Node3D

var velocity = Vector3.ZERO
var speed = 5.0
var bounds = 240.0
var wall_thickness = 10.0

var wing_speed = 10.0
var wing_angle = 0.0

func _ready():
	# set a random XZ direction when bee spawns
	velocity = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()

func _physics_process(delta):
	# move
	translate(velocity * speed * delta)

	var pos = global_transform.origin

	# bounnds X
	if pos.x > bounds or pos.x < -bounds:
		velocity.x *= -1
		pos.x = clamp(pos.x, -bounds + wall_thickness, bounds - wall_thickness)

	# Z bounds
	if pos.z > bounds or pos.z < -bounds:
		velocity.z *= -1
		pos.z = clamp(pos.z, -bounds + wall_thickness, bounds - wall_thickness)

	# hover up/down (y)
	pos.y = sin(Time.get_ticks_msec() / 300.0) * 0.5 + 1.5
	global_transform.origin = pos

	# wings flap
	wing_angle = sin(Time.get_ticks_msec() / 100.0) * 30.0
	$left.rotation_degrees = Vector3(0, 0, wing_angle)
	$right.rotation_degrees = Vector3(0, 0, -wing_angle)
