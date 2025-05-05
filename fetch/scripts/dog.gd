extends Node3D

@onready var nav_agent := $NavigationAgent3D
@onready var anim_player := $"Root Scene/AnimationPlayer"
@onready var mouth_slot := $"MouthSlot"

var target_position: Vector3 = Vector3.ZERO
var has_target := false
var move_speed := 3.0
var current_ball: Node3D = null
var carrying_ball := false
var returning_to_player := false
var player_position := Vector3.ZERO

func _physics_process(delta):
	if has_target:
		if nav_agent.is_navigation_finished():
			has_target = false

			# Reached the ball
			if current_ball and not carrying_ball:
				anim_player.play("Eating")
				await anim_player.animation_finished

				# Pick up ball
				current_ball.freeze = true
				current_ball.get_parent().remove_child(current_ball)
				mouth_slot.add_child(current_ball)
				current_ball.global_transform = mouth_slot.global_transform
				carrying_ball = true

				# Move to about 2m in front of player (based on their backward direction)
				var player_forward: Vector3 = $"../Player".global_transform.basis.z.normalized()
				target_position = player_position - player_forward * 2.0

				nav_agent.set_target_position(target_position)
				has_target = true
				returning_to_player = true
				anim_player.play("Walk")
				return

			# Reached player
			elif returning_to_player and carrying_ball:
				anim_player.play("Eating")
				await anim_player.animation_finished

				# Drop ball
				current_ball.get_parent().remove_child(current_ball)
				get_parent().add_child(current_ball)
				current_ball.global_position = global_transform.origin + Vector3(0, 0.1, 0.5)
				current_ball.freeze = false

				# Reset state
				current_ball = null
				carrying_ball = false
				returning_to_player = false
				anim_player.play("Idle")
				return

			# General stop fallback
			anim_player.play("Idle")
			return

		# Move toward next point
		var next_position = nav_agent.get_next_path_position()
		var direction = (next_position - global_transform.origin).normalized()
		var new_pos = global_transform.origin + direction * move_speed * delta
		global_transform.origin = new_pos

		# Face movement direction
		if direction.length() > 0.1:
			look_at(global_transform.origin + direction, Vector3.UP)
			rotate_y(deg_to_rad(180)) # Fix model if facing backward

func on_ball_landed(ball: Node3D):
	print("Dog moving to ball at:", ball.global_transform.origin)
	current_ball = ball
	player_position = $"../Player".global_transform.origin

	# Move to the ball first
	target_position = ball.global_transform.origin
	nav_agent.set_target_position(target_position)
	has_target = true
	anim_player.play("Walk")
