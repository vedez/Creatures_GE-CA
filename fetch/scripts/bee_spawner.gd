extends Node3D

@export var bee_scene: PackedScene
@export var bee_count: int = 10
@export var spawn_area_size: Vector2 = Vector2(240, 240)  

func _ready():
	for i in range(bee_count):
		var bee = bee_scene.instantiate()
		add_child(bee)

		var x = randf_range(-spawn_area_size.x, spawn_area_size.x)
		var z = randf_range(-spawn_area_size.y, spawn_area_size.y)
		bee.position = Vector3(x, 3, z)
