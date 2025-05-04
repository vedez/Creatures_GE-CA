extends Node3D

@export var center_position: Vector3 = Vector3(0, 200, 0)  # Where the clouds orbit around
@export var orbit_radius: float = 100.0                   # Distance from center
@export var min_speed: float = 0.01
@export var max_speed: float = 0.02


var cloud_data = {}  # Stores per-cloud rotation info

func _ready():
	for cloud in get_children():
		if cloud is Node3D:
			var angle = randf() * TAU  # Random starting angle
			var speed = lerp(min_speed, max_speed, randf()) * (1 if randf() > 0.5 else -1)

			cloud_data[cloud] = {
				"angle": angle,
				"speed": speed
			}
			# Set initial position
			cloud.global_transform.origin = center_position + Vector3(
				cos(angle) * orbit_radius,
				0,
				sin(angle) * orbit_radius
			)

func _physics_process(delta):
	for cloud in cloud_data.keys():
		var data = cloud_data[cloud]
		data["angle"] += data["speed"] * delta
		var pos = center_position + Vector3(
			cos(data["angle"]) * orbit_radius,
			0,
			sin(data["angle"]) * orbit_radius
		)
		var transform = cloud.global_transform
		transform.origin = pos
		cloud.global_transform = transform
