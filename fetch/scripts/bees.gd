extends Node3D

@export var speed: float = 5.0
@export var wall_thickness: float = 10.0
@export var steer_strength: float = 0.5  # How strongly to steer away from walls

var velocity = Vector3.ZERO
var change_timer = 0.0
var change_interval = 1.5

# Wing animation
var wing_angle = 0.0

# Movement bounds (centered at origin)
const BOUNDS_MIN_X := -50.0
const BOUNDS_MAX_X :=  50.0
const BOUNDS_MIN_Z := -50.0
const BOUNDS_MAX_Z :=  50.0

# Vertical movement
const MIN_Y := 1.0
const MAX_Y := 5.0
var vertical_target: float
var vertical_speed: float = 0.5
var vertical_timer := 0.0
var vertical_interval := 2.5

# Rotation offset (optional if your model faces +Z)
@export var facing_offset_degrees := 0.0

func _ready():
	randomize()
	velocity = random_direction()
	vertical_target = randf_range(MIN_Y, MAX_Y)
	vertical_timer = randf_range(1.0, vertical_interval)

func _physics_process(delta):
	var pos = global_transform.origin

	# Vertical movement
	vertical_timer -= delta
	if vertical_timer <= 0.0:
		vertical_target = randf_range(MIN_Y, MAX_Y)
		vertical_timer = randf_range(1.0, vertical_interval)

	pos.y = lerp(pos.y, vertical_target, vertical_speed * delta)
	pos.y += randf_range(-0.02, 0.02)

	# Wandering
	change_timer -= delta
	if change_timer <= 0.0:
		change_timer = randf_range(1.0, change_interval)
		var wander = random_direction() * 0.5
		velocity = (velocity + wander).normalized()

	# Avoid bounds
	var avoid = Vector3.ZERO
	if pos.x < BOUNDS_MIN_X + wall_thickness:
		avoid.x += 1
	elif pos.x > BOUNDS_MAX_X - wall_thickness:
		avoid.x -= 1

	if pos.z < BOUNDS_MIN_Z + wall_thickness:
		avoid.z += 1
	elif pos.z > BOUNDS_MAX_Z - wall_thickness:
		avoid.z -= 1

	if avoid != Vector3.ZERO:
		velocity = (velocity + avoid.normalized() * steer_strength).normalized()

	# Calculate total movement
	var horizontal_move = velocity * speed * delta
	pos.x += horizontal_move.x
	pos.z += horizontal_move.z

	# Apply final position (both XZ and Y)
	global_transform.origin = pos

	# Face movement direction
	if velocity.length() > 0.01:
		var flat_dir = velocity.normalized()
		flat_dir.y = 0
		if flat_dir.length() > 0.01:
			look_at(pos + flat_dir, Vector3.UP)
			rotate_y(deg_to_rad(180 + facing_offset_degrees))

	# Wing flapping
	wing_angle = sin(Time.get_ticks_msec() / 100.0) * 30.0
	$left.rotation_degrees = Vector3(0, 0, wing_angle)
	$right.rotation_degrees = Vector3(0, 0, -wing_angle)


func random_direction() -> Vector3:
	var angle = randf_range(0, TAU)
	return Vector3(cos(angle), 0, sin(angle)).normalized()
