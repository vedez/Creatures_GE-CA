extends Node3D

@export var bee_scene: PackedScene
@export var bee_count: int = 10
@export var spawn_radius: float = 45.0

func _ready():
	for i in range(bee_count):
		var bee = bee_scene.instantiate()
		add_child(bee)

		var x = randf_range(-spawn_radius, spawn_radius)
		var z = randf_range(-spawn_radius, spawn_radius)
		bee.position = Vector3(x, 3.0, z)
