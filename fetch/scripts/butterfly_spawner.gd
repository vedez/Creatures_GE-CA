extends Node3D

@export var initial_butterfly_count := 10
@export var spawn_radius := 45.0

func _ready():
	for i in range(initial_butterfly_count):
		ButterflyManager.spawn_butterfly(self, spawn_radius)
