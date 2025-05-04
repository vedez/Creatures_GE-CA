extends Node3D

@export var wind_direction: Vector3 = Vector3(1, 0, 0)
@export var wind_speed: float = 1.0
@export var cloud_reset_distance: float = 100.0
@export var cloud_spawn_offset: float = -100.0

func _physics_process(delta):
	var dir = wind_direction.normalized()
	for cloud in get_children():
		if cloud is Node3D:
			cloud.translate(dir * wind_speed * delta)

			# Check how far the cloud has moved along the wind direction
			var local_offset = cloud.global_transform.origin - global_transform.origin
			var projected = local_offset.dot(dir)

			if projected > cloud_reset_distance:
				cloud.translate(dir * cloud_spawn_offset)
