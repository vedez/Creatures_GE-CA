extends Node3D

@export var butterfly_scene: PackedScene
@export var butterfly_count: int = 20
@export var spawn_area_size: Vector2 = Vector2(240, 240)  

func _ready():
	for i in butterfly_count:
		var butterfly = butterfly_scene.instantiate()
		
		# Random position within park area
		var x = randf_range(-spawn_area_size.x, spawn_area_size.x)
		var z = randf_range(-spawn_area_size.y, spawn_area_size.y)
		var y = randf_range(1.0, 4.0) 

		butterfly.global_transform.origin = Vector3(x, y, z)
		add_child(butterfly)
