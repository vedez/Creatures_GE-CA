extends Node3D

@export var wind_direction: Vector3 = Vector3(1, 0, 0)  
@export var wind_speed: float = 2.0                    
@export var cloud_reset_distance: float = 100.0         
@export var cloud_spawn_offset: float = -100.0         

func _physics_process(delta):
	for cloud in get_children():
		if cloud is Node3D:
			cloud.translate(wind_direction.normalized() * wind_speed * delta)

			var relative_pos = global_transform.origin - cloud.global_transform.origin
			if relative_pos.length() > cloud_reset_distance:
				cloud.translate(wind_direction.normalized() * cloud_spawn_offset)
