extends RigidBody3D

signal settled(ball: Node3D)

var was_thrown := false
var has_settled := false
const SETTLE_THRESHOLD := 0.05  # Movement speed under which we consider the ball to be still

@onready var debug_sphere := MeshInstance3D.new()
const DEBUG_SPHERE_RADIUS := 0.3

func _ready():
	sleeping = true
	_setup_debug_visuals()

func _physics_process(delta):
	if was_thrown and not has_settled:
		if sleeping or linear_velocity.length() < SETTLE_THRESHOLD:
			has_settled = true
			emit_signal("settled", self)

	_update_debug()

func mark_as_thrown():
	was_thrown = true
	has_settled = false 
	sleeping = false

func _setup_debug_visuals():
	add_child(debug_sphere)

	var sphere = SphereMesh.new()
	sphere.radius = DEBUG_SPHERE_RADIUS
	sphere.height = DEBUG_SPHERE_RADIUS * 2
	sphere.radial_segments = 16
	sphere.rings = 8
	debug_sphere.mesh = sphere

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.0, 0.0, 0.3)


	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.flags_transparent = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	debug_sphere.material_override = mat

	debug_sphere.visible = false

func _update_debug():
	debug_sphere.visible = Global.debug_enabled
