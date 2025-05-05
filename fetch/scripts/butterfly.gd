extends Node3D

@export var speed: float = 3.0
@export var wall_thickness: float = 10.0
@export var steer_strength: float = 0.5
@export var facing_offset_degrees := 0.0
@export var min_flight_y: float = 2.5
@export var max_flight_y: float = 15

var velocity = Vector3.ZERO
var change_timer := 0.0
var change_interval := 1.5

var vertical_target: float
var vertical_speed := 0.5
var vertical_timer := 0.0
var vertical_interval := 2.5

# Bounds
const BOUNDS_MIN_X := -50.0
const BOUNDS_MAX_X :=  50.0
const BOUNDS_MIN_Z := -50.0
const BOUNDS_MAX_Z :=  50.0

# Debug
@onready var debug_label := Label3D.new()
@onready var trail_line := MeshInstance3D.new()
@onready var debug_circle := MeshInstance3D.new()
var trail_points := []
var last_trail_pos: Vector3
const MAX_TRAIL_POINTS := 20
const TRAIL_POINT_SPACING := 0.2
const DEBUG_CIRCLE_RADIUS := 2.0

func _ready():
	randomize()
	velocity = _random_direction()
	last_trail_pos = global_transform.origin

	# Vertical drift setup
	vertical_target = randf_range(min_flight_y, max_flight_y)
	vertical_timer = randf_range(1.0, vertical_interval)

	# Debug
	add_child(debug_label)
	add_child(trail_line)
	add_child(debug_circle)

	debug_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	debug_label.text = ""
	debug_label.visible = false

	var sphere = SphereMesh.new()
	sphere.radius = DEBUG_CIRCLE_RADIUS * 0.5
	sphere.height = DEBUG_CIRCLE_RADIUS
	sphere.radial_segments = 16
	sphere.rings = 8
	debug_circle.mesh = sphere

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.6, 1.0, 0.3)  # light blue
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.flags_transparent = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	debug_circle.material_override = mat
	debug_circle.visible = false

	if $Sketchfab_Scene/AnimationPlayer:
		$Sketchfab_Scene/AnimationPlayer.play("fly")
		
	ButterflyManager.add_butterfly(self)

func _physics_process(delta):
	var pos = global_transform.origin

	# Vertical drifting
	vertical_timer -= delta
	if vertical_timer <= 0.0:
		vertical_target = randf_range(min_flight_y, max_flight_y)
		vertical_timer = randf_range(1.0, vertical_interval)

	pos.y = lerp(pos.y, vertical_target, vertical_speed * delta)
	pos.y += randf_range(-0.02, 0.02)

	# Wander
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

	# Move
	var horizontal_move = velocity * speed * delta
	pos.x += horizontal_move.x
	pos.z += horizontal_move.z
	global_transform.origin = pos

	# Face movement
	if velocity.length() > 0.01:
		var flat_dir = velocity.normalized()
		flat_dir.y = 0
		if flat_dir.length() > 0.01:
			look_at(pos + flat_dir, Vector3.UP)
			rotate_y(deg_to_rad(180 + facing_offset_degrees))

	_update_debug()

func _update_debug():
	if Global.debug_enabled:
		debug_label.visible = true
		debug_circle.visible = true
		debug_label.global_position = global_transform.origin + Vector3(0, 0.5, 0)
		debug_label.text = "Wandering\nVel: " + str(velocity.round())

		if global_transform.origin.distance_to(last_trail_pos) >= TRAIL_POINT_SPACING:
			trail_points.append(global_transform.origin)
			last_trail_pos = global_transform.origin
			if trail_points.size() > MAX_TRAIL_POINTS:
				trail_points.pop_front()

		if trail_points.size() >= 2:
			var mesh := ImmediateMesh.new()
			var mat := StandardMaterial3D.new()
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mat.albedo_color = Color.CYAN
			mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, mat)
			for point in trail_points:
				mesh.surface_add_vertex(to_local(point))
			mesh.surface_end()
			trail_line.mesh = mesh
	else:
		debug_label.visible = false
		debug_circle.visible = false
		trail_line.mesh = null
		trail_points.clear()

func _random_direction() -> Vector3:
	var angle = randf_range(0, TAU)
	return Vector3(cos(angle), 0, sin(angle)).normalized()
