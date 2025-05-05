extends XRController3D

@onready var grab_area: Area3D = $GrabArea
@onready var anim_player: AnimationPlayer = $HandOffset/HandModel/AnimationPlayer

var held_object: RigidBody3D = null
var last_position: Vector3
var linear_velocity: Vector3
var last_rotation: Basis
var angular_velocity: Vector3

var trigger_value := 0.0
const THROW_FORCE := 1.0
const ANIM_NAME := "Action"
const ANIM_DURATION := 1.0
const GRAB_THRESHOLD := 0.95  # Trigger must be mostly pressed to grab
var trigger_down := false

func _ready():
	last_position = global_transform.origin
	last_rotation = global_transform.basis

func _physics_process(delta):
	# Update movement
	var current_pos = global_transform.origin
	linear_velocity = (current_pos - last_position) / delta
	last_position = current_pos

	var current_rot = global_transform.basis
	angular_velocity = (current_rot.get_euler() - last_rotation.get_euler()) / delta
	last_rotation = current_rot

	# Animate hand based on trigger value
	anim_player.play(ANIM_NAME)
	anim_player.seek(trigger_value * ANIM_DURATION, true)

func _on_input_float_changed(action_name: String, value: float) -> void:
	if action_name == "trigger":
		trigger_value = value

		# Check if we just passed grab threshold
		if trigger_value >= GRAB_THRESHOLD and not trigger_down:
			trigger_down = true
			try_grab()
		elif trigger_value < GRAB_THRESHOLD and trigger_down:
			trigger_down = false
			release()

func try_grab():
	for body in grab_area.get_overlapping_bodies():
		if body is RigidBody3D:
			held_object = body
			held_object.freeze = true
			held_object.get_parent().remove_child(held_object)
			add_child(held_object)
			held_object.global_position = global_transform.origin
			return

func release():
	if held_object == null:
		return

	var obj_transform := held_object.global_transform
	held_object.freeze = false
	remove_child(held_object)
	get_tree().get_current_scene().add_child(held_object)
	held_object.global_transform = obj_transform

	var throw_velocity = linear_velocity * THROW_FORCE
	var max_speed = 20.0

	if throw_velocity.length() > max_speed:
		throw_velocity = throw_velocity.normalized() * max_speed

	held_object.linear_velocity = throw_velocity
	held_object.angular_velocity = angular_velocity
	
	if held_object.has_method("mark_as_thrown"):
		held_object.call("mark_as_thrown")

	held_object = null
