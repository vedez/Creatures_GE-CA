extends Node3D

# Core nodes
@onready var nav_agent := $NavigationAgent3D
@onready var anim_player := $"Root Scene/AnimationPlayer"
@onready var mouth_slot := $"Root Scene/RootNode/AnimalArmature/Skeleton3D/MouthAttachment"

# Debug helpers
@onready var debug_label := Label3D.new()
@onready var prediction_line := MeshInstance3D.new()
@onready var debug_sphere := MeshInstance3D.new()

# Behavior state
var target_position: Vector3 = Vector3.ZERO
var has_target := false
var base_speed := 3.0
var run_speed := 6.0
var current_speed := 3.0
var current_ball: Node3D = null
var carrying_ball := false
var returning_to_player := false
var player_position := Vector3.ZERO
var debug_state := "Idle"

var wandering := true
var wander_timer := 0.0
var idle_timer := 0.0
const WANDER_INTERVAL := 5.0
const IDLE_ANIM_INTERVAL := 8.0

const WANDER_RADIUS := 20.0
const DEBUG_SPHERE_RADIUS := 2.0

func _ready():
	# Label above dog showing state
	add_child(debug_label)
	debug_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	debug_label.visible = false
	debug_label.text = ""

	# Cyan line from dog to target
	add_child(prediction_line)
	prediction_line.visible = false

	# Transparent yellow debug sphere around dog
	add_child(debug_sphere)
	var sphere := SphereMesh.new()
	sphere.radius = DEBUG_SPHERE_RADIUS
	sphere.height = DEBUG_SPHERE_RADIUS * 2
	sphere.radial_segments = 16
	sphere.rings = 8
	debug_sphere.mesh = sphere

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 1.0, 0.0, 0.2)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.flags_transparent = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	debug_sphere.material_override = mat
	debug_sphere.position = Vector3(0, 1.5, 0)
	debug_sphere.visible = false

	# Start walking right away
	anim_player.play("Walk")
	debug_state = "Wandering"
	wander_timer = WANDER_INTERVAL
	idle_timer = IDLE_ANIM_INTERVAL
	
	_set_new_wander_target()

func _physics_process(delta):
	# Wander by default
	if wandering and not has_target and not carrying_ball:
		wander_timer -= delta
		idle_timer -= delta

		if wander_timer <= 0:
			# Pick a random navmesh point nearby
			_set_new_wander_target()

		elif idle_timer <= 0:
			# Play random idle
			var idle_choice = ["Idle", "Idle_2", "Idle_2_HeadLow"].pick_random()
			anim_player.play(idle_choice)
			debug_state = "Idle - " + idle_choice
			idle_timer = IDLE_ANIM_INTERVAL

	# Path follow
	if has_target:
		if nav_agent.is_navigation_finished():
			has_target = false

			# Reached ball
			if current_ball and not carrying_ball:
				debug_state = "Picking Up Ball"
				anim_player.play("Eating")
				await anim_player.animation_finished

				current_ball.freeze = true
				current_ball.get_parent().remove_child(current_ball)
				mouth_slot.add_child(current_ball)
				current_ball.transform = Transform3D.IDENTITY
				current_ball.scale = Vector3.ONE / mouth_slot.global_transform.basis.get_scale()
				carrying_ball = true

				# Return to player
				var player_forward = $"../Player".global_transform.basis.z.normalized()
				target_position = player_position - player_forward * 2.0
				nav_agent.set_target_position(target_position)
				has_target = true
				returning_to_player = true
				wandering = false
				debug_state = "Returning To Player"
				anim_player.play("Gallop")
				return

			elif returning_to_player and carrying_ball:
				debug_state = "Dropping Ball"
				anim_player.play("Eating")
				await get_tree().create_timer(0.5).timeout

				current_ball.get_parent().remove_child(current_ball)
				get_parent().add_child(current_ball)
				current_ball.global_transform = mouth_slot.global_transform
				current_ball.freeze = false

				current_ball = null
				carrying_ball = false
				returning_to_player = false

				current_speed = base_speed
				wandering = true  # Resume wander mode
				var idle_choice = ["Idle", "Idle_2", "Idle_2_HeadLow", "Attack"].pick_random()
				$BarkPlayer.play()
				anim_player.play(idle_choice)
				debug_state = "Idle"
				return

			anim_player.play("Idle")
			debug_state = "Idle"
			return

		# Move toward next path point
		var next_position = nav_agent.get_next_path_position()
		var direction = (next_position - global_transform.origin).normalized()
		global_transform.origin += direction * current_speed * delta


		if direction.length() > 0.1:
			look_at(global_transform.origin + direction, Vector3.UP)
			rotate_y(deg_to_rad(180))

	# Debug visuals
	_update_debug()

# Called externally when a ball has settled
func on_ball_landed(ball: Node3D):
	if carrying_ball:
		return  # already carrying something, ignore

	# Interrupt current state immediately
	has_target = true
	returning_to_player = false
	wandering = false
	current_ball = ball
	player_position = $"../Player".global_transform.origin
	target_position = ball.global_transform.origin

	# Clear any existing path first to prevent a stale nav path
	nav_agent.set_target_position(Vector3.ZERO)
	await get_tree().process_frame
	nav_agent.set_target_position(target_position)

	current_speed = run_speed
	anim_player.play("Gallop")
	debug_state = "Going To Ball"

	# Cancel timers so force reset to prevent wander reactivating
	wander_timer = WANDER_INTERVAL
	idle_timer = IDLE_ANIM_INTERVAL

func _set_new_wander_target():
	var offset = Vector3(randf_range(-WANDER_RADIUS, WANDER_RADIUS), 0, randf_range(-WANDER_RADIUS, WANDER_RADIUS))
	target_position = global_transform.origin + offset
	nav_agent.set_target_position(target_position)
	has_target = true
	anim_player.play("Walk")
	debug_state = "Wandering"
	wander_timer = WANDER_INTERVAL

func reset_to_wander():
	# Clear ball tracking and return to wander
	current_ball = null
	carrying_ball = false
	returning_to_player = false
	has_target = false
	wandering = true
	anim_player.play("Idle")
	debug_state = "Idle"

func _update_debug():
	debug_label.visible = Global.debug_enabled
	prediction_line.visible = Global.debug_enabled
	debug_sphere.visible = Global.debug_enabled

	if Global.debug_enabled:
		debug_label.global_position = global_transform.origin + Vector3(0, 2.5, 0)
		debug_label.text = debug_state

		if has_target:
			var local_from = to_local(global_transform.origin)
			var local_to = to_local(target_position)

			var mesh := ImmediateMesh.new()
			var mat := StandardMaterial3D.new()
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mat.albedo_color = Color.HOT_PINK

			mesh.surface_begin(Mesh.PRIMITIVE_LINES, mat)
			mesh.surface_add_vertex(local_from)
			mesh.surface_add_vertex(local_to)
			mesh.surface_end()

			prediction_line.mesh = mesh
		else:
			prediction_line.mesh = null
