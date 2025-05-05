extends Node3D

# === CONFIGURABLE SETTINGS ===
@export var speed: float = 5.0
@export var wall_thickness: float = 10.0
@export var steer_strength: float = 0.5
@export var facing_offset_degrees := 0.0
@export var min_flight_y: float = 2.5
@export var max_flight_y: float = 7.0
@export var flower_cooldown_min: float = 15.0
@export var flower_cooldown_max: float = 30.0

# === INTERNAL STATE ===
var velocity = Vector3.ZERO
var change_timer := 0.0
var change_interval := 1.5
var vertical_target: float
var vertical_speed := 0.5
var vertical_timer := 0.0
var vertical_interval := 2.5
var wing_angle := 0.0

# Bounds
const BOUNDS_MIN_X := -50.0
const BOUNDS_MAX_X :=  50.0
const BOUNDS_MIN_Z := -50.0
const BOUNDS_MAX_Z :=  50.0

# Flower logic
var is_targeting_flower := false
var target_flower: Node3D = null
var hovering := false
var hover_time := 5.0
var hover_timer := 0.0
var flower_cooldown := 0.0

# Anti-stuck logic
var stuck_timer := 0.0
const STUCK_TIMEOUT := 3.0
const STUCK_DISTANCE_THRESHOLD := 0.1
var last_check_pos: Vector2

# Debug tools
@onready var debug_label := Label3D.new()
@onready var trail_line := MeshInstance3D.new()
@onready var prediction_line := MeshInstance3D.new()
@onready var debug_circle := MeshInstance3D.new()

var trail_points := []
const MAX_TRAIL_POINTS := 20
const TRAIL_POINT_SPACING := 0.2
var last_trail_pos: Vector3

const DEBUG_CIRCLE_RADIUS := 2.0

func _ready():
	randomize()
	velocity = _random_direction()

	# Initialize vertical range
	var base_min := min_flight_y
	var base_max := max_flight_y
	min_flight_y = randf_range(base_min, base_min + 2.0)
	max_flight_y = randf_range(base_max - 2.0, base_max)
	if max_flight_y <= min_flight_y:
		max_flight_y = min_flight_y + 0.5

	vertical_target = randf_range(min_flight_y, max_flight_y)
	vertical_timer = randf_range(1.0, vertical_interval)

	# Cooldown before visiting flower
	flower_cooldown = randf_range(flower_cooldown_min, flower_cooldown_max)

	# Setup debug nodes
	last_trail_pos = global_transform.origin
	add_child(debug_label)
	add_child(trail_line)
	add_child(prediction_line)
	add_child(debug_circle)

	# Setup debug label
	debug_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	debug_label.visible = false
	debug_label.text = ""

	# Setup debug sphere
	var sphere = SphereMesh.new()
	sphere.radius = DEBUG_CIRCLE_RADIUS * 0.5
	sphere.height = DEBUG_CIRCLE_RADIUS
	sphere.radial_segments = 16
	sphere.rings = 8
	debug_circle.mesh = sphere

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.4, 1.0, 0.3)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.flags_transparent = true
	debug_circle.material_override = material
	debug_circle.visible = false

func _physics_process(delta):
	var pos = global_transform.origin

	# Vertical movement logic
	vertical_timer -= delta
	if vertical_timer <= 0.0:
		vertical_target = randf_range(min_flight_y, max_flight_y)
		vertical_timer = randf_range(1.0, vertical_interval)

	pos.y = lerp(pos.y, vertical_target, vertical_speed * delta)
	if not hovering:
		pos.y += randf_range(-0.02, 0.02)

	# Hover logic
	if hovering:
		hover_timer -= delta
		if hover_timer <= 0.0:
			hovering = false
			is_targeting_flower = false
			target_flower = null
			vertical_target = randf_range(min_flight_y, max_flight_y)

		global_transform.origin = pos
		_update_debug()
		return

	# Flower target logic
	if not is_targeting_flower:
		flower_cooldown -= delta
		if flower_cooldown <= 0.0:
			var picked = FlowerManager.get_random_flower()
			if picked:
				target_flower = picked
				is_targeting_flower = true
				flower_cooldown = randf_range(flower_cooldown_min, flower_cooldown_max)

	# Move toward flower
	if is_targeting_flower and target_flower:
		var target_pos = target_flower.global_transform.origin
		var to_target = (target_pos - pos).normalized()
		velocity = lerp(velocity, to_target, delta * 2.0)

		# Stuck detection
		var current_pos_2d = Vector2(pos.x, pos.z)
		if current_pos_2d.distance_to(last_check_pos) < STUCK_DISTANCE_THRESHOLD:
			stuck_timer += delta
			if stuck_timer > STUCK_TIMEOUT:
				is_targeting_flower = false
				target_flower = null
				stuck_timer = 0.0
				vertical_target = randf_range(min_flight_y, max_flight_y)
		else:
			stuck_timer = 0.0
			last_check_pos = current_pos_2d

		# Begin hovering when close
		var horizontal_dist = Vector2(pos.x, pos.z).distance_to(Vector2(target_pos.x, target_pos.z))
		if horizontal_dist < 1.0 and not hovering:
			hovering = true
			hover_timer = hover_time
			vertical_target = -0.5  # move low near flower
	else:
		# Wandering
		change_timer -= delta
		if change_timer <= 0.0:
			change_timer = randf_range(1.0, change_interval)
			var wander = _random_direction() * 0.5
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

	# Apply position
	var horizontal_move = velocity * speed * delta
	pos.x += horizontal_move.x
	pos.z += horizontal_move.z
	global_transform.origin = pos

	# Rotation to face movement
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

	# Debug visuals
	_update_debug()

func _update_debug():
	if Global.debug_enabled:
		debug_label.visible = true
		debug_circle.visible = true
		debug_label.global_position = global_transform.origin + Vector3(0, 0.5, 0)

		var behavior := "Hovering" if hovering else ("Going to Flower" if is_targeting_flower else "Wandering")
		debug_label.text = behavior + "\nVel: " + str(velocity.round()) + "\nCooldown: " + str(snapped(flower_cooldown, 0.1)) + "s"

		# Trail logic
		if global_transform.origin.distance_to(last_trail_pos) >= TRAIL_POINT_SPACING:
			trail_points.append(global_transform.origin)
			last_trail_pos = global_transform.origin
			if trail_points.size() > MAX_TRAIL_POINTS:
				trail_points.pop_front()

		if trail_points.size() >= 2:
			var mesh := ImmediateMesh.new()
			var mat := StandardMaterial3D.new()
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mat.albedo_color = Color.YELLOW
			mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, mat)
			for point in trail_points:
				mesh.surface_add_vertex(to_local(point))
			mesh.surface_end()
			trail_line.mesh = mesh
		else:
			trail_line.mesh = null

		# Prediction
		if is_targeting_flower and target_flower:
			draw_line(global_transform.origin, target_flower.global_transform.origin, prediction_line, Color.CYAN)
		else:
			prediction_line.mesh = null
	else:
		debug_label.visible = false
		debug_circle.visible = false
		trail_line.mesh = null
		prediction_line.mesh = null
		trail_points.clear()

func draw_line(from_global: Vector3, to_global: Vector3, target: MeshInstance3D, color: Color = Color.YELLOW):
	var local_from = to_local(from_global)
	var local_to = to_local(to_global)
	var mesh := ImmediateMesh.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mesh.surface_begin(Mesh.PRIMITIVE_LINES, mat)
	mesh.surface_add_vertex(local_from)
	mesh.surface_add_vertex(local_to)
	mesh.surface_end()
	target.mesh = mesh

func _random_direction() -> Vector3:
	var angle = randf_range(0, TAU)
	return Vector3(cos(angle), 0, sin(angle)).normalized()
